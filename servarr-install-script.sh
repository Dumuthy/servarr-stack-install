#!/bin/bash
### Description: Servarr .NET Debian install
### Originally written for Radarr by: DoctorArr - doctorarr@the-rowlands.co.uk on 2021-10-01 v1.0
### Version v1.1 2021-10-02 - Bakerboy448 (Made more generic and conformant)
### Version v1.1.1 2021-10-02 - DoctorArr (Spellcheck and boilerplate update)
### Version v2.0.0 2021-10-09 - Bakerboy448 (Refactored and ensured script is generic. Added more variables.)
### Version v2.0.1 2021-11-23 - brightghost (Fixed datadir step to use correct variables.)
### Version v3.0.0 2022-02-03 - Bakerboy448 (Rewrote script to prompt for user/group and made generic for all \*Arrs)
### Version v3.0.1 2022-02-05 - aeramor (typo fix line 179: 'chown "$app_uid":"$app_uid" -R "$bindir"' -> 'chown "$app_uid":"$app_guid" -R "$bindir"')
### Version v3.0.3 2022-02-06 - Bakerboy448 fixup ownership
### Version v3.0.3a Readarr to develop
### Version v3.0.4 2022-03-01 - Add sleep before checking service status
### Version v3.0.5 2022-04-03 - VP-EN (Added Whisparr)
### Version v3.0.6 2022-04-26 - Bakerboy448 - binaries to group
### Version v3.0.7 2023-01-05 - Bakerboy448 - Prowlarr to master
### Version v3.0.8 2023-04-20 - Bakerboy448 - Shellcheck fixes & remove prior tarballs
### Version v3.0.9 2023-04-28 - Bakerboy448 - fix tarball check
### Version v3.0.9a 2023-07-14 - DoctorArr - updated scriptversion and scriptdate and to see how this is going! It was still at v3.0.8.
### Version v3.0.10 2024-01-04 - Bakerboy448 - Misc updates and refactoring. Move to own script file.
### Version v3.0.11 2024-01-06 - StevieTV - Exit script when ran from installdir
### Version v3.0.12 2024-04-09 - nostrus-dominion - moved root check, added title splash, added colors, attempted to improve readability, check for installed prerequisites before bothering apt, supressed tarball extraction, added some sleep timers.
### Version v3.0.13+ 2024+ - Additional Updates by: The Servarr Community
### Version v4.0.0 - Multi-app stack installer; added multi-select menu, installation loop,
###                  Sonarr and Readarr support, shared user/group prompts, and summary screen.

### Boilerplate Warning
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
#LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
#OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
#WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

### Colors
green='\033[0;32m'
yellow='\033[1;33m'
red='\033[0;31m'
brown='\033[0;33m'
reset='\033[0m' # No Color

scriptversion="4.0.0"
scriptdate="2025-02-17"

set -uo pipefail

### Am I root?, need root! GROOT!

if [ "$EUID" -ne 0 ]; then
    echo -e ${red}"Please run as root!"
    echo -e "Exiting script!"
    exit
fi

### Title Splash
echo -e ${brown}
echo -e "#############################################################"
echo -e "#                                                           #"
echo -e "#      Welcome to the Servarr Stack Installation Script!    #"
echo -e "#                                                           #"
echo -e "#  This script installs multiple Servarr applications into  #"
echo -e "#  a single environment on any Debian-based distro.         #"
echo -e "#  If you have not done so, exit the script and read the    #"
echo -e "#  Boilerplate Warning just to CYA. Enjoy your new setup!   #"
echo -e "#                                                           #"
echo -e "#############################################################"
echo -e ${reset}

echo -e "Running Servarr Stack Install Script - Version ${brown}[$scriptversion]${reset} as of ${brown}[$scriptdate]${reset}"
echo ""

