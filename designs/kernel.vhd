library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity kernel is
    Generic (
        KERNEL_VAL_WIDTH : integer := 8;        -- Tamanho em bits dos Valores do Kernel
        CLK_FREQ_HZ      : integer := 25000000; -- Frequência do Clock (25MHz para a Colorlight i9+)
        DEBOUNCE_MS      : integer := 30        -- Tempo de debouncing em milissegundos
    );
    port (
        clk   : in  std_logic;
        n_rst : in  std_logic;
        n_btn : in  std_logic;
        
        -- Saídas dos coeficientes
        k11, k12, k13 : out std_logic_vector(KERNEL_VAL_WIDTH-1 downto 0);
        k21, k22, k23 : out std_logic_vector(KERNEL_VAL_WIDTH-1 downto 0);
        k31, k32, k33 : out std_logic_vector(KERNEL_VAL_WIDTH-1 downto 0)
    );
end entity kernel;

architecture rtl of kernel is

    constant CYCLES_LIMIT : integer := (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;
    signal btn_cnt : integer range 0 to CYCLES_LIMIT := 0;
    
    signal btn_flag  : std_logic := '0';

    signal kernel_sel : integer range 0 to 3 := 0;

    -- Sinais internos
    signal v11, v12, v13 : integer;
    signal v21, v22, v23 : integer;
    signal v31, v32, v33 : integer;

begin

    -- --------------------------------
    -- ----        Debounce        ----
    -- --------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if (n_rst = '0') then
                btn_cnt  <= 0;
                btn_flag <= '0';
            else

                if (btn_flag = '0') then
                    if (n_btn = '0') then
                        btn_flag <= '1';

                        if (kernel_sel = 3) then
                            kernel_sel <= 0;
                        else
                            kernel_sel <= kernel_sel + 1;
                        end if;

                    end if;
                else
                    if (btn_cnt < CYCLES_LIMIT) then
                        btn_cnt <= btn_cnt + 1;
                    else
                        if (n_btn = '1') then
                            btn_flag <= '0';
                            btn_cnt <= 0;
                        end if;
                    end if;
                end if;

            end if;
        end if;
    end process;

    -- --------------------------------
    -- ----     Banco de Dados     ----
    -- --------------------------------
    process(kernel_sel)
    begin
        v11 <= 0;
        v12 <= 0;
        v13 <= 0;
        v21 <= 0;
        v22 <= 0;
        v23 <= 0;
        v31 <= 0;
        v32 <= 0;
        v33 <= 0;

        -- Configuração do Kernel
        -- v11 v12 v13
        -- v21 v22 v23
        -- v31 v32 v33

        case (kernel_sel) is
            when 0 => -- IDENTIDADE
                v22 <= 1;

            when 1 => -- EDGE DETECTION
                v11 <= -1;
                v12 <= -1;
                v13 <= -1;
                v21 <= -1;
                v22 <=  8;
                v23 <= -1;
                v31 <= -1;
                v32 <= -1;
                v33 <= -1;

            when 2 => -- SHARPEN
                v12 <= -1;
                v21 <= -1;
                v22 <=  5; 
                v23 <= -1;
                v32 <= -1;

            when 3 => -- EMBOSS
                v11 <= -2;
                v12 <= -1;
                v13 <=  0;
                v21 <= -1;
                v22 <=  1;
                v23 <=  1;
                v31 <=  0;
                v32 <=  1;
                v33 <=  2;

            when others =>
                null;

        end case;
    end process;

    k11 <= std_logic_vector(to_signed(v11, KERNEL_VAL_WIDTH));
    k12 <= std_logic_vector(to_signed(v12, KERNEL_VAL_WIDTH));
    k13 <= std_logic_vector(to_signed(v13, KERNEL_VAL_WIDTH));

    k21 <= std_logic_vector(to_signed(v21, KERNEL_VAL_WIDTH));
    k22 <= std_logic_vector(to_signed(v22, KERNEL_VAL_WIDTH));
    k23 <= std_logic_vector(to_signed(v23, KERNEL_VAL_WIDTH));

    k31 <= std_logic_vector(to_signed(v31, KERNEL_VAL_WIDTH));
    k32 <= std_logic_vector(to_signed(v32, KERNEL_VAL_WIDTH));
    k33 <= std_logic_vector(to_signed(v33, KERNEL_VAL_WIDTH));

end architecture rtl;