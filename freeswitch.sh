#!/bin/bash

# For the Debian APT install you need a signalwire account and token. You can get one from here:
# https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Installation/HOWTO-Create-a-SignalWire-Personal-Access-Token_67240087/

sudo apt-get install -y lsb-release
# Change this here to install a different version. 
fs_version="v1.10.10"

detect_linux_distribution() {
  # Function to see if a specific linux distribution is supported by this script
  # If it is supported then the global variable SETUP_ENTRYPOINT is set to the
  # function to be executed for the FS setup

  local cmd_lsb_release=$(locate_cmd "lsb_release")
  local distro_name=$($cmd_lsb_release -si)
  local distro_version=$($cmd_lsb_release -sr)
  DISTRO="$distro_name"
  DISTRO_VERSION="$distro_version"

  case "$distro_name" in
    Ubuntu ) case "$distro_version" in
               20.04* | 22.04* ) SETUP_ENTRYPOINT="setup_ubuntu"
                    return 0 ;; # Suported Distribution
               *  ) return 1 ;; # Unsupported Distribution
             esac
             ;;
    Debian ) case "$distro_version" in
            10* | 11* | 12* ) SETUP_ENTRYPOINT="setup_debian"
                    return 0 ;; # Suported Distribution
               *  ) return 1 ;; # Unsupported Distribution
             esac
             ;;
    *      ) return 1 ;; # Unsupported Distribution
 esac
}


# Latest debian release:
setup_debian() {
    # See 2nd line in script for this
    TOKEN=YOURSIGNALWIRETOKEN

    sudo apt update && sudo apt install -y gnupg2 wget

    wget --http-user=signalwire --http-password=$TOKEN -O /usr/share/keyrings/signalwire-freeswitch-repo.gpg https://freeswitch.signalwire.com/repo/deb/debian-release/signalwire-freeswitch-repo.gpg

    echo "machine freeswitch.signalwire.com login signalwire password $TOKEN" > /etc/apt/auth.conf
    chmod 600 /etc/apt/auth.conf
    echo "deb [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" > /etc/apt/sources.list.d/freeswitch.list
    echo "deb-src [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" >> /etc/apt/sources.list.d/freeswitch.list

    # you may want to populate /etc/freeswitch at this point.
    #mkdir /etc/freeswitch
    # if /etc/freeswitch does not exist, the standard vanilla configuration is deployed
    sudo apt update && sudo apt install -y freeswitch-meta-all

}

# latest Ubuntu release: or you specific choice 
setup_ubuntu() {
    # Ubuntu 20.04 build from source: 
    # Dependancies 
    sudo apt update && apt upgrade -y
    sudo apt install --yes build-essential pkg-config uuid-dev zlib1g-dev libjpeg-dev libsqlite3-dev libcurl4-openssl-dev \
                libpcre3-dev libspeexdsp-dev libldns-dev libedit-dev libtiff5-dev yasm libopus-dev libsndfile1-dev unzip \
                libavformat-dev libswscale-dev libavresample-dev liblua5.2-dev liblua5.2-0 cmake libpq-dev \
                unixodbc-dev autoconf automake ntpdate libxml2-dev libpq-dev libpq5 sngrep libvorbis0a libogg0 libogg-dev libvorbis-dev libshout3-dev libmpg123-dev libmp3lame-dev
    # libks install
    git clone https://github.com/signalwire/libks.git /usr/local/src/libks
    cd /usr/local/src/libks
    cmake .
    sudo make && sudo make install
    echo "ldconfig && ldconfig -p | grep libks"

    # libsignalwire support:
    git clone https://github.com/signalwire/signalwire-c.git /usr/local/src/signalwire-c
    cd /usr/local/src/signalwire-c
    cmake .
    sudo make && sudo make install
    echo "ldconfig && ldconfig -p | grep signalwire"

    # SpanDSP and sofia SIP
    git clone https://github.com/freeswitch/sofia-sip /usr/local/src/sofia-sip
    cd /usr/local/src/sofia-sip
    ./bootstrap.sh
    ./configure
    sudo make && sudo make install

    git clone https://github.com/freeswitch/spandsp /usr/local/src/spandsp
    cd /usr/local/src/spandsp
    ./bootstrap.sh
    ./configure
    sudo make && sudo make install

    echo "ldconfig -p | grep spandsp"
    echo "ldconfig && ldconfig -p | grep sofia"

    # Install FreeSWITCH version 
    git clone --branch $fs_version https://github.com/signalwire/freeswitch.git /usr/src/freeswitch
    cd /usr/src/freeswitch
    # Because we're in a branch that will go through many rebases, it's better to set this one, or you'll get CONFLICTS when pulling (update).
    git config pull.rebase true
    ./bootstrap.sh -j

    # Now time to actually install.
    ./configure
    sudo make && sudo make install

    # Sounds and MOH install if needed:
    make hd-moh-install
    make hd-sounds-install

    # Simlinks - Important step! This is to keep the same automation paths
    mkdir /var/log/freeswitch/
    mkdir /var/run/freeswitch/

    sudo ln -s /usr/local/lib/libspandsp.so.3.0.0 /usr/local/freeswitch/bin/libspandsp.so.3.0.0
    sudo ln -s /usr/local/lib/libspandsp.so.3 /usr/local/freeswitch/bin/libspandsp.so.3
    sudo ln -s /usr/local/lib/libspandsp.so /usr/local/freeswitch/bin/libspandsp.so

    # For v.1.10.6 we must add the below otherwise it fails to start in AWS - this could be any cloud provider as well
    #sudo ln -s /usr/local/lib/libspandsp.so.3 /lib/x86_64-linux-gnu/libspandsp.so.3

    sudo ln -s /usr/local/freeswitch/conf /etc/freeswitch
    sudo ln -s /usr/local/freeswitch/bin/fs_cli /usr/bin/fs_cli
    sudo ln -s /usr/local/freeswitch/bin/freeswitch /usr/sbin/freeswitch

    # Create user 'freeswitch'
    # Add it to group 'freeswitch'
    # Change owner and group of the freeswitch installation
    cd /usr/local
    groupadd freeswitch
    adduser --quiet --system --home /usr/local/freeswitch --gecos "FreeSWITCH open source softswitch" --ingroup freeswitch freeswitch --disabled-password
    chown -R freeswitch:freeswitch /usr/local/freeswitch/
    chown -R freeswitch:freeswitch /etc/freeswitch/
    chmod -R ug=rwX,o= /usr/local/freeswitch/
    chmod -R u=rwx,g=rx /usr/local/freeswitch/bin/*

    # Reboot here - make sure to add service file as well. otherwise you have to trigger this via /usr/sbin/freeswitch
}

reboot_selection(){
    echo "Install done. Press any key to reboot..."
    read -s -n 1
    echo "You pressed a key! Continuing..."
    sudo reboot
}


banner_start() {
    clear;
    echo "Installing FreeSWITCH on $distro_name"
    echo "Standby"
    echo;
}

banner_end() {
    clear;
    echo "Hopefully FreeSWITCH is now installed on $distro_name"
    echo "Run fs_cli to be sure after rebooting"
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