library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller_board is
    port (
        CLOCK_50  : in  std_logic;                      -- 50 MHz clock input
        SW        : in  std_logic_vector(9 downto 0);   -- Switch input for address and data
        KEY       : in  std_logic_vector(3 downto 0);   -- Key input (active low)
        HEX5      : out std_logic_vector(6 downto 0);   -- 7-segment display for address (high nibble)
        HEX4      : out std_logic_vector(6 downto 0);   -- 7-segment display for address (low nibble)
        HEX3      : out std_logic_vector(6 downto 0);   -- 7-segment display for data (nibble 3)
        HEX2      : out std_logic_vector(6 downto 0);   -- 7-segment display for data (nibble 2)
        HEX1      : out std_logic_vector(6 downto 0);   -- 7-segment display for data (nibble 1)
        HEX0      : out std_logic_vector(6 downto 0);   -- 7-segment display for data (nibble 0)
        -- SDRAM Controller Interface (example signals, adjust as per your controller)
        C_ADDR_IN : out std_logic_vector(14 downto 0);  -- SDRAM address (assuming 15-bit address)
        C_DATA_IN : out std_logic_vector(15 downto 0);  -- SDRAM data input
        C_DATA_OUT: in  std_logic_vector(15 downto 0);  -- SDRAM data output
        C_WRITE   : out std_logic;                      -- Write request
        C_READ    : out std_logic;                      -- Read request
        C_READY   : in  std_logic                       -- SDRAM controller ready signal
    );
end entity controller_board;

architecture behavior of controller_board is
    -- PLL component declaration (generated via Quartus IP Catalog)
    component altpll
        port (
            inclk0 : in  std_logic := '0';   -- 50 MHz input clock
            c0     : out std_logic           -- 143 MHz output clock for SDRAM
        );
    end component;

    -- 7-segment display converter component
    component unsigned_to_7seg
        port (
            bin  : in  std_logic_vector(3 downto 0);
            segs : out std_logic_vector(6 downto 0)
        );
    end component;

    -- State machine states for write operation
    type write_state_t is (IDLE, SET_ADDR, SET_DATA, SEND_WRITE);
    signal write_state : write_state_t := IDLE;

    -- Internal signals
    signal sdram_clk    : std_logic;                     -- 143 MHz clock from PLL
    signal addr_reg     : std_logic_vector(9 downto 0);  -- Registered address
    signal data_reg     : std_logic_vector(15 downto 0); -- Registered data (16-bit)
    signal read_data    : std_logic_vector(15 downto 0); -- Data read from SDRAM
    signal key2_debounced, key3_debounced : std_logic;   -- Debounced button signals
    signal key2_prev, key3_prev : std_logic := '1';      -- Previous button states

    -- Debouncing signals
    signal debounce_counter : integer range 0 to 500000 := 0; -- 10ms debounce at 50 MHz
    constant DEBOUNCE_MAX : integer := 500000;

begin
    -- Instantiate PLL for SDRAM clock (143 MHz)
    pll_inst : altpll
    port map (
        inclk0 => CLOCK_50,
        c0     => sdram_clk
    );

    -- Instantiate 7-segment converters
    hex5_inst : unsigned_to_7seg
    port map (bin => "00" & addr_reg(9 downto 8), segs => HEX5); -- High nibble of address

    hex4_inst : unsigned_to_7seg
    port map (bin => addr_reg(7 downto 4), segs => HEX4);        -- Middle nibble of address

    hex3_inst : unsigned_to_7seg
    port map (bin => read_data(15 downto 12), segs => HEX3);     -- Data nibble 3

    hex2_inst : unsigned_to_7seg
    port map (bin => read_data(11 downto 8), segs => HEX2);      -- Data nibble 2

    hex1_inst : unsigned_to_7seg
    port map (bin => read_data(7 downto 4), segs => HEX1);       -- Data nibble 1

    hex0_inst : unsigned_to_7seg
    port map (bin => read_data(3 downto 0), segs => HEX0);       -- Data nibble 0

    -- Button debouncing process
    debounce_proc : process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            if KEY(2) /= key2_prev or KEY(3) /= key3_prev then
                debounce_counter <= 0;
            elsif debounce_counter < DEBOUNCE_MAX then
                debounce_counter <= debounce_counter + 1;
            else
                key2_debounced <= KEY(2);
                key3_debounced <= KEY(3);
            end if;
            key2_prev <= KEY(2);
            key3_prev <= KEY(3);
        end if;
    end process;

    -- Main control process
    control_proc : process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            -- Default outputs
            C_WRITE <= '0';
            C_READ  <= '0';

            -- Read operation (KEY(3))
            if key3_debounced = '0' and write_state = IDLE then
                addr_reg  <= SW(9 downto 0);
                C_ADDR_IN <= "00000" & SW(9 downto 0); -- !!!!!!!!!!! Não esntendi direito pq C_ADDR_IN é 15 bits
                C_READ    <= '1';
                if C_READY = '1' then
                    -- !!!!!!!!!! Pode ser que o C_DATA_OUT ainda nao esteja pronto                    
                    read_data <= C_DATA_OUT;
                end if;
            end if;

            -- Write operation state machine (KEY(2))
            if key2_debounced = '0' and key2_prev = '1' then
                case write_state is
                    when IDLE =>
                        write_state <= SET_ADDR;
                    when SET_ADDR =>
                        addr_reg    <= SW(9 downto 0);
                        write_state <= SET_DATA;
                    when SET_DATA =>
                        data_reg    <= "000000" & SW(9 downto 0); -- Pad to 16 bits
                        write_state <= SEND_WRITE;
                    when SEND_WRITE =>
                        C_ADDR_IN   <= "00000" & addr_reg;
                        C_DATA_IN   <= data_reg;
                        C_WRITE     <= '1';
                        read_data   <= data_reg; -- Update display with written data
                        write_state <= IDLE;
                end case;
            end if;
        end if;
    end process;

end architecture behavior;