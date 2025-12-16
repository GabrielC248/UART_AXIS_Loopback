----------------------------------------------------------------------------------
-- Company: CEPEDI
-- Engineer: Gabriel Cavalcanti Coelho
-- Create Date: 05.11.2025
-- Module Name: tb_uart_rx
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_uart_rx is
end entity tb_uart_rx;

architecture sim of tb_uart_rx is

    -- Constantes do Testbench 
    constant c_CLOCK_HZ     : natural := 100000000;
    constant c_CLOCK_PERIOD : time    := 10 ns;
    constant c_BAUD_RATE    : natural := 921600;

    -- Cálculo do período de bit
    constant c_BIT_PERIOD   : time    := 1090 ns;

    -- Parâmetros dos DUTs
    constant c_DATA_BITS   : natural := 8;
    constant c_PARITY_TYPE : string  := "EVEN";
    constant c_STOP_BITS   : natural := 1;

    -- Sinais de Conexão

    -- Sinais globais
    signal tb_clk   : std_logic := '0';
    signal tb_n_rst : std_logic := '0';

    -- Sinais de simulação
    signal w_uart_rx_line : std_logic := '1'; -- Linha serial

    -- Fios de conexão entre os DUTs
    signal w_phase_trigger : std_logic;
    signal w_baud_tick     : std_logic;

    -- Sinais da Interface AXI-Stream (Saída do RX)
    signal w_axis_tdata   : std_logic_vector(c_DATA_BITS - 1 downto 0);
    signal w_axis_tvalid  : std_logic;
    signal tb_axis_tready : std_logic;
    signal w_busy         : std_logic;
    
    function xor_reduce(vector : std_logic_vector) return std_logic is
        variable result : std_logic := '0';
    begin
        for i in vector'range loop
            result := result xor vector(i);
        end loop;
        return result;
    end function xor_reduce;

    procedure proc_send_byte(
        signal   tx_line    : out std_logic;
        constant data       : in  std_logic_vector(c_DATA_BITS - 1 downto 0);
        constant bit_period : in  time
    ) is
        variable v_parity : std_logic;
    begin
        -- Start Bit
        tx_line <= '0';
        wait for bit_period;

        -- Data Bits (LSB first)
        for i in 0 to c_DATA_BITS - 1 loop
            tx_line <= data(i);
            wait for bit_period;
        end loop;

        -- Parity Bit (se habilitado)
        v_parity := xor_reduce(data); -- '0' para par, '1' para ímpar
        if (c_PARITY_TYPE = "EVEN") then
            tx_line <= v_parity;
        elsif (c_PARITY_TYPE = "ODD") then
            tx_line <= not v_parity;
        end if;
        wait for bit_period;

        -- Stop Bit(s)
        for i in 1 to c_STOP_BITS loop
            tx_line <= '1';
            wait for bit_period;
        end loop;

        -- Linha volta ao Idle
        tx_line <= '1';
    end procedure proc_send_byte;


begin

    ticker : entity work.uart_rx_baud_ticker
        generic map (
            CLOCK        => c_CLOCK_HZ,
            BAUDRATE     => c_BAUD_RATE,
            OVERSAMPLE   => 1, -- Conforme nossa lógica de RX
            PHASE_VALUE  => 50 -- Conforme nossa lógica de RX
        )
        port map (
            clk           => tb_clk,
            n_rst         => tb_n_rst,
            phase_trigger => w_phase_trigger,
            baud_tick     => w_baud_tick
        );

    rx_uut : entity work.uart_rx
        generic map (
            DATA_BITS   => c_DATA_BITS,
            PARITY_TYPE => c_PARITY_TYPE,
            STOP_BITS   => c_STOP_BITS
        )
        port map (
            clk           => tb_clk,
            n_rst         => tb_n_rst,
            rx            => w_uart_rx_line,  -- Linha de simulação
            baud_tick     => w_baud_tick,     -- Do ticker
            phase_trigger => w_phase_trigger, -- Para o ticker
            m_axis_tdata  => w_axis_tdata,
            m_axis_tvalid => w_axis_tvalid,
            m_axis_tready => tb_axis_tready,
            busy          => w_busy
        );


    --== 6. Processos de Simulação ==--

    -- Processo de Clock
    p_clk_gen : process
    begin
        tb_clk <= '0';
        wait for c_CLOCK_PERIOD / 2;
        tb_clk <= '1';
        wait for c_CLOCK_PERIOD / 2;
    end process p_clk_gen;

    -- Processo de Reset
    p_reset_gen : process
    begin
        tb_n_rst <= '0';
        wait for c_CLOCK_PERIOD;
        tb_n_rst <= '1';
        wait; -- Fim do reset
    end process p_reset_gen;

    -- Processo Consumidor AXI (Simula o receptor)
    p_consumer_ready : process
    begin
        tb_axis_tready <= '0';
        wait until tb_n_rst = '1';
        tb_axis_tready <= '1'; -- Fica sempre pronto para receber
        wait;
    end process p_consumer_ready;

    -- Processo de Estímulo (Envia os dados)
    p_stimulus : process
    begin
        -- 1. Inicializa a linha
        w_uart_rx_line <= '1'; -- Linha em Idle
        wait until tb_n_rst = '1';
        wait for c_BIT_PERIOD; -- Espera um tempo em idle

        -- 2. Envia o primeiro byte (0x41 = 'A')
        proc_send_byte(w_uart_rx_line, x"41", c_BIT_PERIOD);
        wait for c_BIT_PERIOD; -- Gap entre os bytes

        -- 3. Envia o segundo byte (0x55)
        proc_send_byte(w_uart_rx_line, x"55", c_BIT_PERIOD);
        wait for c_BIT_PERIOD;

        wait;

    end process p_stimulus;

end architecture sim;