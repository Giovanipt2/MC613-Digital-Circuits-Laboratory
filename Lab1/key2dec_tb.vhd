library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity key2dec_tb is
end entity key2dec_tb;

architecture tb of key2dec_tb is
  signal hex: std_logic_vector(0 to 6);
  signal keys: std_logic_vector(3 downto 0) := (others => '0');
  
  signal clock: std_logic := '0';
  signal stop: std_logic;
begin
  uut: entity work.key2dec port map(HEX5 => hex, KEY => keys);
  
  clock <= not clock after 5 ns when stop = '0' else '0';
  stop <= '1' when keys = (keys'range => '1') else '0';
  
  process(clock)
  begin
    if clock'event and clock = '1' and stop = '0' then
      keys <= std_logic_vector(to_unsigned(to_integer(unsigned(keys)) + 1, keys'length));
    end if;
  end process;
end architecture tb;