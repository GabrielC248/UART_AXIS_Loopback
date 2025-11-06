----------------------------------------------------------------------------------
-- Company: CEPEDI
-- Engineer: Gabriel Cavalcanti Coelho
-- Create Date: 28.10.2025
-- Module Name: tb_uart_tx
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_uart_tx is
end entity tb_uart_tx;

architecture sim of tb_uart_tx is

    -- Configuração do Testbench
    constant T_FREQ : natural := 100000000; -- Clock de 100 MHz
    constant T_CLK  : time    := 10 ns;     -- Período de 100 MHz

    -- Configuração dos Módulos
    constant BAUDRATE    : natural := 921600;
    constant DATA_BITS   : natural := 8;
    constant PARITY_TYPE : string  := "EVEN";
    constant STOP_BITS   : natural := 1;

    -- Sinais de Conexão
    signal clk   : std_logic := '0';
    signal n_rst : std_logic;

    -- Sinais entre o Ticker e o TX
    signal baud_tick        : std_logic;
    signal phase_trigger : std_logic;

    -- Sinais para a interface AXI-Stream do TX
    signal s_axis_tdata  : std_logic_vector(DATA_BITS - 1 downto 0);
    signal s_axis_tvalid : std_logic;
    signal s_axis_tready : std_logic;

    -- Sinais de saída do TX
    signal uart_tx : std_logic;
    signal busy    : std_logic;

begin

    -- Instanciação do Ticker (com PHASE_FRACTION = 0.0)
    ticker_inst : entity work.uart_baud_ticker
        generic map (
            CLOCK       => T_FREQ,
            BAUDRATE    => BAUDRATE,
            OVERSAMPLE  => 1,
            PHASE_VALUE => 0 -- Configurado para "resetar"
        )
        port map (
            clk           => clk,
            n_rst         => n_rst,
            phase_trigger => phase_trigger, -- Conectado ao TX
            baud_tick     => baud_tick         -- Conectado ao TX
        );

    -- Instanciação do TX
    tx_inst : entity work.uart_tx
        generic map (
            DATA_BITS   => DATA_BITS,
            PARITY_TYPE => PARITY_TYPE,
            STOP_BITS   => STOP_BITS
        )
        port map (
            clk              => clk,
            n_rst            => n_rst,
            baud_tick        => baud_tick,
            phase_trigger    => phase_trigger,
            s_axis_tdata     => s_axis_tdata,
            s_axis_tvalid    => s_axis_tvalid,
            s_axis_tready    => s_axis_tready,
            uart_tx          => uart_tx,
            busy             => busy
        );

    -- Gerador de Clock
    clk_gen: process
    begin
        wait for T_CLK/2;
        clk <= not clk;
    end process clk_gen;

    -- Gerador de Reset
    reset_proc : process
    begin
        n_rst <= '0';
        wait for 10 * T_CLK; -- Mantém em reset por 100 ns
        n_rst <= '1';
        wait;
    end process reset_proc;

    -- Processo de Estímulo
    stimulus_proc : process
    begin
        -- Inicializa as entradas
        s_axis_tvalid <= '0';
        s_axis_tdata  <= (others => '0');
        
        -- Espera o reset terminar
        wait until n_rst = '1';
        wait for 10 * T_CLK;

        -- Teste 1: Enviar Byte
        s_axis_tdata  <= "01010101";
        s_axis_tvalid <= '1';

        -- Espera pelo handshake (IDLE -> START)
        wait until rising_edge(clk) and s_axis_tready = '1';
        
        -- Handshake concluído, abaixa o tvalid
        s_axis_tvalid <= '0';

        wait until rising_edge(clk) and s_axis_tready = '1';
        -- Teste 2: Enviar Byte
        s_axis_tdata  <= "10100010";
        s_axis_tvalid <= '1';

        -- Espera pelo handshake (IDLE -> START)
        wait until rising_edge(clk) and s_axis_tready = '1';
        
        -- Handshake concluído, abaixa o tvalid
        s_axis_tvalid <= '0';

        wait;
        
    end process stimulus_proc;

end architecture sim;