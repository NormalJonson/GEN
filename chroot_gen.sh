chroot /mnt/gentoo /root/chroot_gen.sh
source /etc/profile
export PS1="(chroot) ${PS1}"
sleep 2
echo "Succesfully chrooted into root drive."
emerge-webrsync
echo "Installing the default profile for a default basic system, This may take a while."
echo "USE=\"\"" >> /etc/portage/make.conf
echo "ACCEPT_LICENSE=\"*\"" >> /etc/portage/make.conf
emerge --update --deep --newuse @world
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
