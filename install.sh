# !/usr/bin/env bash

echo "Before you can do this, you must partition EFI, boot, and main encrypted volume"

read -p "Please Enter EFI partition (e.g. /dev/sda1 or /dev/nvme0n1p1): " EFI

read -p "Please Enter boot partition (e.g. /dev/sda2 or /dev/nvme0n1p2): " BOOT

read -p "Please Enter encrypted partition (e.g. /dev/sda3/ or /dev/nvme0n1p3): " VOLUME

echo "Encryption time, first format the partition"
read -p -s "Please Enter password to encrypted partition: " ENCRYPT
echo "$ENCRYPT" | cryptsetup luksFormat "$VOLUME" -d -
echo "$ENCRYPT" | cryptsetup luksOpen "$VOLUME" blackbox -d -
BTRFS="dev/mapper/blackbox"

# Convert volume to a Physical Volume, and then create a volume group
pvcreate "$BTRFS"
vgcreate cardboardbox "$BTRFS"
VOL1=cardboardbox

# Create and Volumes apart of the Volume Group
read -p "Please enter swap size (1G, 2G, 4G, 8G, 16G): " SWAPSIZE
lvcreate -L $SWAPSIZE $VOL1 --name swap
swap="/dev/cardboardbox/swap"

read -p "Please enter root size, same format: " ROOTSIZE
lvcreate -L $ROOTSIZE $VOL1 --name root
root="dev/cardboardbox/root"

read -p "Please enter home size, using the same format or type '100%FREE' to use the rest of the space available: " HOMESIZE
lvcreate -L $HOMESIZE $VOL1 --name home
home="/dev/cardboardbox/home"

if $HOMESIZE="100%FREE"
then
lvreduce --size -512M $VOL1 --name home
elif
echo ""
fi

echo "Continuing to Formatting..."

# Format Volumes
mkswap "$swap"
mkfs.btrfs "$root"
mkfs.btrfs "$home"

# Mount
swapon "$swap"
mount "$root" /mnt
mount --mkdir "$home" /mnt/home
mount --mkdir "$EFI" /mnt/efi
mount --mkdir "$BOOT" /mnt/boot

# Install base packages
pacstrap -K /mnt base base-devel linux linux-firmware linux-headers man-db openssh git sudo nano lvm2 btrfs-progs grub efibootmgr dosfstools mtools os-prober meson networkmanager networkmanager-openvpn sddm uwsm plasma-desktop plasma-nm plasma-pa bluedevil alsa-utils kdialog keditbookmarks kteatime kwalletmanager kscreen kgpg konsole terminator fastfetch ark dolphin kio-admin kate spectacle flatpak firefox vivaldi libreoffice-still protonmail-bridge qbittorrent
pacstrap -K /mnt zsh
# Check if we need laptop sound drivers
read -p "Laptop? (y/n): " laptop
if $laptop=y
then
pacstrap -K /mnt sof-firmware
else
echo "Skipping..."
fi

# CPU and GPU Drivers
echo "This is built for no GPU, or 1 GPU. Skip this and install manually afterwards if you have two, any form. Integrated/Laptop included."
read -p "nvidia or amd gpu? hit enter to skip (nvidia/amd/[enter])" GPU
read -p "intel or amd processor? (intel/amd)" CPU

if $GPU=nvidia
then
echo "Getting NVIDIA GPU Drivers..."
pacstrap -K /mnt nvidia-dkms
elif $GPU=amd
then
echo "Getting AMD GPU Drivers..."
pacstrap -K /mnt mesa
elif $GPU=""
echo "Skipping..."
else
echo "Input Scuffed. Skipping..."
fi

echo "CPU Drivers next!"

if $CPU=amd
then
echo "Getting AMD CPU Drivers..."
pacstrap -K /mnt amd-ucode
elif $CPU=intel
echo "Getting INTEL CPU Drivers..."
pacstrap -K /mnt mesa
else
echo "Skipping CPU Drivers... Be sure you meant to!"
fi

# Generate fstab, chroot
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt sh next.sh
