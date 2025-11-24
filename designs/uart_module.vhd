library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_module is
    generic (
        DATA_BITS   : natural := 8;        -- Número de bits de dados
        PARITY_TYPE : string  := "EVEN";   -- Tipo de paridade: "NONE", "EVEN" ou "ODD"
        STOP_BITS   : natural := 1;        -- Número de stop bits
        CLOCK       : natural := 25000000; -- Frequência do clock de entrada em Hz
        BAUDRATE    : natural := 115200;   -- Baudrate desejado para a comunicação UART
        DATA_WIDTH  : natural := 8;        -- Largura da palavra de dados em bits
        DEPTH       : natural := 16        -- Profundidade da FIFO (número de palavras)
    );
    port (
        -- Sinais Globais
        clk   : in  std_logic; -- Clock do sistema
        n_rst : in  std_logic; -- Reset síncrono, ativo-baixo

        -- Linhas Seriais
        uart_rx : in  std_logic; -- A linha serial de recepção
        uart_tx : out std_logic  -- A linha serial de transmissão
    );
end entity uart_module;

architecture rtl of uart_module is

    -- Sinais de Loopback
    signal fifo_tdata  : std_logic_vector(DATA_BITS - 1 downto 0);
    signal fifo_tvalid : std_logic;
    signal fifo_tready : std_logic;

    -- Sinais da Cadeia TX
    signal tx_fifo_m_tdata  : std_logic_vector(DATA_BITS - 1 downto 0);
    signal tx_fifo_m_tvalid : std_logic;
    signal tx_fifo_m_tready : std_logic;
    signal tx_baud_tick     : std_logic;
    signal tx_phase_trigger : std_logic;

    -- Sinais da Cadeia RX
    signal rx_fifo_s_tdata  : std_logic_vector(DATA_BITS - 1 downto 0);
    signal rx_fifo_s_tvalid : std_logic;
    signal rx_fifo_s_tready : std_logic;
    signal rx_baud_tick     : std_logic;
    signal rx_phase_trigger : std_logic;

begin
    
    -- Ticker para o TX (Fase 0%)
    ticker_tx : entity work.uart_baud_ticker
        generic map (
            CLOCK       => CLOCK,
            BAUDRATE    => BAUDRATE,
            OVERSAMPLE  => 1,
            PHASE_VALUE => 0 -- Fase 0% para TX
        )
        port map (
            clk           => clk,
            n_rst         => n_rst,
            phase_trigger => tx_phase_trigger,
            baud_tick     => tx_baud_tick
        );

    -- Ticker para o RX (Fase 50%)
    ticker_rx : entity work.uart_baud_ticker
        generic map (
            CLOCK       => CLOCK,
            BAUDRATE    => BAUDRATE,
            OVERSAMPLE  => 1,
            PHASE_VALUE => 50 -- Fase 50% para RX
        )
        port map (
            clk           => clk,
            n_rst         => n_rst,
            phase_trigger => rx_phase_trigger,
            baud_tick     => rx_baud_tick
        );
        
    -- FIFO da cadeia TX
    fifo_tx : entity work.axis_fifo
        generic map (
            DATA_WIDTH => DATA_BITS,
            DEPTH      => DEPTH
        )
        port map (
            clk           => clk,
            n_rst         => n_rst,
            s_axis_tdata  => fifo_tdata,
            s_axis_tvalid => fifo_tvalid,
            s_axis_tready => fifo_tready,
            m_axis_tdata  => tx_fifo_m_tdata,
            m_axis_tvalid => tx_fifo_m_tvalid,
            m_axis_tready => tx_fifo_m_tready
        );
        
    -- Módulo UART TX
    uart_tx_module : entity work.uart_tx
        generic map (
            DATA_BITS   => DATA_BITS,
            PARITY_TYPE => PARITY_TYPE,
            STOP_BITS   => STOP_BITS
        )
        port map (
            clk           => clk,
            n_rst         => n_rst,
            baud_tick     => tx_baud_tick,
            phase_trigger => tx_phase_trigger,
            s_axis_tdata  => tx_fifo_m_tdata,
            s_axis_tvalid => tx_fifo_m_tvalid,
            s_axis_tready => tx_fifo_m_tready,
            uart_tx       => uart_tx,
            busy          => open
        );
        
    -- Módulo UART RX
    uart_rx_module : entity work.uart_rx
        generic map (
            DATA_BITS   => DATA_BITS,
            PARITY_TYPE => PARITY_TYPE,
            STOP_BITS   => STOP_BITS
        )
        port map (
            clk           => clk,
            n_rst         => n_rst,
            baud_tick     => rx_baud_tick,
            phase_trigger => rx_phase_trigger,
            uart_rx       => uart_rx,
            m_axis_tdata  => rx_fifo_s_tdata,
            m_axis_tvalid => rx_fifo_s_tvalid,
            m_axis_tready => rx_fifo_s_tready,
            busy          => open
        );
        
    -- FIFO da cadeia RX
    fifo_rx : entity work.axis_fifo
        generic map (
            DATA_WIDTH => DATA_BITS,
            DEPTH      => DEPTH
        )
        port map (
            clk           => clk,
            n_rst         => n_rst,
            s_axis_tdata  => rx_fifo_s_tdata,
            s_axis_tvalid => rx_fifo_s_tvalid,
            s_axis_tready => rx_fifo_s_tready,
            m_axis_tdata  => fifo_tdata,
            m_axis_tvalid => fifo_tvalid,
            m_axis_tready => fifo_tready
        );
    
end architecture rtl;