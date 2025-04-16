library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity time_tb is
end entity time_tb;

architecture sim of time_tb is
    -- Sinais para a UUT
    signal clk            : std_logic := '0';
    signal set_mode_pulse : std_logic := '0';
    signal set_value      : std_logic_vector(5 downto 0) := (others => '0');
    signal hours          : std_logic_vector(6 downto 0);
    signal minutes        : std_logic_vector(6 downto 0);
    signal seconds        : std_logic_vector(6 downto 0);
    signal mode           : std_logic_vector(1 downto 0);

    -- Constantes para os testes (valores em 6 bits)
    constant VAL_HOURS_15    : std_logic_vector(5 downto 0) := "001111"; -- 15
    constant VAL_MINUTES_45  : std_logic_vector(5 downto 0) := "101101"; -- 45
    constant VAL_SECONDS_30  : std_logic_vector(5 downto 0) := "011110"; -- 30
    constant VAL_MAX_HOURS   : std_logic_vector(5 downto 0) := "010111"; -- 23
    constant VAL_MAX_MINSEC  : std_logic_vector(5 downto 0) := "111011"; -- 59

begin
    -----------------------------------------------------------------------------
    -- UUT instantiation
    -----------------------------------------------------------------------------
    uut: entity work.time port map(
        clk            => clk,
        set_mode_pulse => set_mode_pulse,
        set_value      => set_value,
        hours          => hours,
        minutes        => minutes,
        seconds        => seconds,
        mode           => mode
    );

    -----------------------------------------------------------------------------
    -- Clock generation: período de 10 ns (cada ciclo equivale a 1 "segundo" no design)
    -----------------------------------------------------------------------------
    clk_process: process
    begin
        while true loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
        wait;
    end process clk_process;

    -----------------------------------------------------------------------------
    -- Stimulus process
    -----------------------------------------------------------------------------
    stim_proc: process
    begin
        -----------------------------------------------------------------------------
        -- Modo Normal: Deixe o sistema contar por alguns ciclos para observar o rollover
        -----------------------------------------------------------------------------
        report "Normal Mode: Counting test";
        wait for 100 ns;  -- 10 ciclos de clock

        -----------------------------------------------------------------------------
        -- Teste de mudança para Set Hours:
        -- Aplica o valor a ser setado, espera 1 ciclo para estabilização e, somente
        -- no ciclo seguinte, envia o pulso de mudança de modo.
        -----------------------------------------------------------------------------
        report "Test: Setting Hours to 15";
        set_value <= VAL_HOURS_15;
        wait for 10 ns;  -- Espera um ciclo completo com o set_value já aplicado
        set_mode_pulse <= '1';
        wait for 10 ns;  -- Pulso de 1 ciclo
        set_mode_pulse <= '0';
        wait for 20 ns;  -- Aguarda 2 ciclos para que a mudança seja efetivada

        -----------------------------------------------------------------------------
        -- Teste de mudança para Set Minutes:
        -----------------------------------------------------------------------------
        report "Test: Setting Minutes to 45";
        set_value <= VAL_MINUTES_45;
        wait for 10 ns;   -- Estabiliza o set_value
        set_mode_pulse <= '1';  -- Muda o modo (avança no ciclo, utilizando o valor anterior)
        wait for 10 ns;
        set_mode_pulse <= '0';
        wait for 20 ns;   -- Aguarda a efetivação

        -----------------------------------------------------------------------------
        -- Teste de mudança para Set Seconds:
        -----------------------------------------------------------------------------
        report "Test: Setting Seconds to 30";
        set_value <= VAL_SECONDS_30;
        wait for 10 ns;   -- Estabiliza o set_value
        set_mode_pulse <= '1';  -- Muda o modo para Set Seconds
        wait for 10 ns;
        set_mode_pulse <= '0';
        wait for 20 ns;   -- Aguarda para efetivar a mudança

        -----------------------------------------------------------------------------
        -- Teste de borda para os valores máximos
        -----------------------------------------------------------------------------
        report "Edge Test: Setting Hours to Maximum (23)";
        set_value <= VAL_MAX_HOURS;
        wait for 10 ns;
        set_mode_pulse <= '1';  -- Avança o modo para Set Hours
        wait for 10 ns;
        set_mode_pulse <= '0';
        wait for 20 ns;

        report "Edge Test: Setting Minutes to Maximum (59)";
        set_value <= VAL_MAX_MINSEC;
        wait for 10 ns;
        set_mode_pulse <= '1';  -- Avança o modo para Set Minutes
        wait for 10 ns;
        set_mode_pulse <= '0';
        wait for 20 ns;

        report "Edge Test: Setting Seconds to Maximum (59)";
        set_value <= VAL_MAX_MINSEC;
        wait for 10 ns;
        set_mode_pulse <= '1';  -- Avança o modo para Set Seconds
        wait for 10 ns;
        set_mode_pulse <= '0';
        wait for 20 ns;

        -----------------------------------------------------------------------------
        -- Ciclo completo de modos:
        -- Dispara pulsos consecutivos para percorrer: Normal → Set Hours → Set Minutes → Set Seconds → Normal.
        -----------------------------------------------------------------------------
        report "Test: Complete mode cycle";
        set_mode_pulse <= '1'; wait for 10 ns; set_mode_pulse <= '0';
        wait for 10 ns;
        set_mode_pulse <= '1'; wait for 10 ns; set_mode_pulse <= '0';
        wait for 10 ns;
        set_mode_pulse <= '1'; wait for 10 ns; set_mode_pulse <= '0';
        wait for 10 ns;
        set_mode_pulse <= '1'; wait for 10 ns; set_mode_pulse <= '0';
        wait for 50 ns;

        report "Testbench simulation ended";
        wait;
    end process stim_proc;

end architecture sim;