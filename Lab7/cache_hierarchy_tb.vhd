library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_hierarchy_tb is
end cache_hierarchy_tb;

architecture behavior of cache_hierarchy_tb is
  -- Parameters
  constant ADDR_WIDTH   : integer := 16;        -- 16-bit addresses
  constant DATA_WIDTH   : integer := 32;        -- 32-bit cache line (4 bytes)
  constant OFFSET_WIDTH : integer := 2;         -- 2 bits for offset (4 bytes per line)

  -- CPU signals
  signal cpu_addr        : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
  signal cpu_start_search: std_logic := '0';
  signal cpu_data        : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal cpu_write       : std_logic := '0';
  signal cpu_data_out    : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal l1_hit         : std_logic := '0';

  -- Signals between L1 and L2
  signal l1_m_addr_out   : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
  signal l1_search_deeper: std_logic := '0';
  signal l1_m_data_in    : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal l1_m_write       : std_logic := '0';
  signal l1_m_data_out   : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal l2_hit         : std_logic := '0';

  -- Signals between L2 and ROM
  signal l2_m_addr_out   : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
  signal l2_search_deeper: std_logic := '0';
  signal l2_m_data_in    : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal rom_hit         : std_logic := '1';
  signal l2_m_data_out   : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal l2_m_write       : std_logic := '0';

  -- Clock and Reset
  signal clk : std_logic := '0';

  -- Clock process
  constant CLK_PERIOD : time := 10 ns;

  -- Test procedure
  procedure test_address (
    signal cpu_addr         : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal cpu_start_search : out std_logic;
    signal cpu_data         : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    constant test_addr      : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    constant expected_data  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    constant test_name      : in  string
  ) is
  variable delay_counter : integer := 0;
  begin
    -- Setting the address
    wait for CLK_PERIOD;
    cpu_addr <= test_addr;
    wait for CLK_PERIOD;

    -- Resetting the delay counter
    delay_counter := 0;

    -- Starting the search (count 1 cycle)
    cpu_start_search <= '1';
    wait for CLK_PERIOD;
    delay_counter := delay_counter + 1;
    cpu_start_search <= '0';

    -- Wait for 20 cycles using a counter
    while delay_counter < 20 loop
      wait for CLK_PERIOD;
      delay_counter := delay_counter + 1;
    end loop;

    if cpu_data = expected_data then
      report test_name & " - PASSED: Address " & to_hstring(test_addr) & " returned " & to_hstring(cpu_data);
    else
      report test_name & " - FAILED: Address " & to_hstring(test_addr) & " returned " & to_hstring(cpu_data) & ", expected " & to_hstring(expected_data) severity error;
    end if;
  end procedure;

