library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_hierarchy_tb is
end cache_hierarchy_tb;

architecture behavior of cache_hierarchy_tb is
  -- Parâmetros
  constant ADDR_WIDTH   : integer := 16;        -- Enderecos de 16 bits
  constant DATA_WIDTH   : integer := 32;        -- Linha de cache de 32 bits (4 bytes)
  constant OFFSET_WIDTH : integer := 2;         -- 2 bits para offset (4 bytes por linha)

  -- Sinais da CPU
  signal cpu_addr        : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
  signal cpu_start_search: std_logic := '0';
  signal cpu_data        : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal cpu_write       : std_logic := '0';
  signal cpu_data_out    : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal l1_hit         : std_logic := '0';


  -- Sinais entre L1 e L2
  signal l1_m_addr_out   : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
  signal l1_search_deeper: std_logic := '0';
  signal l1_m_data_in    : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal l1_m_write       : std_logic := '0';
  signal l1_m_data_out   : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal l2_hit         : std_logic := '0';

  -- Sinais entre L2 e ROM
  signal l2_m_addr_out   : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
  signal l2_search_deeper: std_logic := '0';
  signal l2_m_data_in    : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal rom_hit         : std_logic := '1';
  signal l2_m_data_out   : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal l2_m_write       : std_logic := '0';

  -- Clock e Reset
  signal clk : std_logic := '0';

  -- Clock process
  constant CLK_PERIOD : time := 10 ns;

  -- Função de teste
  procedure test_address (
    signal cpu_addr         : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal cpu_start_search : out std_logic;
    signal cpu_data         : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    signal l1_hit           : in  std_logic;
    constant test_addr      : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    constant expected_data  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    constant test_name      : in  string
  ) is
  begin
    wait for CLK_PERIOD;
    cpu_addr <= test_addr;
    wait for CLK_PERIOD;
    cpu_start_search <= '1';
    wait for CLK_PERIOD;
    cpu_start_search <= '0';
    wait until l1_hit = '1' for 20 * CLK_PERIOD;
    if l1_hit = '1' then
      if cpu_data = expected_data then
        report test_name & " - PASSOU: Endereco " & to_hstring(test_addr) & " retornou " & to_hstring(cpu_data);
      else
        report test_name & " - FALHOU: Endereco " & to_hstring(test_addr) & " retornou " & to_hstring(cpu_data) & ", esperado " & to_hstring(expected_data) severity error;
      end if;
    else
      report test_name & " - FALHOU: Timeout esperando por hit em L1 para Endereco " & to_hstring(test_addr) severity error;
    end if;
  end procedure;


begin

  -- Instanciação das caches
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

  -- Devolver o valor X quando buscar no Endereco X
  l2_m_data_in <= std_logic_vector(resize(unsigned(l2_m_addr_out), 32));
  -- A ROM sempre "encontra" o dado
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

  -- Processo de simulação
  process
  begin
    wait for 10 ns;

    -- Teste 1: Endereço 0x1000 (miss em L1 e L2, busca na ROM)
    test_address(cpu_addr, cpu_start_search, cpu_data, l1_hit, x"1000", x"00001000", "Teste 1");

    -- Teste 2: Endereço 0x1000 novamente (hit em L1)
    test_address(cpu_addr, cpu_start_search, cpu_data, l1_hit, x"1000", x"00001000", "Teste 2");

    -- Teste 3: Endereço 0x0001 (miss em L1, busca em L2 ou ROM)
    test_address(cpu_addr, cpu_start_search, cpu_data, l1_hit, x"0001", x"00000001", "Teste 3");

    -- Teste 4: Endereço 0x0100 (miss, busca na ROM)
    test_address(cpu_addr, cpu_start_search, cpu_data, l1_hit, x"0100", x"00000100", "Teste 4");

    -- Teste 5: Endereço 0x1004 (mesmo conjunto que 0x1000, offset diferente)
    test_address(cpu_addr, cpu_start_search, cpu_data, l1_hit, x"1004", x"00001004", "Teste 5");

    -- Teste 6: Endereço 0x2000 (novo endereço, miss)
    test_address(cpu_addr, cpu_start_search, cpu_data, l1_hit, x"2000", x"00002000", "Teste 6");

    -- Teste 7: Endereço 0x1000 novamente (hit em L1)
    test_address(cpu_addr, cpu_start_search, cpu_data, l1_hit, x"1000", x"00001000", "Teste 7");

    -- Teste 8: Endereço 0x0001 novamente (hit em L1)
    test_address(cpu_addr, cpu_start_search, cpu_data, l1_hit, x"0001", x"00000001", "Teste 8");

    wait for 3 * CLK_PERIOD;
    report "Fim da simulacao";
    wait;
  end process;

end behavior;
