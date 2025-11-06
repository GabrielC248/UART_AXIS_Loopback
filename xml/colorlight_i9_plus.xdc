# ================================================================================
# Company       : CEPEDI
# Engineer      : Gabriel Cavalcanti Coelho
# Create Date   : 2025-08
# Target Device : Colorlight i9+ (XC7A50T-FGG484)
# Description   : Basic Master XDC defining system clock, LED, and external
#                 board I/O pin constraints for simplified board usage.
# ================================================================================

# Basic Configuration
# ========================================
#set_property CFGBVS VCCO [current_design] PERGUNTAR
#set_property CONFIG_VOLTAGE 3.3 [current_design] PERGUNTAR

# System Clock (xtal 25 MHz - 40 ns)
# ========================================
set_property -dict {PACKAGE_PIN K4 IOSTANDARD LVCMOS33} [get_ports clk]; #IO_L13P_T2_MRCC_35 (Bank 35)
create_clock -name clk -period 40.0 [get_ports clk];

# Board LED (D2)
# ========================================
#set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports led_D2]; #IO_L17P_T2_16 (Bank 16)

# UART
# ========================================
set_property -dict {PACKAGE_PIN M3 IOSTANDARD LVCMOS33} [get_ports uart_rx]; #IO_L16P_T2_35 (Bank 35)    - (P5 15)
set_property -dict {PACKAGE_PIN R3 IOSTANDARD LVCMOS33} [get_ports uart_tx]; #IO_L3P_T0_DQS_34 (Bank 34) - (P5 16)

