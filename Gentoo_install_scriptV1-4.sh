
# ! /bin/bash
set -e
DISK="/dev/sda"
echo "Warning: Wiping everything of the disk for partition."
wipefs -a "${DISK}"
echo "Everything has been wiped off."
echo "Partition disk"
sgdisk --zap-all "${DISK}"
fdisk "${DISK}" <<EOF
g
n
1

+1G  
n
2

+8G
n
3


w
EOF
#1G is Boot /dev/sda1
#8G is Swap /dev/sda2
#The rest is root /dev/sda3
sleep 5
read -p "Partition was successful done, press enter to continue.."
echo "Formatting Partitions."
mkfs.ext4 /dev/sda3
mkfs.fat -F 32 /dev/sda1
mkswap /dev/sda2
sleep 5
echo "Formatting Complete"
echo "Mounting Partitions"
mount /dev/sda3 /mnt/gentoo
mkdir -p /mnt/gentoo/boot/efi
mount /dev/sda1 /mnt/gentoo/boot/efi/
swapon /dev/sda2
echo "Mounting Complete."
echo "Using chronyd to set date, be warned hahahaha."
chronyd -q
sleep 2
cd /mnt/gentoo/
sleep 2
echo "Using links tool to downloading stage3 "
read -p "After downloading the latest stage3 manually click or press on the button 'q' .."
links -g gentoo.org
read -p "Hopefully stage3 has been download press enter to procced further.."
sleep 2
echo "Extracting the stage3 file."
tar xpvf stage3-*.tar.xz --xattrs-include='*.*'  --numeric-owner
sleep 5
echo "MAKEOPTS=\"-j$(($(nproc) / 2))\"" >> /mnt/gentoo/etc/portage/make.conf
echo "GENTOO_MIRRORS=\"https://mirrors.nxtgen.com/gentoo-mirror/gentoo-source/ http://gentoo.mirrors.tera-byte.com/ https://mirror.yandex.ru/gentoo-distfiles/\"" >> /mnt/gentoo/etc/portage/make.conf
sleep 2 
echo "Mirrors of India, North America and Russia has been added "
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
sleep 3
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run
read -p "IF USING GENTOO INSTALLATION MEDIA ENTER (y), IF USING OTHER MEDIA WHICH MAKE /dev/shm SYMBOLIC LINK TO /run/shm/ ENTER (n)" answer
case "$answer" in
	[Yy]|[Yy][Ee][Ss])
		echo "Continuing.."
		;;
	[Nn]|[Nn][Oo])
		echo "Oh you cheeky boy."
		test -L /dev/shm && rm /dev/shm && mkdir /dev/shm
		mount --types tmpfs --options nosuid,nodev,noexec shm /dev/shm
		chmod 1777 /dev/shm /run/shm
		;;
	*)
		echo "Please answer in yes or no."
		;;
esac
sleep 5

echo "chrooting in to the root drive."
chroot /mnt/gentoo /bin/bash <<'EOF'
source /etc/profile
export PS1="(chroot) ${PS1}"
sleep 2
echo "Succesfully chrooted into root drive."
emerge-webrsync
echo "Installing the default profile for a default basic system, This may take a while."
echo "USE=\"\"" >> /etc/portage/make.conf
echo "ACCEPT_LICENSE=\"*\"" >> /etc/portage/make.conf
emerge --ask --verbose --update --deep --newuse @world
sleep 5
echo "Packages installed succesfully"
echo "Setting timezone according to India."
echo "Asia/Kolkata" > /etc/timezone
ln -sf ../usr/share/zoneinfo/Asia/Kolkata /etc/localtime
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
sleep 5
echo "Locale has been generated."
eselect locale list
read -p "Please enter a number from above to set as locale list." locale_variable
eselect locale set "${locale_variable}"
sleep 2
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
echo "Installing Kernel"
emerge sys-kernel/linux-firmware
sleep 5
echo "Choose your CPU vendor for microcode:"
echo "1) Intel"
echo "2) AMD"
read -rp "Enter 1 or 2:" cpu_type
case "$cpu_type" in
	1)
		echo "You have intel cpu which requires microcode."
		emerge sys-firmware/intel-microcode
		;;
	2)
		echo "You got lucky you don't need microcode."
		;;
	*)
		echo "Please answer in 1 or 2."
		;;
esac
sleep 5
echo "Installing a binary kernel."
emerge --autounmask-continue sys-kernel/gentoo-kernel-bin
sleep 5 
emerge sys-apps/pciutils
sleep 2
echo "Kernel has been compiled, yay!"
echo "Setting up FSTAB"
echo "/dev/sda1            /boot           vfat             defaults,noatime       0 2" >> /etc/fstab
echo "/dev/sda2            none            swap             sw                     0 0" >> /etc/fstab
echo "/dev/sda3            /               ext4             defaults,noatime       0 1" >> /etc/fstab
read -rp "Enter your Hostname and make sure there is no space or special characters in it otherwise the script may not work, can use underscore thou(_):" hostname_boy
echo "$hostname_boy" > /etc/hostname
emerge net-misc/dhcpcd
rc-update add dhcpcd default
emerge -av --noreplace net-misc/netifrc -y
sleep 5
echo "Auto detecting active network interface, yeah we can do that"
iface=$(ip route | grep '^default' | awk '{print $5}')
echo "config_$iface=\"dhcp\"" > /etc/conf.d/net
cd /etc/init.d/
ln -s net.lo net."${iface}"
rc-update add net."${iface}" default
echo "127.0.0.1         ${hostname_boy} localhost" >> /etc/hosts
echo "Setting up your root password :)"
passwd
read -rp "Hopefully you have set it up correctly, cause it is not part of my script, well anyway press enter to continue ..."
emerge app-admin/sysklogd
rc-update add sysklogd default
emerge sys-apps/mlocate
updatedb
sleep 5
emerge net-misc/chrony
rc-update add chronyd default
echo "Installing System tools"
emerge sys-fs/e2fsprogs
sleep 5
emerge sys-fs/dosfstools
sleep 5
echo "Installing wireless tools"
emerge net-misc/dhcpcd
emerge net-dialup/ppp
emerge net-wireless/iw net-wireless/wpa_supplicant
emerge wireless-tools
sleep 2
echo "Installing Bootloader"
echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
emerge sys-boot/grub
sleep 2
grub-install --target=x86_64-efi --efi-directory=/boot/efi
sleep 2
grub-mkconfig -o /boot/grub/grub.cfg
echo "Bootloader has been installed"
exit
sleep 2
EOF

echo "Unmounting Partitions"
cd
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo

echo "CONGRATULATIONS!! Gentoo has been succesfully installed."
read -p "If you wanna reboot now then enter yes(y) or stay then enter no(n) " reboot_op
case "$reboot_op" in
	[Yy]|[Yy][Ee][Ss])
		echo "Bye Hope to see you again ;)"
		echo "Reboot in 3s.."
		sleep 3
		reboot
		;;
	[Nn]|[Nn][Oo])
		echo "Oh you wan't stay ok i guess."
		echo "Bye Hope to see you again ;)"
		;;
	*)
		echo "Please answer in yes or no."
		;;
esac

