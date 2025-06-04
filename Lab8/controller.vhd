library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SDRAM_CTRL is
  port (
    -- Interface with CPU
    SYS_CLK    : in  std_logic;
    C_ADDR_IN  : in  std_logic_vector(14 downto 0);
    C_DATA_OUT : out std_logic_vector(15 downto 0);
    C_READY    : out std_logic;
    C_DATA_IN  : in  std_logic_vector(15 downto 0);
    C_WRITE    : in  std_logic;
    C_READ     : in  std_logic;

    -- Interface with SDRAM
    DRAM_DQ    : inout std_logic_vector(15 downto 0);
    DRAM_ADDR  : out   std_logic_vector(12 downto 0);
    DRAM_BA    : out   std_logic_vector(1 downto 0);
    DRAM_CLK   : out   std_logic;
    DRAM_CKE   : out   std_logic;
    DRAM_LDQM  : out   std_logic;
    DRAM_UDQM  : out   std_logic;
    DRAM_WE_N  : out   std_logic;
    DRAM_CAS_N : out   std_logic;
    DRAM_RAS_N : out   std_logic;
    DRAM_CS_N  : out   std_logic
  );
end SDRAM_CTRL;

architecture Behavioral of SDRAM_CTRL is
  -- State machine definition
  type state_type is (INIT, IDLE, READ_STATE, WRITE_STATE, REFRESH_STATE);
  signal state : state_type := INIT;

  -- Counters
  signal counter        : integer range 0 to 14311 := 0; -- For INIT sequence
  signal 	: integer range 0 to 1000 := 0; -- For periodic refresh
  signal seq_counter    : integer range 0 to 13   := 0; -- For READ/WRITE sequences

  -- Data register for read operations
  signal data_reg    : std_logic_vector(15 downto 0);
  signal write_enable: std_logic := '0';

