# The S3IX Operating System #

S3IX provides a sophisticated *nix like operating system that breaks away from the idea that everything is a file. Instead, everything (ideally) is a stream.

This works because all files can be reprented as streams. It is almost a drop in replacement for the original idea of a traditional UNIX or UNIX-like operating system.

### Setup ###

Currently, S3IX is not bootable out of box. As development progresses, this should change in the near future with the implementation of /sbin/loader and a supportive init.lua. HOWEVER, the latest default kernel image is provided under /boot (called 'DEFAULT'). This image should load as is, I try to build and test run it before every push. Keep in mind nothing special will likely happen at the moment while the kernel itself is still under early construction.

If you wish to build your own custom kernel image, you will need to create a kernel configuration. The easiest method to do this is to copy the contents of /etc/sys.d/default into another file such as /etc/sys.d/MYKERNEL, and editing that file in your editor of choice. I recommend placing all of your kernel configurations in /etc/sys.d/ to keep them organized and out of the way. 

To build the S3IX kernel, simple cd to the main directory tree and run the following command (from a normal PC compatible Lua environment):
`lua lib/tools/buildimg.lua etc/sys.d/MYKERNEL .`

###### Note: Don't forget to replace MYKERNEL with the name of your kernel config. ######

After this is complete, you should be able to boot the new kernel (located in /boot) by copying the contents to a floppy / disk Drive and booting from your preferred bootloader.

Check regularly for updates on when S3IX becomes naturally bootable.
