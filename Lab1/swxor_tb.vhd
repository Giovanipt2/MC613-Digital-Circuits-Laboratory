library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity swxor_tb is
end entity swxor_tb;

architecture tb of swxor_tb is
  signal leds: std_logic_vector(9 downto 0);
  signal sw: std_logic_vector(9 downto 0) := (others => '0');
  
  signal clock: std_logic := '0';
  signal stop: std_logic;
begin

  uut: entity work.swxor port map(LEDR => leds, SW => sw);
  
  clock <= not clock after 5 ns when stop = '0' else '0';
  stop <= '1' when sw = (sw'range => '1') else '0';
  
  process(clock)
  begin
    if clock'event and clock = '1' and stop = '0' then
      sw <= std_logic_vector(to_unsigned(to_integer(unsigned(sw)) + 1, sw'length));
    end if;
  end process;
end architecture tb;
