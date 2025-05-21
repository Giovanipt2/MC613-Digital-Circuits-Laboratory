library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity OUTER_CACHE is
    generic(
      DATA_WIDTH   : integer := 32; -- Tamanho em bits dos dados
      ADDR_WIDTH   : integer := 16; -- Tamanho em bits dos endereços recebidos
      TAG_WIDTH    : integer := 10;  -- Número de bits pra indicar tag
      OFFSET_WIDTH : integer := 2   -- Número de bits de offset no endereço
    );
      port (
        CLK       : in  std_logic;
        -- Interface com o nível anterior (CPU, ou outra outer_cache em que o valor não foi encontrado)
        C_ADDR_IN  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        C_DATA_OUT : out std_logic_vector(DATA_WIDTH-1 downto 0);
        C_HIT      : out std_logic;
        C_DATA_IN  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        C_WRITE    : in  std_logic;
        -- Interface com o próximo nível (Outra outer cache, ou memória ROM)
        M_ADDR_OUT : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        M_DATA_IN  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        M_HIT      : in std_logic;
        M_DATA_OUT : out std_logic_vector(DATA_WIDTH-1 downto 0);
        M_WRITE    : out std_logic
        -- Sinais std_lgc para indicar recebimento e envio de dados
        start_search_for_data : in std_logic; -- Sinal para indicar que a cache está procurando dados
        data_found     : out std_logic; -- Sinal para indicar que os dados foram encontrados
        search_deeper : out std_logic; -- Sinal para indicar que a busca deve continuar
      );
end OUTER_CACHE;

architecture Behavioral of OUTER_CACHE is
  -- Declarar o componente INNER_CACHE
  component INNER_CACHE is
    generic (
      DATA_WIDTH   : integer := 32;
      ADDR_WIDTH   : integer := 16;
      TAG_WIDTH    : integer := 10;
      OFFSET_WIDTH : integer := 2
    );
    port (
      CLK      : in  std_logic;
      ADDR     : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
      DATA_OUT : out std_logic_vector(DATA_WIDTH - 1 downto 0);
      HIT      : out std_logic;
      DATA_IN  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
      WRITE    : in  std_logic
    );
  end component;

  -- Sinais internos para conectar à INNER_CACHE
  signal inner_addr     : std_logic_vector(ADDR_WIDTH - 1 downto 0);
  signal inner_data_out : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal inner_hit      : std_logic;
  signal inner_data_in  : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal inner_write    : std_logic;

  -- Máquina de estados
  type state_type is (IDLE, SEARCH);
  signal state : state_type := IDLE;

  -- Sinal auxiliar para detectar borda de subida em start_search_for_data
  signal prev_start_search : std_logic := '0';

begin
  -- Instanciar a INNER_CACHE
  inner_cache_inst : INNER_CACHE
    generic map (
      DATA_WIDTH   => DATA_WIDTH,
      ADDR_WIDTH   => ADDR_WIDTH,
      TAG_WIDTH    => TAG_WIDTH,
      OFFSET_WIDTH => OFFSET_WIDTH
    )
    port map (
      CLK      => CLK,
      ADDR     => inner_addr,
      DATA_OUT => inner_data_out,
      HIT      => inner_hit,
      DATA_IN  => inner_data_in,
      WRITE    => inner_write
    );

  -- Processo principal (síncrono)
  process (CLK)
  begin
    if rising_edge(CLK) then
      -- Atualizar o sinal auxiliar para detecção de borda
      prev_start_search <= start_search_for_data;

      -- Máquina de estados
      case state is
        when IDLE =>
          -- Inicializar sinais de saída
          data_found    <= '0';
          search_deeper <= '0';
          inner_write   <= '0';

          -- Detectar borda de subida em start_search_for_data
          if start_search_for_data = '1' and prev_start_search = '0' then
            -- Passar o endereço da CPU para a INNER_CACHE
            inner_addr <= C_ADDR_IN;

            -- Após um ciclo, HIT será atualizado pela INNER_CACHE
            -- No próximo ciclo, avaliamos o resultado
            if inner_hit = '1' then
              -- Caso 1: HIT na INNER_CACHE
              C_DATA_OUT <= inner_data_out;
              data_found <= '1';
            else
              -- Caso 2: MISS na INNER_CACHE
              state       <= SEARCH;
              M_ADDR_OUT  <= C_ADDR_IN;
              search_deeper <= '1';
            end if;
          end if;

        when SEARCH =>
          -- Aguardar resposta do nível inferior (M_HIT = '1')
          if M_HIT = '1' then
            -- Salvar os dados recebidos na INNER_CACHE
            inner_addr    <= C_ADDR_IN;
            inner_data_in <= M_DATA_IN;
            inner_write   <= '1';

            -- Retornar os dados para a CPU
            C_DATA_OUT <= M_DATA_IN;
            data_found <= '1';

            -- Voltar ao estado IDLE
            state <= IDLE;
          else
            -- Continuar aguardando, manter sinais zerados
            inner_write   <= '0';
            data_found    <= '0';
            search_deeper <= '0';
          end if;

      end case;
    end if;
  end process;

  -- Conectar C_HIT diretamente ao HIT da INNER_CACHE
  C_HIT <= inner_hit;

  -- Sinais não utilizados (conforme simplificação)
  M_DATA_OUT <= (others => '0');
  M_WRITE    <= '0';

end Behavioral;
