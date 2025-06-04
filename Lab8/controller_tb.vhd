library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_SDRAM_CTRL is
end tb_SDRAM_CTRL;

architecture Behavioral of tb_SDRAM_CTRL is
    -- Sinais para as portas do DUT
    signal SYS_CLK    : std_logic := '0';
    signal C_ADDR_IN  : std_logic_vector(14 downto 0) := (others => '0');
    signal C_DATA_OUT : std_logic_vector(15 downto 0);
    signal C_READY    : std_logic;
    signal C_DATA_IN  : std_logic_vector(15 downto 0) := (others => '0');
    signal C_WRITE    : std_logic := '0';
    signal C_READ     : std_logic := '0';
    signal DRAM_DQ    : std_logic_vector(15 downto 0);
    signal DRAM_ADDR  : std_logic_vector(12 downto 0);
    signal DRAM_BA    : std_logic_vector(1 downto 0);
    signal DRAM_CLK   : std_logic;
    signal DRAM_CKE   : std_logic;
    signal DRAM_LDQM  : std_logic;
    signal DRAM_UDQM  : std_logic;
    signal DRAM_WE_N  : std_logic;
    signal DRAM_CAS_N : std_logic;
    signal DRAM_RAS_N : std_logic;
    signal DRAM_CS_N  : std_logic;

    -- Período do clock (aproximadamente 7 ns para 143 MHz)
    constant CLK_PERIOD : time := 7 ns;

    -- Sinais para o modelo simples de SDRAM
    signal read_cmd_detected : std_logic := '0';
    signal read_delay1       : std_logic := '0';
    signal read_delay2       : std_logic := '0';
    signal read_delay3       : std_logic := '0';

    -- Dados de teste
    signal test_data_write : std_logic_vector(15 downto 0) := "1010101010101010";

begin
    -- Instanciação do Device Under Test (DUT)
    DUT : entity work.SDRAM_CTRL
        port map (
            SYS_CLK    => SYS_CLK,
            C_ADDR_IN  => C_ADDR_IN,
            C_DATA_OUT => C_DATA_OUT,
            C_READY    => C_READY,
            C_DATA_IN  => C_DATA_IN,
            C_WRITE    => C_WRITE,
            C_READ     => C_READ,
            DRAM_DQ    => DRAM_DQ,
            DRAM_ADDR  => DRAM_ADDR,
            DRAM_BA    => DRAM_BA,
            DRAM_CLK   => DRAM_CLK,
            DRAM_CKE   => DRAM_CKE,
            DRAM_LDQM  => DRAM_LDQM,
            DRAM_UDQM  => DRAM_UDQM,
            DRAM_WE_N  => DRAM_WE_N,
            DRAM_CAS_N => DRAM_CAS_N,
            DRAM_RAS_N => DRAM_RAS_N,
            DRAM_CS_N  => DRAM_CS_N
        );

    -- Geração do clock
    SYS_CLK <= not SYS_CLK after CLK_PERIOD / 2;

    -- Modelo simples de SDRAM: detecta comando de leitura e conduz DRAM_DQ após latência CAS
    process(SYS_CLK)
    begin
        if rising_edge(SYS_CLK) then
            read_cmd_detected <= '0';
            if DRAM_CS_N = '0' and DRAM_RAS_N = '1' and DRAM_CAS_N = '0' and DRAM_WE_N = '1' then
                read_cmd_detected <= '1';
            end if;
            read_delay1 <= read_cmd_detected;
            read_delay2 <= read_delay1;
            read_delay3 <= read_delay2;
        end if;
    end process;

    -- Conduz DRAM_DQ com os dados de teste após latência CAS de 3 ciclos durante a leitura
    DRAM_DQ <= test_data_write when read_delay3 = '1' else (others => 'Z');

    -- Processo de estímulo
    process
    begin
        -- Espera a inicialização completar (14311 ciclos)
        wait for 14350 * CLK_PERIOD;

        -- Operação de escrita
        C_ADDR_IN <= "000000000000001";  -- Endereço de exemplo
        C_DATA_IN <= test_data_write;    -- Dados a serem escritos
        C_WRITE   <= '1';
        wait for CLK_PERIOD;
        C_WRITE   <= '0';
        wait for 13 * CLK_PERIOD;        -- Espera a sequência de escrita completar (13 ciclos)

        -- Operação de leitura
        C_ADDR_IN <= "000000000000001";  -- Mesmo endereço
        C_READ    <= '1';
        wait for CLK_PERIOD;
        C_READ    <= '0';
        wait for 12 * CLK_PERIOD;        -- Espera a sequência de leitura completar (12 ciclos)

        -- Espera para observar operações de refresh (ocorre a cada 1000 ciclos no estado IDLE)
        wait for 2000 * CLK_PERIOD;

        -- Fim da simulação
        wait;
    end process;

end Behavioral;
