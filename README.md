# Linux-GPU-V-Scripts-for-Hyper-V
Notes and information for building the WSL-Kernel module and setting up GPU-PV in Linux guests.

This uses drivers files provided by WSL2 on your Windows host and compiles the WSL Kernel module within a Hyper-v guest.
```
Step 1 create a Generation2 guest with secure boot, dynamic memory, checkpoints as well as backup services disabled. 
Step 2 make sure not to use quick create and choose to install operating system later.
Step 3 select either an Ubuntu or Debian installation ISO and set this up as a boot device. 
Step 4 you will need to close machine config and reneter to change boot device to cdrom/iso.
Step 5 Install OS and setup software and network as needed. 
(However this guide only covers a minimal install with ssh access enabled and no desktop environment). 
Step 5 Run Linux-GPU-adder.ps1 and select a GPU or GPU's to be partitioned in your selected virtual machine.
Step 6 You will need to transfer over files from your windows host to your virtual machine. This is done by going through the provided steps in file-move.txt
Step 7 you will want to apt-get install "curl git dkms" to provided the dependancies for the kernel compilation script:
Step 8 execute the provided build.sh; after this completes dkms status should show the module is installed. 
Step 9 reboot the VM
Step 10 Verify gpu via dmesg / lspci and or nvidia-smi.
```
