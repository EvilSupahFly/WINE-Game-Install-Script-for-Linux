#!/bin/bash

IFS=$'\n'

# Define some fancy colourful text with BASH's built-in escape codes. Example:
# echo -e "${BOLD}${YELLOW}This text will be displayed in BOLD YELLOW. ${RESET}While this text is normal."
BOLD="\033[1m"
RESET="\e[0m" #Normal
BGND="\e[40m"
ULINE="\033[4m"
YELLOW="${BOLD}${BGND}\e[1;33m"
RED="${BOLD}${BGND}\e[1;91m"
GREEN="${BOLD}${BGND}\e[1;92m"
WHITE="${BOLD}${BGND}\e[1;97m"
SKIP=false
LAUNCHER=""

echo -e "${WHITE}" # Make the text bold and white by default because it's easier to read.
# User ID, working directory and parameter checks - NO ROOT!!!
cd "$(dirname "$(readlink -f "$0")")" || exit; [ "$EUID" = "0" ] && echo -e "${RED}Gotta quit here because I can't run as root. ${WHITE}I'll prompt you if I need root access.${RESET}" && exit 255

# Check if a foler was supplied on the command line and deal with any trailing slashes, should they exist
if [[ ! "$1" =~ ^[Ss][Kk][Ii][Pp]$ && -n "$1" ]]; then
    if [[ "$1" == */ ]]; then
        ONE="${1%/}"
    else
        ONE="$1"
    fi
    NOSPACE="${ONE// /_}"
    echo
    echo "This script will attempt to install WINE for you if it isn't already installed."
    echo -e "As such, it would be ${ULINE}${YELLOW}REALLY HELPFUL${RESET}${WHITE} if you have Internet access."
    echo "It's also largely failproof, so if it encounters something it can't fix, or something"
    echo "which can't be fixed later by tweaking the runner script, it will exit with a fatal"
    echo "error. Everything is mostly automated, only requiring you to answer a few prompts."
    echo
    echo -e "To continue, press ${YELLOW}<ENTER>${WHITE}. To cancel, press ${YELLOW}<CTRL-C>${WHITE}."; read donext
fi

if [[ "${1,,}" == "skip" ]]; then
    SKIP=true
fi