# ============================================================
# [OLD CODE - Remove after testing]
# Original single-app select menu. Replaced by multi-select
# checkbox menu below.
# ============================================================
# echo "Select the application to install: "
# echo ""
# select app in lidarr prowlarr radarr whisparr whisparr-v3 quit; do
#
#     case $app in
#     lidarr)
#         app_port="8686"                                                     # Default App Port; Modify config.xml after install if needed
#         app_prereq="curl sqlite3 libsqlite3-0 libchromaprint-tools mediainfo" # Required packages
#         app_umask="0002"                                                    # UMask the Service will run as
#         branch="master"                                                     # {Update me if needed} branch to install
#         break
#         ;;
#     prowlarr)
#         app_port="9696"                      # Default App Port; Modify config.xml after install if needed
#         app_prereq="curl sqlite3 libsqlite3-0" # Required packages
#         app_umask="0002"                     # UMask the Service will run as
#         branch="master"                      # {Update me if needed} branch to install
#         break
#         ;;
#     radarr)
#         app_port="7878"                      # Default App Port; Modify config.xml after install if needed
#         app_prereq="curl sqlite3 libsqlite3-0" # Required packages
#         app_umask="0002"                     # UMask the Service will run as
#         branch="master"                      # {Update me if needed} branch to install
#         break
#         ;;
#     whisparr)
#         app_port="6969"                      # Default App Port; Modify config.xml after install if needed
#         app_prereq="curl sqlite3 libsqlite3-0" # Required packages
#         app_umask="0002"                     # UMask the Service will run as
#         branch="nightly"                     # {Update me if needed} branch to install
#         break
#         ;;
#     whisparr-v3)
#         app=whisparr
#         app_port="6969"                      # Default App Port; Modify config.xml after install if needed
#         app_prereq="curl sqlite3 libsqlite3-0" # Required packages
#         app_umask="0002"                     # UMask the Service will run as
#         branch="eros"                        # {Update me if needed} branch to install
#         break
#         ;;
#     quit)
#         exit 0
#         ;;
#     *)
#         echo "Invalid option $REPLY"
#         ;;
#     esac
# done
# echo ""
# ============================================================
# [END OLD CODE]
# ============================================================

# ============================================================
# [NEW CODE] Multi-select application menu
# Replaces the original single-app select menu above.
# Uses whiptail checkboxes so users can choose multiple apps.
# ============================================================

# Ensure whiptail is available (it is included in Debian by default)
if ! command -v whiptail &>/dev/null; then
    echo -e ${yellow}"Installing whiptail..."${reset}
    apt-get install -y whiptail
fi

CHOICES=$(whiptail --title "Servarr Stack Installer" \
    --checklist "Select applications to install:\n(Spacebar to select, Enter to confirm)" \
    20 78 8 \
    "radarr"   "Movies             - Port 7878" ON  \
    "sonarr"   "TV Shows           - Port 8989" ON  \
    "lidarr"   "Music              - Port 8686" OFF \
    "prowlarr" "Indexer Manager    - Port 9696" ON  \
    "readarr"  "Books / Comics     - Port 8787" OFF \
    "whisparr" "Adult Content      - Port 6969" OFF \
    3>&1 1>&2 2>&3)

# Check if user pressed Cancel
if [ $? -ne 0 ]; then
    echo ""
    echo "Installation cancelled by user. Exiting."
    exit 0
fi

# Convert whiptail output (space-separated quoted strings) into a bash array
# Example whiptail output: "radarr" "sonarr" "prowlarr"
# tr removes the quotes, read splits on spaces into array elements
read -r -a selected_apps <<< "$(echo "$CHOICES" | tr -d '"')"

