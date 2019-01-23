#!/bin/bash
#modify by liucaili 2017-06-08
set -x

#####加载外部文件################
cd ../../../../utils
source ./sys_info.sh
source ./sh-test-lib
cd -

#############################  Test user id       #########################
! check_root && error_msg "Please run this script as root."

######################## Environmental preparation   ######################
#IMAGE='Image_D02'
IMAGE="Image"
ROOTFS="mini-rootfs.cpio.gz"
HOME_PATH=$HOME
CUR_PATH=$PWD
DISK_NAME=${distro}.img

case $distro in
"centos")
    pkg="wget gcc expect qemu qemu-kvm" 
    install_deps "$pkg"
    print_info $? install-qemu
;;
"debian")
    pkg="wget gcc expect qemu"
    install_deps "$pkg"
   print_info $? install-qemu
  ;;
esac

download_url="${ci_http_addr}/test_dependents/qemu"
#download_url="http://203.160.91.226:18083/test_dependents/qemu"

if [ ! -e ${CUR_PATH}/${IMAGE} ]; then
    download_file ${download_url}/${IMAGE}
fi

if [ ! -e ${CUR_PATH}/${ROOTFS} ]; then
    download_file ${download_url}/${ROOTFS}
fi

if [[ -e ${CUR_PATH}/${IMAGE} && -e ${CUR_PATH}/${ROOTFS} ]]; then
   print_info $? image_or_rootfs_exist
else
   print_info $? image_or_rootfs_not_exist
fi


case "${distro}" in
	ubuntu)
		pkgs="libvirt-bin zlib1g-dev libperl-dev libgtk2.0-dev libfdt-dev bridge-utils"
		install_deps "${pkgs}"
	;;
        debian)
		pkgs="wget libvirt0 zlib1g-dev libperl-dev libgtk2.0-dev libfdt-dev bridge-utils"
		install_deps "${pkgs}"
	;;
	centos)
		yum remove yum-plugin-priorities.noarch -y
		pkgs="wget kvm virt-manager virt-install xauth qemu-img libvirt libvirt-python libvirt-client glib2-devel zlib-devel libtool"
		install_deps "${pkgs}"
	;;
        fedora)
		pkgs="qemu-kvm virt-manager virt-install xauth qemu-img libvirt libvirt-python libvirt-client glib2-devel"
		install_deps "${pkgs}"
        ;;
        opensuse)
		pkgs="qemu virt-manager virt-install xauth kvm_stat libvirt libvirt-python libvirt-client glib2-devel"
		install_deps "${pkgs}"
	;;
	*)
		error_msg "Unsupported distribution!"
esac


#######################  testing the step ###########################
#编译qemu-2.6.0文件
qemu-system-aarch64 --help
if [ $? -ne 0 ]; then
    QEMU_VER=qemu-2.6.0.tar.bz2
    download_file ${ci_http_addr}/test_dependents/qemu-2.6.0.tar.bz2
    #http://wiki.qemu-project.org/download/${QEMU_VER}
    tar xf ${QEMU_VER}
    cd ${QEMU_VER%%.tar.bz2}
    ./configure --target-list=aarch64-softmmu
    make -j16
    make install
    cd -

    qemu-system-aarch64 --help
fi
print_info $? qemu-system-aarch64-help

chmod a+x ${CUR_PATH}/qemu-load-kvm.sh

# start qemu 
${CUR_PATH}/qemu-load-kvm.sh $IMAGE $ROOTFS $distro
if [ $? -ne 0 ]; then
    echo 'qemu system load fail'
    print_info 1 qemu-load
   # lava-test-case qemu-system-load --result fail
    exit 0
else
    print_info 0 qemu-load
    lava-test-case qemu-system-load --result pass
fi

# create image , like virtual matchine disk file 
qemu-img create -f qcow2 $DISK_NAME 10G
if [ $? -ne 0 ]; then
    echo 'qemu-img create fail'
    print_info 1 qemu-img-create
    lava-test-case qemu-img-create --result fail
    exit 0
else
    print_info 0 qemu-img-create
    lava-test-case qemu-img-create --result pass
fi

# mount network block device moduler
modprobe nbd max_part=16
if [ $? -ne 0 ];then
    echo 'modprobe nbd fail'
    print_info 1 modpro-nbd
    lava-test-case modprob-nbd --result fail
    exit 0
else
    print_info 0 modpro-nbd
    lava-test-case modprobe-nbd --result pass
fi

# install os
qemu-nbd -c /dev/nbd0 $DISK_NAME
chmod a+x ${CUR_PATH}/qemu-create-partition.sh
${CUR_PATH}/qemu-create-partition.sh
if [ $? -ne 0 ];then
    echo 'create nbd0 partition fail'
    print_info 1 create-partition
    lava-test-case create-partition --result fail
    exit 0
else
    nbd_p1=$(fdisk /dev/nbd0 -l | grep -w 'Linux')
    if [ "$nbd_p1"x = ""x ] ; then
	print_info 1 create-partition
        lava-test-case create-partition --result fail
    else
	print_info 0 create-parttion 
        lava-test-case create-partition --result pass
    fi
fi

# formate virtual disk 
mkfs.ext4 /dev/nbd0p1
if [ $? -ne 0 ]
then
    echo 'mkfs.ext4 nbd0p1 fail'
    print_info 1 mkfs.ext4-nbd0p1
    lava-test-case mkfs.ext4-nbd0p1 --result fail
    exit 0
else
    print_info 0 mkfs.ext4-nbd0p1
    lava-test-case mkfs.ext4-nbd0p1 --result pass
fi

mkdir -p /mnt/image
mount /dev/nbd0p1 /mnt/image/
if [ $? -ne 0 ];then
    echo 'mount image fail'
    print_info 1 mount-image
    lava-test-case mount-image --result fail
    exit 0

else
    print_info 0 mount-image
    lava-test-case mount-image --result pass
fi

# put rootfs write to virtual disk 
cd /mnt/image
zcat ${CUR_PATH}/${ROOTFS} | cpio -dim
if [ $? -ne 0 ]
then
    echo 'tar file system fail'
    print_info 1 tar-file-system
    lava-test-case tar-file-system --result fail
    exit 0

else
    print_info 0 tar-file-system
    lava-test-case tar-file-system --result pass
fi
cd ${CUR_PATH}

umount /mnt/image
if [ $? -ne 0 ]
then
    echo 'umount image fail'
    print_info 1 umount-image
    lava-test-case umount-image --result fail
    exit 0
else
    print_info 0 umount-image
    lava-test-case umount-image --result pass
fi

qemu-nbd -d /dev/nbd0
if [ $? -ne 0 ];then
    echo 'qemu-nbd fail'
    print_info 1 qemu-nbd
    lava-test-case qemu-nbd --result fail
    exit 0
else

    print_info 0 qemu-nbd
    lava-test-case qemu-nbd --result pass
fi

# start virtual os 
chmod a+x qemu-start-kvm.sh
${CUR_PATH}/qemu-start-kvm.sh  $IMAGE  $DISK_NAME
if [ $? -ne 0 ];then
    print_info 1 qemu-start-fom-img
    lava-test-case qemu-start-from-img --result fail
    exit 0
else
    print_info 0 qemu-start-from-img
    lava-test-case qemu-start-from-img --result pass
fi
