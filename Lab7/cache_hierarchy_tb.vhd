library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_hierarchy_tb is
end cache_hierarchy_tb;

architecture behavior of cache_hierarchy_tb is
  -- Parâmetros
  constant ADDR_WIDTH   : integer := 16;        -- Endereços de 16 bits
  constant DATA_WIDTH   : integer := 32;        -- Linha de cache de 32 bits (4 bytes)
  constant OFFSET_WIDTH : integer := 2;         -- 2 bits para offset (4 bytes por linha)

  -- Sinais da CPU
  signal cpu_addr        : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal cpu_start_search: std_logic;
  signal cpu_data        : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal l1_m_data_found : std_logic;
  signal l1_hit         : std_logic;
  signal cpu_write       : std_logic := '0';
  signal cpu_data_out    : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');


  -- Sinais entre L1 e L2
  signal l1_m_addr_out   : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal l1_search_deeper: std_logic;
  signal l1_m_data_in    : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal l2_hit         : std_logic;
  signal l1_m_write       : std_logic := '0';
  signal l1_m_data_out   : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

  -- Sinais entre L2 e ROM
  signal l2_m_addr_out   : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal l2_search_deeper: std_logic;
  signal l2_m_data_in    : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal l2_m_data_found : std_logic;
  signal l2_m_hit         : std_logic := '1';
  signal l2_m_data_out   : std_logic_vector(DATA_WIDTH-1 downto 0) : = (others => '0');
  signal l2_m_write       : std_logic := '0';

  -- Clock e Reset
  signal clk : std_logic := '0';

  -- Memória ROM
  signal rom_data : std_logic_vector(DATA_WIDTH-1 downto 0);


  -- Clock process
  constant CLK_PERIOD : time := 10 ns;

begin

  -- Instanciação das caches
  cache_l1 : entity work.OUTER_CACHE
    generic map (
      TAG_WIDTH    => 10,
      INDEX_WIDTH  => 4,
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
      M_DATA_FOUND     => l1_m_data_found
      M_SEARCH_DEEPER  => l1_search_deeper,
    );

  cache_l2 : entity work.OUTER_CACHE
    generic map (
      TAG_WIDTH    => 6,
      INDEX_WIDTH  => 8,
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
      M_HIT            => l2_m_hit,
      M_DATA_OUT       => l2_m_data_out,
      M_WRITE          => l2_m_write,
      C_START_SEARCH   => l1_search_deeper,
      M_DATA_FOUND     => l2_m_data_found,
      M_SEARCH_DEEPER  => l2_search_deeper
    );

  -- Devolver o valor X quando buscar no endereço X
  l2_m_data_in <= std_logic_vector(resize(unsigned(l2_m_addr_out), 32));
  -- A ROM sempre "encontra" o dado
  l2_m_data_found <= l2_search_deeper;

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

  -- Simulação da CPU
  process
  begin
    wait for 10 ns;

    -- Teste 1: Solicitar endereço 0x0000 (espera miss em L1 e L2, busca na ROM)
    wait for 3*CLK_PERIOD;
    cpu_addr <= x"0000";
    cpu_start_search <= '1';
    wait for CLK_PERIOD;
    cpu_start_search <= '0';
    wait until cpu_data_found = '1';
    report "Teste 1 - Endereço 0x0000: Dado = " & to_hstring(cpu_data) & " (Esperado: 00000000)";
    assert cpu_data = x"00000000" report "Erro no Teste 1" severity error;

    -- Teste 2: Solicitar endereço 0x0000 novamente (espera hit em L1)
    wait for 3*CLK_PERIOD;
    cpu_addr <= x"0000";
    cpu_start_search <= '1';
    wait for CLK_PERIOD;
    cpu_start_search <= '0';
    wait until cpu_data_found = '1';
    report "Teste 2 - Endereço 0x0000: Dado = " & to_hstring(cpu_data) & " (Hit em L1)";
    assert cpu_data = x"00000000" report "Erro no Teste 2" severity error;

    -- Teste 3: Solicitar endereço 0x0010 (espera miss em L1, busca em L2 ou ROM)
    wait for 3*CLK_PERIOD;
    cpu_addr <= x"0010";
    cpu_start_search <= '1';
    wait for CLK_PERIOD;
    cpu_start_search <= '0';
    wait until cpu_data_found = '1';
    report "Teste 3 - Endereço 0x0010: Dado = " & to_hstring(cpu_data) & " (Esperado: 00000010)";
    assert cpu_data = x"00000010" report "Erro no Teste 3" severity error;

    -- Teste 4: Solicitar endereço 0x0100 (espera miss, busca na ROM)
    wait for 3*CLK_PERIOD;
    cpu_addr <= x"0100";
    cpu_start_search <= '1';
    wait for CLK_PERIOD;
    cpu_start_search <= '0';
    wait until cpu_data_found = '1';
    report "Teste 4 - Endereço 0x0100: Dado = " & to_hstring(cpu_data) & " (Esperado: 00000100)";
    assert cpu_data = x"00000100" report "Erro no Teste 4" severity error;

    wait for 3*CLK_PERIOD;
    report "Fim da simulação";
    wait;
  end process;

end behavior;
