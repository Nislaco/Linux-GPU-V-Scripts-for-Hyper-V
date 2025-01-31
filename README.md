# Linux-GPU-V-Scripts-for-Hyper-V
Notes and scripts for building the WSL-Kernel module and setting up GPU-PV in Linux guests.


This uses drivers files provided by WSL2 on your Windows host and
compiles the WSL Kernel module via github within a Hyper-v guest.

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

Step 4 you will need to close machine config and reneter to change boot device to cdrom/iso.

Step 5 Install OS and setup software and network as needed.

(However this guide only covers a minimal install with ssh access enabled and no desktop environment).

Step 6 Run Linux-GPU-adder.ps1 and select a GPU or GPU's to be partitioned in your selected virtual machine.

Step 7 You will need to transfer over files from your windows host to your virtual machine.

This is done by going through the provided steps in file-move.txt

Step 8 you will want to apt-get install "curl git dkms" to provided the dependancies for the kernel compilation script:

Step 9 download and execute the provided build.sh; after this completes dkms status should show the module is installed. 

Step 10 reboot the VM

Step 11 Verify gpu via dmesg / lspci and or nvidia-smi.
```



```
Other repos used for patches and info:
https://github.com/thexperiments/dxgkrnl-dkms-git?tab=readme-ov-file
https://github.com/staralt/dxgkrnl-dkms

Scripts are based on information provided from:
https://github.com/seflerZ/oneclick-gpu-pv
https://github.com/staralt/dxgkrnl-dkms
```

This repo is meant to provide info for setting up the WSL kernel module on newer LTS kernels 6.x.

GPU add script provided is meant let you select an each GPU for passthrough, and needs to be run again to add additional GPU's. 

If you have multiple Nvidia devices you may need to all to each VM for nvidia-smi to function correctly. 
