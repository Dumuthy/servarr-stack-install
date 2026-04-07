# servarr-stack-install
Multi-application Servarr stack installer with FlareSolverr and Recyclarr support

# Servarr Stack Installer
   
   Multi-application installer for the Servarr suite with additional tools.
   
   ## Credits
   Based on the original Servarr installation script by DoctorArr, Bakerboy448, and the Servarr Community:
   https://github.com/Servarr/Wiki/blob/master/servarr/servarr-install-script.sh
   
   ## Notes
   - This script is to be run inside an existing Debian 12 LXC or bare metal install
   - Future versions will eventually support full Proxmox Community Script functionality.
   - I will not hand-hold you through this, I assume you have some idea of what you are doing
   - Obtain root shell (either via ssh or other means)
   - Run `wget https://raw.githubusercontent.com/Dumuthy/servarr-stack-install/main/servarr-install-script.sh`
   - Run `chmod +x servarr-install-script.sh`
   - Run `bash servarr-install-script.sh`
   - The rest will be explained during the installation process.
   
   ## Features and Supported Applications
   - Install multiple *arr applications at once in a single Proxmox LXC
   - Radarr, Sonarr, Lidarr, Prowlarr, Readarr, Whisparr
   - Easy checkbox selection for which *ARRs you wish to install
   
   ## Future Supported Applications
   - Tdarr
   - FlareSolverr
   - Recyclarr
   - Dispatcharr
   - More *arr tools to be added at a later time
