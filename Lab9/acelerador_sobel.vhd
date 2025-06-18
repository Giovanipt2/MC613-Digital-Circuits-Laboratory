library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    Port (
        CLOCK_50 : in  std_logic;
        LEDR     : out std_logic_vector(7 downto 0)
    );
end top;

architecture Behavioral of top is

    -- === Clock e Reset ===
    signal clk   : std_logic := '0';
    signal reset : std_logic := '0';  -- Implemente a lÃ³gica para reiniciar o estado da comunicaÃ§Ã£o

    -- === Sinais Avalon-MM para a JTAG UART ===
    signal jtag_uart_cs          : std_logic := '1';  -- Sempre ativo
    signal jtag_uart_waitrequest : std_logic;         -- Indica pedido em processamento
    signal jtag_uart_addr        : std_logic := '0';  -- 0 = data, 1 = control
    signal jtag_uart_read        : std_logic := '0';  -- Indica operaÃ§Ã£o de leitura
    signal jtag_uart_write       : std_logic := '0';  -- Indica operaÃ§Ã£o de escrita
    signal jtag_uart_writedata   : std_logic_vector(31 downto 0) := (others => '0');
    signal jtag_uart_readdata    : std_logic_vector(31 downto 0);

    -- === UART Leitura ===
    signal uart_rx_data  : std_logic_vector(7 downto 0);
    signal uart_rx_valid : std_logic;
    signal uart_rx_avail : std_logic_vector(15 downto 0);

    -- === UART Escrita ===
    signal data_to_write : std_logic := '0';  -- Implemente a lÃ³gica para indicar que hÃ¡ dados para escrever

begin

    -- Clock assignment
    clk <= CLOCK_50;

    -- ExtraÃ§Ã£o dos sinais da UART
    uart_rx_data  <= jtag_uart_readdata(7 downto 0);
    uart_rx_valid <= jtag_uart_readdata(15);
    uart_rx_avail <= jtag_uart_readdata(31 downto 16);

    -- === Avalon-MM Controle de Leitura e Escrita ===
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                jtag_uart_read      <= '0';
                jtag_uart_write     <= '0';
                jtag_uart_writedata <= (others => '0');
                LEDR                <= (others => '0');
            else
                if data_to_write = '1' then
                    -- === Escrita ===
                    if jtag_uart_write = '0' then
                        jtag_uart_write     <= '1';
                        jtag_uart_writedata <= x"00000041";  -- Envia ASCII 'A'

                        -- Implemente sua lÃ³gica para criar o pacote de dados a ser escrito

                    elsif jtag_uart_waitrequest = '0' then
                        jtag_uart_write <= '0';
                    end if;
                else
                    -- === Leitura ===
                    if jtag_uart_read = '0' then
                        jtag_uart_read <= '1';
                    elsif jtag_uart_waitrequest = '0' then
                        jtag_uart_read <= '0';
                        if uart_rx_valid = '1' then
                            LEDR <= uart_rx_data;  -- Mostrar o byte recebido nos LEDs
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- === Instancie o mÃ³dulo JTAG UART seguindo o arquivo _inst gerado ===
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

end Behavioral;
