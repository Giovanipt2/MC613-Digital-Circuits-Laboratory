library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sobel_processor is
    generic (
        IMAGE_WIDTH  : integer := 256;  -- Largura da imagem
        IMAGE_HEIGHT : integer := 256   -- Altura da imagem
    );
    port (
        clk             : in  std_logic;
        reset           : in  std_logic;
        uart_rx_avail   : in  std_logic;                      -- Indica dados disponíveis na UART
        jtag_uart_readdata : in  std_logic_vector(31 downto 0); -- Dados lidos da UART
        jtag_uart_waitrequest : in  std_logic;                 -- Sinal de waitrequest da UART
        jtag_uart_read  : out std_logic;                      -- Sinal de leitura da UART
        jtag_uart_write : out std_logic;                      -- Sinal de escrita na UART
        jtag_uart_writedata : out std_logic_vector(31 downto 0) -- Dados a serem escritos na UART
    );
end entity sobel_processor;

architecture behavioral of sobel_processor is
    -- Definição dos estados
    type state_type is (IDLE, RECEIVE_IMAGE, PROCESS_IMAGE, SEND_IMAGE);
    signal state : state_type := IDLE;

    -- Sinais para UART
    signal uart_rx_data  : std_logic_vector(7 downto 0);  -- Últimos 8 bits de dados
    signal uart_rx_valid : std_logic;                     -- Bit de validação (bit 15)

    -- Contadores e flags
    signal pixel_counter : unsigned(15 downto 0) := (others => '0');
    constant IMAGE_SIZE  : integer := IMAGE_WIDTH * IMAGE_HEIGHT;
    signal x_pos         : integer range 0 to IMAGE_WIDTH - 1 := 0;
    signal y_pos         : integer range 0 to IMAGE_HEIGHT - 1 := 0;
    signal data_to_write : std_logic := '0';

    -- Memória para imagem original e processada
    type image_array is array (0 to IMAGE_SIZE - 1) of std_logic_vector(7 downto 0);
    signal original_image : image_array;
    signal processed_image : image_array;

    -- Tabela de correspondência para raiz quadrada (simplificada)
    type sqrt_table_type is array (0 to 255) of std_logic_vector(7 downto 0);
    constant sqrt_table : sqrt_table_type := (
        "00000000", "00000001", "00000010", "00000011", "00000100", "00000101", -- 0-5
        "00000110", "00000111", "00001000", "00001001", "00001010", "00001011", -- 6-11
        "00001100", "00001101", "00001110", "00001111", "00010000", "00010001", -- 12-17
        -- (Valores adicionais podem ser preenchidos até 255)
        others => "00010000"  -- Aproximação para valores maiores
    );

begin
    -- Processo principal da máquina de estados
    process (clk, reset)
        variable Gx, Gy : integer range -2040 to 2040; -- Máximo para 8 bits com Sobel
        variable G_squared : integer range 0 to 4161600; -- Máximo teórico
    begin
        if reset = '1' then
            state <= IDLE;
            pixel_counter <= (others => '0');
            x_pos <= 0;
            y_pos <= 0;
            data_to_write <= '0';
            jtag_uart_read <= '0';
            jtag_uart_write <= '0';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    jtag_uart_read <= '0';
                    jtag_uart_write <= '0';
                    pixel_counter <= (others => '0');
                    if uart_rx_avail = '1' then
                        state <= RECEIlibrary ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sobel_processor is
    generic (
        IMAGE_WIDTH  : integer := 64;  -- Largura da imagem
        IMAGE_HEIGHT : integer := 64   -- Altura da imagem
    );
    port (
        clk             : in  std_logic;
        reset           : in  std_logic;
        jtag_uart_readdata : in  std_logic_vector(31 downto 0); -- Dados lidos da UART
        jtag_uart_waitrequest : in  std_logic;                 -- Sinal de waitrequest da UART
        jtag_uart_read  : out std_logic;                      -- Sinal de leitura da UART
        jtag_uart_write : out std_logic;                      -- Sinal de escrita na UART
        jtag_uart_writedata : out std_logic_vector(31 downto 0) -- Dados a serem escritos na UART
    );
