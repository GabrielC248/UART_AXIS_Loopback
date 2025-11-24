----------------------------------------------------------------------------------
-- Company: CEPEDI
-- Engineer: Gabriel Cavalcanti Coelho
-- Create Date: 05.11.2025
-- Module Name: uart_rx
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_rx is
    generic (
        DATA_BITS   : natural := 8;      -- Número de bits de dados recebidos pela linha serial
        PARITY_TYPE : string  := "EVEN"; -- Tipo de paridade: "NONE", "EVEN" ou "ODD"
        STOP_BITS   : natural := 1       -- Número de stop bits
    );
    port (
        -- Sinais Globais
        clk   : in  std_logic; -- Clock do sistema
        n_rst : in  std_logic; -- Reset síncrono, ativo-baixo

        -- Interface do Ticker
        baud_tick     : in  std_logic; -- Pulso de 1 ciclo no baud rate
        phase_trigger : out std_logic; -- Pulso para o phase_trigger do ticker (a fase deve ser 50%)

        -- Interface de Dados (AXI-Stream)
        m_axis_tdata  : out std_logic_vector(DATA_BITS - 1 downto 0);
        m_axis_tvalid : out std_logic;
        m_axis_tready : in  std_logic;

        -- Entrada Serial
        uart_rx : in std_logic; -- A linha serial de recepção

        -- Saída de Status
        busy : out std_logic -- Nível lógico alto se o módulo estiver ocupado
    );
end entity uart_rx;

architecture rtl of uart_rx is

    -- Função para calcular a paridade
    function xor_reduce(vector : std_logic_vector) return std_logic is
        variable result : std_logic := '0';
    begin
        for i in vector'range loop
            result := result xor vector(i);
        end loop;
        return result;
    end function xor_reduce;

    -- Constante do Frame
    constant USE_PARITY : boolean := (PARITY_TYPE /= "NONE");

    -- Definição dos Estados da Máquina de Estados
    type t_state is (IDLE, START, DATA, PARITY, STOP, AXIS);
    signal state_reg : t_state := IDLE;

    -- Sinais da Máquina de Estados
    signal uart_rx_reg    : std_logic := '1';
    signal data_count_reg : natural range 0 to DATA_BITS-1 := 0;
    signal stop_count_reg : natural range 0 to STOP_BITS-1 := 0;
    signal parity_bit     : std_logic;

    -- Registradores das Saídas
    signal phase_trigger_reg : std_logic := '0';
    signal m_axis_tdata_reg  : std_logic_vector(DATA_BITS-1 downto 0) := (others => '0');
    signal m_axis_tvalid_reg : std_logic := '0';
    signal busy_reg          : std_logic := '0';

begin

    -- Lógica de Paridade (Combinacional)
    parity_bit <= xor_reduce(m_axis_tdata_reg) when (PARITY_TYPE = "EVEN") else
                  not xor_reduce(m_axis_tdata_reg) when (PARITY_TYPE = "ODD") else
                  '0';

    sync_proc: process(clk)
    begin
        if rising_edge(clk) then
            if n_rst = '0' then
                -- Reset de todos os registradores
                state_reg         <= IDLE;
                uart_rx_reg       <= '1';
                data_count_reg    <= 0;
                stop_count_reg    <= 0;
                phase_trigger_reg <= '0';
                m_axis_tdata_reg  <= (others => '0');
                m_axis_tvalid_reg <= '0';
                busy_reg          <= '0';
            else

                -- Registra o dado na linha serial RX
                uart_rx_reg <= uart_rx;

                case(state_reg) is
                
                    when IDLE =>
                        if (uart_rx_reg = '0') then -- Caso o RX caia para '0' começa a recepção
                            phase_trigger_reg <= '1';
                            m_axis_tvalid_reg <= '0';
                            busy_reg          <= '1';
                            state_reg         <= START;        
                        else
                            phase_trigger_reg <= '0';
                            m_axis_tvalid_reg <= '0';
                            busy_reg          <= '0';
                        end if;

                    when START => -- Espera o baud tick centralizado no dado e verifica o bit de start ('0')
                        phase_trigger_reg <= '0';
                        if (baud_tick = '1') then
                            if (uart_rx_reg = '0') then
                                data_count_reg <= 0;
                                state_reg <= DATA;
                            else
                                state_reg <= IDLE;
                            end if;
                        end if;

                    when DATA => -- Faz o sampling de todos os bits de dados ao receber o baud tick
                        if (baud_tick = '1') then
                            m_axis_tdata_reg(data_count_reg) <= uart_rx_reg; -- Sampling
                            if (data_count_reg < DATA_BITS-1) then
                                data_count_reg <= data_count_reg + 1;
                            else
                                data_count_reg <= 0;
                                if (USE_PARITY) then -- Se houver paridade verifica, se não, vai para os bits de stop
                                    state_reg <= PARITY;
                                else
                                    state_reg <= STOP;
                                end if;
                            end if;
                        end if;

                    when PARITY => -- Verifica o bit de paridade
                        if (baud_tick = '1') then
                            if (parity_bit = uart_rx_reg) then
                                stop_count_reg <= 0;
                                state_reg <= STOP;
                            else
                                state_reg <= IDLE;
                            end if;
                        end if;

                    when STOP => -- Verifica os bits de stop
                        if (baud_tick = '1') then
                            if (uart_rx_reg = '1') then
                                if (stop_count_reg < STOP_BITS-1) then
                                    stop_count_reg <= stop_count_reg + 1;
                                else
                                    stop_count_reg <= 0;
                                    m_axis_tvalid_reg <= '1'; -- Indica que o dado lido é válido
                                    state_reg <= AXIS;
                                end if;
                            else
                                state_reg <= IDLE;
                            end if;
                        end if;

                    when AXIS => -- Espera o hand-shake AXIS
                        if (m_axis_tready = '1') then -- Se o hand-shake acontecer, retorna ao estado IDLE
                            m_axis_tvalid_reg <= '0';
                            state_reg         <= IDLE;
                        end if;

                end case;

            end if;
        end if;
    end process sync_proc;

    -- Conexões com a Saída
    phase_trigger <= phase_trigger_reg;
    m_axis_tdata  <= m_axis_tdata_reg;
    m_axis_tvalid <= m_axis_tvalid_reg;
    busy          <= busy_reg;

end architecture rtl;