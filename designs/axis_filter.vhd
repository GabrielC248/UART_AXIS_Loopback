library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity axis_filter is
    Generic (
        DATA_WIDTH       : integer := 8;  -- Largura de Bits do Pixel (Unsigned: 0-255)
        KERNEL_VAL_WIDTH : integer := 8;  -- Largura de Bits dos Coeficientes do Kernel (Signed: -128 a 127)
        IMG_WIDTH        : integer := 256 -- Largura da imagem
    );
    Port (
        clk   : in std_logic;
        n_rst : in std_logic;

        -- Configuração do Kernel
        -- k11 k12 k13
        -- k21 k22 k23
        -- k31 k32 k33
        k11, k12, k13 : in std_logic_vector(KERNEL_VAL_WIDTH-1 downto 0);
        k21, k22, k23 : in std_logic_vector(KERNEL_VAL_WIDTH-1 downto 0);
        k31, k32, k33 : in std_logic_vector(KERNEL_VAL_WIDTH-1 downto 0);

        -- Interface AXIS Slave (Entrada)
        s_axis_tdata  : in std_logic_vector(DATA_WIDTH-1 downto 0);
        s_axis_tvalid : in std_logic;
        s_axis_tready : out std_logic;

        -- Interface AXIS Master (Saída)
        m_axis_tdata  : out std_logic_vector(DATA_WIDTH-1 downto 0);
        m_axis_tvalid : out std_logic;
        m_axis_tready : in std_logic
    );
end axis_filter;

architecture rtl of axis_filter is

    -- Line Buffers
    type ram_type is array (0 to IMG_WIDTH-1) of unsigned(DATA_WIDTH-1 downto 0);
    signal line_buffer_0 : ram_type; -- Linha N-2
    signal line_buffer_1 : ram_type; -- Linha N-1
    
    signal wr_ptr : integer range 0 to IMG_WIDTH-1 := 0;
    
    -- Janela deslizante (Pixels são unsigned 0-255)
    type window_row_type is array (0 to 2) of signed(DATA_WIDTH downto 0); -- +1 bit para garantir sinal positivo ao converter
    type window_type is array (0 to 2) of window_row_type;
    signal window : window_type; 

    -- Sinais internos para os coeficientes (convertidos para signed)
    type kernel_row_type is array (0 to 2) of signed(KERNEL_VAL_WIDTH-1 downto 0);
    type kernel_type is array (0 to 2) of kernel_row_type;
    signal kernel : kernel_type;

    signal axis_enable : std_logic;

begin

    -- Mapeamento das entradas para matriz interna
    kernel(0)(0) <= signed(k11); kernel(0)(1) <= signed(k12); kernel(0)(2) <= signed(k13);
    kernel(1)(0) <= signed(k21); kernel(1)(1) <= signed(k22); kernel(1)(2) <= signed(k23);
    kernel(2)(0) <= signed(k31); kernel(2)(1) <= signed(k32); kernel(2)(2) <= signed(k33);

    -- Controle de Fluxo
    axis_enable   <= s_axis_tvalid and m_axis_tready;
    s_axis_tready <= m_axis_tready;

    process(clk)
        -- Variáveis para cálculo
        variable sum      : signed(DATA_WIDTH + KERNEL_VAL_WIDTH + 4 downto 0); -- Accumulator largo
        variable pixel_in : unsigned(DATA_WIDTH-1 downto 0);
        
    begin
        if rising_edge(clk) then
            if n_rst = '0' then
                wr_ptr        <= 0;
                m_axis_tvalid <= '0';
            else
                if axis_enable = '1' then

                    pixel_in := unsigned(s_axis_tdata);
                    
                    -----------------------------------------------------------
                    -- 1. Gerenciamento da Janela e Line Buffers
                    -----------------------------------------------------------

                    -- Shift Horizontal
                    for r in 0 to 2 loop
                        window(r)(0) <= window(r)(1);
                        window(r)(1) <= window(r)(2);
                    end loop;
                    
                    -- Alimentação Vertical (Buffer Circular)
                    -- Linha 0 (Topo): Recebe o que sai do Buffer 1 (que era linha central)
                    window(0)(2) <= signed('0' & line_buffer_1(wr_ptr)); 
                    
                    -- Linha 1 (Meio): Recebe o que sai do Buffer 0 (que era linha nova)
                    window(1)(2) <= signed('0' & line_buffer_0(wr_ptr));
                    
                    -- Linha 2 (Fundo): Recebe o pixel novo
                    window(2)(2) <= signed('0' & pixel_in);

                    -- Atualização dos Buffers
                    line_buffer_1(wr_ptr) <= line_buffer_0(wr_ptr);
                    line_buffer_0(wr_ptr) <= pixel_in;
                    
                    if wr_ptr = IMG_WIDTH-1 then
                        wr_ptr <= 0;
                    else
                        wr_ptr <= wr_ptr + 1;
                    end if;

                    -----------------------------------------------------------
                    -- 2. Convolução
                    -----------------------------------------------------------
                    sum := (others => '0');
                    
                    sum := sum + (window(0)(0) * kernel(0)(0));
                    sum := sum + (window(0)(1) * kernel(0)(1));
                    sum := sum + (window(0)(2) * kernel(0)(2));
                    
                    sum := sum + (window(1)(0) * kernel(1)(0));
                    sum := sum + (window(1)(1) * kernel(1)(1));
                    sum := sum + (window(1)(2) * kernel(1)(2));
                    
                    sum := sum + (window(2)(0) * kernel(2)(0));
                    sum := sum + (window(2)(1) * kernel(2)(1));
                    sum := sum + (window(2)(2) * kernel(2)(2));

                    -----------------------------------------------------------
                    -- 3. Normalização e Saída
                    -----------------------------------------------------------
                    if sum < 0 then
                        sum := abs(sum); -- Ou 0, dependendo se quer ver bordas negativas
                    end if;
                    
                    if sum > 255 then
                        m_axis_tdata <= std_logic_vector(to_unsigned(255, DATA_WIDTH));
                    else
                        m_axis_tdata <= std_logic_vector(to_unsigned(to_integer(sum), DATA_WIDTH));
                    end if;
                    
                    m_axis_tvalid <= '1';

                else
                    if m_axis_tready = '1' then
                        m_axis_tvalid <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
end rtl;