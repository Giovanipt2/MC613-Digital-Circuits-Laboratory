library ieee;
use ieee.std_logic_1164.all;

entity swxor is
port (
	LEDR: out std_logic_vector(9 downto 0); 	-- Saida nos LEDS vermelhos
	SW: in std_logic_vector(9 downto 0)			-- Entrada nos switches
  );
end entity swxor;

architecture bhv of swxor is
begin

	LEDR(0) <= '0';	-- Manter LEDR(0) sempre apagado
  
	-- Implementando a repetiçao para fazer o xor
	-- Bloco generate sera usado para gerar hardware repetitivo na FPGA
	gen_xor: for i in 1 to 9 generate
		LEDR(i) <= SW(i) xor SW(i - 1);
	end generate;
  
end architecture bhv;
