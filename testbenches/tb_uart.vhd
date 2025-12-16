----------------------------------------------------------------------------------
-- Company: CEPEDI
-- Engineer: Gabriel Cavalcanti Coelho
-- Create Date: 06.11.2025
-- Module Name: tb_uart
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_uart is
end entity tb_uart;

architecture sim of tb_uart is

    -- Constantes do Testbench
    constant CLOCK    : natural := 100000000;
    constant BAUDRATE : natural := 921600;
    constant T        : time    := 10 ns;  -- 100 MHz
    constant B        : time    := 1085 ns;

    constant DATA_BITS   : natural := 8;
    constant PARITY_TYPE : string  := "NONE";
    constant STOP_BITS   : natural := 1;
    constant FIFO_DEPTH  : natural := 16;

    -- ---- Sinais de Conexão ----

    -- Sinais globais
    signal tb_clk   : std_logic := '0';
    signal tb_n_rst : std_logic := '0';

    -- Linha serial
    signal tb_uart_tx : std_logic;
    signal tb_uart_rx : std_logic;

    -- Sinais da Cadeia TX
    signal fifo_tdata  : std_logic_vector(DATA_BITS - 1 downto 0);
    signal fifo_tvalid : std_logic;
    signal fifo_tready : std_logic;
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

    -- Ticker para o TX (Fase 0)
    ticker_tx : entity work.uart_tx_baud_ticker
        generic map (
            CLOCK       => CLOCK,
            BAUDRATE    => BAUDRATE,
            OVERSAMPLE  => 1,
            PHASE_VALUE => 0 -- Fase 0 para TX
        )
        port map (
            clk           => tb_clk,
            n_rst         => tb_n_rst,
            phase_trigger => tx_phase_trigger,
            baud_tick     => tx_baud_tick
        );

    -- Ticker para o RX (Fase 50)
    ticker_rx : entity work.uart_rx_baud_ticker
        generic map (
            CLOCK       => CLOCK,
            BAUDRATE    => BAUDRATE,
            OVERSAMPLE  => 1,
            PHASE_VALUE => 50 -- Fase 50 para RX
        )
        port map (
            clk           => tb_clk,
            n_rst         => tb_n_rst,
            phase_trigger => rx_phase_trigger,
            baud_tick     => rx_baud_tick
        );
        
    -- FIFO da cadeia TX
    fifo_tx : entity work.axis_fifo
        generic map (
            DATA_WIDTH => DATA_BITS,
            DEPTH      => FIFO_DEPTH
        )
        port map (
            clk           => tb_clk,
            n_rst         => tb_n_rst,
            s_axis_tdata  => fifo_tdata,
            s_axis_tvalid => fifo_tvalid,
            s_axis_tready => fifo_tready,
            m_axis_tdata  => tx_fifo_m_tdata,
            m_axis_tvalid => tx_fifo_m_tvalid,
            m_axis_tready => tx_fifo_m_tready
        );
        
    -- Módulo UART TX
    uart_tx : entity work.uart_tx
        generic map (
            DATA_BITS   => DATA_BITS,
            PARITY_TYPE => PARITY_TYPE,
            STOP_BITS   => STOP_BITS
        )
        port map (
            clk           => tb_clk,
            n_rst         => tb_n_rst,
            baud_tick     => tx_baud_tick,
            phase_trigger => tx_phase_trigger,
            s_axis_tdata  => tx_fifo_m_tdata,
            s_axis_tvalid => tx_fifo_m_tvalid,
            s_axis_tready => tx_fifo_m_tready,
            tx            => tb_uart_tx,
            busy          => open
        );
        
    -- Módulo UART RX
    uart_rx : entity work.uart_rx
        generic map (
            DATA_BITS   => DATA_BITS,
            PARITY_TYPE => PARITY_TYPE,
            STOP_BITS   => STOP_BITS
        )
        port map (
            clk           => tb_clk,
            n_rst         => tb_n_rst,
            baud_tick     => rx_baud_tick,
            phase_trigger => rx_phase_trigger,
            rx            => tb_uart_rx,
            m_axis_tdata  => rx_fifo_s_tdata,
            m_axis_tvalid => rx_fifo_s_tvalid,
            m_axis_tready => rx_fifo_s_tready,
            busy          => open
        );
        
    -- FIFO da cadeia RX
    fifo_rx : entity work.axis_fifo
        generic map (
            DATA_WIDTH => DATA_BITS,
            DEPTH      => FIFO_DEPTH
        )
        port map (
            clk           => tb_clk,
            n_rst         => tb_n_rst,
            s_axis_tdata  => rx_fifo_s_tdata,
            s_axis_tvalid => rx_fifo_s_tvalid,
            s_axis_tready => rx_fifo_s_tready,
            m_axis_tdata  => fifo_tdata,
            m_axis_tvalid => fifo_tvalid,
            m_axis_tready => fifo_tready
        );

    --== 5. Processos de Simulação ==--

    -- Processo de Clock
    p_clk_gen : process
    begin
        wait for T/2;
        tb_clk <= not tb_clk;
    end process p_clk_gen;

    -- Processo de Reset
    p_reset_gen : process
    begin
        tb_n_rst <= '0';
        wait for T;
        tb_n_rst <= '1';
        wait; -- Fim do reset
    end process p_reset_gen;

    -- Processo de Estímulo (Envia dados para a FIFO_TX)
    p_stimulus : process
        variable data_byte : unsigned(DATA_BITS - 1 downto 0);
    begin
        -- Aguarda o reset
        wait until tb_n_rst = '1';
        wait for 2*T;


        
        for i in 1 to 8 loop
            data_byte := to_unsigned(i, DATA_BITS);

            tb_uart_rx <= '0';
            wait for B;

            for j in 0 to DATA_BITS-1 loop
                tb_uart_rx <= data_byte(j);
                wait for B;
            end loop;

            tb_uart_rx <= '1';
            wait for B;

            wait for 4*T;

        end loop;

        wait;

    end process p_stimulus;

end architecture sim;