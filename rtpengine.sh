#!/bin/bash


sudo apt-get install -y lsb-release
REL=10.5
# version-8.5 # older LTS release
# version-9.5 # old LTS release
# version-10.5 # latest LTS release
# version-11.3 # previous newest release
# version-11.4 # current newest release
# version-latest # always the latest and newest release
# version-beta # daily builds of the current git master


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
    echo "deb [signed-by=/usr/share/keyrings/dfx.at-rtpengine-archive-keyring.gpg] https://rtpengine.dfx.at/$REL $DISTRO_CODENAME main" | sudo tee /etc/apt/sources.list.d/dfx.at-rtpengine.list
    sudo apt install linux-headers-$(uname -r)
    sudo apt update
    sudo apt install -y rtpengine
}

# latest Ubuntu release: IP Tables issues here so no kernel forwarding.
setup_ubuntu() {
    echo "No iptables-dev in focal/Ubuntu since 20.04"
    echo "You are SOL unless you don't want kernel forwarding, then you are in luck."
}

reboot_selection(){
    echo "Install done. Press any key to reboot..."
    read -s -n 1
    echo "You pressed a key! Rebooting now..."
    sudo reboot
}


banner_start() {
    clear;
    echo "Installing RTPengine on $distro_name"
    echo "Standby"
    echo;
}

banner_end() {
    clear;
    echo "Hopefully RTPengine is now installed on $distro_name"
    echo "Run rtpengine -v to be sure after rebooting"
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