library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test_alu is
end entity test_alu;

architecture behavior of test_alu is
    -- Component declaration for the ALU
    component alu
        port (
            A: in std_logic_vector(31 downto 0);
            B: in std_logic_vector(31 downto 0);
            ALUCtl: in std_logic_vector(1 downto 0);
            R: out std_logic_vector(31 downto 0);
            Zero: out std_logic;
            Overflow: out std_logic;
            Cout: out std_logic
        );
    end component;

    -- Signals to connect to the ALU
    signal A, B, R: std_logic_vector(31 downto 0);
    signal ALUCtl: std_logic_vector(1 downto 0);
    signal Zero, Overflow, Cout: std_logic;

begin
    -- Instantiate the ALU
    uut: alu
        port map (
            A => A,
            B => B,
            ALUCtl => ALUCtl,
            R => R,
            Zero => Zero,
            Overflow => Overflow,
            Cout => Cout
        );

    -- Test process
    process
    begin
        -- Test AND operation
        A <= x"0000000F"; B <= x"000000F0"; ALUCtl <= "00";
        wait for 10 ns;
        A <= x"00000001"; B <= x"00000001"; ALUCtl <= "00";
        wait for 10 ns;
        A <= x"00000000"; B <= x"00000000"; ALUCtl <= "00";
        wait for 10 ns;
        A <= x"00200B0F"; B <= x"0B0A00F0"; ALUCtl <= "00";
        wait for 10 ns;

        -- Test ADD operation
        A <= x"0000000F"; B <= x"000000F0"; ALUCtl <= "01";
        wait for 10 ns;
        A <= x"00000001"; B <= x"00000001"; ALUCtl <= "01";
        wait for 10 ns;
        A <= x"00000000"; B <= x"00000000"; ALUCtl <= "01";
        wait for 10 ns;
        A <= x"00200B0F"; B <= x"0B0A00F0"; ALUCtl <= "01";
        wait for 10 ns;
        -- Case with carry out without overflow
        A <= x"FFFFFFFF"; B <= x"00000001"; ALUCtl <= "01";
        wait for 10 ns;
        -- Case with overflow
        A <= x"7FFFFFFF"; B <= x"00000001"; ALUCtl <= "01";
        wait for 10 ns;
        

        -- Test OR operation
        A <= x"0000000F"; B <= x"000000F0"; ALUCtl <= "10";
        wait for 10 ns;
        A <= x"00000001"; B <= x"00000001"; ALUCtl <= "10";
        wait for 10 ns;
        A <= x"00000000"; B <= x"00000000"; ALUCtl <= "10";
        wait for 10 ns;
        A <= x"00200B0F"; B <= x"0B0A00F0"; ALUCtl <= "10";
        wait for 10 ns;

        -- Test SUB operation
        A <= x"00000002"; B <= x"00000001"; ALUCtl <= "11";
        wait for 10 ns;
        A <= x"00000001"; B <= x"00000002"; ALUCtl <= "11";
        wait for 10 ns;
        A <= x"00000000"; B <= x"00000000"; ALUCtl <= "11";
        wait for 10 ns;
        A <= x"00200B0F"; B <= x"0B0A00F0"; ALUCtl <= "11";
        wait for 10 ns;
        A <= x"00000000"; B <= x"00000001"; ALUCtl <= "11";
        wait for 10 ns;
        A <= x"00000001"; B <= x"00000000"; ALUCtl <= "11";
        wait for 10 ns;
        -- Case with carry out
        A <= x"00000001"; B <= x"00000001"; ALUCtl <= "11";
        wait for 10 ns;



        wait;
    end process;
end architecture behavior;
