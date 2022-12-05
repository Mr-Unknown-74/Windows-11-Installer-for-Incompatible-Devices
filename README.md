# Windows-11-Installer-for-Incompatible-Devices 1.0.0
This program uses code from "Skip TPM Check on Dynamic Update V10", made by AveYo on github.
https://github.com/AveYo/MediaCreationTool.bat/blob/main/bypass11/Skip_TPM_Check_on_Dynamic_Update.cmd
It also uses this code from Stackoverflow: https://stackoverflow.com/a/12264592/1016343 
#
This software takes genuine Windows 11 ISO files and then will install it onto incompatible divices.
It's for the people who are tired of Windows 10 or have an incompatible PC on Windows 11 21H2 that you want to update to 22H2.

If you ran the program, but it crashed or you stopped it, don't worry, you can run it again and it will uninstall.
If it does not say that it was uninstalled, and just reinstalls again, that's ok, because you will just overwrite over the previous extraction.
(If it asks, make sure to type in 'a', meaning to overwrite over the previous extraction)

A great advantage of this program is that you wont loose your data when you update!
#

# HOW TO USE:

1. Put the Windows 11 ISO image into the folder labelled "Copy the ISO file here".
    Note: You technically can put multiple ISOs in the folder, but the program will only choose the first one (Sorted by name).

2. Open Start.bat
    Note: If you do not run it as administrator, do not worry! It will automatically trigger a UAC prompt in order to gain administrator access.

3. Now just wait! Soon the program will say what to do next and expect in the Windows setup.
    Note: You will see if you run the program, but it'll say that it's installing Windows Server.
    That doesn't mean anything, it just tricks the installer that it's installing Windows Server because Windows Server doesn't have the same restrictions as Windows 11.

4. After Windows 11 is installed, you can run Start.cmd again to uninstall the program.