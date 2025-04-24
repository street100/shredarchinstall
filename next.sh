# set timezone
read -p "Time Zone? (e.g. US/Eastern): " TIMEZONE
ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime

# Generate time
hwclock --systohc

# locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf

# Hostname
read -p "Hostname? " HOSTNAME
echo $HOSTNAME > /etc/hostname

# Create User
read -p "What do you want to be called? " USER
read -p -s "Password for account: " PASSWORD
groupadd omnip
sudo groupadd omnip
useradd -m -G omnip /bin/zsh/ $USER
echo "$PASSWORD" | passwd $USER -d -
echo "%omnip ALL=(ALL) ALL" >> /etc/sudoers

# Install packages that need setup
# First, Rustup
pacman -S rustup --noconfirm
rustup default stable
# Second, paru
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd

# Enable multilib and extra, add athena

echo "[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
echo "[extra]/nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf

echo "[athena]\nSigLevel = Optional TrustedOnly\nInclude = /etc/pacman.d/athena-mirrorlist" >> /etc/pacman.conf
curl https://raw.githubusercontent.com/Athena-OS/athena/main/packages/os-specific/system/athena-mirrorlist/athena-mirrorlist -o /etc/pacman.d/athena-mirrorlist
pacman-key --recv-keys A3F78B994C2171D5 --keyserver keys.openpgp.org
pacman-key --lsign A3F78B994C2171D5


# Now, everything is set for final set of package installations, and boot prep
paru -S steam --noconfirm
paru -S github-desktop --noconfirm
paru -S binder_linux-dkms --noconfirm

# Waydroid
pacman -S lzip waydroid libvirt --noconfirm
waydroid init -s GAPPS

# Misc
pacman -S goofcord-bin --noconfirm
pacman -S moonlight-qt --noconfirm
pacman -S neovim --noconfirm

# Enable necessary services
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable sddm
systemctl enable waydroid

# Hooks
sed -i "s/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole sd-encrypt lvm2 block filesystems fsck)/" /etc/mkinitcpio.conf
# Rebuild initramfs
mkinitcpio -P

# Modules (if nvidia)
read -p "Nvidia? (y/n) " NVIDIA
if $NVIDIA=y
echo "setting modules..."
sed -i "s/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/" /etc/mkinitcpio.conf
mkinitcpio -P
elif $NVIDIA=n
echo "Skipping..."
fi
echo "Moving on..."

# Set up grub
echo "Setting up boot..."
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=SHREDDED
echo 'GRUB_CMDLINE_LINUX="cryptdevice=/dev/nvme0n1p3:blackbox root=/dev/cardboardbox/root"' >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Gnabbing shredplasma files
git clone https://github.com/street100/shredplasma /home/$USER

echo "Done."
echo "Run scripts installed in ~/ to complete setup."
echo "Do so in root, by first (in terminal) running:" 
echo "sudo su"
echo "and then:"
echo "sh (nameofscript).sh"
read -p -s "Press enter to continue"
echo "Beyond that, run the following after to exit chroot"
echo "exit"
echo "Make certain this command actually exits you from chroot, if not type exit again"
echo "umount -R /mnt"
echo "swapoff -a"
echo "After, you are clear to type reboot!"
read -p -s "Press enter to continue"
