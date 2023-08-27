#!/bin/bash

sudo apt-get install -y libluajit-5.1-common libluajit-5.1-dev lsb-release wget curl git

[[ "$TRACE" ]] && { set -x; set -o functrace; }

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

logfile="/tmp/$(basename $0).$$.log"
exec > >(tee -ia $logfile)
exec 2> >(tee -ia $logfile >&2)

trap 'exit 1' TERM
my_pid=$$


# HOMER Options, defaults
DB_USER="homer_user"
DB_PASS=$(dd if=/dev/urandom bs=1 count=20 2>/dev/null | base64 | sed 's/[=\+//]//g')
DB_HOST="localhost"
LISTEN_PORT="9060"
CHRONOGRAF_LISTEN_PORT="8888"
INSTALL_INFLUXDB=""

OS=`uname -s`
HOME_DIR=$HOME
CURRENT_DIR=`pwd`
ARCH=`uname -m`

#### NO CHANGES BELOW THIS LINE!

VERSION=7.7
SETUP_ENTRYPOINT=""
OS=""
DISTRO=""
DISTRO_VERSION=""

######################################################################
#
# Start of function definitions
#
######################################################################
is_root_user() {
  # Function to check that the effective user id of the user running
  # the script is indeed that of the root user (0)

  if [[ $EUID != 0 ]]; then
    return 1
  fi
  return 0
}

have_commands() {
  # Function to check if we can find the command(s) passed to us
  # in the systems PATH
  local cmd_list="$1"
  local -a not_found=()

  for cmd in $cmd_list; do
    command -v $cmd >/dev/null 2>&1 || not_found+=("$cmd")
  done

  if [[ ${#not_found[@]} == 0 ]]; then
    # All commands found
    return 0
  else
    # Something not found
    return 1
  fi
}

locate_cmd() {
  # Function to return the full path to the cammnd passed to us
  # Make sure it exists on the system first or else this exits
  # the script execution
  local cmd="$1"
  local valid_cmd=""
  # valid_cmd=$(hash -t $cmd 2>/dev/null)
  valid_cmd=$(command -v $cmd 2>/dev/null)
  if [[ ! -z "$valid_cmd" ]]; then
    echo "$valid_cmd"
  else
    echo "HALT: Please install package for command '$cmd'"
    /bin/kill -s TERM $my_pid
  fi
  return 0
}

is_supported_os() {
  # Function to see if the OS is a supported type, the 1st
  # parameter passed should be the OS type to check. The bash
  # shell has a built in variable "OSTYPE" which should be
  # sufficient for a start

  local os_type=$1

  case "$os_type" in
    linux* ) OS="Linux"
             minimal_command_list="lsb_release wget curl git"
             if ! have_commands "$minimal_command_list"; then
               echo "ERROR: You need the following minimal set of commands installed:"
               echo ""
               echo "       $minimal_command_list"
               echo ""
               exit 1
             fi
             detect_linux_distribution # Supported OS, Check if supported distro.
             return ;;
    *      ) return 1 ;;               # Unsupported OS
  esac
}

detect_linux_distribution() {
  # Function to see if a specific linux distribution is supported by this script
  # If it is supported then the global variable SETUP_ENTRYPOINT is set to the
  # function to be executed for the system setup

  local cmd_lsb_release=$(locate_cmd "lsb_release")
  local distro_name=$($cmd_lsb_release -si)
  local distro_version=$($cmd_lsb_release -sr)
  DISTRO="$distro_name"
  DISTRO_VERSION="$distro_version"

  case "$distro_name" in
    Ubuntu ) case "$distro_version" in
               20.04* | 22.04* ) SETUP_ENTRYPOINT="setup_debian"
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

check_status() {
  # Function to check and do something with the return code of some command

  local return_code="$1"

  if [[ $return_code != 0 ]]; then
    echo "HALT: Return code of command was '$return_code', aborting."
    echo "Please check the log above and correct the issue."
    exit 1
  fi
}

