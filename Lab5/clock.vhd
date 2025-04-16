library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock is
    port(
        CLOCK_50  : in std_logic;  -- 50 MHz clock input
        SW        : in std_logic_vector(9 downto 0);  -- Switch input (controls the setting of the time), only uses SW(5 downto 0)
        KEY       : in std_logic_vector(3 downto 0);  -- Key input, only uses KEY(3 downto 1)
        -- KEY(3): change mode (time/stopwatch)
        -- KEY(2): pause/start (stopwatch) / set time (time)
        -- KEY(1): reset (stopwatch)
        HEX5      : out std_logic_vector(6 downto 0);
        HEX4      : out std_logic_vector(6 downto 0);
        HEX3      : out std_logic_vector(6 downto 0);
        HEX2      : out std_logic_vector(6 downto 0);
        HEX1      : out std_logic_vector(6 downto 0);
        HEX0      : out std_logic_vector(6 downto 0)
        -- HEX*: 7-segment display outputs
    );
end entity clock;

architecture structural of clock is
    signal clock_1Hz          : std_logic := '0';  -- 1 Hz clock signal (used in time)
    signal clock_2Hz          : std_logic := '0';  -- 2 Hz clock signal (used in time)
    signal clock_50Hz        : std_logic := '0';  -- 100 Hz clock signal (used in stopwatch)
    constant MAX_COUNT_1Hz    : integer := 24999999;  -- Count for 1Hz clock (50MHz / 2 - 1)
    signal counter_1Hz        : integer range 0 to MAX_COUNT_1Hz := 0;  -- Counter for 1Hz clock
    constant MAX_COUNT_2Hz    : integer := 12499999;  -- Count for 2Hz clock (50MHz / 4 - 1)
    signal counter_2Hz        : integer range 0 to MAX_COUNT_2Hz := 0;  -- Counter for 2Hz clock
    constant MAX_COUNT_100Hz  : integer := 249999;  -- Count for 100Hz clock (50MHz / 200 - 1)
    signal counter_100Hz      : integer range 0 to MAX_COUNT_100Hz := 0;  -- Counter for 100Hz clock
    signal display_mode       : std_logic := '0';  -- 0 for time, 1 for stopwatch
    signal last_KEY3          : std_logic := '1';  -- Last state of KEY(3), '1' is not pressed
    signal time_hours         : std_logic_vector(6 downto 0);
    signal time_hours_tens    : std_logic_vector(3 downto 0);
    signal time_hours_units   : std_logic_vector(3 downto 0);
    signal time_minutes       : std_logic_vector(6 downto 0);
    signal time_minutes_tens  : std_logic_vector(3 downto 0);
    signal time_minutes_units : std_logic_vector(3 downto 0);
    signal time_seconds       : std_logic_vector(6 downto 0);
    signal time_seconds_tens  : std_logic_vector(3 downto 0);
    signal time_seconds_units : std_logic_vector(3 downto 0);
    signal time_mode          : std_logic_vector(1 downto 0) := (others => '0');  -- Mode output from time entity
    signal sw_minutes         : std_logic_vector(6 downto 0) := (others => '0');
    signal sw_minutes_tens    : std_logic_vector(3 downto 0);
    signal sw_minutes_units   : std_logic_vector(3 downto 0);
    signal sw_seconds         : std_logic_vector(6 downto 0) := (others => '0');
    signal sw_seconds_tens    : std_logic_vector(3 downto 0);
    signal sw_seconds_units   : std_logic_vector(3 downto 0);
    signal sw_cent_secs       : std_logic_vector(6 downto 0) := (others => '0');
    signal sw_cent_tens       : std_logic_vector(3 downto 0);
    signal sw_cent_units      : std_logic_vector(3 downto 0);
    constant BLANK            : std_logic_vector(6 downto 0) := "1111111";  -- Blank display
    signal time_hex5          : std_logic_vector(6 downto 0);
    signal time_hex4          : std_logic_vector(6 downto 0);
    signal time_hex3          : std_logic_vector(6 downto 0);
    signal time_hex2          : std_logic_vector(6 downto 0);
    signal time_hex1          : std_logic_vector(6 downto 0);
    signal time_hex0          : std_logic_vector(6 downto 0);
    signal sw_hex5            : std_logic_vector(6 downto 0);
    signal sw_hex4            : std_logic_vector(6 downto 0);
    signal sw_hex3            : std_logic_vector(6 downto 0);
    signal sw_hex2            : std_logic_vector(6 downto 0);
    signal sw_hex1            : std_logic_vector(6 downto 0);
    signal sw_hex0            : std_logic_vector(6 downto 0);

