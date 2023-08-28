#!/bin/bash

sudo apt-get install -y lsb-release
# No promtheus support in apt version 4.5.1 - for this you need >= 4.5.2
# For 4.5.2 with prometheus support you need to compile from scratch:
version="4.5.2
"
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
    echo "Press 1 to use apt (No Prometheus support)"
    echo "Press 2 to install manually (with Prometheus support)"
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
    sudo apt-get install -y coturn 
}

setup_manual() {
    apt update
    cd /usr/
    apt install -y make git build-essential pkg-config libssl-dev libevent-dev libmicrohttpd-dev libsystemd-dev libhiredis0.14 libmysqlclient21 libpq5 mysql-common sqlite3
    wget https://github.com/digitalocean/prometheus-client-c/releases/download/v0.1.3/libprom-dev-0.1.3-Linux.deb
    wget https://github.com/digitalocean/prometheus-client-c/releases/download/v0.1.3/libpromhttp-dev-0.1.3-Linux.deb
    sudo dpkg -i libprom-dev-0.1.3-Linux.deb
    sudo dpkg -i libpromhttp-dev-0.1.3-Linux.deb
    git clone --branch $version --single-branch https://github.com/coturn/coturn.git
    cd /usr/coturn
    nano configure
    # Change config location to /etc
    # Change the binary location as /usr - was /usr/local
    # Or simlink after testing this
    ./configure
    make && make install
    mkdir /var/log/coturn
}

reboot_selection() {
    echo "Install done. Press any key to reboot..."
    read -s -n 1
    echo "You pressed a key! Rebooting now..."
    sudo reboot
}

banner_start() {
    clear;
    echo "Installing CoTURN v$version on $distro_name"
    echo "Standby"
    echo;
}

banner_end() {
    clear;
    echo "Hopefully CoTURN is now installed on $distro_name"
    echo "Run turnserver to be sure after rebooting"
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
