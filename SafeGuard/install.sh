#! /bin/bash
before_reboot() {
if [[ -d "/home/user/" ]]; then
	cd /home/user/Downloads
else
	echo "You have set the wrong username for the ubuntu installation, please reinstall with a user named user"
	exit 1
fi
local token="$1"
echo "token is:"
echo ${token}
if [[ -z ${token} ]]; then 
    echo
    echo "You must provide a docker registry token!"
    exit 1 
fi
wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
wget https://github.com/scriptsandsuch/compose-oneliner/releases/download/SG/FaceSearch-1.20.0-linux-x86_64.AppImage
chmod +x FaceSearch-1.20.0-linux-x86_64.AppImage && chown user FaceSearch-1.20.0-linux-x86_64.AppImage
apt install vlc curl vim htop net-tools git -y && SuccesfulPrint "Utilities"
git clone https://github.com/scriptsandsuch/compose-oneliner
apt install ./team* -y && SuccesfulPrint "TeamViewer"

##moxa set up
moxadir=/home/user/moxa-config/
mkdir $moxadir
mv /home/user/Downloads/sg-script/moxa_e1214.sh $moxadir
mv /home/user/Downloads/sg-script/cameraList.json $moxadir
chmod +x /home/user/moxa-config/*

wget -qO- https://raw.githubusercontent.com/scriptsandsuch/compose-oneliner/development/compose-oneliner.sh | bash -s -- -b 1.20.0 -k ${token}
ln -s /home/user/docker-compose/1.20.0/docker-compose-local-gpu.yml /home/user/docker-compose/1.20.0/docker-compose.yml && SuccesfulPrint "Create Symbolic Link"
echo "1" > /opt/sg.f ##flag if the script has been run 
}


after_reboot(){
##edit env and yml
dockerfile = "/home/user/docker-compose/1.20.0/docker-compose.yml"
tee -a /home/user/docker-compose/1.20.0/env/broadcaster.env <<'EOF'
## Modbus plugin integration
BCAST_MODBUS_IS_ENABLED=true
BCAST_MODBUS_CMD_PATH=/home/user/moxa-config/moxa_e1214.sh
BCAST_MODBUS_CAMERA_LIST_PATH=/home/user/moxa-config/cameraList.json
EOF
line=$(grep -nF broadcaster.tls.ai /home/user/docker-compose/1.20.0/docker-compose.yml  | awk -F: '{print $1}') ; line=$((line+2))
host=$(hostname)
sed -i "${line}i \      - \/home\/user\/moxa-config:\/home\/user\/moxa-config" $dockerfile
sed -i "s|nginx-\${node_name:-localnode}.tls.ai|nginx-$host.tls.ai|g" $dockerfile
sed -i "s|api.tls.ai|api-$host.tls.ai|g" $dockerfile && SuccesfulPrint "Modify docker files"
cd /home/user/docker-compose/1.20.0/
docker-compose -f ${dockerfile} && docker-compose up-d

echo "DONE!"
echo "Please reboot your machine"
}
SuccesfulPrint(){
local red=`tput setaf 1`
local green=`tput setaf 2`
local reset=`tput sgr0`
	echo "=================================================================="
	echo "                    $1 ....{green}success{reset}                  "
	echo "=================================================================="
}



##Main

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
if [ "$EUID" -ne 0 ]; then	
	echo "Please run this script as root"
	echo "Exiting..."
	exit
fi
if [[ -f "/opt/sg.f" ]]; then
	if [[ -f "/home/user/docker-compose/1.20.0/docker-compose.yml"]]; then
		after_reboot
	else
		echo "App not installed, please Install it and try again"
		echo "Exiting..."
		exit
	fi
else
	before_reboot "$1"
fi
