-- Tamanho, em bytes, da capacidade da cache: 64 bytes
-- Justificativa: 
--   Número de linhas (N) = 2^(ADDR_WIDTH – TAG_WIDTH – OFFSET_WIDTH)
--                        = 2^(16 − 10 − 2) = 2^4 = 16 linhas
--   Tamanho do bloco (B)   = 2^OFFSET_WIDTH bytes
--                        = 2^2 = 4 bytes
--   Capacidade útil (C)    = N × B
--                        = 16 × 4 = 64 bytes

-- Tamaho total da cache, em bytes: 86 bytes
-- Justificativa:
--   Para cada linha, precisamos de
--     1 bit de valido   +
--     TAG_WIDTH bits   +
--     DATA_WIDTH bits  =
--     (1 + 10 + 32) = 43 bits
--   Espaço total (S) = N × 43 bits = 16 × 43 = 688 bits = 688/8 = 86 bytes

-- Aproveitamento de espaço da cache (capacidade/espaço total): aproximadamente 74.4%
-- Justificativa:
--   Aproveitamento de espaço = C / S = 64 / 86 ≈ 0.744 ≃ 74.4%

entity INNER_CACHE is
  generic(
    DATA_WIDTH   : integer := 32; -- Number of data bits per line
    ADDR_WIDTH   : integer := 16; -- Number of address bits
    TAG_WIDTH    : integer := 10; -- Number of bits for the tag field
    OFFSET_WIDTH : integer := 2   -- Number of bits for block offset
  );
	port (
        CLK      : in  std_logic;                                   -- Clock signal for synchronous operations     
        ADDR     : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);   -- Address input
        DATA_OUT : out std_logic_vector(DATA_WIDTH - 1 downto 0);   -- Data output on a hit
        HIT      : out std_logic;                                   -- High when requested data is found in cache
        DATA_IN  : in  std_logic_vector(DATA_WIDTH - 1  downto 0);  -- Data input for write operations
        WRITE    : in  std_logic                                    -- High to store DATA_IN into cache at current index 
	);
end INNER_CACHE;

architecture Behavioral of INNER_CACHE is
  -- Calculate index width = number of bits used to select a cache line
  constant INDEX_WIDTH : integer := ADDR_WIDTH - TAG_WIDTH - OFFSET_WIDTH;
  -- Total number of cache lines = 2^INDEX_WIDTH
  constant NUM_LINES   : integer := 2**INDEX_WIDTH;

  -- Declare an array type to hold the data for each cache line
  type data_array_t is array (0 to NUM_LINES - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
  -- Declare an array type to hold the tag bits for each cache line
  type tag_array_t  is array (0 to NUM_LINES - 1) of std_logic_vector(TAG_WIDTH - 1 downto 0);
  -- Signal to hold the actual data stored in each cache line
  signal data_array  : data_array_t := (others => (others => '0'));
  -- Signal to hold the tag associated with each cache line
  signal tag_array   : tag_array_t  := (others => (others => '0'));
  -- Vector of valid bits; each bit indicates if the corresponding line contains valid data
  signal valid_array : std_logic_vector(0 to NUM_LINES - 1) := (others => '0');

  -- Intermediate signals to hold the tag and index extracted from the address
  signal addr_tag   : std_logic_vector(TAG_WIDTH - 1 downto 0);
  signal addr_index : std_logic_vector(INDEX_WIDTH -1 downto 0);
  signal addr_offset : std_logic_vector(OFFSET_WIDTH - 1 downto 0);

begin
  -- Extract the tag field: the most significant TAG_WIDTH bits of the address
  addr_tag   <= ADDR(ADDR_WIDTH - 1 downto ADDR_WIDTH-TAG_WIDTH);
  -- Extract the index field: bits immediately below the tag, above the offset
  addr_index <= ADDR(OFFSET_WIDTH + INDEX_WIDTH - 1 downto OFFSET_WIDTH);
  -- Extract the offset field: the least significant OFFSET_WIDTH bits of the address
  addr_offset <= ADDR(OFFSET_WIDTH - 1 downto 0);

  process(CLK)
    variable idx          : integer;                                    -- Integer index computed from the extracted bits
    variable offset_int   : integer;                                    -- Integer value of the offset
  begin
    if rising_edge(CLK) then
      -- Convert the index vector to an integer for array addressing
      idx         := to_integer(unsigned(addr_index));
      offset_int  := to_integer(unsigned(addr_offset));
      block       := data_array(idx);  -- Current cache block

      -- WRITE operation: when WRITE is asserted, update line at index 'idx'
      if WRITE = '1' then
        -- Store new block and update tag/valid
        data_array(idx)  <= DATA_IN;
        tag_array(idx)   <= addr_tag;
        valid_array(idx) <= '1';
      end if;

      -- READ/Hit detection: compare stored tag and valid bit
      if valid_array(idx) = '1' and tag_array(idx) = addr_tag then
        HIT <= '1';
        DATA_OUT <= data_array(idx);  -- Output the data from the cache line
      else
        HIT      <= '0';
        DATA_OUT <= (others => '0');
      end if;
    end if;
  end process;
end Behavioral;
