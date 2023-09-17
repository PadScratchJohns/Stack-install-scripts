#!/bin/bash

sudo apt-get install -y lsb-release
# Choose RTPengine version 
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
  local distro_name=$(lsb_release -si)
  local distro_version=$(lsb_release -sr)
  local distro_codename=$(lsb_release -sc)
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

# Latest debian release in apt is 10.5 stable
setup_debian() {
    apt update
    apt install -y rtpengine
}

# latest Ubuntu release: not from apt, but from a ppa 
setup_ubuntu() {
    echo "No iptables-dev in focal/Ubuntu since 20.04"
    echo "But it is in 23.04 - so just wait for it if you wanna use Ubuntu https://manpages.ubuntu.com/manpages/lunar/en/man1/rtpengine.1.html"
    echo "For now we are using a ppa unless it is in Ubuntu LTS"
    sudo add-apt-repository ppa:davidlublink/rtpengine
    sudo apt update
    sudo apt-get install -y ngcp-rtpengine
}

reboot_selection() {
  echo "Install done. Press 1 to reboot..."
  echo "Otherwise press any other key to exit"
  options=("1")
  select choice in "${options[@]}"
  do 
    case $choice in
      "1")
        echo "Rebooting now..."
        sudo reboot
        break
        ;;
      *)
        echo "You pressed a key! Exiting..."
        break
        ;;
  esac
  done
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