if [[ -z "$1" ]] || [[ "${1,,}" == *"skip"* ]]; then
    echo
    # Load all subfolders into an array and make it a numbered list
    #GDIRS=($(find . -maxdepth 1 -type d -exec basename {} \; | grep -vE '^\.$|^\..$|\.redist$'))
    #shopt -s nullglob nocaseglob
    GDIRS=()
    echo -e "${RED}Commandline was blank. ${WHITE}Listing potential game folders. We'll see if they're empty later:"
    echo
    for dir in */; do
        if [[ $dir =~ ^\.[^.]|^\.redist ]]; then
            continue
        fi
        GDIRS+=("$dir")
    done
    for ((i=0; i<"${#GDIRS[@]}"; i++)); do
        # Write the list to the screen, removing the trailing slashes, and determine the color based on the index
        if ((i % 2 == 0)); then
            echo -e "${ULINE}${WHITE}$i: ${GDIRS[$i]%/}${RESET}${WHITE}"
        else
            echo -e "${ULINE}${GREEN}$i: ${GDIRS[$i]%/}${RESET}${WHITE}"
        fi
        #dir="${GDIRS[$i]%/}"
        #echo "$i: $dir"
    done
    # Ask for input based on the list, looping until a valid response is given
    while true; do
        echo -e "${WHITE}"
        read -p "Choose a number from the list above. " dirsel
        echo
        if [[ $dirsel =~ ^[0-9]+$ && $dirsel -ge 0 && $dirsel -le ${#GDIRS[@]} ]]; then
            echo
            break
        else
            echo -e "${YELLOW}\"$dirsel\" was ${RED}NOT ${YELLOW}an option - let's try again."
            echo
        fi
    done

    LAUNCHER="${GDIRS[dirsel]%/}"
    echo -e "${YELLOW}Launching install script for \"${ULINE}${WHITE}$LAUNCHER${RESET}${YELLOW}\":"
    echo
    # By calling '. $0 "${GDIRS[dirsel]}"' we can relaunch this script using the chosen directory as the commandline
    # option and avoid writing extra code to tell the script that each instance of "$1" should be "$1" unless the
    # array for $GDIRS has been set, in which case, use "${GDIRS[dirsel]}". It's much simpler this way because even
    # the first version of the install script has always taken a folder-name as a commandline.
    . "$0" "$LAUNCHER"
    exit 0
fi

# Assuming the script was run with an option by the user, and not called from the loop above,
# check to make sure the provided directory name actually exists. If not, exit with an error.
if [ ! -d "$1" ]; then
    echo
    echo -e "${RED}I can't find \"${WHITE}${ULINE}$1${RESET}${RED}\". Maybe try checking your spelling?${RESET}"
    echo
    exit 255
fi

# This checks to make sure the script is being run on some variation of Ubuntu, and quits with an error if it's not.
if [ -f /etc/os-release ]; then
    # If we're running Ubunto, Kubuntu, Mint, or anything else like it, run /etc/os-release and load the environment variables from it
    . /etc/os-release
else
    echo
    echo -e "${RED}What are you even running this on? This won't work.${RESET}"
    echo
    exit 255
fi

# First, check to see if WINE is installed, if not, proceed accordingly.
if ! command -v wine &> /dev/null; then
    echo
    echo -e "${YELLOW}WINE isn't installed. ${WHITE}Checking for WINEHQ official repositories."
    echo
    # Now, check if WineHQ repositories for WINE and WINETRICKS are configured.
    # If "dl.winehq.org" isn't present in any .source files, add it and update.
    if grep -q -r "dl.winehq.org" /etc/apt/; then
        echo -e "${YELLOW}WINEHQ repository exists. ${WHITE}Proceeding to WINE install."
    else
        # The information for $UBUNTU_CODENAME is provided by /etc/os-release above
        DISTRO=${UBUNTU_CODENAME,,}
        echo -e "${RED}WINEHQ repository not found. ${WHITE}Proceeding to add WINEHQ repository information."
        sudo mkdir -pm755 /etc/apt/keyrings
        sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
        #sudo add-apt-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ $UBUNTU_CODENAME main"
        sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/$DISTRO/winehq-$DISTRO.sources
        sudo apt update -y
    fi

    # If the WINE install fails, save the error to $ERRNUM and exit - we can't do this without WINE.
    if ! sudo apt install -y --install-recommends winehq-stable winetricks; then
        ERRNUM=$?
        echo
        echo -e "${RED}Fatal error ${WHITE}$ERRNUM ${RED}occurred installing WINE. ٩(๏̯๏)۶ "
        echo
        echo -e "${YELLOW}Hey. Don't look at me. ${WHITE}I don't know what it means."
        echo -e "${YELLOW}Try Googling error ${ULINE}$ERRNUM ${RESET}${YELLOW}and see if that helps?${RESET}"
        echo
        exit $ERRNUM
    fi
    echo
fi

# Variable Declarations
# Using the short-circuit trick, check if $WINE is empty (if we didn't have to install WINE, it will be)
# and if so, assign it through command substitution
WINE="$(command -v wine)"
WINEVER="$(wine --version)" # Get the version number of the WINE package we just installed.
WINE_LARGE_ADDRESS_AWARE=1; WINEDLLOVERRIDES="winemenubuilder.exe=d;mshtml=d;nvapi,nvapi64=n" # Set environment variables for WINE
WINEPREFIX="/home/$(whoami)/Game_Storage" # Create Wineprefix if it doesn't exist
GAMESRC="$PWD/$1" # Game Source Folder (where the setup is)
GAMEDEST="$WINEPREFIX/drive_c/Games/$1" # Game Destination Folder (where it's going to be)
GSS="$WINEPREFIX/drive_c/$NOSPACE.sh" # Game Starter Script - written automatically by this script
RSRC="$PWD/.redist" # Location of the MSVC Redistributables
#WINEDBG="$(command -v winedbg)" # <-- WINE Debugger
#WINEBOOT="$(command -v wineboot)" # <-- WINEBOOT
export WINE
export WINEVER
export WINE_LARGE_ADDRESS_AWARE
export WINEDLLOVERRIDES
export WINEPREFIX
export GAMESRC
export GAMEDEST
export GSS
export RSRC
#export WINEDBG
#export WINEBOOT

echo -e "${GREEN}WINE version ${YELLOW}$WINEVER${GREEN} is installed and verified functional."
echo

# Check to see if $GAMESRC actually exists. If not, exit with an error (useful check if user gives $1)
if [ ! -d "$GAMESRC" ]; then
    echo -e "${RED}Error: \"${WHITE}$GAMESRC${RED}\" doesn't exist."
    echo
    echo " ლ(ಠ益ಠ)ლ "
    echo -e "${RESET}"
    exit 255
fi

# Check to see if $GAMESRC contains files. If not, exit with an error (also useful check if user gives $1)
if [ -z "$GAMESRC" ]; then
    echo -e "${RED}Error: \"$GAMESRC\" is an empty directory.${WHITE}"
    echo " ಠ_ಠ "
    echo -e "${RESET}"
    exit 255
fi

# MSVC redistributables - if "skip" was given, don't ask about installing the runtimes.
# Otherwise, ask and act accordingly.
if [ "$SKIP" = false ]; then
    echo -e "${WHITE}If you have already installed MSVC redistributables, you can answer 'y' below,"
    echo "Or you can skip this prompt next time you install something by passing 'skip' on the command line:"
    echo
    echo -e "  ${YELLOW}$0 \"GAME FOLDER\" skip${WHITE}"
    echo
    echo -e "or just like this"
    echo
    echo -e "  ${GREEN}$0 skip${WHITE}"
    echo
    echo "Just remember that folder names containing spaces (' '), need to be enclosed in double quotes (\"Some Folder\")"
    echo "or this entire process breaks down, even though I've done my best to minimize the odds of something breaking."
    echo
    echo -e "${RED}HOWEVER:${WHITE} If this is your first time running this script, you should ${GREEN}definitely${WHITE} install them."
    echo
    read -p "Go ahead and skip the install for MSVC redistributables? (y/n) " YN
    echo
else
    YN="y"
fi
echo -e "${WHITE}"
case $YN in
    [nN] ) echo "Proceeding with MSVC runtime installs.";
      cd "$RSRC";
      for i in *.exe;
        do
            echo -e "${WHITE}Installing \"${YELLOW}$i${WHITE}\" into $WINEPREFIX";
            "$WINE" "$i" >/dev/null 2>&1;
        done;;
    * ) echo -e "${YELLOW}OK, I'm skipping the redistributables. ${RED}Just don't blame me if something breaks.${WHITE}";;
esac

# Create an array containing all the .exe files.
# If there aren't any .exe files in the directory, exit with an error
SETUPEXE=($(find "$GAMESRC" -type f -iname "*.exe"))

if [ "${#SETUPEXE[@]}" -eq 0 ]; then
    echo -e "${WHITE}\"$GAMESRC\" ${RED}doesn't contain any .exe files."
    echo
    echo -e "${WHITE} ლ(ಠ益ಠ)ლ ${RESET}"
    echo
    exit 255
fi
# Print the contents of the array and ask for input, looping until a valid response is recieved, choose color based on even or odd index
echo -e "${YELLOW}Installer options:${WHITE}"

echo
for ((i=0; i<"${#SETUPEXE[@]}"; i++)); do
    if ((i % 2 == 0)); then
        echo -e "${ULINE}${WHITE}$i: ${SETUPEXE[$i]}${RESET}${WHITE}"
    else
        echo -e "${ULINE}${GREEN}$i: ${SETUPEXE[$i]}${RESET}${WHITE}"
    fi
done

echo -e "${WHITE}"
while true; do
    read -p "Select an installer: " instsel
    if [[ "$instsel" =~ ^[0-9]+$ && "$instsel" -le "${#SETUPEXE[@]}" ]]; then
        EXE=$(basename "${SETUPEXE[$instsel]}")
        echo
        break
    else
        echo
        echo -e "${RED}That wasn't an option. ${WHITE}Please choose a valid number."
        echo
    fi
done

# If $GAMEDEST doesn't exist, create it
[ ! -d "$GAMEDEST" ] && mkdir -p "$GAMEDEST"
# Print variables, their contents, and an explanatory note for verification.
echo
echo -e "${WHITE}Technical details, if you care:"
echo
echo -e "${YELLOW}    \$GSS=\"$GSS\""
echo "    \$GAMESRC=\"$GAMESRC\""
echo "    \$WINEPREFIX=\"$WINEPREFIX\""
echo "    \$GAMEDEST=\"$GAMEDEST\""
echo "    \$WINEDLLOVERRIDES=\"winemenubuilder.exe=d;mshtml=d;nvapi,nvapi64=n\""
echo "    \$WINE_LARGE_ADDRESS_AWARE=1"
echo
echo -e "        Installer=\"$EXE\"${WHITE}"
echo
echo -e "  I ${YELLOW}${ULINE}***STRONGLY***${RESET}${WHITE} recommend picking the folder \"${ULINE}${YELLOW}$GAMEDEST${RESET}${WHITE}\""
echo -e "  when the installer launches. For the sake of automation, this installer script creates the directory using"
echo -e "  the placeholder \"${YELLOW}\$GAMEDEST${WHITE}\", and that's where the launcher script will expect it to be."
echo
echo -e "  If the installer doesn't default to C:\Games\\$1 you can change it using the advanced options."
echo
echo "  Also, you don't need to install DirectX or the MSVC Redistributables from the installer menu."
echo "  Vulkan replaces DirectX, and the MSVC Redistributables can be (re)installed any time by running this script again."
echo "  This install scripthandles all that, as you have no doubt already noticed."
echo
echo -e "  If you let the game's installer use a different folder, you will have to manually change the path and possibly the"
echo -e "  filename for the game's primary ${YELLOW}.exe ${WHITE}in the ${YELLOW}$GSS ${WHITE}script to match."
echo
echo -e "  If you do modify the launcher script, remember that paths and files are ${RED}Case Sensitive${WHITE} on Linux."
echo
echo -e "To continue, press ${YELLOW}<ENTER>${WHITE}. To cancel, press ${YELLOW}<CTRL-C>${WHITE}."; read donext
echo

# Install or update Vulkan. Ping GIT HUB to verify network connectivity, then get the latest version of VULKAN,
# compare to what's installed (if any), and download and install the latest version if there's either none already
# installed or the installed version is older than the current release. Downloads are deleted after install.
ping -c 1 github.com >/dev/null || { echo -e "${RED}Possibly no network. Booting might fail.${WHITE}" ; }
VLKLOG="$WINEPREFIX/vulkan.log"; VULKAN="$PWD/vulkan"; VLKVER="$(curl -s -m 5 https://api.github.com/repos/jc141x/vulkan/releases/latest | awk -F '["/]' '/"browser_download_url":/ {print $11}' | cut -c 1-)"
status-vulkan() { [[ ! -f "$VLKLOG" || -z "$(awk "/^${FUNCNAME[1]}\$/ {print \$1}" "$VLKLOG" 2>/dev/null)" ]] || { echo "${FUNCNAME[1]} present" && return 1; }; }
vulkan() { DL_URL="$(curl -s https://api.github.com/repos/jc141x/vulkan/releases/latest | awk -F '["]' '/"browser_download_url":/ {print $4}')" 
VLK="$(basename "$DL_URL")"; [ ! -f "$VLK" ] && command -v curl >/dev/null 2>&1 && curl -LO "$DL_URL" && tar -xvf "vulkan.tar.xz" || { rm "$VLK" && echo "ERROR: Failed to extract vulkan translation." && return 1; }
rm -rf "vulkan.tar.xz" && bash "$PWD/vulkan/setup-vulkan.sh" && rm -Rf "$VULKAN"; }
vulkan-dl() { echo "Using external vulkan translation (dxvk,vkd3d,dxvk-nvapi)." && vulkan && echo "$VLKVER" >"$VLKLOG"; }
[[ ! -f "$VLKLOG" && -z "$(status-vulkan)" ]] && vulkan-dl
[[ -f "$VLKLOG" && -n "$VLKVER" && "$VLKVER" != "$(awk '{print $1}' "$VLKLOG")" ]] && { rm -f vulkan.tar.xz || true; } && vulkan-dl;

