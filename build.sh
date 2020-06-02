#!/bin/bash
set -e
export FORCE_UNSAFE_CONFIGURE=1
echo "Digite o caminho de compilacao"
read TARGET
echo "Baixando dependencias"
sudo apt-get install gcc g++ make libssl-dev libncurses-dev meson bison flex mkisofs -y
echo "Fazendo o download do codigo-fonte"
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.6.15.tar.xz
wget https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v2.35/util-linux-2.35.tar.gz
wget http://ftp.gnu.org/gnu/bash/bash-5.0.tar.gz
wget https://ftp.gnu.org/gnu/inetutils/inetutils-1.9.4.tar.xz
wget https://ftp.gnu.org/gnu/coreutils/coreutils-8.32.tar.gz
wget https://ftp.gnu.org/gnu/glibc/glibc-2.31.tar.xz
mkdir $TARGET
cd $TARGET
umask 022
mkdir usr usr/bin usr/include usr/lib usr/lib32 usr/lib64 usr/libx32 usr/sbin boot isolinux dev etc home media mnt opt proc root run srv sys var src
ln -s usr/bin bin
ln -s usr/lib lib
ln -s usr/lib32 lib32
ln -s usr/lib64 lib64
ln -s usr/libx32 libx32
ln -s usr/sbin sbin
cd src
echo "Descompactando codigo-fonte"
tar -xvf ../../coreutils-8.32.tar.gz
tar -xvf ../../inetutils-1.9.4.tar.xz
tar -xvf ../../bash-5.0.tar.gz
tar -xvf ../../util-linux-2.35.tar.gz
tar -xvf ../../linux-5.6.15.tar.xz
tar -xvf ../../glibc-2.31.tar.xz
echo "Compilando codigo-fonte"
cd coreutils-8.32
./configure --prefix=$TARGET --exec-prefix=$TARGET
make -j12
make install
cd ..
cd inetutils-1.9.4
./configure --prefix=$TARGET --exec-prefix=$TARGET
make -j12
make install
cd ..
cd bash-5.0
./configure --prefix=$TARGET --exec-prefix=$TARGET --enable-static-link
make -j12
make install
cd ..
cd util-linux-2.35
./configure --prefix=$TARGET --exec-prefix=$TARGET
make -j12
make install
cd ..
cd glibc-2.31
mkdir build
cd build
../configure --enable-static-pie --prefix=$TARGET/ --exec-prefix=$TARGET/
make -j12
make install
cd ..
cd ..
cd linux-5.6.15
make mrproper
echo "Baixando a configuração do kernel"
wget https://raw.githubusercontent.com/Cristian0808/linux_minimal/master/config -O .config
echo "Compilando kernel"
export INSTALL_PATH=$TARGET/boot
make -j12
make install 
make modules_install -j12
cd ..
cd ..
rm -rf src
cat > etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
EOF
cat > etc/group << "EOF"
root:x:0:
EOF
cat > init << "EOF"
mount -o proc none /proc
mount -o sysfs none /sys
exec /bin/bash
EOF
read -s -n 1 -p "Entre no seu sistema via chroot e veja se esta tudo OK, estando tudo OK use qualquer tecla para continuar"
chmod 777 init
echo "Criando initramfs"
find . | cpio -H newc -o > initramfs.cpio
cat initramfs.cpio | gzip > boot/initramfs.igz
rm initramfs.cpio
rm -rf  usr dev etc home media mnt opt proc root run srv sys var
echo "Baixando isolinux.bin"
wget http://mirror.centos.org/centos/6/os/x86_64/isolinux/isolinux.bin -O isolinux/isolinux.bin
cat > isolinux/isolinux.cfg << "EOF"
DEFAULT linux

LABEL linux
     KERNEL /boot/vmlinuz
     INITRD /boot/initramfs.igz
     APPEND root=/dev/ram0 init=/init
EOF
ln -s boot/vmlinuz-5.6.15 boot/vmlinuz
genisoimage -b isolinux/isolinux.bin -boot-info-table -no-emul-boot -boot-load-size 4 -allow-limited-size -o SO_Linux.iso $TARGET/
exit 0
