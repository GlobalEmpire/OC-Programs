######################
#OpenFTP Instructions#
######################


Thank you for choosing OpenFTP: Coded by Tonatsi (Also known as Leothehero).
>>>This version utilises encryption (data card T3) and must be run with such a card. The server should be compatible with Release 1 Client programs, if not please contact the developper. The Release 2 client is not compatible with the Release 1 client.


>>> Thank you for choosing this program, if you have any suggestions for future features please tell me! I'm not very imaginative and I do need inspiration.


To use the program (Release 2); you will need  at least 1 server and 1 client.
There are two types available, one that utilises the GERT Networking Protocol; and one that utilises standalone network cards in OpenComputers.
--Although this program will work with any Lua compatible operating system that utilises the same modem component access as the default OpenOS, it is recommended to use a secure Operating system; at minimum for the file-server, such as the FUCHAS OS. It is uncertain exactly how secure this program can be as it was not designed with FUCHAS or other OS in mind, and may not adhere to their security guidelines or make use of its features.
###########
#With GERT#
###########

You can have more than one server host with GERT as there is no automatic discovery: you must obtain the address of the server yourself.
The server will automatically run in the background once started. It is recommended to place the server in the /bin file and to run the server either in the autorun or the .shrc file.

>>>The Server must not be run a second time as there is not yet any process duplication detection. Reboot before re-running; or terminate the processes yourself.
>>>Please report any errors and bugs to Tonatsi; and tell me exactly how to replicate it.

To install; simple place the code in a file somewhere; and execute it. If you intend to have a computer that is solely for this program; you can leave it on the desktop. Our recommendation is placing the programs both in the /bin folders on their respective computers.
A standalone computer is advised; since the server dumps all incoming files in /home/ and does not have any way of deleting files other than someone using the RM command themselves. This will be changed in the future.
It is recommended to autorun the file so that you do not have to worry about whether the program has already been executed or not.
Make sure that GERTi is properly setup on the network; refer to the GERTi wiki for further information.

Once the server is running and you know the address; you can install the Client application on any computer you wish that is also connected to the GERTi Network. Does not work using GERTe... yet!
Then run the program; and follow the onscreen prompts. To exit the program; press ctrl+alt+c. More functions will be added in future versions; this version is effectively a prototype/proof of concept.

-- The server has no way to be exited, you must reboot the computer to get rid of the process. This is planned to be a future addition.
##############
#Without GERT#
##############

===============
==Coming Soon==
===============

Simply follow the same instructions as above; just without the GERTi stuff.

>>>You cannot have more than one server on any connected network (unless you filter out discovery broadcasts from clients to separate between the outside of the network and the inside).

Both Types have the same functionality; although the one that does not use GERTi might run a bit faster; and supports automatic discovery.
