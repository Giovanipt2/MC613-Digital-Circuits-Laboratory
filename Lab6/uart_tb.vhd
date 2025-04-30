library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity uart_tb is
-- testbench sem portas
end entity;

architecture tb of uart_tb is
    impure function to_hstring(v : std_logic_vector) return string is
        constant hexmap : string := "0123456789ABCDEF";
        variable nibs   : integer := v'length / 4;
        variable res    : string(1 to nibs);
        variable idx    : integer;
    begin
        for i in 0 to nibs-1 loop
            idx := to_integer(unsigned(v(v'left - i*4 downto v'left - i*4 - 3)));
            res(i+1) := hexmap(idx+1);
        end loop;
        return res;
    end function;
    
    -- sinalização do DUT
    signal clk         : std_logic := '0';
    signal reset       : std_logic := '1';
    signal data        : std_logic_vector(7 downto 0) := (others=>'0');
    signal send_data   : std_logic := '0';
    signal TX          : std_logic;
    signal RX          : std_logic;
    signal received_bits : std_logic_vector(7 downto 0);

    -- componente UART
    component uart
        port (
            clk           : in  std_logic;
            reset         : in  std_logic;
            data          : in  std_logic_vector(7 downto 0);
            send_data     : in  std_logic;
            TX            : out std_logic;
            RX            : in  std_logic;
            received_bits : out std_logic_vector(7 downto 0)
        );
    end component;

    -- Bit time (100 µs) × 11 bits ≈ 1.1 ms
    constant FRAME_TIME : time := 1 ms + 100 us;

begin

    -- Instancia DUT
    DUT: uart
        port map (
            clk           => clk,
            reset         => reset,
            data          => data,
            send_data     => send_data,
            TX            => TX,
            RX            => TX,            -- loop-back
            received_bits => received_bits
        );

    -- clock 50 MHz
    clk_proc: process is
    begin
        clk <= '0'; wait for 10 ns;
        clk <= '1'; wait for 10 ns;
    end process;

    -- estímulos
    stim_proc: process
        type byte_array is array (natural range <>) of std_logic_vector(7 downto 0);
        constant vectors : byte_array := (
            x"55", x"AA", x"FF", x"00"
        );
    begin
        -- reset
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        for i in vectors'range loop
            data      <= vectors(i);
            send_data <= '1';
            wait for 20 ns;        -- um pulso de start
            send_data <= '0';

            wait for FRAME_TIME;   -- aguarda a frame completa

            -- checa recebimento
            assert received_bits = vectors(i)
                report "FAIL: enviado " & to_hstring(vectors(i))
                       & " recebeu " & to_hstring(received_bits)
                       severity error;
            report "PASS: " & to_hstring(vectors(i)) severity note;
        end loop;

        -- encerra simulação
        wait;
    end process;

end architecture;
