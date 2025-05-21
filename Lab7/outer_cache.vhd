entity OUTER_CACHE is
  generic(
    DATA_WIDTH   : integer := 32; -- Tamanho em bits dos dados
    ADDR_WIDTH   : integer := 16; -- Tamanho em bits dos endereços recebidos
    TAG_WIDTH    : integer := 10;  -- Número de bits pra indicar tag
    OFFSET_WIDTH : integer := 2   -- Número de bits de offset no endereço
  );
	port (
    CLK       : in  std_logic;
    -- Interface com o nível anterior
    C_ADDR_IN  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    C_DATA_OUT : out std_logic_vector(DATA_WIDTH-1 downto 0);
    C_HIT      : out std_logic;
    C_DATA_IN  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    C_WRITE    : in  std_logic;
    -- Interface com o próximo nível
    M_ADDR_OUT : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    M_DATA_IN  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    M_HIT      : in std_logic;
    M_DATA_OUT : out std_logic_vector(DATA_WIDTH-1 downto 0);
    M_WRITE    : out std_logic
    --- Adicione outros sinais que julgar necessário.
	);
end OUTER_CACHE;
Copy