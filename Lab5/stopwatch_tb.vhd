library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.ENV.STOP;

entity stopwatch_tb is
end stopwatch_tb;

architecture Behavioral of stopwatch_tb is
    signal clk         : std_logic := '0';
    signal pause_start : std_logic := '0';
    signal reset       : std_logic := '0';
    signal minutes     : std_logic_vector(6 downto 0);
    signal seconds     : std_logic_vector(6 downto 0);
    signal cent_secs   : std_logic_vector(6 downto 0);

    constant clk_period : time := 10 ms;  -- período de 0,01s
begin

    -- Instância da entidade stopwatch
    uut: entity work.stopwatch
        port map (
            clk         => clk,
            pause_start => pause_start,
            reset       => reset,
            minutes     => minutes,
            seconds     => seconds,
            cent_secs   => cent_secs
        );

    -- Geração do clock
    clock_process : process
    begin
        while true loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
    end process;

    -- Processo de estímulo
    stimulus : process
    begin
        -- Inicialização: realizar reset
        reset <= '1';
        wait for 20 ms;
        reset <= '0';
        wait for 10 ms;

        -- Iniciar o cronômetro: gerar pulso em pause_start
        pause_start <= '1';
        wait for clk_period;
        pause_start <= '0';
        wait for 4000 ms;  -- deixar contar por um tempo

        -- Pausar o cronômetro: gerar pulso em pause_start
        pause_start <= '1';
        wait for clk_period;
        pause_start <= '0';
        wait for 500 ms;   -- parado

        -- Retomar a contagem: gerar novo pulso
        pause_start <= '1';
        wait for clk_period;
        pause_start <= '0';
        wait for 1000 ms;

        -- Teste do reset assíncrono
        reset <= '1';
        wait for 10 ms;
        reset <= '0';
        wait for 100 ms;

        -- Continua contando por 4 segundos
        wait for 4000 ms;
        
        -- Pausar o cronômetro: gerar pulso em pause_start
        pause_start <= '1';
        wait for clk_period;
        pause_start <= '0';

        -- Finaliza a simulação
        stop;
    end process;

end Behavioral;
