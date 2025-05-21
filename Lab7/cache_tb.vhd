library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_inner_cache is
end tb_inner_cache;

architecture behavior of tb_inner_cache is
  constant DATA_WIDTH   : integer := 32;
  constant ADDR_WIDTH   : integer := 16;
  constant TAG_WIDTH    : integer := 10;
  constant OFFSET_WIDTH : integer := 2;

  signal CLK       : std_logic := '0';
  signal ADDR      : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal DATA_OUT  : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal HIT       : std_logic;
  signal DATA_IN   : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal WRITE     : std_logic;

  -- Clock period
  constant CLK_PERIOD : time := 10 ns;

begin

  -- Instantiate the Unit Under Test (UUT)
  uut: entity work.INNER_CACHE
    generic map (
      DATA_WIDTH   => DATA_WIDTH,
      ADDR_WIDTH   => ADDR_WIDTH,
      TAG_WIDTH    => TAG_WIDTH,
      OFFSET_WIDTH => OFFSET_WIDTH
    )
    port map (
      CLK      => CLK,
      ADDR     => ADDR,
      DATA_OUT => DATA_OUT,
      HIT      => HIT,
      DATA_IN  => DATA_IN,
      WRITE    => WRITE
    );

  -- Clock process
  clk_process: process
  begin
    while true loop
      CLK <= '0';
      wait for CLK_PERIOD / 2;
      CLK <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
  end process;

  -- Stimulus process
  stim_proc: process
    variable index : integer;
    variable tag   : std_logic_vector(TAG_WIDTH - 1 downto 0);
    variable addr  : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  begin

    -- Initialization
    WRITE <= '0';
    ADDR  <= (others => '0');
    DATA_IN <= (others => '0');
    wait for 20 ns;

    ------------------------------------------------------------------------
    -- Writings: write on all 16 lines with different tags
    ------------------------------------------------------------------------
    for index in 0 to 15 loop
      tag := std_logic_vector(to_unsigned(index, TAG_WIDTH));
      addr := tag & std_logic_vector(to_unsigned(index, 4)) & "00"; -- TAG + INDEX + OFFSET
      ADDR <= addr;
      DATA_IN <= std_logic_vector(to_unsigned(index * 100, DATA_WIDTH)); -- Arbitrário
      WRITE <= '1';
      wait for CLK_PERIOD;
    end loop;
    WRITE <= '0';
    wait for CLK_PERIOD;

    ------------------------------------------------------------------------
    -- Reading: HIT (valid = 1 and TAG matches)
    ------------------------------------------------------------------------
    report "==== Leitura com HIT esperado ====";
    for index in 0 to 15 loop
      tag := std_logic_vector(to_unsigned(index, TAG_WIDTH));
      addr := tag & std_logic_vector(to_unsigned(index, 4)) & "00"; -- Mesma tag usada na escrita
      ADDR <= addr;
      wait for CLK_PERIOD;
      assert HIT = '1'
        report "Erro: Esperava HIT = 1 na linha " & integer'image(index)
        severity error;
    end loop;

    ------------------------------------------------------------------------
    -- Reading: MISS by different TAG (valid = 1, but different TAG)
    ------------------------------------------------------------------------
    report "==== Leitura com TAG diferente (MISS esperado) ====";
    for index in 0 to 15 loop
      tag := std_logic_vector(to_unsigned(index + 1, TAG_WIDTH)); -- TAG diferente da armazenada
      addr := tag & std_logic_vector(to_unsigned(index, 4)) & "00";
      ADDR <= addr;
      wait for CLK_PERIOD;
      assert HIT = '0'
        report "Erro: Esperava MISS (HIT=0) com TAG diferente na linha " & integer'image(index)
        severity error;
    end loop;

    ------------------------------------------------------------------------
    -- Read: MISS for invalid line (valid = 0)
    ------------------------------------------------------------------------
    report "==== Leitura em linha inválida (MISS esperado) ====";
    -- Use line 0 and overwrite with a different TAG but without WRITE
    addr := std_logic_vector(to_unsigned(0, ADDR_WIDTH)); -- linha 0
    -- Manual reset of cache signals can be done only if accessible,
    -- but here we simulate an "address that was not written"
    -- So we access an address never used: tag 0x3FF (maximum)
    tag := std_logic_vector(to_unsigned(1023, TAG_WIDTH));
    addr := tag & std_logic_vector(to_unsigned(0, 4)) & "00";
    ADDR <= addr;
    wait for CLK_PERIOD;
    assert HIT = '0'
      report "Erro: Esperava MISS (linha inválida)" severity error;

    report "==== Fim dos testes ====";
    wait;
  end process;

end behavior;