begin
    -- frequency divisor for 1Hz clock
    process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            if counter_1Hz = MAX_COUNT_1Hz then
                counter_1Hz <= 0;
                clock_1Hz <= not clock_1Hz;
            else
                counter_1Hz <= counter_1Hz + 1;
            end if;
        end if;
    end process;

    -- frequency divisor for 2Hz clock
    process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            if counter_2Hz = MAX_COUNT_2Hz then
                counter_2Hz <= 0;
                clock_2Hz <= not clock_2Hz;
            else
                counter_2Hz <= counter_2Hz + 1;
            end if;
        end if;
    end process;

    -- frequency divisor for 100Hz clock
    process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            if counter_100Hz = MAX_COUNT_100Hz then
                counter_100Hz <= 0;
                clock_50Hz <= not clock_50Hz;
            else
                counter_100Hz <= counter_100Hz + 1;
            end if;
        end if;
    end process;

    -- alternate mode between time and stopwatch
    process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            if last_KEY3 = '1' and KEY(3) = '0' then
                display_mode <= not display_mode;  -- toggle mode
            end if;
            last_KEY3 <= KEY(3);  -- update last state
        end if;
        end process;
        
    -- instantiation of entity time
    time_inst: entity work.time
        port map(
            clk            => clock_1Hz,
            set_mode_pulse => not KEY(2),
            set_value      => SW(5 downto 0),
            hours          => time_hours,
            minutes        => time_minutes,
            seconds        => time_seconds,
            mode           => time_mode
        );

    -- instantiation of entity stopwatch
    sw_inst: entity work.stopwatch
        port map(
            clk         => clock_50Hz,
            pause_start => not KEY(2),
            reset       => not KEY(1),
            minutes     => sw_minutes,
            seconds     => sw_seconds,
            cent_secs   => sw_cent_secs
            );

        -- convert numbers into digits for 7-segment display
    time_hours_tens <= std_logic_vector(to_unsigned(to_integer(unsigned(time_hours)) / 10, 4));
    time_hours_units <= std_logic_vector(to_unsigned(to_integer(unsigned(time_hours)) mod 10, 4));
    time_minutes_tens <= std_logic_vector(to_unsigned(to_integer(unsigned(time_minutes)) / 10, 4));
    time_minutes_units <= std_logic_vector(to_unsigned(to_integer(unsigned(time_minutes)) mod 10, 4));
    time_seconds_tens <= std_logic_vector(to_unsigned(to_integer(unsigned(time_seconds)) / 10, 4));
    time_seconds_units <= std_logic_vector(to_unsigned(to_integer(unsigned(time_seconds)) mod 10, 4));

    sw_minutes_tens <= std_logic_vector(to_unsigned(to_integer(unsigned(sw_minutes)) / 10, 4));
    sw_minutes_units <= std_logic_vector(to_unsigned(to_integer(unsigned(sw_minutes)) mod 10, 4));
    sw_seconds_tens <= std_logic_vector(to_unsigned(to_integer(unsigned(sw_seconds)) / 10, 4));
    sw_seconds_units <= std_logic_vector(to_unsigned(to_integer(unsigned(sw_seconds)) mod 10, 4));
    sw_cent_tens <= std_logic_vector(to_unsigned(to_integer(unsigned(sw_cent_secs)) / 10, 4));
    sw_cent_units <= std_logic_vector(to_unsigned(to_integer(unsigned(sw_cent_secs)) mod 10, 4));

    time_hex5_label: entity work.unsigned_to_7seg port map(bin => time_hours_tens, segs => time_hex5);
    time_hex4_label: entity work.unsigned_to_7seg port map(bin => time_hours_units, segs => time_hex4);
    time_hex3_label: entity work.unsigned_to_7seg port map(bin => time_minutes_tens, segs => time_hex3);
    time_hex2_label: entity work.unsigned_to_7seg port map(bin => time_minutes_units, segs => time_hex2);
    time_hex1_label: entity work.unsigned_to_7seg port map(bin => time_seconds_tens, segs => time_hex1);
    time_hex0_label: entity work.unsigned_to_7seg port map(bin => time_seconds_units, segs => time_hex0);
    
    sw_hex5_label: entity work.unsigned_to_7seg port map(bin => sw_minutes_tens, segs => sw_hex5);
    sw_hex4_label: entity work.unsigned_to_7seg port map(bin => sw_minutes_units, segs => sw_hex4);
    sw_hex3_label: entity work.unsigned_to_7seg port map(bin => sw_seconds_tens, segs => sw_hex3);
    sw_hex2_label: entity work.unsigned_to_7seg port map(bin => sw_seconds_units, segs => sw_hex2);
    sw_hex1_label: entity work.unsigned_to_7seg port map(bin => sw_cent_tens, segs => sw_hex1);
    sw_hex0_label: entity work.unsigned_to_7seg port map(bin => sw_cent_units, segs => sw_hex0);

    process(CLOCK_50)
    begin
        if display_mode = '0' then -- time mode
            -- blinking display for when time is being set
            if time_mode = "01" then
                if clock_2Hz = '1' then
                    HEX5 <= BLANK;
                    HEX4 <= BLANK;
                    HEX3 <= time_hex3;
                    HEX2 <= time_hex2;
                    HEX1 <= time_hex1;
                    HEX0 <= time_hex0;
                else
                    HEX5 <= time_hex5;
                    HEX4 <= time_hex4;
                    HEX3 <= time_hex3;
                    HEX2 <= time_hex2;
                    HEX1 <= time_hex1;
                    HEX0 <= time_hex0;
                end if;
            elsif time_mode = "10" then
                if clock_2Hz = '1' then
                    HEX5 <= time_hex5;
                    HEX4 <= time_hex4;
                    HEX3 <= BLANK;
                    HEX2 <= BLANK;
                    HEX1 <= time_hex1;
                    HEX0 <= time_hex0;
                else
                    HEX5 <= time_hex5;
                    HEX4 <= time_hex4;
                    HEX3 <= time_hex3;
                    HEX2 <= time_hex2;
                    HEX1 <= time_hex1;
                    HEX0 <= time_hex0;
                end if;
            elsif time_mode = "11" then
                if clock_2Hz = '1' then
                    HEX5 <= time_hex5;
                    HEX4 <= time_hex4;
                    HEX3 <= time_hex3;
                    HEX2 <= time_hex2;
                    HEX1 <= BLANK;
                    HEX0 <= BLANK;
                else
                    HEX5 <= time_hex5;
                    HEX4 <= time_hex4;
                    HEX3 <= time_hex3;
                    HEX2 <= time_hex2;
                    HEX1 <= time_hex1;
                    HEX0 <= time_hex0;
                end if;
            else
                HEX5 <= time_hex5;
                HEX4 <= time_hex4;
                HEX3 <= time_hex3;
                HEX2 <= time_hex2;
                HEX1 <= time_hex1;
                HEX0 <= time_hex0;
            end if;
        else -- stopwatch mode
            HEX5 <= sw_hex5;
            HEX4 <= sw_hex4;
            HEX3 <= sw_hex3;
            HEX2 <= sw_hex2;
            HEX1 <= sw_hex1;
            HEX0 <= sw_hex0;
        end if;
    end process;

end architecture structural;