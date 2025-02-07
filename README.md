# Linux-GPU-V-Scripts-for-Hyper-V
Notes and scripts for building the WSL-Kernel module and setting up GPU-PV in Linux guests.


This uses the hosts installed GPU drivers and files provided by WSL2 on your Windows host to
compile the Microsoft WSL Kernel module from github within a Linux Hyper-v guest running LTS/Generic/AMD64 6.1 - 6.12 kernels.

These are the folders on windows host with relavent files. 
Please install WSL2 and or run wsl update to provide these files.
```
C:\Windows\System32\lxss\lib
C:\Program Files\WSL\lib
C:\Windows\System32\DriverStore\FileRepository
```

```
Step 1 create a Generation2 guest with these services disabled secure boot, dynamic memory, checkpoints as well as backup services. 

Step 2 make sure not to use quick create and choose to install operating system later.

Step 3 select either an Ubuntu or Debian installation ISO and set this up as a boot device.

Tested with Debian 12 bookworm, Debian 13 Trixie, Ubuntu 24.04, and Fedora 41.

Step 4 you will need to close machine config and reneter to change boot device to cdrom/iso.

Step 5 Install OS and setup software and network as needed.

(However this guide only covers a minimal install with ssh access enabled and no desktop environment).

Step 6 Run Linux-GPU-adder.ps1 and select a GPU or GPU's to be partitioned in your selected virtual machine.

Step 7 You will need to transfer over files from your windows host to your virtual machine.

This is done by going through the provided steps in "file-move-nv.txt" or "file-move-wsl".txt

Step 8 you will want to apt-get install "curl git dkms dwarves" to provided the dependancies for the kernel compilation script:

Step 9 download and execute the appropriate build.sh for your linux distro; after this completes dkms status should show the module is installed.
Step 9a if using debian you will need to also run through resolve_btfids.txt before running build.sh.

Step 10 reboot the VM

Step 11 Verify gpu via dmesg / lspci and or nvidia-smi.

Step 12 install Nvidia cuda tool kit via:
https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64
Tested on Ubuntu 24 with ubuntu-wsl selection and Debian 12 with Debian Selection.
```



```
Other repos used for patches and info:
https://github.com/thexperiments/dxgkrnl-dkms-git
https://github.com/staralt/dxgkrnl-dkms
https://github.com/seflerZ/oneclick-gpu-pv
https://gist.github.com/krzys-h/e2def49966aa42bbd3316dfb794f4d6a
https://github.com/brokeDude2901/dxgkrnl_ubuntu/tree/main
https://gist.github.com/OlfillasOdikno/f87a4444f00984625558dad053255ace
https://unix.stackexchange.com/questions/762985/compiling-external-kernel-module-fails-on-debian-bookworm-due-to-missing-resolve
https://qask.org/ubuntu/2022/10/25/skipping-btf-generation-xxx-due-to-unavailability-of-vmlunux-on-ubuntu-21-04-generic-version
```

This repo is meant to provide info for setting up the WSL kernel module on newer LTS kernels 6.x.

The provided scripts are working with linux kernels versions up to 6.12.x.

Specifically kernels 6.1, 6.8, 6.9, and 6.12 have been tested with the provided scripts.

Only up to kernel 6.8.0-52-generic has been tested on Ubuntu 24.04 LTS. Currently 6.11 is working on Ubuntu 24.10 via the same script.

![image](https://github.com/user-attachments/assets/68dde6db-babf-4f30-911c-f0a3caacf0b9)

Kernel 6.9.10+bpo-amd64 tested on debian 12 bookworm via backports.

![image](https://github.com/user-attachments/assets/ad1afa99-8cf3-497e-989a-0d9c8e08dfd5)

Kernel 6.12.11 tested working on debian 13 trixie 
![image](https://github.com/user-attachments/assets/d97c93c4-2295-4eac-a9a9-97b5c3d3ae06)


Kernel 6.12.11-220 working from fedora 41:

![image](https://github.com/user-attachments/assets/22b2b8f4-5f7c-4738-ba02-f3ac9139e010)


GPU add script provided is meant to let you select each GPU to be utilized for passthrough, and needs to be run again to add additional GPU's. 

If you have multiple Nvidia devices you may need to add all cuda capable devices to each VM in order for nvidia-smi to function correctly. 