end entity sobel_processor;

architecture behavioral of sobel_processor is
    -- Definição dos estados
    type state_type is (IDLE, RECEIVE_IMAGE, PROCESS_IMAGE, SEND_IMAGE);
    signal state : state_type := IDLE;

    -- Sinais para UART
    signal uart_rx_avail : std_logic_vector(15 downto 0);
    signal uart_rx_data  : std_logic_vector(7 downto 0);
    signal uart_rx_valid : std_logic;

    -- Contadores e flags
    constant IMAGE_SIZE  : integer := IMAGE_WIDTH * IMAGE_HEIGHT;
    signal pixel_counter : integer range 0 to IMAGE_SIZE - 1 := 0;
    signal x_pos         : integer range 0 to IMAGE_WIDTH - 1 := 0;
    signal y_pos         : integer range 0 to IMAGE_HEIGHT - 1 := 0;
    signal data_to_write : std_logic := '0';

    -- Memória para imagem original e processada
    type image_array is array (0 to IMAGE_SIZE - 1) of std_logic_vector(7 downto 0);
    signal original_image : image_array;
    signal processed_image : image_array;

    -- Sinais para tabela de raiz quadrada
    signal sqrt_addr : std_logic_vector(15 downto 0);
    signal sqrt_value : std_logic_vector(7 downto 0);

