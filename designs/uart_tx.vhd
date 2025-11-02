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
        DATA_BITS   : natural range 5 to 9 := 8; -- Número de bits de dados a serem transmitidos
        PARITY_TYPE : string := "NONE";          -- Tipo de paridade: "NONE", "EVEN" ou "ODD"
        STOP_BITS   : natural := 1               -- Número de stop bits
    );
    port (
        -- Sinais Globais
        clk   : in  std_logic; -- Clock do sistema
        n_rst : in  std_logic; -- Reset síncrono, ativo-baixo

        -- Interface do Ticker
        baud_tick        : in  std_logic; -- Pulso de 1 ciclo no baud rate
        tx_phase_trigger : out std_logic; -- Pulso para o phase_trigger do ticker

        -- Interface de Dados (AXI-Stream)
        s_axis_tdata  : in  std_logic_vector(DATA_BITS - 1 downto 0);
        s_axis_tvalid : in  std_logic;
        s_axis_tready : out std_logic;

        -- Saída Serial
        uart_tx : out std_logic; -- A linha serial de transmissão

        -- Saída de Status
        busy    : out std_logic
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
    constant TOTAL_BITS     : natural := 1 + DATA_BITS + PARITY_BITS + STOP_BITS;
    constant TX_BUFFER_BITS : natural := DATA_BITS + PARITY_BITS + STOP_BITS;
    constant STOP_BITS_VEC  : std_logic_vector(STOP_BITS - 1 downto 0) := (others => '1');
    
    -- Tipos e Sinais Internos
    type t_state is (IDLE, START, TRANSMIT);
    signal state_reg, state_next : t_state;

    -- Sinais da Datapath
    signal data_reg        : std_logic_vector(DATA_BITS - 1 downto 0);
    signal tx_buffer_reg   : std_logic_vector(TX_BUFFER_BITS - 1 downto 0);
    signal parity_bit      : std_logic;
    signal bit_count_reg, bit_count_next : natural range 0 to TOTAL_BITS;
    signal uart_tx_reg     : std_logic;

    -- Sinais de controle
    signal s_axis_tready_reg, s_axis_tready_next : std_logic;
    signal busy_reg, busy_next                   : std_logic;
    signal tx_phase_trigger_reg, tx_phase_trigger_next : std_logic;

begin

    -- Lógica de Paridade (Combinacional)
    parity_bit <= xor_reduce(data_reg) when (PARITY_TYPE = "EVEN") else
                  not xor_reduce(data_reg) when (PARITY_TYPE = "ODD") else
                  '0';

    -- Lógica de Próximo Estado (FSM Combinacional)
    fsm_comb_proc: process(state_reg, s_axis_tvalid, baud_tick, bit_count_reg)
    begin
        -- Valores padrão
        state_next <= state_reg;
        bit_count_next <= bit_count_reg;
        s_axis_tready_next   <= '0';
        busy_next            <= '1';
        tx_phase_trigger_next <= '0';

        case state_reg is
            when IDLE =>
                busy_next <= '0';
                s_axis_tready_next <= '1';
                if (s_axis_tvalid = '1') then
                    state_next <= START;
                    s_axis_tready_next <= '0';
                    busy_next <= '1';
                    tx_phase_trigger_next <= '1';
                    bit_count_next <= TOTAL_BITS;
                end if;
                
            when START =>
                if (baud_tick = '1') then
                    state_next <= TRANSMIT;
                    bit_count_next <= bit_count_reg - 1;
                end if;

            when TRANSMIT =>
                if (baud_tick = '1') then
                    if (bit_count_reg > 1) then
                        bit_count_next <= bit_count_reg - 1;
                    else
                        bit_count_next <= 0;
                        state_next <= IDLE;
                        busy_next <= '0';
                    end if;
                end if;
        end case;
    end process fsm_comb_proc;
    
    -- Registradores e Datapath (Processo Síncrono)
    fsm_sync_proc: process(clk)
    begin
        if rising_edge(clk) then
            if (n_rst = '0') then
                -- Reset de todos os registradores
                state_reg <= IDLE;
                bit_count_reg <= 0;
                uart_tx_reg <= '1';
                s_axis_tready_reg <= '1';
                busy_reg <= '0';
                tx_phase_trigger_reg <= '0';
                data_reg <= (others => '0');
                tx_buffer_reg <= (others => '1');
            else
                -- Atualização dos registradores de controle
                state_reg <= state_next;
                bit_count_reg <= bit_count_next;
                s_axis_tready_reg <= s_axis_tready_next;
                busy_reg <= busy_next;
                tx_phase_trigger_reg <= tx_phase_trigger_next;
                
                -- ** CORRIGIDO: Ações do Datapath baseadas no estado atual (case) **
                case state_reg is
                    when IDLE =>
                        uart_tx_reg <= '1'; -- Mantém a linha ociosa
                        if (s_axis_tvalid = '1') then
                            data_reg <= s_axis_tdata; -- Latch do dado
                        end if;

                    when START =>
                        -- Espera o primeiro tick para agir
                        if (baud_tick = '1') then
                            uart_tx_reg <= '0'; -- Envia o Start Bit
                            
                            -- Carrega o buffer de deslocamento
                            if USE_PARITY then
                                tx_buffer_reg <= STOP_BITS_VEC & parity_bit & data_reg;
                            else
                                tx_buffer_reg <= STOP_BITS_VEC & data_reg;
                            end if;
                        end if;

                    when TRANSMIT =>
                        -- Ações a cada tick durante a transmissão
                        if (baud_tick = '1') then
                            uart_tx_reg <= tx_buffer_reg(0); -- Envia LSB
                            tx_buffer_reg <= '1' & tx_buffer_reg(TX_BUFFER_BITS - 1 downto 1); -- Desloca
                        end if;
                end case;
            end if;
        end if;
    end process fsm_sync_proc;

    -- Conexões de Saída
    uart_tx <= uart_tx_reg;
    s_axis_tready <= s_axis_tready_reg;
    busy <= busy_reg;
    tx_phase_trigger <= tx_phase_trigger_reg;

end architecture rtl;