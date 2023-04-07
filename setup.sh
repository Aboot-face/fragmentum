#!/bin/bash

# Colors for status messages
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if script is being run with sudo
if [[ $(id -u) -ne 0 ]]; then
  echo -e "${RED}This script requires superuser privilege.${NC}"
  exit 1
fi

# Check if repository is updated and update it if not
echo -e "${CYAN}Checking for repository updates...${NC}"
apt update -y &> /dev/null
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Repository is up-to-date.${NC}"
else
  echo -e "${YELLOW}Repository is updating...${NC}"
  spin='-\|/'
  i=0
  while ! apt update -y &> /dev/null; do
    printf "\r${YELLOW}%s${NC} " "${spin:$i++%${#spin}:1}"
    sleep 0.1
  done
  echo -e "\n${GREEN}Repository update complete.${NC}"
fi

# Upgrade all packages
echo -e "${CYAN}Upgrading packages...${NC}"
spin='-\|/'
i=0
while ! apt upgrade -y &> /dev/null; do
  printf "\r${YELLOW}%s${NC} " "${spin:$i++%${#spin}:1}"
  sleep 0.1
done
echo -e "\n${GREEN}Package upgrade complete.${NC}"

# List of required programs
programs=(ruby)

# Check if each program is installed and install if necessary
for program in "${programs[@]}"; do
  if ! command -v "$program" > /dev/null; then
    echo -e "${CYAN}Installing $program...${NC}"
    apt install -y "$program" &> /dev/null
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}$program installation complete.${NC}"
    else
      echo -e "${RED}$program installation failed.${NC}"
    fi
  else
    echo -e "${GREEN}$program is already installed.${NC}"
  fi
done

# List of required gems
gems=(tty-prompt nokogiri open-uri)

# Check if each gem is installed and install if necessary
for gem in "${gems[@]}"; do
  if ! gem list | grep -q "$gem"; then
    echo -e "${CYAN}Installing $gem...${NC}"
    gem install "$gem" &> /dev/null
    if [ $? -eq 0 ]; then
      echo -e "${GREEN}$gem installation complete.${NC}"
    else
      echo -e "${RED}$gem installation failed.${NC}"
    fi
  else
    echo -e "${GREEN}$gem is already installed.${NC}"
  fi
done
