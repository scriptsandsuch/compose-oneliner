#! /bin/bash
before_reboot() {
if [[ -d "/home/user/" ]]; then
	cd /home/user/Downloads
else
	echo "You have set the wrong username for the ubuntu installation, please reinstall with a user named user"
	exit 1
fi
local token="$1"
echo "Token is:"
echo -e "$'\e[1;36m'${token}$'\e[0m'"
if [[ -z ${token} ]]; then 
    echo
    echo "You must provide a docker registry token!"
    echo "Exiting..."
    exit 1 
fi
dpkg -a --configure
wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
wget https://github.com/scriptsandsuch/compose-oneliner/releases/download/SG/FaceSearch-1.20.0-linux-x86_64.AppImage
mv FaceSearch-1.20.0-linux-x86_64.AppImage /home/user/Desktop/SafeGuard.AppImage
chmod +x /home/user/Desktop/SafeGuard.AppImage && chown /home/user/Desktop/SafeGuard.AppImage
apt install vlc curl vim htop net-tools git -y -qq > /dev/null && SuccesfulPrint "Utilities"
git clone https://github.com/scriptsandsuch/compose-oneliner > /dev/null && SuccesfulPrint "Repo Cloned"
apt install ./team* -y -qq > /dev/null && SuccesfulPrint "TeamViewer"

##moxa set up
moxadir=/home/user/moxa-config/
mkdir ${moxadir}
mv /home/user/Downloads/compose-oneliner/SafeGuard/moxa_e1214.sh ${moxadir}
mv /home/user/Downloads/compose-oneliner/SafeGuard/cameraList.json ${moxadir} && SuccesfulPrint "Moxa setup" || FailedPrint "Moxa setup"
chmod +x ${moxadir}* && chown user ${moxadir}*

cat << "EOF"
 _____              _          _  _  _                    _____          __        _____                         _          
|_   _|            | |        | || |(_)                  / ____|        / _|      / ____|                       | |         
  | |   _ __   ___ | |_  __ _ | || | _  _ __    __ _    | (___    __ _ | |_  ___ | |  __  _   _   __ _  _ __  __| |         
  | |  | '_ \ / __|| __|/ _` || || || || '_ \  / _` |    \___ \  / _` ||  _|/ _ \| | |_ || | | | / _` || '__|/ _` |         
 _| |_ | | | |\__ \| |_| (_| || || || || | | || (_| |    ____) || (_| || | |  __/| |__| || |_| || (_| || |  | (_| | _  _  _ 
|_____||_| |_||___/ \__|\__,_||_||_||_||_| |_| \__, |   |_____/  \__,_||_|  \___| \_____| \__,_| \__,_||_|   \__,_|(_)(_)(_)
                                                __/ |                                                                       
                                               |___/                                                                        
EOF
wget -qO- https://raw.githubusercontent.com/scriptsandsuch/compose-oneliner/development/compose-oneliner.sh | bash -s -- -b 1.20.0 -k ${token}
ln -s /home/user/docker-compose/1.20.0/docker-compose-local-gpu.yml /home/user/docker-compose/1.20.0/docker-compose.yml && SuccesfulPrint "Create Symbolic Link" || FailedPrint "Create Symbolic Link"
echo "1" > /opt/sg.f ##flag if the script has been run 

##make script auto run after login
tee -a /home/user/.profile <<'EOF' && SuccesfulPrint "Startup added"
gnome-terminal -e 'bash -c "/home/user/Downloads/compose-oneliner/SafeGuard/install.sh; exec bash"'
EOF
}


after_reboot(){
##edit env and ymld
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
##doesn't hurt to run again since it's replacing not appending.
line=$(grep -nF broadcaster.tls.ai /home/user/docker-compose/1.20.0/docker-compose.yml  | awk -F: '{print $1}') ; line=$((line+2))
host=$(hostname)
sed -i "${line}i \      - \/home\/user\/moxa-config:\/home\/user\/moxa-config" ${dockerfile}
sed -i "s|nginx-\${node_name:-localnode}.tls.ai|nginx-$host.tls.ai|g" ${dockerfile}
sed -i "s|api.tls.ai|api-$host.tls.ai|g" ${dockerfile} && SuccesfulPrint "Modify docker files"
cd /home/user/docker-compose/1.20.0/ && docker-compose up -d
echo "2" > /opt/sg.f ##marks second iteration has happened
echo "DONE!"
echo "Please reboot your machine"
}
Clean(){
cat << "EOF"

  _____  _                      _                  _____              _                   
 / ____|| |                    (_)                / ____|            | |                  
| |     | |  ___   __ _  _ __   _  _ __    __ _  | (___   _   _  ___ | |_  ___  _ __ ___  
| |     | | / _ \ / _` || '_ \ | || '_ \  / _` |  \___ \ | | | |/ __|| __|/ _ \| '_ ` _ \ 
| |____ | ||  __/| (_| || | | || || | | || (_| |  ____) || |_| |\__ \| |_|  __/| | | | | |
 \_____||_| \___| \__,_||_| |_||_||_| |_| \__, | |_____/  \__, ||___/ \__|\___||_| |_| |_|
                                           __/ |           __/ |                          
                                          |___/           |___/                           
EOF
apt remove --purge docker* docker-compose nvidia-container-runtime nvidia-container-toolkit nvidia-docker nvidia* > /dev/null && SuccesfulPrint "Purge drivers and docker"
rm -rfv /home/user/docker-compose/*
rm -rfv /home/user/Downloads/*
rm -rfv /opt/sg.f ##clear iteration flag because everything has been cleaned
rm -rfv /ssd/*
rm -rfv /storage/*
SuccesfulPrint "System Clean"
}
SuccesfulPrint(){
local green=$'\e[1;32m'
local white=$'\e[0m'
	echo -e "=================================================================="
	echo -e "                    $1 ....${green}Success${white}                  "
	echo -e "=================================================================="
}
FailedPrint(){
local red=$'\e[1;31m'
local white=$'\e[0m'
	echo -e "=================================================================="
	echo -e "                    $1 ....${red}Failed!${white}                  "
	echo -e "=================================================================="
}
##main
local red=$'\e[1;31m'
local white=$'\e[0m'
if [ "$EUID" -ne 0 ]; then	
	echo "Please run this script as root"
	echo "Exiting..."
	exit 1
if grep -q "1" /opt/sg.f; then
	if [[ -f "/home/user/docker-compose/1.20.0/docker-compose.yml" ]]; then
		after_reboot
	else
		echo "App not installed, please Install it and try again"
		echo "Exiting..."
		exit
	fi
elif [[ ! -f "/opt/sg.f" ]];then
	before_reboot "$1"
elif grep -q "2" /opt/sg.f;then
	echo "Script has been run fully already"
	read -p "Do you wish to clean this pc? [Y/N] ${red}(Warning! this will delete EVERYTHING)${white}" -n 1 -r $yn
	case "$yn" in
		y|Y) Clean && exit 0;;
		n|N) 
			echo "Not Cleaning..."
			echo "Exiting..."
			exit 1;;
		*) echo "Invalid choice, Exiting.."; exit 1;;
	esac
fi



# if [[ -f "/opt/sg.f" ]]; then
# 	if [[ -f "/home/user/docker-compose/1.20.0/docker-compose.yml" ]]; then
# 		after_reboot
# 	else
# 		echo "App not installed, please Install it and try again"
# 		echo "Exiting..."
# 		exit
# 	fi
# else
# 	before_reboot "$1"
# fi