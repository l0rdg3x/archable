#!/bin/bash

# Set PATH
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Dialog dimensions
HEIGHT=20
WIDTH=90
CHOICE_HEIGHT=12

# Titles and messages
BACKTITLE="Archable - An Arch Linux Post Install Setup Util"
TITLE="Please Make a Selection"
MENU="Please Choose one of the following options:"

# Other variables
OH_MY_ZSH_URL="https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

# Check for dialog installation
if ! pacman -Q dialog &>/dev/null; then
    sudo pacman -S --needed --noconfirm dialog || { exit 1; }
fi
if ! pacman -Q git &>/dev/null; then
    sudo pacman -S --needed --noconfirm git || { exit 1; }
fi

# Options for the menu
OPTIONS=(
    1 "Install yay"
    2 "Update Firmware"
    3 "Install Flatpak - Enables the Flatpak repo and installs packages located in flatpak-packages.txt"
    4 "Install Software - Installs software located in system-packages.txt"
    5 "Install Oh-My-ZSH - Installs Oh-My-ZSH & Starship Prompt"
    6 "Install Nvidia - Install Nvidia drivers"
    7 "Install Virtualization - KVM/QEMU  + VirtManager"
    8 "Install TLP"
    9 "Install OpenRazer + Polychromatic"
    10 "Install RustDesk"
    11 "Install Docker"
    12 "Quit"
)

install_yay() {
    echo "Install yay"
    sudo pacman -S --needed base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd ..
    rm -rf yay
}

# Function to update firmware
update_firmware() {
    echo "Updating System Firmware"
    sudo pacman -S --needed --noconfirm fwupd
    sudo fwupdmgr get-devices
    sudo fwupdmgr refresh --force
    sudo fwupdmgr get-updates
    sudo fwupdmgr update
}

# Function to enable Flatpak
install_flatpak() {
    echo "Install Flatpak and install packages"
    yay -S --needed flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak update -y
    if [ -f flatpak-install.sh ]; then
        source flatpak-install.sh
    fi
}

# Function to install software
install_software() {
    echo "Installing Software"

    if [ -f system-packages.txt ]; then
        yay -S --needed --noconfirm $(cat system-packages.txt)
        sudo systemctl enable --now cronie
    fi
}

# Function to install Oh-My-Zsh and Starship
install_oh_my_zsh() {
    echo "Installing Oh-My-Zsh with Starship"
    yay -S --needed --noconfirm zsh curl util-linux
    sh -c "$(curl -fsSL $OH_MY_ZSH_URL)" "" --unattended
    chsh -s "$(which zsh)"
    curl -sS https://starship.rs/install.sh | sh
    echo 'eval "$(starship init zsh)"' >> ~/.zshrc
}

# Function to install Nvidia drivers
install_nvidia() {
    echo "Installing Nvidia Driver"
    yay -S --needed --noconfirm nvidia
}

install_virt() {
    yay -S --needed --noconfirm qemu-full qemu-img libvirt virt-install virt-manager virt-viewer edk2-ovmf swtpm guestfs-tools libosinfo dnsmasq
    sudo usermod -aG libvirt $(whoami)
    sudo sed -i 's/#unix_sock_group = "libvirt"/unix_sock_group = "libvirt"/' /etc/libvirt/libvirtd.conf
    sudo sed -i 's/#unix_sock_ro_perms = "0777"/unix_sock_ro_perms = "0777"/' /etc/libvirt/libvirtd.conf
    sudo sed -i 's/#unix_sock_rw_perms = "0770"/unix_sock_rw_perms = "0770"/' /etc/libvirt/libvirtd.conf
    sudo setfacl -R -b /var/lib/libvirt/images/
    sudo setfacl -R -m u:$(whoami):rwX /var/lib/libvirt/images/
    sudo setfacl -m d:u:$(whoami):rwx /var/lib/libvirt/images/
    sudo virsh net-start default
    sudo virsh net-autostart default
    sudo systemctl enable --now libvirtd
}

install_tlp() {
    yay -S --needed --noconfirm tlp
    sudo systemctl enable --now tlp.service
}

install_openrazer() {
    yay -S --needed --noconfirm openrazer-daemon polychromatic
    sudo gpasswd -a $(whoami) plugdev
}

install_rustdesk() {
    yay -S --needed --noconfirm rustdesk-bin
    sudo systemctl enable --now rustdesk
}

install_docker() {
    yay -S --needed --noconfirm docker docker-compose nvidia-container-toolkit
    sudo usermod -aG docker $(whoami)
    sudo systemctl enable --now docker
}

# Main loop
while true; do
    CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --nocancel \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

    clear
    case $CHOICE in
        1) install_yay ;;
        2) update_firmware ;;
        3) install_flatpak ;;
        4) install_software ;;
        5) install_oh_my_zsh ;;
        6) install_nvidia ;;
        7) install_virt ;;
        8) install_tlp ;;
        9) install_openrazer ;;
        10) install_rustdesk ;;
        11) install_docker ;;
        12) exit 0 ;;
        *) ;;
    esac
done
