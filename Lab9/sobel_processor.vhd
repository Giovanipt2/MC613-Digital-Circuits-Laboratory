library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sobel_processor is
    generic (
        IMAGE_WIDTH  : integer := 256;  -- Image's width
        IMAGE_HEIGHT : integer := 256   -- Image's height
    );
    port (
        CLOCK_50 : in  std_logic;
        LEDR     : out std_logic_vector(7 downto 0)
    );
end entity sobel_processor;

architecture behavioral of sobel_processor is
    -- Clock and Reset 
    signal clk   : std_logic := '0';
    signal reset : std_logic := '0';  

    -- Avalon-MM signals to the JTAG UART 
    signal jtag_uart_cs          : std_logic := '1';  -- Always active
    signal jtag_uart_waitrequest : std_logic;         -- Indicates request in processing
    signal jtag_uart_addr        : std_logic := '0';  -- 0 = data, 1 = control
    signal jtag_uart_read        : std_logic := '0';  -- Indicates read operation
    signal jtag_uart_write       : std_logic := '0';  -- Indicates write operation
    signal jtag_uart_writedata   : std_logic_vector(31 downto 0) := (others => '0');
    signal jtag_uart_readdata    : std_logic_vector(31 downto 0);

    -- UART reading
    signal uart_rx_data  : std_logic_vector(7 downto 0);
    signal uart_rx_valid : std_logic;
    signal uart_rx_avail : std_logic_vector(15 downto 0);

    -- UART writing 
    signal data_to_write : std_logic := '0';  

    -- States definition
    type state_type is (IDLE, RECEIVE_IMAGE, PROCESS_IMAGE, SEND_IMAGE);
    signal state : state_type := IDLE;

    -- Counters and flags
    signal pixel_counter        : unsigned(15 downto 0) := (others => '0');
    signal x_pos                : integer range 0 to IMAGE_WIDTH - 1 := 0;
    signal y_pos                : integer range 0 to IMAGE_HEIGHT - 1 := 0;
    signal line_counter         : unsigned(15 downto 0) := (others => '0');  
    signal first_lines_received : std_logic := '0';  -- Flag to indicate if the first 3 lines have been received

    -- Signals for square root calculation
    signal sqrt_addr  : std_logic_vector(17 downto 0);
    signal sqrt_value : std_logic_vector(7 downto 0);

    -- Buffer lines to process 3 lines at a time
    type line_buffer_type is array (0 to IMAGE_WIDTH - 1) of std_logic_vector(7 downto 0);
    signal line_buffer_0      : line_buffer_type;  -- Previous line
    signal line_buffer_1      : line_buffer_type;  -- Current line
    signal line_buffer_2      : line_buffer_type;  -- Next line
    signal output_line_buffer : line_buffer_type;  -- Processed output line

