----------------------------------------------------------------------------------
-- Company: CEPEDI
-- Engineer: Gabriel Cavalcanti Coelho
-- Create Date: 28.10.2025
-- Module Name: tb_axis_fifo_01
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_axis_fifo_01 is
end entity tb_axis_fifo_01;

architecture behavior of tb_axis_fifo_01 is

    -- Constantes do Testbench
    constant DATA_WIDTH : natural := 8;
    constant DEPTH      : natural := 16;
    constant T          : time    := 10 ns; -- Clock de 100 MHz

    -- Sinais globais
    signal clk   : std_logic := '0';
    signal n_rst : std_logic := '0';

    -- Sinais para a entrada da FIFO 01 (gerados pelo estímulo)
    signal s_axis_tdata_1  : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal s_axis_tvalid_1 : std_logic := '0';
    signal s_axis_tready_1 : std_logic;

    -- Sinais para a conexão entre FIFO 01 e FIFO 02
    signal inter_fifo_tdata  : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal inter_fifo_tvalid : std_logic;
    signal inter_fifo_tready : std_logic;

    -- Sinais para a saída da FIFO 02 (consumidos pelo verificador)
    signal m_axis_tdata_2  : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal m_axis_tvalid_2 : std_logic;
    signal m_axis_tready_2 : std_logic := '0';

begin

    -- Instanciação dos Componentes
    -- FIFO 01: Recebe dados do processo de estímulo e os envia para a FIFO 02
    fifo_01 : entity work.axis_fifo
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            DEPTH      => DEPTH
        )
        port map (
            clk           => clk,
            n_rst         => n_rst,
            s_axis_tdata  => s_axis_tdata_1,
            s_axis_tvalid => s_axis_tvalid_1,
            s_axis_tready => s_axis_tready_1,
            m_axis_tdata  => inter_fifo_tdata,  -- (Saída Master)
            m_axis_tvalid => inter_fifo_tvalid, -- (Saída Master)
            m_axis_tready => inter_fifo_tready  -- (Saída Master)
        );
        
    -- FIFO 02: Recebe dados da FIFO 01 e os envia para o processo de verificação
    fifo_02 : entity work.axis_fifo
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            DEPTH      => DEPTH
        )
        port map (
            clk           => clk,
            n_rst         => n_rst,
            s_axis_tdata  => inter_fifo_tdata,  -- (Entrada Slave)
            s_axis_tvalid => inter_fifo_tvalid, -- (Entrada Slave)
            s_axis_tready => inter_fifo_tready, -- (Entrada Slave)
            m_axis_tdata  => m_axis_tdata_2,
            m_axis_tvalid => m_axis_tvalid_2,
            m_axis_tready => m_axis_tready_2
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

    -- Processo de Estímulo (Escreve na FIFO 01)
    stimulus_proc : process
        variable data_to_write : unsigned(DATA_WIDTH - 1 downto 0);
    begin
        -- Espera o reset terminar
        s_axis_tvalid_1 <= '0';
        wait for 8*T;

        -- Loop para escrever 16 palavras de dados
        for i in 0 to 15 loop
            -- Prepara os dados e o sinal de validade
            data_to_write := to_unsigned(15 + i, DATA_WIDTH);
            s_axis_tdata_1  <= std_logic_vector(data_to_write);
            s_axis_tvalid_1 <= '1';
            
            -- Espera o handshake (FIFO 01 aceitar o dado)
            wait until rising_edge(clk) and s_axis_tready_1 = '1';

        end loop;

        s_axis_tvalid_1 <= '0';
        s_axis_tdata_1  <= (others => '0');

        wait;

    end process stimulus_proc;

    -- 7. Processo de Verificação (Lê da FIFO 02)
    consumer_checker_proc : process
    begin
        -- Começa sem estar pronto para receber dados
        m_axis_tready_2 <= '0';
        wait for 28*T;

        -- Loop para ler as 16 palavras de dados
        for i in 0 to 15 loop
            -- Sinaliza que está pronto para receber
            m_axis_tready_2 <= '1';
            
            -- Espera o handshake (FIFO 02 apresentar dado válido)
            wait until rising_edge(clk) and m_axis_tvalid_2 = '1';

        end loop;

        m_axis_tready_2 <= '0';
        
        wait;

    end process consumer_checker_proc;

end architecture behavior;