import hid                              # Biblioteca para comunicação com dispositivos HID via USB
from threading import Event, Thread     # Para agendar tarefas em segundo plano
import psutil                           # Biblioteca para acessar informações do sistema, como temperatura da CPU

# Função para obter a temperatura atual da CPU
def get_cpu_temp():
    # 'k10temp' é o sensor usado por CPUs AMD; pode variar em outras arquiteturas
    temp = psutil.sensors_temperatures()['k10temp'][0].current
    return temp

# IDs do dispositivo HID (vendor e produto) — obtidos via lsusb
VENDOR_ID = 0xaa88
PRODUCT_ID = 0x8666

# Inicializa o dispositivo HID
device = hid.device()
try:
    device.open(VENDOR_ID, PRODUCT_ID)
    print(f'✅ Conectado ao dispositivo HID (Vendor: {hex(VENDOR_ID)}, Product: {hex(PRODUCT_ID)})')
except OSError as e:
    print(f'❌ Falha ao abrir o dispositivo HID: {e}')
    exit(1)

# Função que envia a temperatura da CPU para o display do cooler
def write_to_cpu_fan_display(dev):
    # Obtém a temperatura atual
    fCpuTemp = get_cpu_temp()

    # Cria um comando em bytes para enviar ao dispositivo
    # O primeiro byte pode ser um identificador de comando (ex: 0), seguido pela temperatura
    byte_command = [0, int(fCpuTemp)]

    try:
        # Envia os dados para o dispositivo
        num_bytes_written = dev.write(byte_command)
        print(f'📤 Temperatura enviada: {fCpuTemp}°C')
    except IOError as e:
        print(f'⚠️ Erro ao escrever no dispositivo: {e}')
        return None

    return num_bytes_written

# Função que executa uma tarefa repetidamente em intervalos definidos
def call_repeatedly(interval, func, *args):
    stopped = Event()

    def loop():
        while not stopped.wait(interval):
            func(*args)

    # Inicia a thread em segundo plano
    Thread(target=loop).start()
    return stopped.set  # Retorna função para parar a execução futura

# Define o intervalo de atualização (em segundos)
seconds = 1

# Inicia o envio contínuo da temperatura para o cooler
cancel_future_calls = call_repeatedly(seconds, write_to_cpu_fan_display, device)
