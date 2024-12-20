#!/bin/bash

# Define color codes
RED='\033[1;31m'
GRN='\033[1;32m'
BLU='\033[1;34m'
YEL='\033[1;33m'
PUR='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m'

# Get drive name
get_drive_name() {
    while true; do
        if [ -d "/Volumes/Macintosh HD" ]; then
            echo "Macintosh HD"
            return
        else
            read -p "Default drive name 'Macintosh HD' not found. Please enter your drive name: " drive_name
            if [ -d "/Volumes/${drive_name}" ]; then
                echo "$drive_name"
                return
            else
                echo -e "${RED}Error: The drive '${drive_name}' was not found. Please try again.${NC}" >&2
            fi
        fi
    done
}

# Display header
echo -e "${CYAN}Bypass MDM By Assaf Dori (assafdori.com)${NC}"
echo ""

# Get drive name
DRIVE_NAME=$(get_drive_name)
DATA_VOLUME="${DRIVE_NAME} - Data"

# Prompt user for choice
PS3='Please enter your choice: '
options=("Bypass MDM from Recovery" "Reboot & Exit")
select opt in "${options[@]}"; do
    case $opt in
        "Bypass MDM from Recovery")
            # Bypass MDM from Recovery
            echo -e "${YEL}Bypass MDM from Recovery"
            if [ -d "/Volumes/${DATA_VOLUME}" ]; then
                diskutil rename "${DATA_VOLUME}" "Data"
            fi

            # Create Temporary User
            echo -e "${NC}Create a Temporary User"
            read -p "Enter Temporary Fullname (Default is 'Apple'): " realName
            realName="${realName:=Apple}"
            read -p "Enter Temporary Username (Default is 'Apple'): " username
            username="${username:=Apple}"
            read -p "Enter Temporary Password (Default is '1234'): " passw
            passw="${passw:=1234}"

            # Create User
            dscl_path='/Volumes/Data/private/var/db/dslocal/nodes/Default'
            echo -e "${GREEN}Creating Temporary User"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UserShell "/bin/zsh"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" RealName "$realName"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UniqueID "501"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" PrimaryGroupID "20"
            mkdir "/Volumes/Data/Users/$username"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" NFSHomeDirectory "/Users/$username"
            dscl -f "$dscl_path" localhost -passwd "/Local/Default/Users/$username" "$passw"
            dscl -f "$dscl_path" localhost -append "/Local/Default/Groups/admin" GroupMembership $username

            # Block MDM domains
            echo "0.0.0.0 deviceenrollment.apple.com" >> "/Volumes/${DRIVE_NAME}/etc/hosts"
            echo "0.0.0.0 mdmenrollment.apple.com" >> "/Volumes/${DRIVE_NAME}/etc/hosts"
            echo "0.0.0.0 iprofiles.apple.com" >> "/Volumes/${DRIVE_NAME}/etc/hosts"
            echo -e "${GRN}Successfully blocked MDM & Profile Domains"

            # Remove configuration profiles
            touch /Volumes/Data/private/var/db/.AppleSetupDone
            rm -rf "/Volumes/${DRIVE_NAME}/var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord"
            rm -rf "/Volumes/${DRIVE_NAME}/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound"
            touch "/Volumes/${DRIVE_NAME}/var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled"
            touch "/Volumes/${DRIVE_NAME}/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound"

            echo -e "${GRN}MDM enrollment has been bypassed!${NC}"
            echo -e "${NC}Exit terminal and reboot your Mac.${NC}"
            break
            ;;
        "Reboot & Exit")
            # Reboot & Exit
            echo "Rebooting..."
            reboot
            break
            ;;
        *) echo "Invalid option $REPLY" ;;
    esac
done
