----------------------------------------------------------------------------------
-- Company: CEPEDI
-- Engineer: Gabriel Cavalcanti Coelho
-- Create Date: 28.10.2025
-- Module Name: tb_axis_fifo_02
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_axis_fifo_02 is
end entity tb_axis_fifo_02;

architecture behavior of tb_axis_fifo_02 is

    -- Constantes do Testbench
    constant DATA_WIDTH : natural := 8;
    constant DEPTH      : natural := 16;
    constant T          : time    := 10 ns; -- Clock de 100 MHz

    -- Sinais globais
    signal clk   : std_logic := '0';
    signal n_rst : std_logic := '0';

    -- Sinais para a entrada da FIFO (Interface Slave)
    signal s_axis_tdata  : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal s_axis_tvalid : std_logic := '0';
    signal s_axis_tready : std_logic;

    -- Sinais para a saída da FIFO (Interface Master)
    signal m_axis_tdata  : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal m_axis_tvalid : std_logic;
    signal m_axis_tready : std_logic := '0';

begin

    -- Instanciação da FIFO 
    fifo_01 : entity work.axis_fifo 
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            DEPTH      => DEPTH
        )
        port map (
            clk           => clk,
            n_rst         => n_rst,
            s_axis_tdata  => s_axis_tdata,
            s_axis_tvalid => s_axis_tvalid,
            s_axis_tready => s_axis_tready,
            m_axis_tdata  => m_axis_tdata,
            m_axis_tvalid => m_axis_tvalid,
            m_axis_tready => m_axis_tready
        );

    -- Geradores de Clock e Reset
    clk_process: process
    begin
        clk <= '0';
        wait for (T/2);
        clk <= '1';
        wait for (T/2);
    end process clk_process;

    n_rst_process: process
    begin
        n_rst <= '0';
        wait for (T);
        n_rst <= '1';
        wait;
    end process n_rst_process;

    -- Teste Básico
    test_proc: process
        variable data_to_write : unsigned(DATA_WIDTH - 1 downto 0);
    begin
        -- Aguarda um tempo após o reset
        s_axis_tvalid <= '0';
        s_axis_tdata  <= (others => '0');
        m_axis_tready <= '0';
        wait for 8*T;
        
        -- Preenche a FIFO (16 palavras)
        for i in 0 to 15 loop
            data_to_write := to_unsigned(15 + i, DATA_WIDTH);
            s_axis_tdata  <= std_logic_vector(data_to_write);
            s_axis_tvalid <= '1';
            
            -- Espera o handshake de escrita (FIFO aceitar o dado)
            wait until rising_edge(clk) and s_axis_tready = '1';
        end loop;
        s_axis_tdata  <= (others => '0');
        s_axis_tvalid <= '0';

        -- Espera um pouco
        wait for 4*T;
        wait until falling_edge(clk);

        -- Lê todos os dados da FIFO (16 palavras)
        for i in 0 to 15 loop
            m_axis_tready <= '1';
            -- Espera o handshake de leitura (FIFO fornecer o dado)
            wait until rising_edge(clk) and m_axis_tvalid = '1';
        end loop;
        m_axis_tready <= '0';

        -- Espera um pouco
        wait for 4*T;
        wait until falling_edge(clk);

        -- Escreve o dado "4" na FIFO
        data_to_write := to_unsigned(4, DATA_WIDTH);
        s_axis_tdata  <= std_logic_vector(data_to_write);
        s_axis_tvalid <= '1';
        
        -- Espera o handshake de escrita
        wait until rising_edge(clk) and s_axis_tready = '1';
        
        s_axis_tvalid <= '0';
        s_axis_tdata  <= (others => '0');

        -- Espera um pouco
        wait for 4*T;
        wait until falling_edge(clk);

        -- Escreve o dado "5" e realiza uma leitura (do dado "4") ao mesmo tempo
        data_to_write := to_unsigned(5, DATA_WIDTH);
        s_axis_tdata  <= std_logic_vector(data_to_write);
        s_axis_tvalid <= '1';
        m_axis_tready <= '1';

        -- Espera pelo clock edge onde ambas as condições de handshake são verdadeiras
        -- (FIFO está pronta para escrever E FIFO tem dado válido para ler)
        wait until rising_edge(clk) and s_axis_tready = '1' and m_axis_tvalid = '1';

        s_axis_tdata  <= (others => '0');
        s_axis_tvalid <= '0';
        m_axis_tready <= '0';

        wait;

    end process test_proc;

end architecture behavior;