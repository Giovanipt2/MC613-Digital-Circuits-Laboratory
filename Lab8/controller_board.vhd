library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller_board is
    port (
        -- Board Interface
        CLOCK_50  : in  std_logic;                      -- 50 MHz clock input
        -- OBS: When passing the address, SW[9:6] is used for column address, and SW[5:0] for row address
        SW        : in  std_logic_vector(9 downto 0);   -- Switch input for address and data
        KEY       : in  std_logic_vector(3 downto 0);   -- Key input (active low)
        HEX5      : out std_logic_vector(6 downto 0);   -- 7-segment display for address (bits 11-8)
        HEX4      : out std_logic_vector(6 downto 0);   -- 7-segment display for address (bits 7-4)
        HEX3      : out std_logic_vector(6 downto 0);   -- 7-segment display for data (bits 3-0)
        HEX2      : out std_logic_vector(6 downto 0);   -- 7-segment display for data (bits 11-8)
        HEX1      : out std_logic_vector(6 downto 0);   -- 7-segment display for data (bits 7-4)
        HEX0      : out std_logic_vector(6 downto 0);   -- 7-segment display for data (bits 3-0)

        -- SDRAM Physical Interface
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
end entity controller_board;

architecture behavior of controller_board is

    -- PLL component declaration (Generated via Quartus IP Catalog)
    -- Input: 50MHz, Output: 143MHz
    component pll
    port (
		refclk   : in  std_logic := '0'; --  refclk.clk
		rst      : in  std_logic := '0'; --   reset.reset
		outclk_0 : out std_logic;        -- outclk0.clk
		locked   : out std_logic         --  locked.export
	);
    end component;

    -- SDRAM Controller component
    component SDRAM_CTRL
      port (
        SYS_CLK    : in  std_logic;
        C_ADDR_IN  : in  std_logic_vector(14 downto 0);
        C_DATA_OUT : out std_logic_vector(15 downto 0);
        C_READY    : out std_logic;
        C_DATA_IN  : in  std_logic_vector(15 downto 0);
        C_WRITE    : in  std_logic;
        C_READ     : in  std_logic;
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
    end component;

    -- 7-segment display converter component
    component unsigned_to_7seg
        port (
            bin  : in  std_logic_vector(3 downto 0);
            segs : out std_logic_vector(6 downto 0)
        );
    end component;

    -- Internal signals
    signal sdram_clk          : std_logic; -- 143 MHz clock from PLL

    -- State machine for operations
    type op_state_t is (
        S_IDLE,
        S_READ_ASSERT_CMD, S_READ_WAIT_SDRAM,
        S_WRITE_GET_ADDR, S_WRITE_GET_DATA, S_WRITE_ASSERT_CMD, S_WRITE_WAIT_SDRAM
    );
    signal current_op_state : op_state_t := S_IDLE;

    -- Signals for SDRAM Controller interface
    signal s_c_addr_in        : std_logic_vector(14 downto 0);
    signal s_c_data_in        : std_logic_vector(15 downto 0);
    signal s_c_write_cmd      : std_logic := '0';
    signal s_c_read_cmd       : std_logic := '0';
    signal s_c_data_out_raw   : std_logic_vector(15 downto 0); -- from SDRAM_CTRL (sdram_clk domain)
    signal s_c_ready_raw      : std_logic;                     -- from SDRAM_CTRL (sdram_clk domain)

    -- Registers for display values
    signal disp_addr_val      : std_logic_vector(9 downto 0)  := (others => '0');
    signal disp_data_val      : std_logic_vector(15 downto 0) := (others => '0');

    -- Edge detection for KEY presses
    signal last_key2 : std_logic := '0';
    signal last_key3 : std_logic := '0';

    -- Temporary storage for write operation
    signal temp_write_addr    : std_logic_vector(9 downto 0);

begin

    -- Instantiate PLL for SDRAM clock (143 MHz)
    pll_inst : pll
    port map (
        refclk   => CLOCK_50,
        rst      => '0', -- No reset
        outclk_0 => sdram_clk,
        locked   => open -- Not used in this design
    );

    -- Instantiate SDRAM Controller
    sdram_ctrl_inst : SDRAM_CTRL
    port map (
        SYS_CLK    => sdram_clk,
        C_ADDR_IN  => s_c_addr_in,
        C_DATA_OUT => s_c_data_out_raw,
        C_READY    => s_c_ready_raw,
        C_DATA_IN  => s_c_data_in,
        C_WRITE    => s_c_write_cmd,
        C_READ     => s_c_read_cmd,
        DRAM_DQ    => DRAM_DQ,
        DRAM_ADDR  => DRAM_ADDR,
        DRAM_BA    => DRAM_BA,
        DRAM_CLK   => DRAM_CLK,
        DRAM_CKE   => DRAM_CKE,
        DRAM_LDQM  => DRAM_LDQM,
        DRAM_UDQM  => DRAM_UDQM,
        DRAM_WE_N  => DRAM_WE_N,
        DRAM_CAS_N => DRAM_CAS_N,
        DRAM_RAS_N => DRAM_RAS_N,
        DRAM_CS_N  => DRAM_CS_N
    );



    -- Main Control FSM (driven by sdram_clk)
    control_fsm_proc : process(sdram_clk)
    begin
        if rising_edge(sdram_clk) then
            -- Default command values
            s_c_read_cmd  <= '0';
            s_c_write_cmd <= '0';
            -- Edge detection for KEY presses
            last_key2 <= KEY(2);
            last_key3 <= KEY(3);

            case current_op_state is
                when S_IDLE =>
                    -- If KEY(2) is pressed, initiate Write operation
                    if KEY(2) = '0' and last_key2 = '1' then
                        disp_addr_val <= SW(9 downto 0); -- Show current SW as potential address
                        disp_data_val <= "0000000000000000"; -- Clear data display
                        -- HEX displays could show "SETA" (Set Address) or similar indication
                        current_op_state <= S_WRITE_GET_ADDR;
                    -- If KEY(3) is pressed, initiate Read operation
                    elsif KEY(3) = '0' and last_key3 = '1' then
                        disp_addr_val <= SW(9 downto 0);
                        disp_data_val <= "0000000000000000"; -- Clear data display
                        s_c_addr_in   <= "00000" & SW(9 downto 0); -- Use SW for lower 10 bits of address
                        s_c_read_cmd  <= '1';
                        current_op_state <= S_READ_ASSERT_CMD;
                    end if;

                -- Read Operation States
                when S_READ_ASSERT_CMD => -- Assert command for one cycle
                    s_c_read_cmd <= '1'; -- Keep C_ADDR_IN stable
                    current_op_state <= S_READ_WAIT_SDRAM;

                when S_READ_WAIT_SDRAM =>
                    -- Wait for SDRAM controller to become ready again
                    -- C_READY goes low when busy, then high when done.
                    if s_c_ready_raw = '1' then
                        disp_data_val <= s_c_data_out_raw; -- Latch data
                        current_op_state <= S_IDLE;
                    end if;
                    -- C_ADDR_IN is held by s_c_addr_in signal from S_IDLE transition

                -- Write Operation States
                when S_WRITE_GET_ADDR =>
                    -- User sets address on SW, presses KEY(2) to confirm
                    disp_addr_val <= SW(9 downto 0); -- Continuously display SW for address
                    if KEY(2) = '0' and last_key2 = '1' then
                        temp_write_addr <= SW(9 downto 0);
                        disp_addr_val   <= SW(9 downto 0); -- Freeze displayed address
                        current_op_state <= S_WRITE_GET_DATA;
                    end if;
                     -- If KEY(3) is pressed during write setup, ignore it (as per requirement)

                when S_WRITE_GET_DATA =>
                    -- User sets data on SW, presses KEY(2) to confirm and send
                    disp_data_val <= "000000" & SW(9 downto 0); -- Continuously display SW for data
                    if KEY(2) = '0' and last_key2 = '1' then
                        s_c_addr_in   <= "00000" & temp_write_addr;
                        s_c_data_in   <= "000000" & SW(9 downto 0);
                        disp_data_val <= "000000" & SW(9 downto 0); -- Freeze displayed data
                        s_c_write_cmd <= '1';
                        current_op_state <= S_WRITE_ASSERT_CMD;
                    end if;

                when S_WRITE_ASSERT_CMD => -- Assert command for one cycle
                    s_c_write_cmd <= '1'; -- Keep C_ADDR_IN and C_DATA_IN stable
                    current_op_state <= S_WRITE_WAIT_SDRAM;

                when S_WRITE_WAIT_SDRAM =>
                    -- Wait for SDRAM controller to become ready again
                    if s_c_ready_raw = '1' then
                        current_op_state <= S_IDLE;
                    end if;
                    -- C_ADDR_IN and C_DATA_IN are held by s_c_addr_in/s_c_data_in signals

            end case;
        end if;
    end process;

    -- 7-Segment Display Logic
    -- Displaying 10-bit address (disp_addr_val) on HEX5-HEX3
    hex5_inst : unsigned_to_7seg
    port map (bin => "00" & disp_addr_val(9 downto 8), segs => HEX5);

    hex4_inst : unsigned_to_7seg
    port map (bin => disp_addr_val(7 downto 4), segs => HEX4);

    hex3_inst : unsigned_to_7seg
    port map (bin => disp_addr_val(3 downto 0), segs => HEX3);

    -- Displaying 16-bit data (disp_data_val) on HEX2-HEX0
    hex2_inst : unsigned_to_7seg
    port map (bin => disp_data_val(11 downto 8), segs => HEX2);

    hex1_inst : unsigned_to_7seg
    port map (bin => disp_data_val(7 downto 4), segs => HEX1);

    hex0_inst : unsigned_to_7seg
    port map (bin => disp_data_val(3 downto 0), segs => HEX0);

end architecture behavior;