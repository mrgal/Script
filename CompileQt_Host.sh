#!/bin/bash

##### User settings ######
# Set DEVICE with
# 	linux-rasp-pi-g++ 	- Raspberry Pi 1 (+ Zero and Zero W)
# 	linux-rasp-pi2-g++	- Raspberry Pi 2
# 	linux-rasp-pi3-g++	- Raspberry Pi 3
# 	linux-rasp-pi3-vc4-g++	- Raspberry Pi 3 with VC4 driver

DEVICE=linux-rasp-pi3-vc4-g++
IP=192.168.178.37
CORES=4
DIRECTORY=/opt/RaspberryQt
COMPILER_PATH=/opt/RaspberryQt
ARM_PATH=/opt/RaspberryQt/tools/arm-bcm2708
###########################

#### Colors #####
Red="\033[0;31m"
Green="\033[0;32m"
Reset="\033[0m"
Yellow="\033[0;33m"
Cyan="\033[0;36m"
#################

echo -e ${Yellow}"Install packages..."${Reset}
sudo apt-get update
sudo apt-get -y install gcc git bison python gperf pkg-config gdb-multiarch qt5-default

echo -e ${Yellow}"Create directories..."${Reset}
sudo mkdir -p ${DIRECTORY}/log ${DIRECTORY}/build
sudo mkdir -p ${COMPILER_PATH}/sysroot ${COMPILER_PATH}/sysroot/usr ${COMPILER_PATH}/sysroot/opt

cd ${DIRECTORY}
sudo chown -R 1000:1000 ${DIRECTORY}
sudo chown -R 1000:1000 ${COMPILER_PATH}

#echo -e ${Yellow}"Generate SSH keys..."${Reset}
#ssh-keygen -t rsa -C root@${IP} -P "" -f ~/.ssh/rpi_root_id_rsa
#ssh-keygen -t rsa -C pi@${IP} -P "" -f ~/.ssh/rpi_pi_id_rsa
#cat ~/.ssh/rpi_root_id_rsa.pub | ssh root@${IP} 'cat >> .ssh/authorized_keys && chmod 640 .ssh/authorized_keys'
#cat ~/.ssh/rpi_pi_id_rsa.pub | ssh pi@${IP} 'cat >> .ssh/authorized_keys && chmod 640 .ssh/authorized_keys'

echo -e ${Yellow}"Download toolchain..."${Reset}
cd ${COMPILER_PATH}
git clone https://github.com/raspberrypi/tools
cd ${DIRECTORY}

echo -e ${Yellow}"Download Qt..."${Reset}
wget http://ftp.oregonstate.edu/.1/blfs/conglomeration/qt5/qt-everywhere-src-5.11.3.tar.xz

echo -e ${Yellow} "Download Compiler"${Reset}
cd ${ARM_PATH}
wget  https://developer.arm.com/-/media/Files/downloads/gnu-a/8.3-2019.03/binrel/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf.tar.xz
tar xf gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf.tar.xz
rm -r gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf.tar.xz


echo -e ${Yellow}"Download python script..."${Reset}
cd ${DIRECTORY}
wget https://raw.githubusercontent.com/riscv/riscv-poky/master/scripts/sysroot-relativelinks.py
sudo chmod +x sysroot-relativelinks.py

tar xf qt-everywhere-src-5.11.3.tar.xz
cp -R qt-everywhere-src-5.11.3/qtbase/mkspecs/linux-arm-gnueabi-g++ qt-everywhere-src-5.11.3/qtbase/mkspecs/linux-arm-gnueabihf-g++
sed -i -e 's/arm-linux-gnueabi-/arm-linux-gnueabihf-/g' qt-everywhere-src-5.11.3/qtbase/mkspecs/linux-arm-gnueabihf-g++/qmake.conf

cd ${COMPILER_PATH}
echo -e ${Yellow}"Download /lib..."${Reset}
rsync -avz root@${IP}:/lib sysroot | tee ${DIRECTORY}/log/copy_lib.log
echo -e ${Yellow}"Download /usr/include..."${Reset}
rsync -avz root@${IP}:/usr/include sysroot/usr | tee ${DIRECTORY}/log/copy_usr_include.log
echo -e ${Yellow}"Download /usr/lib..."${Reset}
rsync -avz root@${IP}:/usr/lib sysroot/usr | tee ${DIRECTORY}/log/copy_usr_lib.log
echo -e ${Yellow}"Download /opt/vc..."${Reset}
rsync -avz root@${IP}:/opt/vc sysroot/opt | tee ${DIRECTORY}/log/copy_opt_vc.log

echo -e ${Yellow}"Change symlinks..."${Reset}
ln -s sysroot/opt/vc/lib/libEGL.so sysroot/usr/lib/arm-linux-gnueabihf/libEGL.so.1.1.0
ln -s sysroot/opt/vc/lib/libGLESv2.so sysroot/usr/lib/arm-linux-gnueabihf/libGLESv2.so.2.1.0
ln -s sysroot/opt/vc/lib/libEGL.so sysroot/opt/vc/lib/libEGL.so.1
ln -s sysroot/opt/vc/lib/libGLESv2.so sysroot/opt/vc/lib/libGLESv2.so.2
${DIRECTORY}/sysroot-relativelinks.py sysroot

echo -e ${Yellow}"Configure Qt..."${Reset}
cd ${DIRECTORY}/build
../qt-everywhere-src-5.11.3/configure -opengl es2 -device ${DEVICE} -device-option CROSS_COMPILE=${COMPILER_PATH}/tools/arm-bcm2708/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabihf/bin/arm-linux-gnueabihf- -sysroot ${COMPILER_PATH}/sysroot -prefix /usr/local/RaspberryQt -opensource -confirm-license -no-gbm -skip qtscript -nomake tests -nomake examples -make libs -pkg-config -no-use-gold-linker -v | tee ${DIRECTORY}/log/config.log

echo -e ${Yellow}"Build Qt..."${Reset}
make -j${CORES} | tee ${DIRECTORY}/log/make.log
make install | tee ${DIRECTORY}/log/install.log

echo -e ${Yellow}"Clean..."${Reset}
sudo rm -r ${DIRECTORY}/build
sudo rm -r ${DIRECTORY}/qt-everywhere-src-5.10.1
sudo rm ${DIRECTORY}/qt-everywhere-src-5.10.1.tar.xz

echo -e ${Yellow}"Upload to Raspberry Pi..."${Reset}
cd ${DIRECTORY}
rsync -avz ${COMPILER_PATH}/sysroot/usr/local/RaspberryQt pi@${IP}:/usr/local | tee ${DIRECTORY}/log/copy_RaspberryQt.log