# Enables some nVidia-specific functionality, offering entry points for supporting the following features in applications:
# - NVIDIA DLSS for Vulkan, by supporting the relevant adapter information by querying from Vulkan.
# - NVIDIA DLSS for D3D11 and D3D12, by querying from Vulkan and forwarding the relevant calls into DXVK / VKD3D-Proton.
# - NVIDIA Reflex, by forwarding the relevant calls into either DXVK / VKD3D-Proton or LatencyFleX.
# - Several NVAPI D3D11 extensions, among others SetDepthBoundsTest and UAVOverlap, by forwarding the relevant calls into DXVK.
# - NVIDIA PhysX, by supporting entry points for querying PhysX capabilities.
# - Several GPU topology related methods for adapter and display information, by querying from DXVK and Vulkan.
# Note that DXVK-NVAPI does not implement DLSS, Reflex or PhysX. It mostly forwards the relevant calls.
export DXVK_ENABLE_NVAPI=1
echo


# Start WINE and pass the primary installer .EXE to it.
echo -e "${WHITE}Starting \"${YELLOW}$1${WHITE}\" installer..."
echo

cd "$GAMESRC" # This is the source folder for the .exe
#Run WINE with an "If It Fails" assumption block.
if ! "$WINE" "$EXE" "$@" >/dev/null 2>&1; then
    # If it did fail, save the error number and exit with a message.
    ERRNUM=$?
    echo
    echo -e "${RED}Error code ${YELLOW}$ERRNUM ${RED} detected on exit."
    echo -e "${WHITE}Looks like something went wrong."
    echo "Unfortunately, since ${RED}$ERRNUM${WHITE} is a Windows-related error, I can't help you."
    echo
    exit 255