banner_start() {
  # This is the banner displayed at the start of script execution

  clear;
  echo "**************************************************************"
  echo "                                                              "
  echo "      ,;;;;;,       HOMER SIP CAPTURE (http://sipcapture.org) "
  echo "     ;;;;;;;;;.     Single-Node Auto-Installer (beta $VERSION)"
  echo "   ;;;;;;;;;;;;;                                              "
  echo "  ;;;;  ;;;  ;;;;   <--------------- INVITE ---------------   "
  echo "  ;;;;  ;;;  ;;;;    --------------- 200 OK --------------->  "
  echo "  ;;;;  ...  ;;;;                                             "
  echo "  ;;;;       ;;;;   WARNING: This installer is intended for   "
  echo "  ;;;;  ;;;  ;;;;   dedicated/vanilla OS setups without any   "
  echo "  ,;;;  ;;;  ;;;;   customization and with default settings   "
  echo "   ;;;;;;;;;;;;;                                              "
  echo "    :;;;;;;;;;;     THIS SCRIPT IS PROVIDED AS-IS, USE AT     "
  echo "     ^;;;;;;;^      YOUR *OWN* RISK, REVIEW LICENSE & DOCS    "
  echo "                                                              "
  echo "**************************************************************"
  echo;
}

banner_end() {
  # This is the banner displayed at the end of script execution

  local cmd_ip=$(locate_cmd "ip")
  local cmd_head=$(locate_cmd "head")
  local cmd_awk=$(locate_cmd "awk")

  local my_primary_ip=$($cmd_ip route get 8.8.8.8 | $cmd_head -1 | grep -Po '(\d+\.){3}\d+' | tail -n1)

  echo "*************************************************************"
  echo "      ,;;;;,                                                 "
  echo "     ;;;;;;;;.     Congratulations! HOMER has been installed!"
  echo "   ;;;;;;;;;;;;                                              "
  echo "  ;;;;  ;;  ;;;;   <--------------- INVITE ---------------   "
  echo "  ;;;;  ;;  ;;;;    --------------- 200 OK --------------->  "
  echo "  ;;;;  ..  ;;;;                                             "
  echo "  ;;;;      ;;;;   Your system should be now ready to rock!"
  echo "  ;;;;  ;;  ;;;;   Please verify/complete the configuration  "
  echo "  ,;;;  ;;  ;;;;   files generated by the installer below.   "
  echo "   ;;;;;;;;;;;;                                              "
  echo "    :;;;;;;;;;     THIS SCRIPT IS PROVIDED AS-IS, USE AT     "
  echo "     ;;;;;;;;      YOUR *OWN* RISK, REVIEW LICENSE & DOCS    "
  echo "                                                             "
  echo "*************************************************************"
  echo
  echo "     * Configuration Files:"
  echo "         '/usr/local/homer/etc/webapp_config.json'"
  echo "         '/etc/heplify-server.toml'"
  echo
  echo "     * Start/stop HOMER Application Server:"
  echo "         'systemctl start|stop homer-app'"
  echo
  echo "     * Start/stop HOMER SIP Capture Server:"
  echo "         'systemctl start|stop heplify-server'"
  echo
  echo "     * Start/stop HOMER SIP Capture Agent:"
  echo "         'systemctl start|stop heplify'"
  echo
  echo "     * Access HOMER UI:"
  echo "         http://$my_primary_ip:443"
  echo "         [default: admin/sipcapture]"
  echo
  echo "     * Send HEP/EEP Encapsulated Packets to:"
  echo "         hep://$my_primary_ip:$LISTEN_PORT"
  echo
  echo "     * Prometheus Metrics URL:"
  echo "         http://$my_primary_ip:9096/metrics"
  echo
  if [[ "$INSTALL_INFLUXDB" =~ y|yes|Y|Yes|YES ]] ; then
    echo "     * Access InfluxDB UI:"
    echo "         http://$my_primary_ip:$CHRONOGRAF_LISTEN_PORT"
    echo
  fi
  echo
  echo "**************************************************************"
  echo
  echo " IMPORTANT: Do not forget to send Homer node some traffic! ;) "
  echo " For our capture agents, visit http://github.com/sipcapture "
  echo " For more help and information visit: http://sipcapture.org "
  echo
  echo "**************************************************************"
  echo " Installer Log saved to: $logfile "
  echo
}

start_app() {
  # This is the main app

  banner_start

  if ! is_root_user; then
    echo "ERROR: You must be the root user. Exiting..." 2>&1
    echo  2>&1
    exit 1
  fi

  if ! is_supported_os "$OSTYPE"; then
    echo "ERROR:"
    echo "Sorry, this Installer does not support your OS yet!"
    echo "Please follow instructions in the HOW-TO for manual installation & setup"
    echo "available at http://sipcapture.org"
    echo
    exit 1
  else
    unalias cp 2>/dev/null
    $SETUP_ENTRYPOINT
    banner_end
  fi
  exit 0
}