# Confirm at least one app was selected
if [ ${#selected_apps[@]} -eq 0 ]; then
    echo ""
    echo "No applications selected. Exiting."
    exit 0
fi

echo ""
echo -e "Applications selected for installation: ${brown}${selected_apps[*]}${reset}"
echo ""
# ============================================================
# [END NEW CODE]
# ============================================================

### CONSTANTS
### Update these variables as required for your specific instance
installdir="/opt"              # {Update me if needed} Install Location
# ============================================================
# [OLD CODE - Remove after testing]
# bindir and datadir were set here using $app in the original
# single-app flow. They are now set inside the loop below,
# where $app is defined for each selected application.
# ============================================================
# bindir="${installdir}/${app^}" # Full Path to Install Location
# datadir="/var/lib/$app/"       # {Update me if needed} AppData directory to use
# app_bin=${app^}                # Binary Name of the app
# ============================================================
# [END OLD CODE]
# ============================================================

# ============================================================
# [OLD CODE - Remove after testing]
# This warning block used $app to check if prowlarr was
# selected. Replaced by a general warning below that covers
# all apps in the multi-select scenario.
# ============================================================
# if [[ $app != 'prowlarr' ]]; then
#     echo -e ${red}"   WARNING! WARNING! WARNING!"${reset}
#     echo ""
#     echo -e "   It is ${red}CRITICAL${reset} that the ${brown}User${reset} and ${brown}Group${reset} you select"
#     echo -e "   to run ${brown}[${app^}]${reset} will have both ${red}READ${reset} and ${red}WRITE${reset} access"
#     echo -e "   to your Media Library and Download Client directories!"${reset}
#     sleep 5
# fi
# ============================================================
# [END OLD CODE]
# ============================================================

# ============================================================
# [NEW CODE] General media access warning shown once for all apps
# ============================================================
echo -e ${red}"   WARNING! WARNING! WARNING!"${reset}
echo ""
echo -e "   It is ${red}CRITICAL${reset} that the ${brown}User${reset} and ${brown}Group${reset} you select"
echo -e "   to run these applications will have both ${red}READ${reset} and ${red}WRITE${reset} access"
echo -e "   to your Media Library and Download Client directories!"
sleep 5
# ============================================================
# [END NEW CODE]
# ============================================================

# This script should not be run from installdir
if [ "$installdir" == "$(dirname -- "$( readlink -f -- "$0"; )")" ]; then
    echo ""
    echo -e "${red}Error!${reset} You should not run this script from the intended install directory."
    echo "Please re-run it from another directory."
    echo "Exiting Script!"
    exit
fi

# ============================================================
# [OLD CODE - Remove after testing]
# Original single-app user/group prompts used $app as the
# default username (e.g. "radarr"). Replaced below with a
# shared prompt that defaults to "servarr" as the user, so
# all apps run under the same account.
# ============================================================
# # Prompt User
# echo ""
# read -r -p "What user should [${app^}] run as? (Default: $app): " app_uid
# app_uid=$(echo "$app_uid" | tr -d ' ')
# app_uid=${app_uid:-$app}
# # Prompt Group
# echo ""
# read -r -p "What group should [${app^}] run as? (Default: media): " app_guid
# app_guid=$(echo "$app_guid" | tr -d ' ')
# app_guid=${app_guid:-media}
#
# echo ""
# echo -e "${brown}[${app^}]${reset} selected for installation."
# echo ""
# echo -e "${brown}[${app^}]${reset} will then be installed to ${brown}[$bindir]${reset} and use ${brown}[$datadir]${reset} for the AppData Directory."
# if [[ $app == 'prowlarr' ]]; then
#     echo ""
#     echo -e "${brown}[${app^}]${reset} will run as the user ${brown}[$app_uid]${reset} and group ${brown}[$app_guid]${reset}."
# else
#     echo ""
#     echo -e "${brown}[${app^}]${reset} will run as the user ${brown}[$app_uid]${reset} and group ${brown}[$app_guid]${reset}."
#     echo ""
#     echo -e "   By continuing, you've ${red}CONFIRMED${reset} that that ${brown}[$app_uid]${reset} and ${brown}[$app_guid]${reset}"
#     echo -e "   will have both ${red}READ${reset} and ${red}WRITE${reset} access to all required directories."
#     echo ""
# fi
# ============================================================
# [END OLD CODE]
# ============================================================

# ============================================================
# [NEW CODE] Shared user/group prompt for all apps
# Asked once up front; every selected app will use the same
# user and group to keep permissions simple and consistent.
# ============================================================
echo ""
read -r -p "What user should all Servarr apps run as? (Default: servarr): " app_uid
app_uid=$(echo "$app_uid" | tr -d ' ')
app_uid=${app_uid:-servarr}

echo ""
read -r -p "What group should all Servarr apps run as? (Default: media): " app_guid
app_guid=$(echo "$app_guid" | tr -d ' ')
app_guid=${app_guid:-media}

echo ""
echo -e "The following apps will be installed: ${brown}${selected_apps[*]}${reset}"
echo ""
echo -e "All apps will run as user ${brown}[$app_uid]${reset} and group ${brown}[$app_guid]${reset}."
echo ""
echo -e "   By continuing, you've ${red}CONFIRMED${reset} that ${brown}[$app_uid]${reset} and ${brown}[$app_guid]${reset}"
echo -e "   will have both ${red}READ${reset} and ${red}WRITE${reset} access to all required directories."
echo ""
# ============================================================
# [END NEW CODE]
# ============================================================

# User confirmation that installation will continue
echo ""
read -r -p "Please type 'yes' to continue with the installation: " response
if [[ $response != "yes" && $response != "YES" ]]; then
    echo "Invalid response. Operation is canceled!"
    echo "Exiting script!"
    exit 0
fi

# Create User / Group as needed
if [ "$app_guid" != "$app_uid" ]; then
    if ! getent group "$app_guid" >/dev/null; then
        groupadd "$app_guid"
    fi
fi
if ! getent passwd "$app_uid" >/dev/null; then
    adduser --system --no-create-home --ingroup "$app_guid" "$app_uid"
    echo ""
    echo -e "Created User ${yellow}$app_uid${reset}"
    echo ""
    echo -e "Created Group ${yellow}$app_guid${reset}."
    sleep 3
fi
if ! getent group "$app_guid" | grep -qw "$app_uid"; then
    echo ""
    echo -e "User ${yellow}$app_uid${reset} did not exist in Group ${yellow}$app_guid${reset}."
    usermod -a -G "$app_guid" "$app_uid"
    echo ""
    echo -e "Added User ${yellow}$app_uid${reset} to Group ${yellow}$app_guid${reset}."
    sleep 3
fi

# ============================================================
# [NEW CODE] Installation loop
# Iterates over every app the user selected and installs each
# one in sequence. The case statement sets the app-specific
# variables (port, prereqs, branch) that the original install
# code below relies on, so that code needs no changes at all.
# ============================================================

# Capture the host IP once before the loop (used in the
# summary screen at the end)
host=$(hostname -I)
ip_local=$(grep -oP '^\S*' <<<"$host")

# Collect results for the summary screen
declare -a install_results=()

for app in "${selected_apps[@]}"; do

    echo ""
    echo -e "${brown}============================================================${reset}"
    echo -e "${brown}  Installing: ${app^}${reset}"
    echo -e "${brown}============================================================${reset}"
    echo ""

    # Set per-app variables used throughout the original install code
    case $app in
    radarr)
        app_port="7878"
        app_prereq="curl sqlite3 libsqlite3-0"
        app_umask="0002"
        branch="master"
        ;;
    sonarr)
        app_port="8989"
        app_prereq="curl sqlite3 libsqlite3-0"
        app_umask="0002"
        ;;
    lidarr)
        app_port="8686"
        app_prereq="curl sqlite3 libsqlite3-0 libchromaprint-tools mediainfo"
        app_umask="0002"
        branch="master"
        ;;
    prowlarr)
        app_port="9696"
        app_prereq="curl sqlite3 libsqlite3-0"
        app_umask="0002"
        branch="master"
        ;;
    readarr)
        app_port="8787"
        app_prereq="curl sqlite3 libsqlite3-0"
        app_umask="0002"
        ;;
    whisparr)
        app_port="6969"
        app_prereq="curl sqlite3 libsqlite3-0"
        app_umask="0002"
        branch="nightly"
        ;;
    *)
        echo -e ${red}"Unknown application: $app - skipping."${reset}
        install_results+=("${app^}: SKIPPED (unknown app)")
        continue
        ;;
    esac

    # Set derived path variables for this app
    bindir="${installdir}/${app^}"
    datadir="/var/lib/$app/"
    app_bin=${app^}

    # -------------------------------------------------------
    # Everything below this line is the ORIGINAL install code,
    # unchanged. It works for each app because all the
    # variables it needs ($app, $app_port, $bindir, etc.)
    # are now set by the case statement above.
    # -------------------------------------------------------

    # Stop the App if running
    if service --status-all | grep -Fq "$app"; then
        systemctl stop "$app"
        systemctl disable "$app".service
        echo "Stopped existing $app."
    fi

    # Create Appdata Directories
    mkdir -p "$datadir"
    chown -R "$app_uid":"$app_guid" "$datadir"
    chmod 775 "$datadir"
    echo ""
    echo -e "Directories ${yellow}$bindir${reset} and ${yellow}$datadir${reset} created!"

    # Download and install the App

    # Check if prerequisite packages are already installed and install them if needed
    echo ""
    echo -e ${yellow}"Checking Pre-Requisite Packages..."${reset}
    sleep 3

    missing_packages=()
    for pkg in $app_prereq; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            missing_packages+=("$pkg")
        fi
    done

    if [ ${#missing_packages[@]} -eq 0 ]; then
        echo ""
        echo -e ${green}"All prerequisite packages are already installed!"${reset}
    else
        echo ""
        echo -e "Installing missing prerequisite packages: ${brown}${missing_packages[*]}${reset}"
        # Install missing prerequisite packages
        apt update && apt install -y "${missing_packages[@]}"
    fi

# ============================================================
    # [OLD CODE - Remove after testing]
    # Generic URL builder used $app and $branch to construct a
    # single download URL pattern. Failed for Sonarr which uses
    # a completely different endpoint. Replaced below with
    # explicit per-app URLs matching community-scripts/ProxmoxVE.
    # ============================================================
    # ARCH=$(dpkg --print-architecture)
    # dlbase="https://$app.servarr.com/v1/update/$branch/updatefile?os=linux&runtime=netcore"
    # case "$ARCH" in
    # "amd64") DLURL="${dlbase}&arch=x64" ;;
    # "armhf") DLURL="${dlbase}&arch=arm" ;;
    # "arm64") DLURL="${dlbase}&arch=arm64" ;;
    # *)
    #     echo -e ${red}"Your arch is not supported!"
    #     echo -e "Exiting installer script!"${reset}
    #     exit 1
    #     ;;
    # esac
    # ============================================================
    # [END OLD CODE]
    # ============================================================

    # [NEW CODE] Explicit per-app URLs matching community-scripts
    # patterns. Sonarr uses services.sonarr.tv; all others use
    # their respective servarr.com subdomain endpoints.
    ARCH=$(dpkg --print-architecture)
    case "$ARCH" in
        "amd64") arch_str="x64"   ;;
        "armhf") arch_str="arm"   ;;
        "arm64") arch_str="arm64" ;;
        *)
            echo -e ${red}"Architecture ($ARCH) is not supported. Skipping ${app^}."${reset}
            install_results+=("${app^}|Port: $app_port|FAILED - unsupported arch")
            continue
            ;;
    esac

    case "$app" in
        sonarr)
            DLURL="https://services.sonarr.tv/v1/download/main/latest?version=4&os=linux&arch=${arch_str}"
            ;;
        radarr|lidarr|prowlarr|whisparr)
            DLURL="https://${app}.servarr.com/v1/update/${branch}/updatefile?os=linux&runtime=netcore&arch=${arch_str}"
            ;;
        readarr)
            DLURL="https://readarr.servarr.com/v1/update/develop/updatefile?os=linux&runtime=netcore&arch=${arch_str}"
            ;;
    esac
    echo ""
    # [END NEW CODE]

    echo -e ${yellow}"Removing tarballs..."${reset}
    sleep 3
    # -f to Force so we do not fail if it doesn't exist
    rm -f "${app^}".*.tar.gz
    echo ""
    echo -e ${yellow}"Downloading required files..."${reset}
    echo ""
    # [NEW CODE] Explicit error trap on download so a bad URL
    # or network failure skips this app and continues the loop
    # rather than crashing the whole script silently.
    if ! wget --content-disposition "$DLURL"; then
        echo ""
        echo -e "${red}Download failed for ${app^}. Skipping.${reset}"
        install_results+=("${app^}|Port: $app_port|FAILED - download error")
        continue
    fi
    # [END NEW CODE]
    echo ""
    echo -e ${yellow}"Download complete!"${reset}
    echo ""
    echo -e ${yellow}"Extracting tarball!"${reset}
    # [NEW CODE] Explicit error trap on extraction. If wget
    # returned a JSON error page instead of a tarball (like the
    # original Sonarr failure), tar will fail here and the loop
    # continues cleanly to the next app.
    if ! tar -xvzf "${app^}".*.tar.gz >/dev/null 2>&1; then
        echo ""
        echo -e "${red}Extraction failed for ${app^}. The download may not be a valid tarball. Skipping.${reset}"
        install_results+=("${app^}|Port: $app_port|FAILED - extraction error")
        rm -f "${app^}".*.tar.gz
        continue
    fi
    # [END NEW CODE]
    echo ""
    echo -e ${yellow}"Installation files downloaded and extracted!"${reset}

    # remove existing installs
    echo ""
    echo -e "Removing existing installation files from ${brown}[$bindir]"${reset}
    rm -rf "$bindir"
    sleep 2
    echo ""
    echo -e "Attempting to install ${brown}[${app^}]${reset}..."
    sleep 2
    mv "${app^}" $installdir
    chown "$app_uid":"$app_guid" -R "$bindir"
    chmod 775 "$bindir"
    # Ensure we check for an update in case user installs older version or different branch
    touch "$datadir"/update_required
    chown "$app_uid":"$app_guid" "$datadir"/update_required
    echo ""
    echo -e "Successfully installed ${brown}[${app^}]${reset}!!"
    rm -rf "${app^}.*.tar.gz"
    sleep 2

    # Check GLIBC version and create symlink to system SQLite if needed
    echo ""
    echo -e ${yellow}"Checking GLIBC version for SQLite compatibility..."${reset}
    GLIBC_VERSION=$(ldd --version | awk '/ldd/{print $NF}')
    GLIBC_MAJOR=$(echo "$GLIBC_VERSION" | cut -d. -f1)
    GLIBC_MINOR=$(echo "$GLIBC_VERSION" | cut -d. -f2)

    # Check if GLIBC is older than 2.38
    if [ "$GLIBC_MAJOR" -lt 2 ] || { [ "$GLIBC_MAJOR" -eq 2 ] && [ "$GLIBC_MINOR" -lt 38 ]; }; then
        echo ""
        echo -e ${yellow}"Detected GLIBC ${GLIBC_VERSION} (older than 2.38)."${reset}
        echo -e "Creating symlink to system SQLite library..."

        # Backup original and create symlink based on architecture
        mv "$bindir/libe_sqlite3.so" "$bindir/libe_sqlite3.so.backup" 2>/dev/null || true

        case "$ARCH" in
            "amd64") SYSTEM_SQLITE="/usr/lib/x86_64-linux-gnu/libsqlite3.so.0" ;;
            "arm64") SYSTEM_SQLITE="/usr/lib/aarch64-linux-gnu/libsqlite3.so.0" ;;
            "armhf") SYSTEM_SQLITE="/usr/lib/arm-linux-gnueabihf/libsqlite3.so.0" ;;
            *) SYSTEM_SQLITE="/usr/lib/x86_64-linux-gnu/libsqlite3.so.0" ;;
        esac

        if [ -f "$SYSTEM_SQLITE" ]; then
            ln -s "$SYSTEM_SQLITE" "$bindir/libe_sqlite3.so"
            echo -e ${green}"Symlink created. ${app^} will use system SQLite at $SYSTEM_SQLITE"${reset}
        else
            echo -e ${red}"System SQLite library not found at $SYSTEM_SQLITE"${reset}
            echo -e ${red}"This should not happen as libsqlite3-0 is a prerequisite."${reset}
        fi
        sleep 2
    else
        echo -e ${green}"GLIBC ${GLIBC_VERSION} is compatible with bundled SQLite."${reset}
    fi

    # Configure Autostart

    # Remove any previous app .service
    echo ""
    echo "Removing old service file..."
    rm -rf /etc/systemd/system/"$app".service
    sleep 2

    # Create app .service with correct user startup
    echo ""
    echo "Creating new service file..."
    cat <<EOF | tee /etc/systemd/system/"$app".service >/dev/null
