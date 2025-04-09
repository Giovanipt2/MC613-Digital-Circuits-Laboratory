library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ledshift is
   port(
		CLOCK_50: in std_logic;
      KEY: in std_logic_vector(3 downto 0); -- Entradas KEY(3) e KEY(0)
      LEDR: out std_logic_vector(9 downto 0):= "0000100000" -- Saída para LEDs
   );
end entity ledshift;

architecture bhv of ledshift is
	signal position : INTEGER range 0 to 9 := 5;
   signal led_reg  : STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
   signal key_last : STD_LOGIC_VECTOR(3 downto 0) := "1111";

begin
   process(CLOCK_50)
	begin
		if rising_edge(CLOCK_50) then
			if key_last(3) = '1' and KEY(3) = '0' then -- Borda de descida para mover à esquerda
				if position < 9 then
					position <= position + 1;
				end if;
				elsif key_last(0) = '1' and KEY(0) = '0' then -- Borda de descida para mover à direita
					if position > 0 then
						position <= position - 1;
					end if;
			  end if;
			  key_last <= KEY; -- Atualiza o estado anterior dos botões
		end if;
    end process;

    -- Atualiza os LEDs conforme a posição
    process(position)
    begin
        led_reg <= (others => '0');
        led_reg(position) <= '1';
    end process;

    LEDR <= led_reg;

end architecture bhv;

