----------------------------------------------------------------------------------
-- Company: CEPEDI
-- Engineer: Gabriel Cavalcanti Coelho
-- Create Date: 28.10.2025
-- Module Name: tb_uart_baud_ticker
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_uart_baud_ticker is
end entity tb_uart_baud_ticker;

architecture behavior of tb_uart_baud_ticker is

    -- Período de clock para o testbench (500 MHz)
    constant T : time := 2 ns;

    -- Parâmetros
    constant CLOCK_FREQ  : positive := 500000000; -- 500 MHz
    constant OVERSAMPLE  : positive := 1;
    constant BAUDRATE    : positive := 10000000;  -- 10 MHz
    constant PHASE_VALUE : natural  := 50;
    
    -- Sinais de interface
    signal clk           : std_logic := '0';
    signal n_rst         : std_logic;
    signal phase_trigger : std_logic;
    signal baud_tick     : std_logic;

begin

    -- Instanciação do Módulo
    UUT: entity work.uart_tx_baud_ticker
        generic map (
            CLOCK       => CLOCK_FREQ,
            BAUDRATE    => BAUDRATE,
            OVERSAMPLE  => OVERSAMPLE,
            PHASE_VALUE => PHASE_VALUE
        )
        port map (
            clk           => clk,
            n_rst         => n_rst,
            phase_trigger => phase_trigger,
            baud_tick     => baud_tick
        );

    -- Geração de Clock
    clk_gen: process
    begin
        wait for T/2;
        clk <= not clk;
    end process clk_gen;

    -- Processo de Estímulo
    stimulus_proc: process
    begin
        -- Reset Inicial
        n_rst         <= '0';
        phase_trigger <= '0';
        
        -- Mantém em reset por 4 ciclos de clock
        for i in 1 to 4 loop
            wait until rising_edge(clk);
        end loop;

        -- Libera o reset
        n_rst <= '1';

        -- Espera pelos dois primeiros ticks
        for i in 1 to 108 loop
            wait until falling_edge(clk);
        end loop;

        -- Testa o phase_trigger
        phase_trigger <= '1';
        wait until rising_edge(clk);
        phase_trigger <= '0';

        wait;

    end process stimulus_proc;

end architecture behavior;