# External Board I/Os
# ========================================
# ======== P6 ========
#set_property -dict {PACKAGE_PIN L4 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L18N_T2_35 (Bank 35)         - (P6 03)
#set_property -dict {PACKAGE_PIN G4 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L12N_T1_MRCC_35 (Bank 35)    - (P6 04)
#set_property -dict {PACKAGE_PIN G3 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L11N_T1_SRCC_35 (Bank 35)    - (P6 05)
#set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L9P_T1_DQS_AD7P_35 (Bank 35) - (P6 06)
#set_property -dict {PACKAGE_PIN M1 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L15P_T2_DQS_35 (Bank 35)     - (P6 07)
#set_property -dict {PACKAGE_PIN K1 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L7P_T1_AD6P_35 (Bank 35)     - (P6 09)
#set_property -dict {PACKAGE_PIN H3 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L11P_T1_SRCC_35 (Bank 35)    - (P6 12)
#set_property -dict {PACKAGE_PIN V5 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L16N_T2_34 (Bank 34)         - (P6 13)
#set_property -dict {PACKAGE_PIN U6 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L16P_T2_34 (Bank 34)         - (P6 14)
#set_property -dict {PACKAGE_PIN T6 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L17N_T2_34 (Bank 34)         - (P6 15)
#set_property -dict {PACKAGE_PIN P5 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L21P_T3_DQS_35 (Bank 35)     - (P6 16)
#set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS33} [get_ports port]; #IO_25_34 (Bank 34)              - (P6 17)
#set_property -dict {PACKAGE_PIN U5 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L14N_T2_SRCC_34 (Bank 34)    - (P6 18)
#set_property -dict {PACKAGE_PIN U1 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L1N_T0_34 (Bank 34)          - (P6 19)
#set_property -dict {PACKAGE_PIN J1 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L7N_T1_AD6N_35 (Bank 35)     - (P6 22)
#set_property -dict {PACKAGE_PIN L1 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L15N_T2_DQS_35 (Bank 35)     - (P6 24)
#set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L9N_T1_DQS_AD7N_35 (Bank 35) - (P6 25)
#set_property -dict {PACKAGE_PIN K3 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L14N_T2_SRCC_35 (Bank 35)    - (P6 26)
#set_property -dict {PACKAGE_PIN J4 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L13N_T2_MRCC_35 (Bank 35)    - (P6 27)
#set_property -dict {PACKAGE_PIN F4 IOSTANDARD LVCMOS33} [get_ports port]; #IO_0_35 (Bank 35)               - (P6 28)
# ======== P5 ========
#set_property -dict {PACKAGE_PIN P17 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L21N_T3_DQS_A06_D22_14 (Bank 14) - (P5 03)
#set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L21P_T3_DQS_14 (Bank 14)         - (P5 04)
#set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L24P_T3_A01_D17_14 (Bank 14)     - (P5 05)
#set_property -dict {PACKAGE_PIN N14 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L23N_T3_A02_D18_14 (Bank 14)     - (P5 06)
#set_property -dict {PACKAGE_PIN V7 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L19P_T3_34 (Bank 34)              - (P5 07)
#set_property -dict {PACKAGE_PIN L6 IOSTANDARD LVCMOS33} [get_ports port]; #IO_25_35 (Bank 35)                   - (P5 09)
#set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L15N_T2_DQS_34 (Bank 34)          - (P5 12)
#set_property -dict {PACKAGE_PIN J5 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L10P_T1_AD15P_35 (Bank 35)        - (P5 13)
#set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L13P_T2_MRCC_34 (Bank 34)         - (P5 14)
#set_property -dict {PACKAGE_PIN M3 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L16P_T2_35 (Bank 35)              - (P5 15)
#set_property -dict {PACKAGE_PIN R3 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L3P_T0_DQS_34 (Bank 34)           - (P5 16)
#set_property -dict {PACKAGE_PIN V4 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L12P_T1_MRCC_34 (Bank 34)         - (P5 17)
#set_property -dict {PACKAGE_PIN T5 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L14P_T2_SRCC_34 (Bank 34)         - (P5 18)
#set_property -dict {PACKAGE_PIN J6 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L17N_T2_35 (Bank 35)              - (P5 19)
#set_property -dict {PACKAGE_PIN L5 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L18P_T2_35 (Bank 35)              - (P5 22)
#set_property -dict {PACKAGE_PIN W6 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L15P_T2_DQS_34 (Bank 34)          - (P5 24)
#set_property -dict {PACKAGE_PIN N13 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L23P_T3_A03_D19_14 (Bank 14)     - (P5 25)
#set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L22P_T3_A05_D21_14 (Bank 14)     - (P5 26)
#set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L22N_T3_A04_D20_14 (Bank 14)     - (P5 27)
#set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L16P_T2_CSI_B_14 (Bank 14)       - (P5 28)
# ======== P4 ========
#set_property -dict {PACKAGE_PIN AB21 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L10P_T1_D14_14 (Bank 14)     - (P4 03)
#set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L18P_T2_A12_D28_14 (Bank 14)  - (P4 04)
#set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L24N_T3_A00_D16_14 (Bank 14)  - (P4 05)
#set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L20P_T3_A08_D24_14 (Bank 14)  - (P4 06)
#set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L5N_T0_D07_14 (Bank 14)       - (P4 07)
#set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports port]; #IO_25_14 (Bank 14)               - (P4 09)
#set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L19N_T3_A21_VREF_15 (Bank 15) - (P4 12)
#set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L24P_T3_RS1_15 (Bank 15)      - (P4 13)
#set_property -dict {PACKAGE_PIN N22 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L15P_T2_DQS_15 (Bank 15)      - (P4 14)
#set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L5P_T0_AD9P_15 (Bank 15)      - (P4 15)
#set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L3P_T0_DQS_AD1P_15 (Bank 15)  - (P4 16)
#set_property -dict {PACKAGE_PIN AA8 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L22P_T3_34 (Bank 34)          - (P4 17)
#set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L23P_T3_FOE_B_15 (Bank 15)    - (P4 18)
#set_property -dict {PACKAGE_PIN L15 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L22N_T3_A16_15 (Bank 15)      - (P4 19)
#set_property -dict {PACKAGE_PIN M16 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L24N_T3_RS0_15 (Bank 15)      - (P4 22)
#set_property -dict {PACKAGE_PIN N19 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L17N_T2_A25_15 (Bank 15)      - (P4 24)
#set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L17P_T2_A26_15 (Bank 15)      - (P4 25)
#set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L18N_T2_A11_D27_14 (Bank 14)  - (P4 26)
#set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L20N_T3_A07_D23_14 (Bank 14)  - (P4 27)
#set_property -dict {PACKAGE_PIN Y21 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L9P_T1_DQS_14 (Bank 14)       - (P4 28)
# ======== P3 ========
#set_property -dict {PACKAGE_PIN AB8 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L22N_T3_34 (Bank 34)                 - (P3 03)
#set_property -dict {PACKAGE_PIN V8 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L21N_T3_DQS_34 (Bank 34)              - (P3 04)
#set_property -dict {PACKAGE_PIN V9 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L21P_T3_DQS_34 (Bank 34)              - (P3 05)
#set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L19P_T3_A10_D26_14 (Bank 14)         - (P3 06)
#set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L13P_T2_MRCC_14 (Bank 14)            - (P3 07)
#set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L12P_T1_MRCC_14 (Bank 14)            - (P3 09)
#set_property -dict {PACKAGE_PIN Y19 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L13N_T2_MRCC_14 (Bank 14)            - (P3 12)
#set_property -dict {PACKAGE_PIN V18 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L14P_T2_SRCC_14 (Bank 14)            - (P3 13)
#set_property -dict {PACKAGE_PIN AB20 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L15N_T2_DQS_DOUT_CSO_B_14 (Bank 14) - (P3 14)
#set_property -dict {PACKAGE_PIN AA21 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L8N_T1_D12_14 (Bank 14)             - (P3 15)
#set_property -dict {PACKAGE_PIN AA20 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L8P_T1_D11_14 (Bank 14)             - (P3 16)
#set_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L14N_T2_SRCC_14 (Bank 14)            - (P3 17)
#set_property -dict {PACKAGE_PIN AA19 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L15P_T2_DQS_RDWR_B_14 (Bank 14)     - (P3 18)
#set_property -dict {PACKAGE_PIN AB18 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L17N_T2_A13_D29_14 (Bank 14)        - (P3 19)
#set_property -dict {PACKAGE_PIN AA18 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L17P_T2_A14_D30_14 (Bank 14)        - (P3 22)
#set_property -dict {PACKAGE_PIN W17 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L16N_T2_A15_D31_14 (Bank 14)         - (P3 24)
#set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L19N_T3_A09_D25_VREF_14 (Bank 14)    - (P3 25)
#set_property -dict {PACKAGE_PIN W9 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L24P_T3_34 (Bank 34)                  - (P3 26)
#set_property -dict {PACKAGE_PIN Y9 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L24N_T3_34 (Bank 34)                  - (P3 27)
#set_property -dict {PACKAGE_PIN AA6 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L18N_T2_34 (Bank 34)                 - (P3 28)
# ======== P2 ========
#set_property -dict {PACKAGE_PIN T3 IOSTANDARD LVCMOS33} [get_ports port]; #IO_0_34 (Bank 34)            - (P2 03)
#set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L2P_T0_34 (Bank 34)       - (P2 04)
#set_property -dict {PACKAGE_PIN V2 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L2N_T0_34 (Bank 34)       - (P2 05)
#set_property -dict {PACKAGE_PIN W1 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L5P_T0_34 (Bank 34)       - (P2 06)
#set_property -dict {PACKAGE_PIN AA1 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L7P_T1_34 (Bank 34)      - (P2 07)
#set_property -dict {PACKAGE_PIN W2 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L4P_T0_34 (Bank 34)       - (P2 09)
#set_property -dict {PACKAGE_PIN AB2 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L8N_T1_34 (Bank 34)      - (P2 12)
#set_property -dict {PACKAGE_PIN AB3 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L8P_T1_34 (Bank 34)      - (P2 13)
#set_property -dict {PACKAGE_PIN W4 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L12N_T1_MRCC_34 (Bank 34) - (P2 14)
#set_property -dict {PACKAGE_PIN Y6 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L18P_T2_34 (Bank 34)      - (P2 15)
#set_property -dict {PACKAGE_PIN Y4 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L11P_T1_SRCC_34 (Bank 34) - (P2 16)
#set_property -dict {PACKAGE_PIN Y3 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L9P_T1_DQS_34 (Bank 34)   - (P2 17)
#set_property -dict {PACKAGE_PIN AA3 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L9N_T1_DQS_34 (Bank 34)  - (P2 18)
#set_property -dict {PACKAGE_PIN Y2 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L4N_T0_34 (Bank 34)       - (P2 19)
#set_property -dict {PACKAGE_PIN AB1 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L7N_T1_34 (Bank 34)      - (P2 22)
#set_property -dict {PACKAGE_PIN Y1 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L5N_T0_34 (Bank 34)       - (P2 24)
#set_property -dict {PACKAGE_PIN V3 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L6N_T0_VREF_34 (Bank 34)  - (P2 25)
#set_property -dict {PACKAGE_PIN U3 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L6P_T0_34 (Bank 34)       - (P2 26)
#set_property -dict {PACKAGE_PIN T4 IOSTANDARD LVCMOS33} [get_ports port]; #IO_L13N_T2_MRCC_34 (Bank 34) - (P2 27)
set_property -dict {PACKAGE_PIN R2 IOSTANDARD LVCMOS33} [get_ports n_rst]; #IO_L3N_T0_DQS_34 (Bank 34)   - (P2 28)