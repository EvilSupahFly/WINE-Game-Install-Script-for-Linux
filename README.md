This Windows game installer was written in BASH and is designed (originally) to be run on Ubuntu and Ubuntu-based systems (like Mint, for example). At this point, it will fail if this is not the case, though changing that is on my eventual to-do list.

For launching, there are several options:

    1. ./install.sh
    2. ./install skip
    3. ./install "Some Folder"
    4. ./install "Some Folder" skip

In the first instance, the script will read in a list of all the directories present under the one it's being run from. Useful if you can't remember where you saved the installer .EXE or if you just don't feel like typing more than the minimum required to make this work.

In the second instance, using "skip" allows you to bypass the MSVC prompt.

The third instance skips the directory listing and just gives you a list of .EXE files in "Some Folder", prompting you to pick one.

The last option combines the second and third choices, skipping the directory listing, and skipping the MSVC prompt.

This script will also attempt to ascertain whether or not WINE is installed. If it can't find the official WINE respositories listed in any .source files, and WINE doesn't appear to be installed, the script will attempt to add the official repositories and install both WINE and WINETRICKS.

Assuming a WINE install can be verified, the script will create a WINEPREFIX and a "destination" folder for the game, and offer you the choice to skip installing the MSVC Redistributables from the `.redist` folder. If you say "no", the script will call WINE to sequentially run any .EXE files it finds. If you say "yes", it will move to the next step. Since this list is dynamic, new versions of the MSVC can be added as they are released without needing to change the installer script.

At this point, the script looks for any .EXE files in the source directory (either chosen from the menu or supplied on the command-line), present a list, ask you to pick one, then call WINE to run it.

Next, we install the newest release of Vulkan from [JC141's Vulkan repository](https://github.com/jc141x/vulkan) to replace DX11, and once the initial "setup" completes in WINE, the script looks for any .EXE files in the "destination" folder, once again presenting a user-selectable list.

With the final .EXE selected, this script writes a runner script for the chosen game which defines the WINEPREFIX and game install location, and the name of the game's primary .EXE, makes it executable, and reports all this to the user.

Screenshots:

![Screenshot_01](https://github.com/user-attachments/assets/50c0c39f-7840-4ea8-aa3e-c59c8ed60746)

![Screenshot_02](https://github.com/user-attachments/assets/8d9a6c7e-640e-48dd-a44c-9f8f4345ad49)

![Screenshot_03](https://github.com/user-attachments/assets/ad2bb588-dcd1-4132-b5f2-f130240f53eb)

![Screenshot_04](https://github.com/user-attachments/assets/34cea0b0-d985-43f1-83e5-2b3e9d4d975b)

![Screenshot_05](https://github.com/user-attachments/assets/43c1eb69-e946-44ce-a43f-d6e1d0fc42f4)

![Screenshot_06](https://github.com/user-attachments/assets/9ae1af66-8519-41a4-8945-f71e39dc0606)

![Screenshot_07](https://github.com/user-attachments/assets/7ba00531-037f-4eb0-8b07-b59cd38bdcc2)

