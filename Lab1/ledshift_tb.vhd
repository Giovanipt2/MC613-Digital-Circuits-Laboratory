library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ledshift_tb is
end entity ledshift_tb;

architecture tb of ledshift_tb is

    signal CLOCK_50 : std_logic := '0';
    signal KEY : std_logic_vector(3 downto 0) := "1111";
    signal LEDR : std_logic_vector(9 downto 0);
    
    -- Período do clock (50 MHz -> período de 20 ns)
    constant CLK_PERIOD : time := 20 ns;
    
    -- Instância do DUT (Device Under Test)
    component ledshift
        port(
            CLOCK_50: in std_logic;
            KEY: in std_logic_vector(3 downto 0);
            LEDR: out std_logic_vector(9 downto 0)
        );
    end component;
    
begin
    
    -- Instanciando o DUT
    uut: ledshift port map (
        CLOCK_50 => CLOCK_50,
        KEY => KEY,
        LEDR => LEDR
    );
    
    -- Processo para geração do clock
    process
    begin
        while now < 500 ns loop
            CLOCK_50 <= '0';
            wait for CLK_PERIOD / 2;
            CLOCK_50 <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;
    
    -- Processo para simular os botões
    process
    begin
        wait for 100 ns;
        
        -- Pressiona KEY(3) (mover LED para a esquerda)
        KEY(3) <= '0';
        wait for 20 ns;
        KEY(3) <= '1';
        wait for 100 ns;
        
        -- Pressiona KEY(0) (mover LED para a direita)
        KEY(0) <= '0';
        wait for 20 ns;
        KEY(0) <= '1';
        wait for 100 ns;
        
        -- Pressiona KEY(3) duas vezes (mover LED duas vezes para a esquerda)
        KEY(3) <= '0';
        wait for 20 ns;
        KEY(3) <= '1';
        wait for 50 ns;
        KEY(3) <= '0';
        wait for 20 ns;
        KEY(3) <= '1';
        wait for 100 ns;
        
        -- Pressiona KEY(0) três vezes (mover LED três vezes para a direita)
        KEY(0) <= '0';
        wait for 20 ns;
        KEY(0) <= '1';
        wait for 50 ns;
        KEY(0) <= '0';
        wait for 20 ns;
        KEY(0) <= '1';
        wait for 50 ns;
        KEY(0) <= '0';
        wait for 20 ns;
        KEY(0) <= '1';
        
        wait;
    end process;
    
end architecture tb;