fi

# We used this once already so we're blanking it so we can reuse it
EXE=""

# This is the destination folder, originally set at the start: GAMEDEST="$WINEPREFIX/drive_c/Games/$1"
cd "$GAMEDEST"

# Create an array of .EXE files just like the initial setup, ignoring filename case
GAME_EXE=($(find "$GAMEDEST" -type f -iname "*.exe"))

if [ ${#GAME_EXE[@]} -ne 0 ]; then
    # As long as the array isn't empty we can proceed normally so we'll set DO_GSS and check it later
    DO_GSS="y"
elif [ ${#GAME_EXE[@]} -eq 0 ]; then
    # If the array is empty, no .EXE files could be found, but it's not always fatal so we'll ask to try and continue
    echo
    echo -e "${WHITE}\"${RED}$GAMESRC${WHITE}\" doesn't contain any .exe files."
    echo
    echo -e "${YELLOW} ლ(ಠ益ಠ)ლ ${WHITE}"
    echo
    read -p "Continue anyway? You'll have to manually edit the launcher scxript. (y/n) " DO_GSS
    case $DO_GSS in
        [yY] ) echo;
            # If DO_GSS="y" we'll continue with the script, but use a place holder for the runner script since no .EXE was found
            echo -e "${WHITE}Continuing as per your request.";
            EXE="\"Just A Place Holder - Replace Me With Actual Game .EXE\"";
            echo;;
        * ) echo;
            # If anything other than "y" was selected, treat it as a fatal error and abandon the install without creating the runner script
            echo -e "${RED}OK, I'm Stopping this process. You'll have to start over if you want to proceed.${RESET}";
            echo;
            exit 255;;
    esac
fi

# If DO_GSS is "y" and the array wasn't empty, present a list of .exe files, looping until we get a valid response
if [[ "${DO_GSS,,}" == "y" ]] && [ ${#GAME_EXE[@]} -ne 0 ]; then
    echo
    echo -e "${WHITE}Game runner options:"
    echo
    for ((i=0; i<"${#GAME_EXE[@]}"; i++)); do
        if ((i % 2 == 0)); then
            echo -e "${ULINE}${WHITE}$i: ${GAME_EXE[$i]}${RESET}${WHITE}"
        else
            echo -e "${ULINE}${GREEN}$i: ${GAME_EXE[$i]}${RESET}${WHITE}"
        fi
    done
    echo
    while true; do
        read -p "Select game .EXE: " gamesel
        if [[ $gamesel =~ ^[0-9]+$ && $gamesel -le ${#GAME_EXE[@]} ]]; then
            GAMEDEST=$(dirname "${GAME_EXE[$((gamesel))]}")
            EXE=$(basename "${GAME_EXE[$gamesel]}")
            echo
            break
        else
            echo
            echo -e "${YELLOW}$gamesel ${RED}wasn't an option. ${WHITE}Please choose a ${RED}valid ${WHITE}number."
        fi
    done
fi
echo
echo -e "${WHITE}Game Destination: \"${YELLOW}$GAMEDEST${WHITE}\" (C:\Games\\$1)"
echo
echo -e "Writing Game Starter Script (GSS) for ${YELLOW}$1 ${WHITE}to ${YELLOW}$GSS ${WHITE}..."
echo

# Create game starter script by writing everything up to "EOL" in the file defined in $GSS
cat << EOL > "$GSS"
#!/bin/bash

###############
## Script Name:
## $GSS
###############

# Change the current working directory to the one the scipt was run from
cd "\$(dirname "\$(readlink -f "\$0")")" || exit; [ "\$EUID" = "0" ] && echo "Please don't run as root!" && exit

# Make sure WINE is configured (although, I'm assuming it was done by the original installer script)
export WINE="\$(command -v wine)"
export WINEPREFIX="/home/\$(whoami)/Game_Storage"
export WINEDLLOVERRIDES="winemenubuilder.exe=d;mshtml=d;nvapi,nvapi64=n"
export WINE_LARGE_ADDRESS_AWARE=1
export RESTORE_RESOLUTION=1
export WINE_D3D_CONFIG="renderer=vulkan"
export GAMEDEST="\$WINEPREFIX/drive_c/Games/$1"

# Check Vulkan version and download and install if there's a newer version available online

ping -c 1 github.com >/dev/null || { echo "Possibly no network. This may mean that booting will fail." ; }; VLKLOG="\$WINEPREFIX/vulkan.log"; VULKAN="\$PWD/vulkan"
VLKVER="\$(curl -s -m 5 https://api.github.com/repos/jc141x/vulkan/releases/latest | awk -F '["/]' '/"browser_download_url":/ {print \$11}' | cut -c 1-)"
status-vulkan() { [[ ! -f "\$VLKLOG" || -z "\$(awk "/^\${FUNCNAME[1]}\$/ {print \$1}" "\$VLKLOG" 2>/dev/null)" ]] || { echo "\${FUNCNAME[1]} present" && return 1; }; }
vulkan() { DL_URL="\$(curl -s https://api.github.com/repos/jc141x/vulkan/releases/latest | awk -F '["]' '/"browser_download_url":/ {print \$4}')"; VLK="\$(basename "\$DL_URL")"
[ ! -f "\$VLK" ] && command -v curl >/dev/null 2>&1 && curl -LO "\$DL_URL" && tar -xvf "vulkan.tar.xz" || { rm "\$VLK" && echo "ERROR: Failed to extract vulkan translation." && return 1; }
rm -rf "vulkan.tar.xz" && bash "\$PWD/vulkan/setup-vulkan.sh" && rm -Rf "\$VULKAN"; }
vulkan-dl() { echo "Using external vulkan translation (dxvk,vkd3d,dxvk-nvapi)." && vulkan && echo "\$VLKVER" >"\$VLKLOG"; }
[[ ! -f "\$VLKLOG" && -z "\$(status-vulkan)" ]] && vulkan-dl;
[[ -f "\$VLKLOG" && -n "\$VLKVER" && "\$VLKVER" != "\$(awk '{print \$1}' "\$VLKLOG")" ]] && { rm -f vulkan.tar.xz || true; } && vulkan-dl

# Start process in WINE
export DXVK_ENABLE_NVAPI=1
cd "\$GAMEDEST"
"\$WINE" "$EXE" "\$@"
EOL

# Make the script executable and present a recap
chmod a+x "$GSS"
echo
cat "$GSS"
echo
echo -e "${WHITE}\"${YELLOW}$GSS${WHITE}\" has been written and made executable."
echo
echo "If you aren't running an nVidia GPU, you should change this:"
echo
echo -e "        ${YELLOW}export WINEDLLOVERRIDES=\"winemenubuilder.exe=d;mshtml=d;nvapi,nvapi64=n\""
echo
echo -e "${WHITE}to this:"
echo
echo -e "        ${YELLOW}export WINEDLLOVERRIDES=\"winemenubuilder.exe=d;mshtml=d\"${WHITE}"
echo
echo "It probably won't cause any problems for non-nVidia GPUs, but it's best just to be safe."
echo
echo -e "The full path of your ${YELLOW}$1 ${WHITE}wineprefix is: \"${YELLOW}$WINEPREFIX${WHITE}\""
echo
echo -e "Be sure to verify that the game executable written to \"${YELLOW}$GSS${WHITE}\" is actually \"${YELLOW}$EXE${WHITE}\" and modify if necessary.${RESET}"
echo

exit 0
