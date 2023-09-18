#!/bin/bash

sudo apt-get install -y lsb-release
# apt versions are different per distro - check with apt-cache policy janus to check which one you get
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
               20.04* | 22.04* ) SETUP_ENTRYPOINT="setup_apt"
                    return 0 ;; # Suported Distribution
               *  ) return 1 ;; # Unsupported Distribution
             esac
             ;;
    Debian ) case "$distro_version" in
            10* | 11* | 12* ) SETUP_ENTRYPOINT="setup_apt"
                    return 0 ;; # Suported Distribution
               *  ) return 1 ;; # Unsupported Distribution
             esac
             ;;
    *      ) return 1 ;; # Unsupported Distribution
 esac
}


setup_apt() {
  sudo apt-get install -y janus 
  VERSION="janus --version"
}

setup_manual() {
  apt update
# magic dust here
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
  echo "Installing Janus $VERSION on $distro_name"
  echo "Standby"
  echo;
}

banner_end() {
  clear;
  echo "Hopefully Janus $VERSION is now installed on $distro_name"
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