[Unit]
Description=${app^} Daemon
After=syslog.target network.target
[Service]
User=$app_uid
Group=$app_guid
UMask=$app_umask
Type=simple
ExecStart=$bindir/$app_bin -nobrowser -data=$datadir
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
    sleep 2

    # Start the App
    echo ""
    echo -e "New service file created!"
    echo ""
    echo -e "${brown}[${app^}]${reset} is attempting to start, this may take a few seconds..."
    systemctl -q daemon-reload
    systemctl enable --now -q "$app"
    sleep 3

    # Check if the service is up and running
    echo ""
    echo "Checking if the service is up and running..."

    # Loop to wait until the service is active
    while ! systemctl is-active --quiet "$app"; do
        sleep 1
    done

    echo ""
    echo -e "${brown}[${app^}]${reset} installation and service start up is complete!"

    # ============================================================
    # [OLD CODE - Remove after testing]
    # Original per-app finish block printed a single URL and
    # exited immediately. Replaced by collecting results into
    # an array and printing a combined summary after the loop.
    # ============================================================
    # # Finish Installation
    # host=$(hostname -I)
    # ip_local=$(grep -oP '^\S*' <<<"$host")
    # echo ""
    # echo -e "Attempting to check for a connection at http://$ip_local:$app_port..."
    # sleep 3
    # STATUS="$(systemctl is-active "$app")"
    # if [ "${STATUS}" = "active" ]; then
    #     echo ""
    #     echo "Successful connection!"
    #     echo ""
    #     echo -e "Browse to ${green}http://$ip_local:$app_port${reset} for the GUI."
    #     echo ""
    #     echo "Script complete! Exiting now!"
    #     echo ""
    # else
    #     echo ""
    #     echo -e ${red}"${app^} failed to start."${reset}
    #     echo ""
    #     echo "Please try again. Exiting script."
    #     echo
    # fi
    # ============================================================
    # [END OLD CODE]
    # ============================================================

    # ============================================================
    # [NEW CODE] Collect per-app result for summary screen
    # ============================================================
    STATUS="$(systemctl is-active "$app")"
    if [ "${STATUS}" = "active" ]; then
        install_results+=("${app^}|http://$ip_local:$app_port|OK")
    else
        install_results+=("${app^}|http://$ip_local:$app_port|FAILED")
    fi
    # ============================================================
    # [END NEW CODE]
    # ============================================================

