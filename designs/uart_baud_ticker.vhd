----------------------------------------------------------------------------------
-- Company: CEPEDI
-- Engineer: Gabriel Cavalcanti Coelho
-- Create Date: 28.10.2025
-- Module Name: uart_baud_ticker
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity uart_baud_ticker is
    generic (
        CLOCK          : natural := 25000000;        -- Frequência do clock de entrada em Hz
        BAUDRATE       : natural := 115200;          -- Baudrate desejado para a comunicação UART
        OVERSAMPLE     : natural := 1;               -- Fator de oversampling
        PHASE_FRACTION : natural range 0 to 100 := 0 -- Fator de fase (0 a 100) (50 para RX e 0 ou 100 para TX)
    );
    port (
        clk           : in  std_logic; -- Entrada do clock de sistema
        n_rst         : in  std_logic; -- Reset síncrono, ativo em nível lógico baixo ('0')
        phase_trigger : in  std_logic; -- Ao ativar, reseta o contador para o valor de fase
        baud_tick     : out std_logic  -- Saída de um pulso ('tick'), ativa por um ciclo na frequência desejada
    );
end entity uart_baud_ticker;

architecture rtl of uart_baud_ticker is

    -- Constante que calcula o fator de divisão necessário
    constant DIV : natural := natural(round(real(CLOCK)/real(BAUDRATE*OVERSAMPLE)));

    -- Calcula o número de ciclos de atraso desejado a partir do trigger
    constant DELAY_CYCLES : natural := natural(round((real(PHASE_FRACTION)*real(DIV))/real(100)));

    -- Calcula o valor que deve ser carregado no contador para que (DIV - PHASE_OFFSET_VALUE)
    -- seja o atraso desejado, o mod DIV permite o "wrap-around" desse valor
    constant PHASE_OFFSET_VALUE : natural := (DIV - DELAY_CYCLES) mod DIV;

    -- Sinal do contador que conta os ciclos do clock principal (clk)
    signal counter_reg : natural range 0 to DIV-1 := 0;

    -- Sinal que armazena o estado do pulso de saída
    signal baud_tick_reg : std_logic := '0';

begin

    -- Processo síncrono que implementa a lógica de geração do pulso
    counter_proc: process(clk)
    begin
        if rising_edge(clk) then
            if (n_rst = '0') then -- Lógica de reset síncrono
                counter_reg   <= 0;
                baud_tick_reg <= '0';
            else
                if (phase_trigger = '1') then -- Lógica da fase 
                    counter_reg   <= PHASE_OFFSET_VALUE;
                    baud_tick_reg <= '0'; -- Garante que não haja tick durante o resync
                else 
                    if (counter_reg = DIV-1) then -- Lógica de contagem
                        counter_reg   <= 0;
                        baud_tick_reg <= '1';
                    else -- Contagem normal
                        counter_reg   <= counter_reg + 1;
                        baud_tick_reg <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process counter_proc;

    -- Conecta o registrador à saída
    baud_tick <= baud_tick_reg;

end architecture rtl;