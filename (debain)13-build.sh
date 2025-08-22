#!/bin/bash -e
BRANCH=linux-msft-wsl-6.6.y
DXBRANCH=main

if [ "$EUID" -ne 0 ]; then
    echo "Swithing to root..."
    exec sudo $0 "$@"
fi

apt-get install -y git dkms curl dwarves  linux-source-6.12 linux-headers-amd64 pahole

#This installs resolve_btfids and objtool which is needed with vmlinux for proper compilation.
cd /usr/src/
tar xvf linux-source-6.12.tar.xz
cd linux-source-6.12/tools/bpf/resolve_btfids
make
mkdir -p /usr/src/linux-headers-`uname -r`/tools/bpf/resolve_btfids
ln -s /usr/src/linux-source-6.12/tools/bpf/resolve_btfids/resolve_btfids /usr/src/linux-headers-`uname -r`/tools/bpf/resolve_btfids/resolve_btfids

cd /tmp
git clone -b $DXBRANCH  --no-checkout  --depth=1 https://github.com/microsoft/libdxg.git
cd libdxg
git sparse-checkout set --no-cone /include
git checkout

cd /tmp
git clone -b $BRANCH  --no-checkout  --depth=1 https://github.com/microsoft/WSL2-Linux-Kernel.git
cd WSL2-Linux-Kernel
git sparse-checkout set --no-cone /drivers/hv/dxgkrnl /include/uapi/misc/d3dkmthk.h /include/linux/hyperv.h /include/linux/eventfd.h
git checkout


BATCH='test'
RUN=$(git rev-parse --short HEAD)
VERSION="${RUN}${BATCH}"


cp -r drivers/hv/dxgkrnl /usr/src/dxgkrnl-$VERSION
mkdir -p /usr/src/dxgkrnl-$VERSION/include/uapi/misc
mkdir -p /usr/src/dxgkrnl-$VERSION/include/linux
mkdir -p /usr/src/dxgkrnl-$VERSION/include/libdxg
cp -r /tmp/libdxg/include/* /usr/src/dxgkrnl-$VERSION/include/libdxg/
cp include/uapi/misc/d3dkmthk.h /usr/src/dxgkrnl-$VERSION/include/uapi/misc/d3dkmthk.h
cp include/linux/hyperv.h /usr/src/dxgkrnl-$VERSION/include/linux/hyperv_dxgkrnl.h
cp include/linux/eventfd.h /usr/src/dxgkrnl-$VERSION/include/linux/eventfd.h
sed -i 's/\$(CONFIG_DXGKRNL)/m/' /usr/src/dxgkrnl-$VERSION/Makefile
sed -i 's#<uapi/linux/eventfd.h>#<linux/eventfd.h>#g' /usr/src/dxgkrnl-$VERSION/include/linux/eventfd.h
sed -i 's#linux/hyperv.h#linux/hyperv_dxgkrnl.h#' /usr/src/dxgkrnl-$VERSION/dxgmodule.c
sed -i 's/l(event->cpu_event, 1)/l(event->cpu_event)/g' /usr/src/dxgkrnl-$VERSION/dxgmodule.c
echo "EXTRA_CFLAGS=-I\$(PWD)/include -D_MAIN_KERNEL_ -DCONFIG_DXGKRNL=m -include /usr/src/dxgkrnl-$VERSION/include/extra-defines.h -I /usr/src/dxgkrnl-$VERSION/include/libdxg/ -I /usr/src/linux-source-6.12/include/linux/ -include /usr/src/linux-source-6.12/include/linux/vmalloc.h -include /usr/src/dxgkrnl-$VERSION/include/uapi/misc/d3dkmthk.h    -Wno-empty-body" >> /usr/src/dxgkrnl-$VERSION/Makefile
wget https://raw.githubusercontent.com/MBRjun/dxgkrnl-dkms-lts/master/extra-defines.h
cp extra-defines.h  /usr/src/dxgkrnl-$VERSION/include/extra-defines.h
cp /sys/kernel/btf/vmlinux /usr/lib/modules/`uname -r`/build/


cat > /usr/src/dxgkrnl-$VERSION/dkms.conf <<EOF
PACKAGE_NAME="dxgkrnl"
PACKAGE_VERSION="$VERSION"
BUILT_MODULE_NAME="dxgkrnl"
DEST_MODULE_LOCATION="/kernel/drivers/hv/dxgkrnl/"
AUTOINSTALL="yes"
EOF


sudo dkms add dxgkrnl/$VERSION
sudo dkms build dxgkrnl/$VERSION
sudo dkms install dxgkrnl/$VERSION
