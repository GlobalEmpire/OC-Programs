# **OpenFTP Beta 3.0**

Thank you for choosing **OpenFTP**! This file details installation options for all variants of **OpenFTP** Beta 3.0.

## Dependencies
All variants of OpenFTP Beta 3.0 require `FTPCore.lua`, which can be found in the [GERTi modules repository](https://github.com/GlobalEmpire/GERT/tree/master/GERTi/Modules). We recommend using GUS to stay updated

## OpenFTP LITE
You will find both files under the LITE folder next to this file.
> Ensure `GERTiClient.lua` and `FTPCore.lua` are installed on all machines involved.

The installation procedure for the server is as follows:
- Install `OpenFTPLITE-Server.lua` onto the server device. We recommend leaving it the root directory. 
  - Edit the file and modify `customPath` (line 12) if you wish to have a different file storage location.
- Run the program. The server application is now fully configured and operational.

The installation procedure for all clients is as follows:
- Install `OpenFTPLITE-Client.lua` onto each client device. We recommend putting it under `/bin` with the file name `OpenFTP.lua`. It is not necessary to have both the LITE and FULL version of OpenFTP installed on one device, as the FULL version is capable of interfacing with the LITE version.
  - Edit the file and modify `PERMANENTADDRESS` (line 31) to bypass the server selection dialogue at startup.
- Run the program. The client application is now fully functional.

## OpenFTP FULL
W.I.P