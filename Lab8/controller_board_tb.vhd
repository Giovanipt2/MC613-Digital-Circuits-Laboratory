library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller_board_tb is
end entity controller_board_tb;

architecture sim of controller_board_tb is

    -- Component declaration for the DUT
    component controller_board
        port (
            CLOCK_50  	 : in  std_logic;
            SW        : in  std_logic_vector(9 downto 0);
            KEY       : in  std_logic_vector(3 downto 0);
            HEX5      : out std_logic_vector(6 downto 0);
            HEX4      : out std_logic_vector(6 downto 0);
            HEX3      : out std_logic_vector(6 downto 0);
            HEX2      : out std_logic_vector(6 downto 0);
            HEX1      : out std_logic_vector(6 downto 0);
            HEX0      : out std_logic_vector(6 downto 0);
            DRAM_DQ   : inout std_logic_vector(15 downto 0);
            DRAM_ADDR : out   std_logic_vector(12 downto 0);
            DRAM_BA   : out   std_logic_vector(1 downto 0);
            DRAM_CLK  : out   std_logic;
            DRAM_CKE  : out   std_logic;
            DRAM_LDQM : out   std_logic;
            DRAM_UDQM : out   std_logic;
            DRAM_WE_N : out   std_logic;
            DRAM_CAS_N: out   std_logic;
            DRAM_RAS_N: out   std_logic;
            DRAM_CS_N : out   std_logic
        );
    end component;

    -- Testbench signals
	 signal tb_clock_50      : std_logic := '0';
    signal tb_clock      : std_logic := '0';
    signal tb_sw         : std_logic_vector(9 downto 0) := (others => '0');
    signal tb_key        : std_logic_vector(3 downto 0) := (others => '1'); -- Active low
    signal tb_hex5       : std_logic_vector(6 downto 0);
    signal tb_hex4       : std_logic_vector(6 downto 0);
    signal tb_hex3       : std_logic_vector(6 downto 0);
    signal tb_hex2       : std_logic_vector(6 downto 0);
    signal tb_hex1       : std_logic_vector(6 downto 0);
    signal tb_hex0       : std_logic_vector(6 downto 0);
    signal tb_dram_dq    : std_logic_vector(15 downto 0) := (others => 'Z');
    signal tb_dram_addr  : std_logic_vector(12 downto 0);
    signal tb_dram_ba    : std_logic_vector(1 downto 0);
    signal tb_dram_clk   : std_logic;
    signal tb_dram_cke   : std_logic;
    signal tb_dram_ldqm  : std_logic;
    signal tb_dram_udqm  : std_logic;
    signal tb_dram_we_n  : std_logic;
    signal tb_dram_cas_n : std_logic;
    signal tb_dram_ras_n : std_logic;
    signal tb_dram_cs_n  : std_logic;

    -- Clock period
    constant CLOCK_PERIOD : time := 7 ns;  -- 50 MHz
	 constant CLOCK_50_PERIOD : time := 20 ns;

begin

    -- Instantiate the DUT
    dut : controller_board
    port map (
        CLOCK_50     => tb_clock_50,
        SW        => tb_sw,
        KEY       => tb_key,
        HEX5      => tb_hex5,
        HEX4      => tb_hex4,
        HEX3      => tb_hex3,
        HEX2      => tb_hex2,
        HEX1      => tb_hex1,
        HEX0      => tb_hex0,
        DRAM_DQ   => tb_dram_dq,
        DRAM_ADDR => tb_dram_addr,
        DRAM_BA   => tb_dram_ba,
        DRAM_CLK  => tb_clock,
        DRAM_CKE  => tb_dram_cke,
        DRAM_LDQM => tb_dram_ldqm,
        DRAM_UDQM => tb_dram_udqm,
        DRAM_WE_N => tb_dram_we_n,
        DRAM_CAS_N=> tb_dram_cas_n,
        DRAM_RAS_N=> tb_dram_ras_n,
        DRAM_CS_N => tb_dram_cs_n
    );

    -- Clock generation
    tb_clock <= not tb_clock after CLOCK_PERIOD/2;
	 tb_clock_50 <= not tb_clock_50 after CLOCK_50_PERIOD/2;

    -- Simple SDRAM model: Acknowledge read/write after delay
    sdram_model : process
    begin
        wait for 14340*CLOCK_PERIOD; -- Simulate SDRAM init time
        while true loop
            if tb_dram_cs_n = '0' and tb_dram_ras_n = '1' and tb_dram_cas_n = '0' then
                -- Read or Write command
                wait for 2*CLOCK_PERIOD; -- Simulate latency
                if tb_dram_we_n = '1' then
                    tb_dram_dq <= x"1234"; -- Dummy read data
                else
                    tb_dram_dq <= (others => 'Z');
                end if;
                wait for CLOCK_PERIOD;
                tb_dram_dq <= (others => 'Z');
            end if;
            wait for CLOCK_PERIOD;
        end loop;
    end process;

    -- Stimulus process
    stimulus : process
    begin
        -- Initialize
		  wait for 15000*CLOCK_PERIOD;
        tb_key <= (others => '1');
        tb_sw  <= (others => '0');
        wait for 10*CLOCK_PERIOD;

        -- Test Read Operation
        report "Testing Read Operation";
        tb_sw <= "0000000001"; -- Address 0x001
        wait for 5*CLOCK_PERIOD;
        tb_key(3) <= '0';      -- Press KEY(3)
        wait for CLOCK_PERIOD;
        tb_key(3) <= '1';      -- Release
        wait for 20*CLOCK_PERIOD;       -- Wait for operation

        -- Test Write Operation
        report "Testing Write Operation";
        tb_sw <= "0000000010"; -- Address 0x002
        wait for 50 ns;
        tb_key(2) <= '0';      -- Press KEY(2) to start write
        wait for CLOCK_PERIOD;
        tb_key(2) <= '1';      -- Release
        wait for 15*CLOCK_PERIOD;

        tb_sw <= "0000001111"; -- Data 0x00F
        wait for 50*CLOCK_PERIOD;
        tb_key(2) <= '0';      -- Press KEY(2) to confirm data
        wait for CLOCK_PERIOD;
        tb_key(2) <= '1';      -- Release
        wait for 20*CLOCK_PERIOD;       -- Wait for operation

        report "Test completed. Check waveforms.";
        wait;
    end process;

end architecture sim;