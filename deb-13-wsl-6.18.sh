#!/bin/bash -e
BRANCH=linux-msft-wsl-6.18.y
DXBRANCH=main

if [ "$EUID" -ne 0 ]; then
    echo "Swithing to root..."
    exec sudo $0 "$@"
fi

#apt-get install -y git dkms curl dwarves linux-headers-`uname -r`

#cd /tmp
#git clone -b $DXBRANCH  --no-checkout  --depth=1 https://github.com/microsoft/libdxg.git
#cd libdxg
#git sparse-checkout set --no-cone /include
#git checkout

cd /tmp
#git clone -b $BRANCH  --no-checkout  --depth=1 https://github.com/microsoft/WSL2-Linux-Kernel.git
cd WSL2-Linux-Kernel
git sparse-checkout set --no-cone /drivers/hv/dxgkrnl /include/uapi/misc/d3dkmthk.h \
/include/linux/hyperv.h /include/linux/eventfd.h /include/hyperv/hvhdk.h /include/hyperv/hvhdk_mini.h \
/include/hyperv/hvgdk_mini.h /include/hyperv/hvgdk.h /include/hyperv/hvgdk_ext.h
git checkout


BATCH='test'
RUN=$(git rev-parse --short HEAD)
VERSION="${RUN}${BATCH}"

cp -r drivers/hv/dxgkrnl /usr/src/dxgkrnl-$VERSION
mkdir -p /usr/src/dxgkrnl-$VERSION/include/uapi/misc
mkdir -p /usr/src/dxgkrnl-$VERSION/include/linux
mkdir -p /usr/src/dxgkrnl-$VERSION/include/hyperv
mkdir -p /usr/src/dxgkrnl-$VERSION/include/libdxg
cp -r /tmp/libdxg/include/* /usr/src/dxgkrnl-$VERSION/include/libdxg/
cp include/uapi/misc/d3dkmthk.h /usr/src/dxgkrnl-$VERSION/include/uapi/misc/d3dkmthk.h
cp include/linux/hyperv.h /usr/src/dxgkrnl-$VERSION/include/linux/hyperv_dxgkrnl.h
cp include/linux/eventfd.h /usr/src/dxgkrnl-$VERSION/include/linux/eventfd.h
cp include/hyperv/hvhdk.h /usr/src/dxgkrnl-$VERSION/include/hyperv/hvhdk.h
cp include/hyperv/hvhdk_mini.h /usr/src/dxgkrnl-$VERSION/include/hyperv/hvhdk_mini.h
cp include/hyperv/hvgdk.h /usr/src/dxgkrnl-$VERSION/include/hyperv/hvgdk.h
cp include/hyperv/hvgdk_ext.h /usr/src/dxgkrnl-$VERSION/include/hyperv/hvgdk_ext.h
sed -i 's/\$(CONFIG_DXGKRNL)/m/' /usr/src/dxgkrnl-$VERSION/Makefile
sed -i 's#<uapi/linux/eventfd.h>#<linux/eventfd.h>#g' /usr/src/dxgkrnl-$VERSION/include/linux/eventfd.h
sed -i 's#linux/hyperv.h#linux/hyperv_dxgkrnl.h#' /usr/src/dxgkrnl-$VERSION/dxgmodule.c
sed -i 's/l(event->cpu_event, 1)/l(event->cpu_event)/g' /usr/src/dxgkrnl-$VERSION/dxgmodule.c
# =====================================================================
# KERNEL 6.12+ COMPATIBILITY PATCHES
# =====================================================================

## Fix 1: Update __dma_fence_is_later multi-line argument mapping in dxgsyncfile.c
#sed -i ':a;N;$!ba;s/return __dma_fence_is_later(fence, syncpoint->fence_value,\n\s*fence->ops);/return __dma_fence_is_later(fence->seqno, syncpoint->fence_value, fence->ops);/g' /usr/src/dxgkrnl-$VERSION/dxgsyncfile.c
# Fix 1: Update __dma_fence_is_later clean multiline layout replacement in dxgsyncfile.c
# Find the line number containing the target function call
LINE_NUM=$(grep -n "__dma_fence_is_later" /usr/src/dxgkrnl-$VERSION/dxgsyncfile.c | cut -d: -f1 | head -n1)

if [ ! -z "$LINE_NUM" ]; then
    # Overwrite the precise two lines containing the split function statement
    NEXT_LINE=$((LINE_NUM + 1))
    sed -i "${LINE_NUM}s/.*/        return __dma_fence_is_later(fence->seqno, syncpoint->fence_value,/" /usr/src/dxgkrnl-$VERSION/dxgsyncfile.c
    sed -i "${NEXT_LINE}s/.*/                                    fence->ops);/" /usr/src/dxgkrnl-$VERSION/dxgsyncfile.c
fi

# Alternate backup patch if spaces or formatting differ in your specific branch pull:
sed -i 's/__dma_fence_is_later(fence,/__dma_fence_is_later(fence->seqno,/g' /usr/src/dxgkrnl-$VERSION/dxgsyncfile.c

# Fix 2: Resolve get_task_comm validation failure in dxgvmbus.c
sed -i '/get_task_comm(s, current);/i \        char comm_buf[TASK_COMM_LEN];' /usr/src/dxgkrnl-$VERSION/dxgvmbus.c
sed -i 's/get_task_comm(s, current);/get_task_comm(comm_buf, current); strscpy(s, comm_buf, TASK_COMM_LEN);/' /usr/src/dxgkrnl-$VERSION/dxgvmbus.c

# =====================================================================
echo "EXTRA_CFLAGS=-I\$(PWD)/include -D_MAIN_KERNEL_ -DCONFIG_DXGKRNL=m -include /usr/src/dxgkrnl-$VERSION/include/extra-defines.h -I /usr/src/dxgkrnl-$VERSION/include/libdxg/ -I  /usr/src/linux-headers-$(uname -r | sed 's/-[^-]*$/-common/')/include/linux/ -include  /usr/src/linux-headers-$(uname -r | sed 's/-[^-]*$/-common/')/include/linux/vmalloc.h -include /usr/src/dxgkrnl-$VERSION/include/uapi/misc/d3dkmthk.h  -Wno-empty-body" >> /usr/src/dxgkrnl-$VERSION/Makefile
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

dkms add dxgkrnl/$VERSION
dkms build dxgkrnl/$VERSION
dkms install dxgkrnl/$VERSION
