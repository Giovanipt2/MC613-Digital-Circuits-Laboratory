library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity two_comp_to_7seg is
    port (
        bin         : in  std_logic_vector(3 downto 0);
        segs        : out std_logic_vector(6 downto 0);
        segs_signal : out std_logic_vector(6 downto 0);
        neg         : out std_logic
    );
end two_comp_to_7seg;

architecture Behavioral of two_comp_to_7seg is
    signal neg_int : std_logic;
begin
    -- Assigns the sign bit to the internal signal
    neg_int <= bin(3);
    -- Assigns this internal signal to the output
    neg <= neg_int;
    
    -- Uses the internal signal to display the negative sign
    segs_signal <= "0111111" when neg_int = '1' else "1111111";

    with bin select
        segs <= "1000000" when "0000",  
                "1111001" when "0001",  
                "0100100" when "0010", 
                "0110000" when "0011", 
                "0011001" when "0100",  
                "0010010" when "0101",  
                "0000010" when "0110",  
                "1111000" when "0111",  
                "0000000" when "1000",  
                "1111000" when "1001",  
                "0000010" when "1010",  
                "0010010" when "1011", 
                "0011001" when "1100",  
                "0110000" when "1101",
                "0100100" when "1110",  
                "1111001" when "1111", 
                "1111111" when others; 
				 
end Behavioral;
