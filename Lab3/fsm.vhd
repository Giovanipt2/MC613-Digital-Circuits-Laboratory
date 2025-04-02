--**State Machine**
--A coffee vending machine sells a coffee for R$ 2.50. The machine allows payment with 50-cent coins, 1-real coins, and 2-real bills only. To purchase the coffee, the user must insert coins and bills into the machine until the total value reaches the cost of the coffee. As soon as the total amount inserted is equal to or greater than the cost of the coffee, the machine prepares and dispenses the coffee. Additionally, if the total amount exceeds the cost of the coffee, the machine returns the change to the user corresponding to the difference.

--Your task is to model and develop the hardware for a Moore State Machine to perform the function of the coffee vending machine. The coffee machine is equipped with sensors that detect when each type of coin or bill is inserted, emitting a high-level logical signal. Additionally, it has actuators that can release each type of coin or bill as change, also active at a high logical level. You can assume that it is impossible for more than one input sensor to be active at any given time and that the signals will be active for only one clock period. You can also assume that the actuators can release more than one coin or bill at the same time. The machine also has an actuator that commands the preparation of the coffee. You can assume that having the actuator active (at a high logical level) for one clock period is sufficient to prepare the coffee. You should model the necessary states and transitions, as well as the outputs for each state, in order to fulfill the machine's function.

--The inputs and outputs are:

--| Name      | Width  | Description                           |
--|-----------|--------|---------------------------------------|
--| **Inputs**|
--| clk       | 1 bit  | Clock signal.                         |
--| rst       | 1 bit  | Synchronous reset, active high.       |
--| r50       | 1 bit  | 50-cent coin received.                |
--| r100      | 1 bit  | 1-real coin received.                |
--| r200      | 1 bit  | 2-real bill received.                |
--| **Outputs**|
--| cafe      | 1 bit  | Commands the start of coffee preparation. |
--| t50       | 1 bit  | 50-cent coin as change.              |
--| t100      | 1 bit  | 1-real coin as change.               |
--| t200      | 1 bit  | 2-real bill as change.               |
--| state     | ? bits | Indicates the current state of the machine. |

--The machine should have the following states:
-- 0000: RS0.00
-- 0001: RS0.50
-- 0010: RS1.00
-- 0011: RS1.50
-- 0100: RS2.00
-- 0101: RS2.50
-- 0110: RS3.00
-- 0111: RS3.50
-- 1000: RS4.00

library ieee;
use ieee.std_logic_1164.all;

entity fsm is
port (
    clk, rst, r50, r100, r200 : in std_logic;
    cafe, t50, t100, t200 : out std_logic;
    state : out std_logic_vector(3 downto 0):= "0000" -- initial state
    );
end entity fsm;

architecture logic of fsm is
    signal temp_state : std_logic_vector(3 downto 0);
begin
    state <= temp_state;
    -- when state = "0101", "0110", "0111", "1000" the coffee is prepared
    cafe <= '1' when temp_state = "0101" or temp_state = "0110" or temp_state = "0111" or temp_state = "1000" else '0';

    -- the change will include 50 cents if the temp_state is "0110", 1000"
    t50 <= '1' when temp_state = "0110" or temp_state = "1000" else '0';
    -- the change will include 100 cents if the temp_state is "0111", "1000"
    t100 <= '1' when temp_state = "0111" or temp_state = "1000" else '0';
    -- the change will never include 200 cents
    t200 <= '0';

    -- process to change the temp_state
    process(clk, rst)
    begin
        if rst = '1' then
            temp_state <= "0000";
        elsif rising_edge(clk) then
            case temp_state is
                when "0000" =>
                    if r50 = '0' then
                        temp_state <= "0001";
                    elsif r100 = '0' then
                        temp_state <= "0010";
                    elsif r200 = '0' then
                        temp_state <= "0100";
                    end if;
                when "0001" =>
                    if r50 = '0' then
                        temp_state <= "0010";
                    elsif r100 = '0' then
                        temp_state <= "0011";
                    elsif r200 = '0' then
                        temp_state <= "0101";
                    end if;
                when "0010" =>
                    if r50 = '0' then
                        temp_state <= "0011";
                    elsif r100 = '0' then
                        temp_state <= "0100";
                    elsif r200 = '0' then
                        temp_state <= "0110";
                    end if;
                when "0011" =>
                    if r50 = '0' then
                        temp_state <= "0100";
                    elsif r100 = '0' then
                        temp_state <= "0101";
                    elsif r200 = '0' then
                        temp_state <= "0111";
                    end if;
                when "0100" =>
                    if r50 = '0' then
                        temp_state <= "0101";
                    elsif r100 = '0' then
                        temp_state <= "0110";
                    elsif r200 = '0' then
                        temp_state <= "1000";
                    end if;
                -- If temp_state is "0101", "0110", "0111", "1000" the coffee is prepared, and the temp_state is reset to "0000"
                when "0101" | "0110" | "0111" | "1000" =>
                    temp_state <= "0000";
                when others =>
                    temp_state <= "0000";
            end case;
        end if;
    end process;

end architecture logic;