begin

  -- Instantiation of caches
  cache_l1 : entity work.OUTER_CACHE
    generic map (
      TAG_WIDTH    => 10,
      OFFSET_WIDTH => OFFSET_WIDTH,
      DATA_WIDTH   => DATA_WIDTH,
      ADDR_WIDTH   => ADDR_WIDTH
    )
    port map (
      CLK              => clk,
      C_ADDR_IN        => cpu_addr,
      C_DATA_OUT       => cpu_data,
      C_HIT            => l1_hit,
      C_DATA_IN        => cpu_data_out,
      C_WRITE          => cpu_write,
      M_ADDR_OUT       => l1_m_addr_out,
      M_DATA_IN        => l1_m_data_in,
      M_HIT            => l2_hit,
      M_DATA_OUT       => l1_m_data_out,
      M_WRITE          => l1_m_write,
      C_START_SEARCH   => cpu_start_search,
      M_SEARCH_DEEPER  => l1_search_deeper
    );

  cache_l2 : entity work.OUTER_CACHE
    generic map (
      TAG_WIDTH    => 6,
      OFFSET_WIDTH => OFFSET_WIDTH,
      DATA_WIDTH   => DATA_WIDTH,
      ADDR_WIDTH   => ADDR_WIDTH
    )
    port map (
      CLK              => clk,
      C_ADDR_IN        => l1_m_addr_out,
      C_DATA_OUT       => l1_m_data_in,
      C_HIT            => l2_hit,
      C_DATA_IN        => l1_m_data_out,
      C_WRITE          => l1_m_write,
      M_ADDR_OUT       => l2_m_addr_out,
      M_DATA_IN        => l2_m_data_in,
      M_HIT            => rom_hit,
      M_DATA_OUT       => l2_m_data_out,
      M_WRITE          => l2_m_write,
      C_START_SEARCH   => l1_search_deeper,
      M_SEARCH_DEEPER  => l2_search_deeper
    );

    -- Note: This is a simplified ROM implementation for testing purposes
    -- Return the value (X - X%4) when searching for address X
    -- This means the ROM return (X AND 0xFFFFFFFC) to simulate 4-byte alignment
  l2_m_data_in <= std_logic_vector(resize(unsigned(l2_m_addr_out), 32)(31 downto 2) & "00");
  -- The ROM always "finds" the data
  rom_hit <= l2_search_deeper;

  -- Clock process
  process
  begin
    while true loop
      clk <= '0';
      wait for CLK_PERIOD / 2;
      clk <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
  end process;

  -- Simulation process
  process
  begin
    wait for 10 ns;

    -- Test 1: Address 0x1000 (miss in L1 and L2, fetch from ROM)
    test_address(cpu_addr, cpu_start_search, cpu_data, x"1000", x"00001000", "Test 1");

    -- Test 2: Address 0x1000 again (hit in L1)
    test_address(cpu_addr, cpu_start_search, cpu_data, x"1000", x"00001000", "Test 2");

    -- Test 3: Address 0x0001 (miss in L1, fetch from L2 or ROM)
    test_address(cpu_addr, cpu_start_search, cpu_data, x"0001", x"00000000", "Test 3");

    -- Test 4: Address 0x0100 (miss, fetch from ROM)
    test_address(cpu_addr, cpu_start_search, cpu_data, x"0100", x"00000100", "Test 4");

    -- Test 5: Address 0x1004 (same set as 0x1000, different offset)
    test_address(cpu_addr, cpu_start_search, cpu_data, x"1004", x"00001004", "Test 5");

    -- Test 6: Address 0x2000 (new address, miss)
    test_address(cpu_addr, cpu_start_search, cpu_data, x"2000", x"00002000", "Test 6");

    -- Test 7: Address 0x1000 again (hit in L1)
    test_address(cpu_addr, cpu_start_search, cpu_data, x"1000", x"00001000", "Test 7");

    -- Test 8: Address 0x0001 again (hit in L1)
    test_address(cpu_addr, cpu_start_search, cpu_data, x"0001", x"00000000", "Test 8");

    -- Test 9: Address 0x0000 (first access, miss all)
    test_address(cpu_addr, cpu_start_search, cpu_data, x"0000", x"00000000", "Test 9");

    -- Test 10: Address 0x0000 again (should hit in L1)
    test_address(cpu_addr, cpu_start_search, cpu_data, x"0000", x"00000000", "Test 10");

    -- Test 11: Address 0x0003 (max offset within a line)
    test_address(cpu_addr, cpu_start_search, cpu_data, x"0003", x"00000000", "Test 11");

    -- Test 12: Address 0xFFFC (last 4‐byte aligned in space)
    test_address(cpu_addr, cpu_start_search, cpu_data, x"FFFC", x"0000FFFC", "Test 12");

    -- Test 13: Address 0xFFFF (unaligned at very end)
    test_address(cpu_addr, cpu_start_search, cpu_data, x"FFFF", x"0000FFFC", "Test 13");

    -- Test 14: Address 0x0010 (miss, fetch from ROM)
    test_address(cpu_addr, cpu_start_search, cpu_data, x"0010", x"00000010", "Test 14");

    -- Test 15: Address 0x0050 (miss, fetch from ROM)
    test_address(cpu_addr, cpu_start_search, cpu_data, x"0050", x"00000050", "Test 15");

    -- Test 16: Re‐access 0x0010 (should miss in L1 due to eviction and hit)
    test_address(cpu_addr, cpu_start_search, cpu_data, x"0010", x"00000010", "Test 16");


    wait for 3 * CLK_PERIOD;
    report "End of simulation";
    wait;
  end process;

end behavior;

--PERGUNTAS:
-- 1. Pode implementar a memoria ROM da forma que foi feita (só devolver o endereço)?
-- 2. Era assim que queria que implementasse a espera de 20 ciclos antes de devolver a resposta?
-- 3. E o offset? Precisa recortar ele da resposta final ou assim está bom?
-- 4. O diagram está bom? 
