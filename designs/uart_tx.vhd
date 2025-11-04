----------------------------------------------------------------------------------
-- Company: CEPEDI
-- Engineer: Gabriel Cavalcanti Coelho
-- Create Date: 28.10.2025
-- Module Name: uart_tx
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_tx is
    generic (
        DATA_BITS   : natural := 8;      -- Número de bits de dados a serem transmitidos
        PARITY_TYPE : string  := "EVEN"; -- Tipo de paridade: "NONE", "EVEN" ou "ODD"
        STOP_BITS   : natural := 1       -- Número de stop bits
    );
    port (
        -- Sinais Globais
        clk   : in  std_logic; -- Clock do sistema
        n_rst : in  std_logic; -- Reset síncrono, ativo-baixo

        -- Interface do Ticker
        baud_tick     : in  std_logic; -- Pulso de 1 ciclo no baud rate
        phase_trigger : out std_logic; -- Pulso para o phase_trigger do ticker (a fase deve ser 0.0)

        -- Interface de Dados (AXI-Stream)
        s_axis_tdata  : in  std_logic_vector(DATA_BITS - 1 downto 0);
        s_axis_tvalid : in  std_logic;
        s_axis_tready : out std_logic;

        -- Saída Serial
        uart_tx : out std_logic; -- A linha serial de transmissão

        -- Saída de Status
        busy : out std_logic
    );
end entity uart_tx;

architecture rtl of uart_tx is

    -- Função para calcular a paridade
    function xor_reduce(vector : std_logic_vector) return std_logic is
        variable result : std_logic := '0';
    begin
        for i in vector'range loop
            result := result xor vector(i);
        end loop;
        return result;
    end function xor_reduce;

    -- Constantes de Cálculo de Frame
    constant USE_PARITY     : boolean := (PARITY_TYPE /= "NONE");
    constant PARITY_BITS    : natural := 1 when USE_PARITY else 0;
    constant TX_BUFFER_BITS : natural := DATA_BITS + PARITY_BITS + STOP_BITS;
    constant STOP_BITS_VEC  : std_logic_vector(STOP_BITS - 1 downto 0) := (others => '1');
    
    -- Definição dos Estados da Máquina de Estados
    type t_state is (IDLE, TRIM, START, TRANSMIT);
    signal state_reg, state_next_reg : t_state := IDLE;

    -- Sinais da Máquina de Estados
    signal bit_count_reg, bit_count_next_reg : natural range 0 to TX_BUFFER_BITS-1 := 0;
    signal data_reg      : std_logic_vector(DATA_BITS-1 downto 0) := (others => '1');
    signal tx_buffer_reg : std_logic_vector(TX_BUFFER_BITS-1 downto 0) := (others => '1');
    signal parity_bit        : std_logic;
    signal uart_tx_reg       : std_logic := '1';
    signal s_axis_tready_reg : std_logic := '0';
    signal busy_reg          : std_logic := '1';
    signal phase_trigger_reg : std_logic := '0';

begin

    -- Lógica de Paridade (Combinacional)
    parity_bit <= xor_reduce(data_reg) when (PARITY_TYPE = "EVEN") else
                  not xor_reduce(data_reg) when (PARITY_TYPE = "ODD") else
                  '0';

    sync_proc: process(clk)
    begin
        if rising_edge(clk) then
            if n_rst = '0' then
                -- Reset de todos os registradores
                state_reg            <= IDLE;
                bit_count_reg        <= 0;
                data_reg             <= (others => '1');
                tx_buffer_reg        <= (others => '1');
            else
                -- Atualização dos registradores de controle
                state_reg <= state_next_reg;
                bit_count_reg <= bit_count_next_reg;

                case( state_reg ) is
                
                    when IDLE =>
                        if (s_axis_tvalid = '1') then
                            data_reg <= s_axis_tdata; -- Captura o dado recebido pelo AXIS
                        end if;

                    when START =>
                        if (baud_tick = '1') then
                            if (USE_PARITY) then
                                tx_buffer_reg <= STOP_BITS_VEC & parity_bit & data_reg;
                            else
                                tx_buffer_reg <= STOP_BITS_VEC & data_reg;
                            end if;
                        end if;

                    when TRANSMIT =>
                        if (baud_tick = '1') then
                            tx_buffer_reg <= '1' & tx_buffer_reg(TX_BUFFER_BITS-1 downto 1); -- Desloca
                        end if;

                    when others =>
                end case;
            end if;
        end if;
    end process sync_proc;

    comb_proc: process(state_reg, bit_count_reg, s_axis_tvalid, baud_tick, tx_buffer_reg)
    begin
        state_next_reg <= state_reg;
        bit_count_next_reg <= bit_count_reg;

        case(state_reg) is
        
            when IDLE =>
                uart_tx_reg <= '1';
                s_axis_tready_reg <= '1';
                busy_reg <= '0';
                phase_trigger_reg <= '0';
                if (s_axis_tvalid = '1') then
                    s_axis_tready_reg <= '0';
                    busy_reg <= '1';
                    phase_trigger_reg <= '1';
                    state_next_reg <= TRIM;
                end if;
            
            when TRIM =>
                uart_tx_reg <= '1';
                s_axis_tready_reg <= '0';
                busy_reg <= '1';
                phase_trigger_reg <= '0';
                state_next_reg <= START;

            when START =>
                uart_tx_reg <= '0';
                s_axis_tready_reg <= '0';
                busy_reg <= '1';
                phase_trigger_reg <= '0';
                if (baud_tick = '1') then
                    bit_count_next_reg <= 0;  -- Reseta o contador de dados enviados
                    state_next_reg <= TRANSMIT;
                end if;

            when TRANSMIT =>
                uart_tx_reg <= tx_buffer_reg(0); -- Envia LSB
                s_axis_tready_reg <= '0';
                busy_reg <= '1';
                phase_trigger_reg <= '0';
                if (baud_tick = '1') then
                    if (bit_count_reg < TX_BUFFER_BITS-1) then
                        bit_count_next_reg <= bit_count_reg + 1;
                    else
                        bit_count_next_reg <= 0;
                        state_next_reg <= IDLE;
                    end if;
                end if;
        
        end case;
    end process comb_proc;

    -- Conexões de Saída
    uart_tx <= uart_tx_reg;
    s_axis_tready <= s_axis_tready_reg;
    busy <= busy_reg;
    phase_trigger <= phase_trigger_reg;

end architecture rtl;