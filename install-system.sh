#!/bin/bash

# Sai em caso de erro
set -e

# Verifica se está sendo executado como root
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script deve ser executado como root. Por favor, use sudo."
  exit 1
fi

# Pega VENDOR_ID e PRODUCT_ID do usuário
read -p "Digite o VENDOR_ID do seu dispositivo: " VENDOR_ID
read -p "Digite o PRODUCT_ID do seu dispositivo: " PRODUCT_ID

if [ -z "$VENDOR_ID" ] || [ -z "$PRODUCT_ID" ]; then
  echo "VENDOR_ID e PRODUCT_ID não podem estar vazios."
  exit 1
fi

echo "Criando regra udev para permitir acesso ao dispositivo..."
UDEV_RULE_CONTENT="SUBSYSTEMS==\"usb\", ATTRS{idVendor}==\"$VENDOR_ID\", ATTRS{idProduct}==\"$PRODUCT_ID\", MODE=\"0666\""
echo "$UDEV_RULE_CONTENT" > /etc/udev/rules.d/99-cpu-cooler.rules

echo "Atualizando regras do udev..."
udevadm control --reload-rules
udevadm trigger

echo "Regra udev criada e aplicada."
echo "Pode ser necessário desconectar e reconectar seu dispositivo para que as alterações tenham efeito."

echo "Instalando o script para rodar como um serviço systemd de sistema..."

# Instala o script python
INSTALL_PATH="/usr/local/bin"
echo "Instalando script python em $INSTALL_PATH..."
mkdir -p "$INSTALL_PATH"
cp cpu_cooler.py "$INSTALL_PATH/"
chmod +x "$INSTALL_PATH/cpu_cooler.py"

# Encontra o caminho do python3
PYTHON_PATH=$(which python3)
if [ -z "$PYTHON_PATH" ]; then
    echo "python3 não encontrado no PATH. Por favor, instale o python3."
    exit 1
fi

# Instala o serviço systemd
SERVICE_FILE_PATH="/etc/systemd/system/cpu-cooler.service"
echo "Criando arquivo de serviço systemd em $SERVICE_FILE_PATH..."

cp cpu-cooler.service > "$SERVICE_FILE_PATH"

echo "Recarregando o systemd, habilitando e iniciando o serviço..."
systemctl daemon-reload
systemctl enable cpu-cooler.service
systemctl start cpu-cooler.service

echo "Serviço instalado e iniciado."
echo "Instalação completa!"
echo "Você pode verificar o status do serviço com: systemctl status cpu-cooler.service"