done
# ============================================================
# [END NEW CODE - Installation loop]
# ============================================================

# ============================================================
# [NEW CODE] Installation summary screen
# Printed once after all apps have been processed, showing
# the URL and status of every app that was attempted.
# ============================================================
echo ""
echo -e "${brown}============================================================${reset}"
echo -e "${brown}  Servarr Stack Installation Summary${reset}"
echo -e "${brown}============================================================${reset}"
echo ""

all_ok=true
for result in "${install_results[@]}"; do
    # Each result is stored as "AppName|URL|STATUS"
    app_name=$(echo "$result" | cut -d'|' -f1)
    app_url=$(echo "$result"  | cut -d'|' -f2)
    app_stat=$(echo "$result" | cut -d'|' -f3)

    if [ "$app_stat" = "OK" ]; then
        echo -e "  ${green}[OK]${reset}     ${brown}${app_name}${reset} → ${green}${app_url}${reset}"
    else
        echo -e "  ${red}[FAILED]${reset} ${brown}${app_name}${reset} → ${red}${app_url}${reset}"
        all_ok=false
    fi
done

echo ""
if [ "$all_ok" = true ]; then
    echo -e "${green}All applications installed and running successfully!${reset}"
else
    echo -e "${red}One or more applications failed to start.${reset}"
    echo -e "Check the output above for details, or run:"
    echo -e "  ${yellow}systemctl status <appname>${reset}"
fi
echo ""
echo "Script complete! Exiting now."
echo ""
# ============================================================
# [END NEW CODE]
# ============================================================

# Exit
exit 0