create_postgres_user_database(){
  cwd=$(pwd)
  cd /tmp
  sudo -u postgres psql -c "CREATE DATABASE homer_config;"
  sudo -u postgres psql -c "CREATE DATABASE homer_data;"
  sudo -u postgres psql -c "CREATE ROLE ${DB_USER} WITH SUPERUSER LOGIN PASSWORD '$DB_PASS';"
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE homer_config to homer_user;"
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE homer_data to homer_user;"
  cd $cwd
}

install_homer(){

  local cmd_curl=$(locate_cmd "curl")
  local cmd_sed=$(locate_cmd "sed")
  echo "Installing Homer-App"
  if [ -f /etc/debian_version ]; then
	  local cmd_apt_get=$(locate_cmd "apt-get")
	  $cmd_curl -s https://packagecloud.io/install/repositories/qxip/sipcapture/script.deb.sh | sudo bash
	  $cmd_apt_get install homer-app heplify-server -y
  fi

  $cmd_sed -i -e "s/homer_user/$DB_USER/g" /usr/local/homer/etc/webapp_config.json
  $cmd_sed -i -e "s/homer_password/$DB_PASS/g" /usr/local/homer/etc/webapp_config.json
  $cmd_sed -i "s/9080/443/g" /usr/local/homer/etc/webapp_config.json
  
  local cmd_homerapp=$(locate_cmd "homer-app")
  $cmd_homerapp -create-table-db-config
  $cmd_homerapp -populate-table-db-config

  $cmd_sed -i -e "s/DBUser\s*=\s*\"postgres\"/DBUser          = \"$DB_USER\"/g" /etc/heplify-server.toml
  $cmd_sed -i -e "s/DBPass\s*=\s*\"\"/DBPass          = \"$DB_PASS\"/g" /etc/heplify-server.toml
  $cmd_sed -i -e "s/PromAddr\s*=\s*\"\"/PromAddr        = \"0.0.0.0:9096\"/g" /etc/heplify-server.toml

  sudo systemctl enable homer-app
  sudo systemctl restart homer-app
  sudo systemctl status homer-app

  sudo systemctl enable heplify-server
  sudo systemctl restart heplify-server
  sudo systemctl status heplify-server

}
# DB setup
setup_influxdb(){
if [ -f /etc/debian_version ]; then

    echo "DEBIAN Platform detected!"

    sudo apt-get install -y apt-transport-https
    wget -q https://repos.influxdata.com/influxdata-archive_compat.key

    echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null

    echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list

    echo "Installing TICK stack ..."
    sudo apt-get update && sudo apt-get install influxdb kapacitor chronograf telegraf -y

    yes | cp $CURRENT_DIR/telegraf.conf /etc/telegraf/telegraf.conf

    sudo systemctl restart influxdb
    sudo systemctl restart kapacitor
    sudo systemctl restart chronograf

    sudo systemctl enable influxdb
    sudo systemctl enable kapacitor
    sudo systemctl enable chronograf
    sudo systemctl enable telegraf

    sudo systemctl restart telegraf

    echo "done!"
fi

}

# Debian/Ubuntu install latest postgresql from apt
setup_debian() {
  local base_pkg_list="software-properties-common make cmake gcc g++ dirmngr sudo python3-dev net-tools"
  local cmd_apt_get=$(locate_cmd "apt-get")
  local cmd_wget=$(locate_cmd "wget")
  local cmd_apt_key=$(locate_cmd "apt-key")
  local cmd_service=$(locate_cmd "systemctl")
  local cmd_curl=$(locate_cmd "curl")
  local cmd_wget=$(locate_cmd "wget")

  $cmd_apt_get update && $cmd_apt_get upgrade -y

  $cmd_apt_get install -y postgresql postgresql-contrib

  $cmd_service daemon-reload
  $cmd_service enable postgresql
  $cmd_service restart postgresql

  create_postgres_user_database

  install_homer

  printf "Would you like to install influxdb and chronograf? [y/N]: "
  read INSTALL_INFLUXDB
  case "$INSTALL_INFLUXDB" in
          "y"|"yes"|"Y"|"Yes"|"YES") setup_influxdb;;
          *) echo "...... [ Exiting ]"; echo;;
  esac
}

######################################################################
#
# End of function definitions
#
######################################################################

######################################################################
#
# Start of main script
#
######################################################################

[[ "$0" == "$BASH_SOURCE" ]] && start_app
