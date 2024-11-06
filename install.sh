#!/bin/bash

# NoMachine Installer Script
# ----------------------------
# This script sets up a Linux VPS environment with options for installing 
# desktop environments, NoMachine for remote access, swapfile setup, 
# and network and firewall configurations.

echo "###############################################################"
echo "#                                                             #"
echo "#                NoMachine Installer                          #"
echo "#                                                             #"
echo "###############################################################"

# Function to prompt and execute a command with user confirmation
function run_cmd() {
  echo -e "\n> Command: $1"
  read -p "Proceed? (Y/n) " choice
  if [[ "$choice" == "n" || "$choice" == "N" ]]; then
    echo "Bypassing..."
  else 
    echo "Executing command..."
    eval "$1"
  fi
}

####################################################

# Prompt user to choose a desktop environment with descriptions
function choose_desktop_environment() {
  echo -e "\nChoose a desktop environment to install:"
  echo "1. Ubuntu Desktop - Full-featured (Requires at least 4GB RAM)"
  echo "2. LXQt - Lightweight, minimal resource usage"
  echo "3. Xfce - Lightweight with a traditional desktop feel"
  echo "4. KDE Plasma - Feature-rich, requires moderate resources"
  read -p "Enter the number of your choice: " env_choice
  
  case $env_choice in
    1) 
      desktop_pkg="ubuntu-desktop"
      ;;
    2)
      desktop_pkg="lxqt"
      ;;
    3)
      desktop_pkg="xfce4"
      ;;
    4)
      desktop_pkg="kde-plasma-desktop"
      ;;
    *)
      echo "Invalid choice. Defaulting to Ubuntu Desktop."
      desktop_pkg="ubuntu-desktop"
      ;;
  esac

  run_cmd "sudo apt-get install $desktop_pkg -y"
}

####################################################

# Function to create a 2GB swapfile for improved performance on low-memory VPS
function create_swapfile() {
  echo -e "\nCreating a 2GB swapfile at /swapfile if it does not exist."
  read -p "Proceed with swapfile setup? (Y/n) " choice
  if [[ "$choice" == "n" || "$choice" == "N" ]]; then
    echo "Skipping swapfile setup."
  else 
    if [ -f /swapfile ]; then
      echo "/swapfile already exists. Skipping..."
    else 
      echo "Building /swapfile..."
      cd /
      sudo dd if=/dev/zero of=/swapfile bs=1M count=2048 status=progress
      sudo chmod 600 /swapfile
      sudo mkswap /swapfile
      sudo swapon /swapfile
      echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    fi
  fi
}

####################################################

# Replace VPS provider-controlled networking with OS-controlled network configuration
function configure_networking() {
  echo -e "\nConfiguring OS-controlled networking."
  read -p "Proceed with network configuration? (Y/n) " choice
  if [[ "$choice" == "n" || "$choice" == "N" ]]; then
    echo "Skipping network configuration."
  else 
    sudo mmv '/etc/netplan/*.yaml' '/etc/netplan/#1.bak'
    sudo wget https://cloudtechlinks.com/V47-cloudtech-dot-yaml --output-document=/etc/netplan/v47-cloudtech-youtube-video.yaml
  fi
}

####################################################

# Install NoMachine for remote desktop access
function install_nomachine() {
  echo -e "\nInstalling NoMachine for remote desktop access."
  read -p "Proceed with NoMachine installation? (Y/n) " choice
  if [[ "$choice" == "n" || "$choice" == "N" ]]; then
    echo "Skipping NoMachine installation."
  else 
    sudo wget https://download.nomachine.com/download/8.14/Linux/nomachine_8.14.2_1_amd64.deb
    sudo apt install -f ./nomachine_8.14.2_1_amd64.deb
  fi
}

####################################################

# Install and configure UFW firewall
function configure_firewall() {
  echo -e "\nSetting up UFW (Uncomplicated Firewall) and opening necessary ports."
  read -p "Proceed with UFW setup? (Y/n) " choice
  if [[ "$choice" == "n" || "$choice" == "N" ]]; then
    echo "Skipping UFW setup."
  else 
    sudo apt-get install ufw -y
    sudo ufw allow 22     # Allow SSH
    sudo ufw allow 4000   # Allow NoMachine default port
    sudo ufw enable
    sudo ufw status numbered
  fi
}

####################################################

# Create a dedicated user for NoMachine and lock the root user
function setup_nomachine_user() {
  echo -e "\nCreating a NoMachine user and locking the root user."
  read -p "Proceed with user setup? (Y/n) " choice
  if [[ "$choice" == "n" || "$choice" == "N" ]]; then
    echo "Skipping NoMachine user setup."
  else 
    sudo adduser nomachine
    sudo usermod -aG sudo,adm,lp,sys,lpadmin nomachine
    sudo passwd --delete --lock rootuser
  fi
}

####################################################

# Main Script Routine
# ---------------------
run_cmd "sudo apt-get update" 
run_cmd "sudo apt-get upgrade -y" 
choose_desktop_environment
run_cmd "sudo apt-get install stacer -y"
run_cmd "sudo apt-get install mmv -y"
run_cmd "sudo apt-get install firefox -y"
run_cmd "sudo apt-get install qdirstat -y"

create_swapfile
configure_networking
install_nomachine
configure_firewall
setup_nomachine_user

run_cmd "sudo reboot"

echo -e "\nNoMachine Installer script completed."
