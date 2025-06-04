library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_SDRAM_CTRL is
end tb_SDRAM_CTRL;

architecture Behavioral of tb_SDRAM_CTRL is
    -- Declare signals for DUT ports
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

    -- Clock period (approx 7 ns for 143 MHz)
    constant CLK_PERIOD : time := 7 ns;

    -- Signals for simple SDRAM model
    signal read_cmd_detected : std_logic := '0';
    signal read_delay1       : std_logic := '0';
    signal read_delay2       : std_logic := '0';
    signal read_delay3       : std_logic := '0';

begin
    -- Instantiate the Device Under Test (DUT)
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

    -- Clock generation
    SYS_CLK <= not SYS_CLK after CLK_PERIOD / 2;

    -- Simple SDRAM model: detect READ command and drive DRAM_DQ after CAS latency
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

    -- Drive DRAM_DQ with test data after CAS latency of 3 cycles during read
    DRAM_DQ <= "1111000011110000" when read_delay3 = '1' else (others => 'Z');

    -- Stimulus process
    process
    begin
        -- Wait for initialization to complete (100 μs ≈ 14301 cycles, use 15000 for margin)
        wait for 15000 * CLK_PERIOD;

        -- Write operation
        C_ADDR_IN <= "000000000000001";  -- Example address
        C_DATA_IN <= "1010101010101010"; -- Example data
        C_WRITE   <= '1';
        wait for CLK_PERIOD;
        C_WRITE   <= '0';
        wait until C_READY = '1';        -- Wait for operation to complete

        -- Read operation
        C_ADDR_IN <= "000000000000001";  -- Same address
        C_READ    <= '1';
        wait for CLK_PERIOD;
        C_READ    <= '0';
        wait until C_READY = '1';        -- Wait for operation to complete

        -- Wait to observe refresh operations (refresh occurs every 1000 cycles in IDLE)
        wait for 2000 * CLK_PERIOD;

        -- End simulation
        wait;
    end process;

end Behavioral;