begin
    -- Clock assignment
    clk <= CLOCK_50;

    -- Square root table instantiation
    sqrt_table_inst: entity work.sqrt_table
        port map (
            addr     => sqrt_addr,
            sqrt_out => sqrt_value
        );

    -- Instantiate the JTAG UART module following the generated _inst file
    jtag_uart_inst: entity work.jtag_uart
        port map (
            clk_clk         => clk,
            reset_reset_n   => not reset,
            av_chipselect   => jtag_uart_cs,
            av_address      => jtag_uart_addr,
            av_read_n       => not jtag_uart_read,
            av_readdata     => jtag_uart_readdata,
            av_write_n      => not jtag_uart_write,
            av_writedata    => jtag_uart_writedata,
            av_waitrequest  => jtag_uart_waitrequest,
            irq_irq         => open
        );

    -- Main process to handle the Sobel processing
    process (clk)
        variable Gx, Gy    : integer;
        variable G_squared : integer;
        variable p00, p01, p02, p10, p11, p12, p20, p21, p22 : unsigned(7 downto 0);
    begin
        if reset = '1' then
            state <= IDLE;
            pixel_counter <= (others => '0');
            line_counter <= (others => '0');
            first_lines_received <= '0';
            x_pos <= 0;
            y_pos <= 0;
            data_to_write <= '0';
            jtag_uart_read <= '0';
            jtag_uart_write <= '0';
            jtag_uart_writedata <= (others => '0');
            LEDR <= (others => '0');

        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if uart_rx_avail /= "0000000000000000" then
                        state <= RECEIVE_IMAGE;
                    end if;

                when RECEIVE_IMAGE =>
                    if jtag_uart_read = '0' then
                        if uart_rx_avail /= "0000000000000000" then
                            jtag_uart_read <= '1';
                        -- If there is no data available and it has not finished reading the line, it returns to IDLE
                        elsif pixel_counter < IMAGE_WIDTH then
                            state <= IDLE;  
                        end if;
                    elsif jtag_uart_waitrequest = '0' then
                        uart_rx_data <= jtag_uart_readdata(7 downto 0);
                        uart_rx_valid <= jtag_uart_readdata(15);
                        uart_rx_avail <= jtag_uart_readdata(31 downto 16);
                        if uart_rx_valid = '1' then
                            LEDR <= uart_rx_data;   -- Display the received data on LEDs
                            if first_lines_received = '0' then
                                -- Read the first three lines
                                if line_counter = 0 then
                                    line_buffer_0(to_integer(pixel_counter)) <= uart_rx_data;
                                elsif line_counter = 1 then
                                    line_buffer_1(to_integer(pixel_counter)) <= uart_rx_data;
                                elsif line_counter = 2 then
                                    line_buffer_2(to_integer(pixel_counter)) <= uart_rx_data;
                                end if;
                            else
                                -- Read just the subsequent line
                                line_buffer_2(to_integer(pixel_counter)) <= uart_rx_data;
                            end if;
                            pixel_counter <= pixel_counter + 1;
                            -- Check if the line is complete
                            if pixel_counter = IMAGE_WIDTH - 1 then
                                pixel_counter <= (others => '0');
                                line_counter <= line_counter + 1;
                                if first_lines_received = '0' and line_counter = 2 then
                                    first_lines_received <= '1';
                                    state <= PROCESS_IMAGE;
                                    x_pos <= 0;
                                    y_pos <= 1;  -- Processes the central line (line_buffer_1)
                                elsif first_lines_received = '1' then
                                    state <= PROCESS_IMAGE;
                                    x_pos <= 0;
                                    y_pos <= to_integer(line_counter) - 1;
                                end if;
                            end if;
                        end if;
                        jtag_uart_read <= '0';
                    end if;

                when PROCESS_IMAGE =>
                    -- Loads the 3x3 window of pixels
                    if x_pos > 0 then
                        p00 := unsigned(line_buffer_0(x_pos - 1));
                        p10 := unsigned(line_buffer_1(x_pos - 1));
                        p20 := unsigned(line_buffer_2(x_pos - 1));
                    else
                        p00 := (others => '0');
                        p10 := (others => '0');
                        p20 := (others => '0');
                    end if;
                    p01 := unsigned(line_buffer_0(x_pos));
                    p11 := unsigned(line_buffer_1(x_pos));
                    p21 := unsigned(line_buffer_2(x_pos));
                    if x_pos < IMAGE_WIDTH - 1 then
                        p02 := unsigned(line_buffer_0(x_pos + 1));
                        p12 := unsigned(line_buffer_1(x_pos + 1));
                        p22 := unsigned(line_buffer_2(x_pos + 1));
                    else
                        p02 := (others => '0');
                        p12 := (others => '0');
                        p22 := (others => '0');
                    end if;

                    -- Calculates the Sobel gradient
                    Gx := -to_integer(p00) + to_integer(p02) - 2*to_integer(p10) + 2*to_integer(p12) - to_integer(p20) + to_integer(p22);
                    Gy := -to_integer(p00) - 2*to_integer(p01) - to_integer(p02) + to_integer(p20) + 2*to_integer(p21) + to_integer(p22);
                    G_squared := (Gx * Gx) + (Gy * Gy);
                    if G_squared > 65025 then
                        G_squared := 65025;
                    end if;
                    sqrt_addr <= std_logic_vector(to_unsigned(G_squared, 18));
                    output_line_buffer(x_pos) <= sqrt_value;

                    -- Updates the position
                    if x_pos = IMAGE_WIDTH - 1 then
                        data_to_write <= '1';
                        state <= SEND_IMAGE;
                        pixel_counter <= (others => '0');
                    else
                        x_pos <= x_pos + 1;
                    end if;

                when SEND_IMAGE =>
                    if jtag_uart_write = '0' then
                        if pixel_counter < IMAGE_WIDTH then
                            jtag_uart_writedata(7 downto 0) <= output_line_buffer(to_integer(pixel_counter));
                            jtag_uart_writedata(15) <= '1';
                            jtag_uart_writedata(31 downto 16) <= (others => '0');
                            jtag_uart_writedata(14 downto 8) <= (others => '0');
                            jtag_uart_write <= '1';
                        else
                            data_to_write <= '0';
                            -- Shifts the line buffers
                            line_buffer_0 <= line_buffer_1;
                            line_buffer_1 <= line_buffer_2;
                            if y_pos < IMAGE_HEIGHT - 1 then
                                state <= RECEIVE_IMAGE;     -- Receives the next line
                            else
                                state <= IDLE;              -- All processing is done
                            end if;
                        end if;
                    elsif jtag_uart_waitrequest = '0' then
                        jtag_uart_write <= '0';
                        pixel_counter <= pixel_counter + 1;
                    end if;
            end case;
        end if;
    end process;
end architecture behavioral;
