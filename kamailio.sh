#!/bin/bash
sudo apt-get install -y lsb-release
# REMEMBER TO INSTALL MODULE DEPENDENCIES BEFORE RUNNING SCRIPT 

# Change this here to install a different APT version. 57 is kamailio 5.7, 56 is 5.6 etc
kam_version="57"
# Change this to install a difference sopurce version:
source_version="5.5.6"

# Could be a simple one depending on the modules you need. 
# If the one you need is not in the apt repo you will have to build from source. 
# Example: apt-cache search kamailio
# If they are in the apt repo just add them below with spaces and follow the setup_apt  
apt_modules="kamailio-mysql-modules kamailio-python3-modules kamailio-websocket-modules kamailio-tls-modules"
# Amend this for your modules for building from source. Make sure to install the dependencies first!
source_modules="jsonrpcs pv textops tm tmx kex corex sl rr maxfwd textopsx siputils xlog sanity ctl cfg_rpc counters usrloc registrar dispatcher htable auth app_python3 rtpengine topoh acc uac_redirect pike nathelper siptrace debugger"

detect_linux_distribution() {
  # Function to see if a specific linux distribution is supported by this script
  # If it is supported then the global variable SETUP_ENTRYPOINT is set to the
  # function to be executed for the FS setup

    local cmd_lsb_release=$(locate_cmd "lsb_release")
    local distro_name=$($cmd_lsb_release -si)
    local distro_version=$($cmd_lsb_release -sr)
    local distro_codename=$($cmd_lsb_release -sc)
    DISTRO="$distro_name"
    DISTRO_VERSION="$distro_version"
    DISTRO_CODENAME="$distro_codename"
# Also get entrypoint for the install
    echo "Press 1 to use apt (Have you checked the modules are in apt?)"
    echo "Press 2 to install manually (Modules needed not in apt repo)"
    read -n 1 -p "Input Selection:" mainmenuinput
    if [ "$mainmenuinput" = "1" ]; then
            SETUP_ENTRYPOINT="setup_apt"
    elif [ "$mainmenuinput" = "2" ]; then
            SETUP_ENTRYPOINT="setup_manual"
    else
        echo "You have entered an invallid selection!"
        echo "Please try again!"
        echo ""
        echo "Press any key to continue..."
        detect_linux_distribution
}

setup_apt() {
    # Add the key
    wget -O- http://deb.kamailio.org/kamailiodebkey.gpg | sudo apt-key add -
    # Our GPG key fingerprint is E79A CECB 87D8 DCD2 3A20  AD2F FB40 D3E6 508E A4C8 - make sure you verify it and check it in a key store before trusting it.
    echo "deb     http://deb.kamailio.org/kamailio$kam_version $distro_codename main" | sudo tee /etc/apt/sources.list.d/kamailio.list
    apt update 
    apt install -y kamailio $apt_modules
}

setup_manual() {
    echo "Time for some fun..."
    apt update && apt upgrade -y
# Create dir and get source
    mkdir -p /usr/local/src/kamailio-$source_version/
    cd /usr/local/src/kamailio-$source_version/
    git clone --branch $source_version https://github.com/kamailio/kamailio kamailio
    cd /usr/local/src/kamailio-$source_version/kamailio/
# make config files:
    make cfg
    make include_modules="$source_modules" cfg
    make install
# Copy config to /etc
    ln -s /usr/local/etc/kamailio /etc
# systemd setup
    cd /usr/local/src/kamailio-5.5.6/kamailio
    make install-systemd-debian
    mkdir /run/kamailio
    mkdir /cfg
    chown kamailio:kamailio /run/kamailio
    echo "D /run/kamailio 0700 kamailio kamailio -" > /etc/tmpfiles.d/kamailio.conf
    systemctl enable kamailio
    systemctl start kamailio
}

reboot_selection() {
    echo "Install done. Press any key to reboot..."
    read -s -n 1
    echo "You pressed a key! Rebooting now..."
    sudo reboot
}

banner_start() {
    clear;
    echo "Installing Kamailio on $distro_name"
    echo "Standby"
    echo;
}

banner_end() {
    clear;
    echo "Hopefully Kamailio is now installed on $distro_name"
    echo "Run Kamailio -v to be sure after rebooting"
    echo;
}

# Actual install logic
start_app() {
    detect_linux_distribution
    
    banner_start

    $SETUP_ENTRYPOINT

    banner_end

    reboot_selection
    
}


######################################################################
#
# Start of main script
#
######################################################################

[[ "$0" == "$BASH_SOURCE" ]] && start_app
