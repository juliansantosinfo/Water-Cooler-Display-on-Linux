#!/bin/bash

# Exit in case of error
set -e

# Get VENDOR_ID and PRODUCT_ID from user
read -p "Enter the VENDOR_ID of your device: " VENDOR_ID
read -p "Enter the PRODUCT_ID of your device: " PRODUCT_ID

if [ -z "$VENDOR_ID" ] || [ -z "$PRODUCT_ID" ]; then
  echo "VENDOR_ID and PRODUCT_ID cannot be empty."
  exit 1
fi

echo "Creating udev rule to allow user access to the device..."
UDEV_RULE_CONTENT="SUBSYSTEMS==\"usb\", ATTRS{idVendor}==\"$VENDOR_ID\", ATTRS{idProduct}==\"$PRODUCT_ID\", MODE=\"0666\""
echo "$UDEV_RULE_CONTENT" | sudo tee /etc/udev/rules.d/99-cpu-cooler.rules > /dev/null

echo "Updating udev rules..."
sudo udevadm control --reload-rules
sudo udevadm trigger

echo "Udev rule created and applied."
echo "You may need to unplug and plug your device back in for the changes to take full effect."

echo "Installing the script to run as a systemd service..."

# Create directories
mkdir -p ~/.local/bin
mkdir -p ~/.config/systemd/user

# Copy files
cp cpu_cooler.py ~/.local/bin/
cp cpu-cooler.service ~/.config/systemd/user/

# Reload systemd, enable and start the service
systemctl --user daemon-reload
systemctl --user enable cpu-cooler
systemctl --user start cpu-cooler

echo "Service installed and started."
echo "Installation complete!"
echo "You can check the service status with: systemctl --user status cpu-cooler"
