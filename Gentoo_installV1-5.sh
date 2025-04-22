
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
cp chroot_gen.sh /mnt/gentoo/root/
chmod +x /mnt/gentoo/root/chroot_gen.sh
chroot /mnt/gentoo /root/chroot_gen.sh