begin
    -- Instância da tabela de raiz quadrada
    sqrt_table_inst: entity work.sqrt_table
        port map (
            addr     => sqrt_addr,
            sqrt_out => sqrt_value
        );

    -- Processo principal da máquina de estados
    process (clk, reset)
        variable Gx, Gy : integer;
        variable G_squared : integer;
        variable p00, p01, p02, p10, p11, p12, p20, p21, p22 : unsigned(7 downto 0);
    begin
        if reset = '1' then
            state <= IDLE;
            pixel_counter <= 0;
            x_pos <= 0;
            y_pos <= 0;
            data_to_write <= '0';
            jtag_uart_read <= '0';
            jtag_uart_write <= '0';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    jtag_uart_write <= '0';
                    pixel_counter <= 0;
                    if uart_rx_avail /= "0000000000000000" then
                        state <= RECEIVE_IMAGE;
                    end if;

                when RECEIVE_IMAGE =>
                    if jtag_uart_read = '0' then
                        if uart_rx_avail /= "0000000000000000" then
                            jtag_uart_read <= '1';
                        elsif pixel_counter < IMAGE_SIZE then
                            state <= IDLE;
                        else
                            state <= PROCESS_IMAGE;
                            x_pos <= 0;
                            y_pos <= 0;
                        end if;
                    elsif jtag_uart_waitrequest = '0' then
                        uart_rx_data <= jtag_uart_readdata(7 downto 0);
                        uart_rx_valid <= jtag_uart_readdata(15);
                        uart_rx_avail <= jtag_uart_readdata(31 downto 16);
                        if uart_rx_valid = '1' then
                            original_image(pixel_counter) <= uart_rx_data;
                            pixel_counter <= pixel_counter + 1;
                        end if;
                        jtag_uart_read <= '0';
                    end if;

                when PROCESS_IMAGE =>
                    -- Carregar janela 3x3 com padding
                    if y_pos > 0 and x_pos > 0 then
                        p00 := unsigned(original_image((y_pos-1)*IMAGE_WIDTH + x_pos-1));
                    else
                        p00 := (others => '0');
                    end if;
                    if y_pos > 0 then
                        p01 := unsigned(original_image((y_pos-1)*IMAGE_WIDTH + x_pos));
                    else
                        p01 := (others => '0');
                    end if;
                    if y_pos > 0 and x_pos < IMAGE_WIDTH - 1 then
                        p02 := unsigned(original_image((y_pos-1)*IMAGE_WIDTH + x_pos+1));
                    else
                        p02 := (others => '0');
                    end if;
                    if x_pos > 0 then
                        p10 := unsigned(original_image(y_pos*IMAGE_WIDTH + x_pos-1));
                    else
                        p10 := (others => '0');
                    end if;
                    p11 := unsigned(original_image(y_pos*IMAGE_WIDTH + x_pos));
                    if x_pos < IMAGE_WIDTH - 1 then
                        p12 := unsigned(original_image(y_pos*IMAGE_WIDTH + x_pos+1));
                    else
                        p12 := (others => '0');
                    end if;
                    if y_pos < IMAGE_HEIGHT - 1 and x_pos > 0 then
                        p20 := unsigned(original_image((y_pos+1)*IMAGE_WIDTH + x_pos-1));
                    else
                        p20 := (others => '0');
                    end if;
                    if y_pos < IMAGE_HEIGHT - 1 then
                        p21 := unsigned(original_image((y_pos+1)*IMAGE_WIDTH + x_pos));
                    else
                        p21 := (others => '0');
                    end if;
                    if y_pos < IMAGE_HEIGHT - 1 and x_pos < IMAGE_WIDTH - 1 then
                        p22 := unsigned(original_image((y_pos+1)*IMAGE_WIDTH + x_pos+1));
                    else
                        p22 := (others => '0');
                    end if;

                    -- Calcular Gx e Gy
                    Gx := -to_integer(p00) + to_integer(p02) - 2*to_integer(p10) + 2*to_integer(p12) - to_integer(p20) + to_integer(p22);
                    Gy := -to_integer(p00) - 2*to_integer(p01) - to_integer(p02) + to_integer(p20) + 2*to_integer(p21) + to_integer(p22);
                    G_squared := Gx*Gx + Gy*Gy;
                    if G_squared > 65025 then
                        G_squared := 65025;
                    end if;
                    sqrt_addr <= std_logic_vector(to_unsigned(G_squared, 16));
                    processed_image(y_pos*IMAGE_WIDTH + x_pos) <= sqrt_value;

                    -- Atualizar posição
                    if x_pos = IMAGE_WIDTH - 1 then
                        x_pos <= 0;
                        if y_pos = IMAGE_HEIGHT - 1 then
                            data_to_write <= '1';
                            state <= SEND_IMAGE;
                            pixel_counter <= 0;
                        else
                            y_pos <= y_pos + 1;
                        end if;
                    else
                        x_pos <= x_pos + 1;
                    end if;

                when SEND_IMAGE =>
                    if jtag_uart_write = '0' then
                        if pixel_counter < IMAGE_SIZE then
                            jtag_uart_writedata(7 downto 0) <= processed_image(pixel_counter);
                            jtag_uart_writedata(15) <= '1';
                            jtag_uart_writedata(31 downto 16) <= (others => '0');
                            jtag_uart_writedata(14 downto 8) <= (others => '0');
                            jtag_uart_write <= '1';
                        else
                            data_to_write <= '0';
                            state <= IDLE;
                        end if;
                    elsif jtag_uart_waitrequest = '0' then
                        jtag_uart_write <= '0';
                        pixel_counter <= pixel_counter + 1;
                    end if;
            end case;
        end if;
    end process;

