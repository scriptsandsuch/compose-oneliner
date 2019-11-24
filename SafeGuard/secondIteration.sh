#! /bin/bash

#This is the second Iteration of the SafeGuard Installation Script.
# Meant to be run automatically on startup after the first part has rebooted.
# Written By Gilad Ben-Nun
SecondIteration(){
SecondIteration(){
local printCyan=$'\e[1;36m'
local printWhite=$'\e[0m'
local printRed=$'\e[1;31m'
local printGreen=$'\e[1;32m'
dockerfile=/home/user/docker-compose/1.20.0/docker-compose.yml
echo "Dockerfile set as:"
echo ${dockerfile}
local isInFile=$(cat /home/user/docker-compose/1.20.0/env/broadcaster.env | grep -c "/moxa_e1214.sh")
##check if script has been run before, to not add duplicates
if [ $isInFile -eq 0 ]; then
	tee -a /home/user/docker-compose/1.20.0/env/broadcaster.env <<'EOF'
	## Modbus plugin integration
	BCAST_MODBUS_IS_ENABLED=true
	BCAST_MODBUS_CMD_PATH=/home/user/moxa-config/moxa_e1214.sh
	BCAST_MODBUS_CAMERA_LIST_PATH=/home/user/moxa-config/cameraList.json
EOF
else
	echo "It seems the script has been run already, skipping broadcaster edits..."
fi
##doesnt hurt to run again since it's replacing not appending.
line=$(grep -nF broadcaster.tls.ai /home/user/docker-compose/1.20.0/docker-compose.yml  | awk -F: '{print $1}') ; line=$((line+2))
host=$(hostname)
sed -i "${line}i \      - \/home\/user\/moxa-config:\/home\/user\/moxa-config" ${dockerfile}
sed -i "s|nginx-\${node_name:-localnode}.tls.ai|nginx-$host.tls.ai|g" ${dockerfile}
sed -i "s|api.tls.ai|api-$host.tls.ai|g" ${dockerfile} && SuccesfulPrint "Modify docker files" || FailedPrint "Modify docker files"
cd /home/user/docker-compose/1.20.0/ 
docker-compose -f docker-compose.yml up -d
sleep 5
footprint=docker exec -it $(docker ps | grep backend | awk '{print $1}') license-ver -o
echo "2" > /opt/sg.f ##marks second iteration has happened
sed '/gnome-terminal/d' /home/user/.profile && SuccesfulPrint "Remove startup line" ## to test
cat << "EOF"
 _____   ____  _   _ ______ 
|  __ \ / __ \| \ | |  ____|
| |  | | |  | |  \| | |__   
| |  | | |  | | . ` |  __|  
| |__| | |__| | |\  | |____ 
|_____/ \____/|_| \_|______|

EOF
}

SuccesfulPrint(){
local printGreen=$'\e[1;32m'
local printWhite=$'\e[0m'
	echo -e "=================================================================="
	echo -e "                    $1 ....${green}Success${white}                  "
	echo -e "=================================================================="
}

FailedPrint(){
local printRed=$'\e[1;31m'
local printWhite=$'\e[0m'
	echo -e "=================================================================="
	echo -e "                    $1 ....${red}Failed!${white}                  "
	echo -e "=================================================================="
}
if [ "$EUID" -ne 0 ]; then
	echo "Could not obtain root access.."
	echo "Is your password set correctly?"
	echo "Please change your password and run the script manually"
	echo "Exiting..."
	exit 1
fi
if [[ -f "/home/user/docker-compose/1.20.0/docker-compose.yml" ]]; then
		SecondIteration
	else
		echo "App not installed, please Install it and try again"
		echo "Exiting..."
		exit 1;
	fi