This Windows game installer was written in BASH and is designed (originally) to be run on Ubuntu and Ubuntu-based systems
(like Mint, for example). At this point, it will fail if this is not the case.

You can either specify a folder name on the command-line, or you can allow the script to show you a list.

This script will also attempt to ascertain whether or not WINE is installed. If it can't find the official WINE respositories
listed in any .source files, and WINE doesn't appear to be installed, the script will attempt to add the official repositories
and install both WINE and WINETRICKS.

Assuming a WINE install can be verified, the script will create a WINEPREFIX and a "destination" folder for the game, and
prompt you to run the MSVC Redistributables from the .redist folder. If you say "yes", the script will call WINE to 
sequentially run any .EXE files it finds. If you say "no", it will move to the next step.

At this point, it will look for any .EXE files in the source directory (either chosen from the menu or supplied on the
command-line), present a list, ask you to pick one, then call WINE to run it.

Next, we install Vulkan from the JC141 official GIT to replace DX11, and once the initial "setup" completes in WINE, the
script looks for any .EXE files in the "destination" folder, once again presenting a user-selectable list.

With the final .EXE selected, this script writes a runner script for the chosen game which defines the WINEPREFIX and
game install location, and the name of the game's primary .EXE, makes it executable, and reports all this to the user.

![terminal_output](https://github.com/user-attachments/assets/0321c339-ff94-499a-a352-155c7495f155)
