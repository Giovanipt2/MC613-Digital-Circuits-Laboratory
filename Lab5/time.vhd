library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity time is
    port(
        clk             : in  std_logic;                             -- Clock (assumed 1Hz)
        set_mode_pulse  : in  std_logic;                             -- Single pulse on KEY[2] press (debounced)
        set_value       : in  std_logic_vector(5 downto 0);          -- Value from SW[5..0] for setting time
        hours           : out std_logic_vector(6 downto 0);          -- Current hours (0-23)
        minutes         : out std_logic_vector(6 downto 0);          -- Current minutes (0-59)
        seconds         : out std_logic_vector(6 downto 0);          -- Current seconds (0-59)
        mode            : out std_logic_vector(1 downto 0)           -- Current mode (00: Normal, 01: Set H, 10: Set M, 11: Set S)
    );
end entity time;

architecture behavioral of time is
    -- Internal signals for time counters (already 7 bits)
    signal s_hours   : unsigned(6 downto 0) := (others => '0'); -- 0 to 23
    signal s_minutes : unsigned(6 downto 0) := (others => '0'); -- 0 to 59
    signal s_seconds : unsigned(6 downto 0) := (others => '0'); -- 0 to 59

    -- Internal signal for current mode
    signal s_mode    : std_logic_vector(1 downto 0) := "00"; -- Start in Normal mode
-- Auxiliar signal to save the last mode
signal s_mode_reg : std_logic_vector(1 downto 0) := "00";

    -- Mode constants for readability
    constant MODE_NORMAL : std_logic_vector(1 downto 0) := "00";
    constant MODE_SET_H  : std_logic_vector(1 downto 0) := "01";
    constant MODE_SET_M  : std_logic_vector(1 downto 0) := "10";
    constant MODE_SET_S  : std_logic_vector(1 downto 0) := "11";

begin
    -- Process to control the operating mode (Normal, Set Hour, Set Minute, Set Second)
    mode_control_proc : process(clk) -- Removed reset from sensitivity list
    begin
        if rising_edge(clk) then
            if set_mode_pulse = '1' then
                case s_mode is
                    when MODE_NORMAL => s_mode <= MODE_SET_H;
                    when MODE_SET_H  => s_mode <= MODE_SET_M;
                    when MODE_SET_M  => s_mode <= MODE_SET_S;
                    when MODE_SET_S  => s_mode <= MODE_NORMAL;
                    when others      => s_mode <= MODE_NORMAL;
                end case;
            end if;
s_mode_reg <= s_mode;
        end if;
    end process mode_control_proc;

    -- Process to handle time counting and setting
    time_update_proc : process(clk) -- Removed reset from sensitivity list
        variable v_seconds : unsigned(6 downto 0);
        variable v_minutes : unsigned(6 downto 0);
        variable v_hours   : unsigned(6 downto 0);
        variable set_val_uint : unsigned(5 downto 0);
    begin
        if rising_edge(clk) then
            -- Default to current values
            v_seconds := s_seconds;
            v_minutes := s_minutes;
            v_hours   := s_hours;

            -- Time Counting Logic (always active on clk edge)
            if s_seconds = 59 then
                v_seconds := (others => '0');
                if s_minutes = 59 then
                    v_minutes := (others => '0');
                    if s_hours = 23 then
                        v_hours := (others => '0');
                    else
                        v_hours := s_hours + 1;
                    end if;
                else
                    v_minutes := s_minutes + 1;
                end if;
            else
                v_seconds := s_seconds + 1;
            end if;

            -- Time Setting Logic (overrides counting for the specific unit being set)
            set_val_uint := unsigned(set_value);

            case s_mode_reg is
                when MODE_SET_S =>
                    if set_val_uint <= 59 then
                        -- Resize to match v_seconds width (7 bits)
                        v_seconds := resize(set_val_uint, v_seconds'length);
                    end if;
                when MODE_SET_M =>
                    if set_val_uint <= 59 then
                         -- Resize to match v_minutes width (7 bits)
                        v_minutes := resize(set_val_uint, v_minutes'length);
                    end if;
                when MODE_SET_H =>
                    if set_val_uint <= 23 then
                         -- Resize to match v_hours width (7 bits)
                         v_hours := resize(set_val_uint, v_hours'length);
                    end if;
                when others => -- MODE_NORMAL
                    null; -- Only counting applies
            end case;

            -- Update signals
            s_seconds <= v_seconds;
            s_minutes <= v_minutes;
            s_hours   <= v_hours;

        end if;
    end process time_update_proc;

    -- Assign internal signals to output ports
    hours   <= std_logic_vector(s_hours);
    minutes <= std_logic_vector(s_minutes);
    seconds <= std_logic_vector(s_seconds);
    mode    <= s_mode;

end architecture behavioral;