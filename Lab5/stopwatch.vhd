library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stopwatch is
    Port (
        clk         : in  std_logic;  -- Clock 50MHz
        clk_enable  : in  std_logic;  -- habilita o funcionamento do cronômetro
        pause_start : in  std_logic;  -- borda de subida: alterna start/pausa
        reset       : in  std_logic;  -- ativo em '1': reseta o cronômetro
        control     : in  std_logic;
        minutes     : out std_logic_vector(6 downto 0);  -- valores de 0 a 99
        seconds     : out std_logic_vector(6 downto 0);  -- valores de 0 a 59
        cent_secs   : out std_logic_vector(6 downto 0)   -- valores de 0 a 99 (centésimos)
    );
end stopwatch;

architecture Behavioral of stopwatch is
    signal running         : std_logic := '0';
    signal cent_counter    : integer range 0 to 99 := 0;
    signal sec_counter     : integer range 0 to 59 := 0;
    signal min_counter     : integer range 0 to 99 := 0;
    signal previous_pause_start : std_logic := '0';
begin

    process(clk, reset)
    begin
        if control = '1' and reset = '1' then
            running      <= '0';
            cent_counter <= 0;
            sec_counter  <= 0;
            min_counter  <= 0;
            previous_pause_start <= '0'; -- Reset previous_pause_start
        elsif rising_edge(clk) then
            if clk_enable = '1' then
                -- Check for pause_start edge
                if control = '1' and (previous_pause_start = '0' and pause_start = '1') then
                    running <= not running;
                end if;
        
                -- Update counters if running
                if running = '1' then
                    if cent_counter = 99 then
                        cent_counter <= 0;
                        if sec_counter = 59 then
                            sec_counter <= 0;
                            if min_counter = 99 then
                                min_counter <= 0;
                            else
                                min_counter <= min_counter + 1;
                            end if;
                        else
                            sec_counter <= sec_counter + 1;
                        end if;
                    else
                        cent_counter <= cent_counter + 1;
                    end if;
                end if;
                
                -- Update previous_pause_start
                previous_pause_start <= pause_start;
            end if;
            
        end if;
    end process;

    minutes   <= std_logic_vector(to_unsigned(min_counter, 7));
    seconds   <= std_logic_vector(to_unsigned(sec_counter, 7));
    cent_secs <= std_logic_vector(to_unsigned(cent_counter, 7));

end Behavioral;