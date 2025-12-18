import serial
from PIL import Image
from PIL import ImageFilter
import numpy as np
import time

# --- Parâmetros de Configuração ---
# Ajuste conforme a sua configuração real
SERIAL_PORT = 'COM6'     # Porta serial
BAUD_RATE = 115200       # Deve ser a mesma taxa configurada na FPGA
IMAGE_PATH = 'lion.jpg'
WIDTH = 256              # Largura da imagem
HEIGHT = 256             # Altura da imagem

def process_image_with_fpga(image_path, port, baudrate, width, height):
    try:
        # 1. Pré-processamento e Envio
        print(f"1. Carregando imagem: {image_path}...")
        img = Image.open(image_path)
        
        # Converte para Grayscale ('L' significa luminância, 8-bit, 1 canal)
        # Os valores dos pixels serão inteiros de 0 a 255 (1 byte)
        img_gray = img.convert('L')
        
        if img_gray.size != (width, height):
            print(f"Redimensionando de {img_gray.size} para {width}x{height}...")
            img_gray = img_gray.resize((width, height))

        # Converte a imagem para um array numpy de 1 byte por pixel (uint8)
        pixel_array = np.array(img_gray, dtype=np.uint8)
        
        # Achata o array para um fluxo linear (row-major: Linha 0, Linha 1...)
        # Isso simula o AXI Stream de pixels sequenciais
        stream_data = pixel_array.flatten()
        
        # Abre a porta serial
        with serial.Serial(port, baudrate, timeout=1, parity=serial.PARITY_EVEN) as ser:
            print(f"Porta serial {port} aberta. Enviando {len(stream_data)} bytes...")

            # Envio dos dados da imagem
            start_time = time.time()
            ser.write(stream_data.tobytes())

            # 2. Recebimento e Reconstrução
            total_pixels = width * height
            received_bytes = ser.read(total_pixels)
            
            if len(received_bytes) < total_pixels:
                print(f"Erro de recebimento: Esperado {total_pixels} bytes, recebido {len(received_bytes)}.")
                return None
                
            print(f"Recebidos {len(received_bytes)} bytes. Reconstruindo imagem...")

        # Converte os bytes recebidos de volta para um array numpy
        received_array_flat = np.frombuffer(received_bytes, dtype=np.uint8)
        
        # Remodela o array linear para a matriz 2D (H x W) da imagem
        received_array_2d = received_array_flat.reshape((height, width))
        
        # 3. Visualização
        output_img = Image.fromarray(received_array_2d, mode='L')
        output_path = 'processed_image.jpg'
        output_img.save(output_path)
        
        print(f"✅ Processamento concluído. Imagem salva em: {output_path}")
        
        return output_img

    except FileNotFoundError:
        print(f"Erro: Imagem não encontrada em {image_path}")
    except serial.SerialException as e:
        print(f"Erro de comunicação serial: {e}. Verifique a porta e a taxa de baud.")
    except Exception as e:
        print(f"Ocorreu um erro: {e}")

process_image_with_fpga(IMAGE_PATH, SERIAL_PORT, BAUD_RATE, WIDTH, HEIGHT)