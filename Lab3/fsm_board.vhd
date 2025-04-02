library ieee;
use ieee.std_logic_1164.all;

entity fsm_board is
    port (
        SW    : in  std_logic_vector(9 downto 0);  -- SW[0] -> rst
        KEY   : in  std_logic_vector(3 downto 0);  -- KEY[0] -> clk, KEY[1] -> r50, KEY[2] -> r100, KEY[3] -> r200
        LEDR  : out std_logic_vector(9 downto 0);    -- LEDR[0] -> cafe, LEDR[1] -> t50, LEDR[2] -> t100, LEDR[3] -> t200
        HEX0, HEX1, HEX2 : out std_logic_vector(0 to 6)  -- 7-seg displays
    );
end entity fsm_board;

architecture behav of fsm_board is

    -- Signals to connect to the FSM
    signal clk_sig, rst_sig, r50_sig, r100_sig, r200_sig : std_logic;
    signal cafe_sig, t50_sig, t100_sig, t200_sig : std_logic;
    signal state_sig : std_logic_vector(3 downto 0);

    -- Component declaration for the FSM (fsm.vhd)
    component fsm
        port (
            clk, rst, r50, r100, r200 : in std_logic;
            cafe, t50, t100, t200 : out std_logic;
            state : out std_logic_vector(3 downto 0)
        );
    end component;

    -- Seven segment codes for digits:
    constant seg0 : std_logic_vector(0 to 6) := "0000001";  -- 0
    constant seg1 : std_logic_vector(0 to 6) := "1001111";  -- 1
    constant seg2 : std_logic_vector(0 to 6) := "0010010";  -- 2
    constant seg3 : std_logic_vector(0 to 6) := "0000110";  -- 3
    constant seg4 : std_logic_vector(0 to 6) := "1001100";  -- 4
    constant seg5 : std_logic_vector(0 to 6) := "0100100";  -- 5

    signal hundreds, tens : std_logic_vector(6 downto 0);

begin
    -- Map board inputs
    rst_sig  <= SW(0);
    clk_sig  <= KEY(0);
    r50_sig  <= KEY(1);
    r100_sig <= KEY(2);
    r200_sig <= KEY(3);

    -- Instantiate the FSM
    U1: fsm
        port map (
            clk   => clk_sig,
            rst   => rst_sig,
            r50   => r50_sig,
            r100  => r100_sig,
            r200  => r200_sig,
            cafe  => cafe_sig,
            t50   => t50_sig,
            t100  => t100_sig,
            t200  => t200_sig,
            state => state_sig
        );

    -- Map FSM outputs to LEDs
    LEDR(0) <= cafe_sig;
    LEDR(1) <= t50_sig;
    LEDR(2) <= t100_sig;
    LEDR(3) <= t200_sig;

    -- HEX0 always shows 0
    HEX0 <= "0000001";

    -- Determine tens digit: 0 for states with even number (0000, 0010, 0100, 0110, 1000)
    -- and 5 for states with odd number (0001, 0011, 0101, 0111).
    with state_sig select
        tens <= seg0 when "0000",
                seg5 when "0001",
                seg0 when "0010",
                seg5 when "0011",
                seg0 when "0100",
                seg5 when "0101",
                seg0 when "0110",
                seg5 when "0111",
                seg0 when "1000",
                seg0 when others;
    HEX1 <= tens;

    -- Determine hundreds digit:
    -- "0000"/"0001" => 0, "0010"/"0011" => 1, "0100"/"0101" => 2, "0110"/"0111" => 3, "1000" => 4.
    with state_sig select
        hundreds <= seg0 when "0000" | "0001",
                      seg1 when "0010" | "0011",
                      seg2 when "0100" | "0101",
                      seg3 when "0110" | "0111",
                      seg4 when "1000",
                      seg0 when others;
    HEX2 <= hundreds;

end architecture behav;