end architecture behavioral;VE_IMAGE;
                        jtag_uart_read <= '1'; -- Inicia leitura
                    end if;

                when RECEIVE_IMAGE =>
                    if jtag_uart_waitrequest = '0' and jtag_uart_read = '1' then
                        uart_rx_data <= jtag_uart_readdata(7 downto 0);
                        uart_rx_valid <= jtag_uart_readdata(15);
                        if uart_rx_valid = '1' then
                            original_image(to_integer(pixel_counter)) <= uart_rx_data;
                            pixel_counter <= pixel_counter + 1;
                        end if;
                        jtag_uart_read <= '0'; -- Desativa leitura após 1 ciclo
                    elsif uart_rx_avail = '0' and pixel_counter < IMAGE_SIZE then
                        state <= IDLE;
                        jtag_uart_read <= '0';
                    elsif pixel_counter = IMAGE_SIZE then
                        state <= PROCESS_IMAGE;
                        jtag_uart_read <= '0';
                        x_pos <= 1; -- Começa a partir de 1 por causa das bordas
                        y_pos <= 1;
                    elsif uart_rx_avail = '1' then
                        jtag_uart_read <= '1'; -- Continua leitura
                    end if;

                when PROCESS_IMAGE =>
                    -- Cálculo do Sobel para posição (x_pos, y_pos)
                    Gx := to_integer(unsigned(original_image(y_pos * IMAGE_WIDTH + x_pos + 1 - IMAGE_WIDTH))) + 
                          2 * to_integer(unsigned(original_image(y_pos * IMAGE_WIDTH + x_pos + 1))) + 
                          to_integer(unsigned(original_image(y_pos * IMAGE_WIDTH + x_pos + 1 + IMAGE_WIDTH))) -
                          to_integer(unsigned(original_image(y_pos * IMAGE_WIDTH + x_pos - 1 - IMAGE_WIDTH))) - 
                          2 * to_integer(unsigned(original_image(y_pos * IMAGE_WIDTH + x_pos - 1))) - 
                          to_integer(unsigned(original_image(y_pos * IMAGE_WIDTH + x_pos - 1 + IMAGE_WIDTH)));

                    Gy := to_integer(unsigned(original_image(y_pos * IMAGE_WIDTH + x_pos - 1 + IMAGE_WIDTH))) + 
                          2 * to_integer(unsigned(original_image(y_pos * IMAGE_WIDTH + x_pos + IMAGE_WIDTH))) + 
                          to_integer(unsigned(original_image(y_pos * IMAGE_WIDTH + x_pos + 1 + IMAGE_WIDTH))) -
                          to_integer(unsigned(original_image(y_pos * IMAGE_WIDTH + x_pos - 1 - IMAGE_WIDTH))) - 
                          2 * to_integer(unsigned(original_image(y_pos * IMAGE_WIDTH + x_pos - IMAGE_WIDTH))) - 
                          to_integer(unsigned(original_image(y_pos * IMAGE_WIDTH + x_pos + 1 - IMAGE_WIDTH)));

                    G_squared := Gx * Gx + Gy * Gy;
                    -- Usa tabela de correspondência para raiz quadrada (limitada a 255)
                    if G_squared > 255 then
                        processed_image(y_pos * IMAGE_WIDTH + x_pos) <= sqrt_table(255);
                    else
                        processed_image(y_pos * IMAGE_WIDTH + x_pos) <= sqrt_table(G_squared);
                    end if;

                    -- Atualiza posição
                    if x_pos = IMAGE_WIDTH - 2 then
                        x_pos <= 1;
                        if y_pos = IMAGE_HEIGHT - 2 then
                            data_to_write <= '1';
                            state <= SEND_IMAGE;
                            pixel_counter <= (others => '0');
                        else
                            y_pos <= y_pos + 1;
                        end if;
                    else
                        x_pos <= x_pos + 1;
                    end if;

                when SEND_IMAGE =>
                    if jtag_uart_waitrequest = '0' and jtag_uart_write = '1' then
                        jtag_uart_write <= '0'; -- Desativa escrita após 1 ciclo
                        pixel_counter <= pixel_counter + 1;
                    elsif pixel_counter < IMAGE_SIZE then
                        jtag_uart_writedata(7 downto 0) <= processed_image(to_integer(pixel_counter));
                        jtag_uart_writedata(15) <= '1'; -- Bit de validação
                        jtag_uart_writedata(31 downto 16) <= (others => '0');
                        jtag_uart_writedata(14 downto 8) <= (others => '0');
                        jtag_uart_write <= '1'; -- Inicia escrita
                    elsif pixel_counter = IMAGE_SIZE then
                        data_to_write <= '0';
                        state <= IDLE;
                    end if;

            end case;
        end if;
    end process;

end architecture behavioral;