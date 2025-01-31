#!/bin/bash -e
BRANCH=linux-msft-wsl-6.6.y

if [ "$EUID" -ne 0 ]; then
    echo "Swithing to root..."
    exec sudo $0 "$@"
fi

apt-get install -y git dkms curl

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
cp include/uapi/misc/d3dkmthk.h /usr/src/dxgkrnl-$VERSION/include/uapi/misc/d3dkmthk.h
cp include/linux/hyperv.h /usr/src/dxgkrnl-$VERSION/include/linux/hyperv_dxgkrnl.h
cp include/linux/eventfd.h /usr/src/dxgkrnl-$VERSION/include/linux/eventfd.h
sed -i 's/\$(CONFIG_DXGKRNL)/m/' /usr/src/dxgkrnl-$VERSION/Makefile
sed -i 's#<uapi/linux/eventfd.h>#<linux/eventfd.h>#g' /usr/src/dxgkrnl-$VERSION/include/linux/eventfd.h
sed -i 's#linux/hyperv.h#linux/hyperv_dxgkrnl.h#' /usr/src/dxgkrnl-$VERSION/dxgmodule.c
echo "EXTRA_CFLAGS=-I\$(PWD)/include -D_MAIN_KERNEL_" >> /usr/src/dxgkrnl-$VERSION/Makefile

cat > /usr/src/dxgkrnl-$VERSION/dkms.conf <<EOF
PACKAGE_NAME="dxgkrnl"
PACKAGE_VERSION="$VERSION"
BUILT_MODULE_NAME="dxgkrnl"
DEST_MODULE_LOCATION="/kernel/drivers/hv/dxgkrnl/"
AUTOINSTALL="yes"
EOF


dkms add dxgkrnl/$VERSION
dkms build dxgkrnl/$VERSION
dkms install dxgkrnl/$VERSION