begin
  -- Clock assignment
  DRAM_CLK <= SYS_CLK;
  DRAM_CKE <= '1'; -- Always high for normal operation

  -- Data mask signals
  DRAM_LDQM <= '1' when state = INIT and counter < 14286 else '0';
  DRAM_UDQM <= '1' when state = INIT and counter < 14286 else '0';

  -- Data bus control
  DRAM_DQ <= C_DATA_IN when write_enable = '1' else (others => 'Z');

  -- Ready signal
  C_READY <= '1' when state = IDLE else '0';

  -- Output data assignment
  C_DATA_OUT <= data_reg;

  -- Main state machine process
  process(SYS_CLK)
  begin
    if rising_edge(SYS_CLK) then
      case state is
        -- Initialization state
        when INIT =>
          if counter < 14286 then
            -- NOP for 100us (14286 cycles at 143 MHz)
            DRAM_CS_N  <= '0';
            DRAM_RAS_N <= '1';
            DRAM_CAS_N <= '1';
            DRAM_WE_N  <= '1';
            counter <= counter + 1;
          elsif counter = 14286 then
            -- PRECHARGE all banks
            DRAM_CS_N  <= '0';
            DRAM_RAS_N <= '0';
            DRAM_CAS_N <= '1';
            DRAM_WE_N  <= '0';
            DRAM_ADDR  <= (10 => '1', others => '0'); -- A10=1 for precharge all
            DRAM_BA    <= "00"; -- Don't care
            counter <= counter + 1;
          elsif counter = 14287 then
            -- AUTO REFRESH 1
            DRAM_CS_N  <= '0';
            DRAM_RAS_N <= '0';
            DRAM_CAS_N <= '0';
            DRAM_WE_N  <= '1';
            counter <= counter + 1;
          elsif counter < 14297 then
            -- NOP for 9 cycles
            DRAM_CS_N  <= '0';
            DRAM_RAS_N <= '1';
            DRAM_CAS_N <= '1';
            DRAM_WE_N  <= '1';
            counter <= counter + 1;
          elsif counter = 14297 then
            -- AUTO REFRESH 2
            DRAM_CS_N  <= '0';
            DRAM_RAS_N <= '0';
            DRAM_CAS_N <= '0';
            DRAM_WE_N  <= '1';
            counter <= counter + 1;
          elsif counter < 14307 then
            -- NOP for 9 cycles
            DRAM_CS_N  <= '0';
            DRAM_RAS_N <= '1';
            DRAM_CAS_N <= '1';
            DRAM_WE_N  <= '1';
            counter <= counter + 1;
          elsif counter = 14307 then
            -- LOAD MODE REGISTER
            DRAM_CS_N  <= '0';
            DRAM_RAS_N <= '0';
            DRAM_CAS_N <= '0';
            DRAM_WE_N  <= '0';
            DRAM_BA    <= "00";
            DRAM_ADDR  <= "0001000110000"; -- Mode settings as specified
            counter <= counter + 1;
          elsif counter < 14311 then
            -- NOP for 3 cycles
            DRAM_CS_N  <= '0';
            DRAM_RAS_N <= '1';
            DRAM_CAS_N <= '1';
            DRAM_WE_N  <= '1';
            counter <= counter + 1;
          else
            state <= IDLE;
            counter <= 0;
          end if;

        -- Idle state
        when IDLE =>
				<= 	 + 1;
          DRAM_CS_N  <= '0';
          DRAM_RAS_N <= '1';
          DRAM_CAS_N <= '1';
          DRAM_WE_N  <= '1';
          if 	 >= 1000 then
            state <= REFRESH_STATE;
					<= 0;
            seq_counter <= 0;
          -- OBS: this might need to be adjusted (there is the possibility that the C_WRITE or C_READ signals are asserted during the refresh)
          elsif C_WRITE = '1' then
            state <= WRITE_STATE;
            seq_counter <= 0;
          elsif C_READ = '1' then
            state <= READ_STATE;
            seq_counter <= 0;
          end if;

        -- Refresh state
        when REFRESH_STATE =>
          if seq_counter = 0 then
            -- AUTO REFRESH
            DRAM_CS_N  <= '0';
            DRAM_RAS_N <= '0';
            DRAM_CAS_N <= '0';
            DRAM_WE_N  <= '1';
            seq_counter <= seq_counter + 1;
          elsif seq_counter < 10 then
            -- NOP for 9 cycles
            DRAM_CS_N  <= '0';
            DRAM_RAS_N <= '1';
            DRAM_CAS_N <= '1';
            DRAM_WE_N  <= '1';
            seq_counter <= seq_counter + 1;
          else
            state <= IDLE;
            seq_counter <= 0;
          end if;

        -- Write state
        when WRITE_STATE =>
          if seq_counter < 3 then
            -- NOP for 3 cycles
            DRAM_CS_N  <= '0';
            DRAM_RAS_N <= '1';
            DRAM_CAS_N <= '1';
            DRAM_WE_N  <= '1';
            seq_counter <= seq_counter + 1;
					<= 	 + 1; -- Increment refresh counter even in write state
          elsif seq_counter = 3 then
            -- ACTIVE
            DRAM_CS_N  <= '0';
            DRAM_RAS_N <= '0';
            DRAM_CAS_N <= '1';
            DRAM_WE_N  <= '1';
            DRAM_BA    <= "00"; -- Fixed bank
            DRAM_ADDR  <= "00000" & C_ADDR_IN(14 downto 10); -- Row address
            seq_counter <= seq_counter + 1;
					<= 	 + 1;
          elsif seq_counter < 7 then
            -- Wait 3 cycles (tRCD)
            DRAM_CS_N  <= '0';
            DRAM_RAS_N <= '1';
            DRAM_CAS_N <= '1';
            DRAM_WE_N  <= '1';
            seq_counter <= seq_counter + 1;
					<= 	 + 1;
          elsif seq_counter = 7 then
            -- WRITE
            DRAM_CS_N  <= '0';
            DRAM_RAS_N <= '1';
            DRAM_CAS_N <= '0';
            DRAM_WE_N  <= '0';
            DRAM_BA    <= "00";
            DRAM_ADDR  <= "00" & '1' & C_ADDR_IN(9 downto 0); -- Column with A10=1
            write_enable <= '1';
            seq_counter <= seq_counter + 1;
					<= 	 + 1;
          else
            write_enable <= '0';
            if seq_counter < 13 then
              -- Wait 5 cycles
              DRAM_CS_N  <= '0';
              DRAM_RAS_N <= '1';
              DRAM_CAS_N <= '1';
              DRAM_WE_N  <= '1';
              seq_counter <= seq_counter + 1;
						<= 	 + 1;
            else
              state <= IDLE;
              seq_counter <= 0;
            end if;
          end if;

        -- Read state
        when READ_STATE =>
          if seq_counter < 3 then
            -- NOP for 3 cycles
            DRAM_CS_N  <= '0';
            DRAM_RAS_N <= '1';
            DRAM_CAS_N <= '1';
            DRAM_WE_N  <= '1';
            seq_counter <= seq_counter + 1;
					<= 	 + 1; -- Increment refresh counter even in read state
          elsif seq_counter = 3 then
            -- ACTIVE
            DRAM_CS_N  <= '0';
            DRAM_RAS_N <= '0';
            DRAM_CAS_N <= '1';
            DRAM_WE_N  <= '1';
            DRAM_BA    <= "00";
            DRAM_ADDR  <= "00000" & C_ADDR_IN(14 downto 10); -- Row address
            seq_counter <= seq_counter + 1;
					<= 	 + 1;
          elsif seq_counter < 7 then
            -- Wait 3 cycles
            DRAM_CS_N  <= '0';
            DRAM_RAS_N <= '1';
            DRAM_CAS_N <= '1';
            DRAM_WE_N  <= '1';
            seq_counter <= seq_counter + 1;
					<= 	 + 1;
          elsif seq_counter = 7 then
            -- READ
            DRAM_CS_N  <= '0';
            DRAM_RAS_N <= '1';
            DRAM_CAS_N <= '0';
            DRAM_WE_N  <= '1';
            DRAM_BA    <= "00";
            DRAM_ADDR  <= "00" & '1' & C_ADDR_IN(9 downto 0); -- Column with A10=1
            seq_counter <= seq_counter + 1;
					<= 	 + 1;
          elsif seq_counter < 10 then
            -- Wait until CAS latency (data available at seq_counter=10)
            DRAM_CS_N  <= '0';
            DRAM_RAS_N <= '1';
            DRAM_CAS_N <= '1';
            DRAM_WE_N  <= '1';
            seq_counter <= seq_counter + 1;
					<= 	 + 1;
          if seq_counter = 10 then
              data_reg <= DRAM_DQ; -- Latch data after CAS latency (3 cycles)
            end if;
          else
            if seq_counter < 12 then
              -- Wait remaining cycles
              DRAM_CS_N  <= '0';
              DRAM_RAS_N <= '1';
              DRAM_CAS_N <= '1';
              DRAM_WE_N  <= '1';
              seq_counter <= seq_counter + 1;
						<= 	 + 1;
            else
              state <= IDLE;
              seq_counter <= 0;
            end if;
          end if;

      end case;
    end if;
  end process;

end Behavioral;