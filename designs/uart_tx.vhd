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
        PARITY_TYPE : string := "NONE";          -- Tipo de paridade: "NONE" (nenhuma), "EVEN" (par) ou "ODD" (ímpar)
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

    -- Função local para calcular a paridade
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
    type t_state is (s_IDLE, s_START, s_TRANSMIT);
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
    -- Calcula o bit de paridade com base no dado já registrado (data_reg)
    parity_bit <= xor_reduce(data_reg) when (PARITY_TYPE = "EVEN") else
                  not xor_reduce(data_reg) when (PARITY_TYPE = "ODD") else
                  '0'; -- Valor irrelevante se USE_PARITY = false

    -- Lógica de Próximo Estad
    fsm_comb_proc: process(state_reg, s_axis_tvalid, baud_tick, bit_count_reg)
    begin
        -- Valores padrão
        state_next <= state_reg;
        bit_count_next <= bit_count_reg;
        
        s_axis_tready_next   <= '0';
        busy_next            <= '1';
        tx_phase_trigger_next <= '0';

        case state_reg is
            
            -- Estado Ocioso: Espera por dados
            when s_IDLE =>
                busy_next <= '0'; -- Único estado ocioso
                s_axis_tready_next <= '1'; -- Pronto para dados
                
                if (s_axis_tvalid = '1') then
                    -- Dado recebido, inicia a transmissão
                    state_next <= s_START;
                    s_axis_tready_next <= '0';
                    busy_next <= '1';
                    tx_phase_trigger_next <= '1'; -- Reseta o ticker
                    bit_count_next <= TOTAL_BITS; -- Carrega o contador total
                end if;
                
            -- Estado Start: Espera o primeiro tick para enviar o Start Bit
            when s_START =>
                if (baud_tick = '1') then
                    state_next <= s_TRANSMIT;
                    bit_count_next <= bit_count_reg - 1;
                end if;

            -- Estado Transmit: Envia o restante do frame (Data, Parity, Stop)
            when s_TRANSMIT =>
                if (baud_tick = '1') then
                    if (bit_count_reg > 1) then
                        bit_count_next <= bit_count_reg - 1;
                    else
                        -- Este foi o último bit
                        bit_count_next <= 0;
                        state_next <= s_IDLE;
                        busy_next <= '0'; -- Fica ocioso
                    end if;
                end if;

        end case;
    end process fsm_comb_proc;
    
    -- Registradores (Processo Síncrono)
    fsm_sync_proc: process(clk)
    begin
        if rising_edge(clk) then
            if (n_rst = '0') then
                -- Reset de todos os registradores
                state_reg <= s_IDLE;
                bit_count_reg <= 0;
                uart_tx_reg <= '1';
                s_axis_tready_reg <= '1';
                busy_reg <= '0';
                tx_phase_trigger_reg <= '0';
                data_reg <= (others => '0');
                tx_buffer_reg <= (others => '1');
                
            else
                -- Lógica síncrona principal
                state_reg <= state_next;
                bit_count_reg <= bit_count_next;
                s_axis_tready_reg <= s_axis_tready_next;
                busy_reg <= busy_next;
                tx_phase_trigger_reg <= tx_phase_trigger_next;
                
                -- IDLE -> START
                if (state_reg = s_IDLE) and (s_axis_tvalid = '1') then
                    data_reg <= s_axis_tdata;
                end if;
                
                -- START -> TRANSMIT: Envia '0' (Start Bit) e carrega o buffer
                if (state_reg = s_START) and (baud_tick = '1') then
                    uart_tx_reg <= '0';
                    
                    if USE_PARITY then
                        tx_buffer_reg <= STOP_BITS_VEC & parity_bit & data_reg;
                    else
                        tx_buffer_reg <= STOP_BITS_VEC & data_reg;
                    end if;
                
                -- TRANSMIT -> TRANSMIT: Desloca e envia bits
                elsif (state_reg = s_TRANSMIT) and (baud_tick = '1') then
                    uart_tx_reg <= tx_buffer_reg(0);
                    tx_buffer_reg <= '1' & tx_buffer_reg(TX_BUFFER_BITS - 1 downto 1);
                    
                -- TRANSMIT -> IDLE: Volta ao estado ocioso
                elsif (state_next = s_IDLE) then
                    uart_tx_reg <= '1';
                end if;
                
            end if;
        end if;
    end process fsm_sync_proc;

    -- Conexões de Saída
    uart_tx <= uart_tx_reg;
    s_axis_tready <= s_axis_tready_reg;
    busy <= busy_reg;
    tx_phase_trigger <= tx_phase_trigger_reg;

end architecture rtl;