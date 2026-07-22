#!/bin/bash

# Setup Plymouth Theme
echo -e "   \033[1;36m[...]\033[0m Installing Cupcake Plymouth theme..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../.. && pwd)"

sudo mkdir -p /usr/share/plymouth/themes/cupcake
sudo cp -r "$SCRIPT_DIR/Source/plymouth/cupcake/"* /usr/share/plymouth/themes/cupcake/

sudo plymouth-set-default-theme -R cupcake

echo -e "   \033[1;32m[OK]\033[0m Cupcake Plymouth theme installed successfully!"
