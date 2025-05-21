library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Top‐level for DE1-SoC board integration
entity uart_board is
    port (
        -- Board clock
        CLOCK_50   : in  std_logic;                    -- 50 MHz system clock

        -- Pushbuttons (DE1-SoC KEY[1:0], active low on the board)
        KEY        : in  std_logic_vector(1 downto 0);

        -- Slide switches for transmit data
        SW         : in  std_logic_vector(7 downto 0);

        -- LEDs to display received byte
        LEDR       : out std_logic_vector(7 downto 0);

        -- GPIO pins for UART lines (to/from external device)
        GPIO_0     : inout std_logic_vector(35 downto 0)
        -- We will use GPIO_0[0] as RX and GPIO_0[1] as TX
        -- Actual pin assignments in the .qsf constraints:
        -- set_pin_assignment PIN_T20 -name GPIO_0[0] -location RX_GPIO_PIN
        -- set_pin_assignment PIN_R20 -name GPIO_0[1] -location TX_GPIO_PIN
    );
end entity uart_board;

architecture structural of uart_board is

    -- Internal signals
    signal clk          : std_logic;                    -- internal 50 MHz clock
    signal tx_data      : std_logic_vector(7 downto 0); -- data to transmit
    signal rx_data      : std_logic_vector(7 downto 0); -- received data

    -- Map board GPIO to UART RX/TX
    signal uart_rx_line : std_logic;
    signal uart_tx_line : std_logic;

begin

    -------------------------------------------------------------------------
    -- Clock & button de-bouncing / polarity correction
    -------------------------------------------------------------------------
    clk       <= CLOCK_50;

    -- Data to send comes directly from switches
    tx_data   <= SW;

    -- Tie GPIO pins to internal RX/TX signals
    uart_rx_line <= GPIO_0(0);      -- external TX → our RX
    GPIO_0(1)    <= uart_tx_line;   -- our TX → external RX

    -------------------------------------------------------------------------
    -- Instantiate UART controller
    -------------------------------------------------------------------------
    uart_inst : entity work.uart
        port map (
            clk           => clk,
            reset         => not KEY(1),  -- active low
            data          => tx_data,
            send_data     => not KEY(0),  -- active low
            TX            => uart_tx_line,
            RX            => uart_rx_line,
            received_bits => rx_data
        );

    -- Drive LEDs with the latched byte
    LEDR <= rx_data;
                    
end architecture structural;
