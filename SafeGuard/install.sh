#! usr/bin/env bash
before_reboot() {
if [[ -d "/home/user/" ]]; then
	cd /home/user/Downloads
else
	echo "You have set the wrong username for the ubuntu installation, please reinstall with a user named user"
	exit 1
fi
for item in "${args[@]}"
do
    case $item in
        "-k"|"--token")
            token="${args[((i+1))]}"
        ;;
        *) echo "Invalid Argument, Please Enter a Valid argument"; echo "Exiting...";exit 1;;
    esac
    ((i++))
done
if [[ -z ${token} ]]; then 
    echo
    echo "You must privide a docker registry token!"
    exit 1 
fi
wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
wget -O https://s3.eu-central-1.amazonaws.com/anyvision-dashboard/on-demand-verint/f3c9a36/AnyVision-1.20.0-linux-x86_64.AppImage /home/user/Downloads/SafeGuard.AppImage
chmod +x SafeGuard.AppImage && chown user SafeGuard.AppImage
apt install vlc curl vim htop net-tools git -y && SuccesfulPrint "Utilities"
git clone https://github.com/scriptsandsuch/sg-script.git
apt install ./team* -y && SuccesfulPrint "TeamViewer"

##moxa set up
moxadir=/home/user/moxa-config/
mkdir $moxadir
mv /home/user/Downloads/sg-script/moxa_e1214.sh $moxadir
mv /home/user/Downloads/sg-script/cameraList.json $moxadir
chmod +x /home/user/moxa-config/*

wget -qO- https://raw.githubusercontent.com/scriptsandsuch/compose-oneliner/development/compose-oneliner.sh | bash -s -- -b 1.20.0 -k ${token}
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
echo "2" > /opt/sg.f ##flag if the script has been run

echo "DONE!"
echo "Please reboot your machine"
}
mount_storage(){
	##TODO
}
SuccesfulPrint(){
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
	if [[-f "/home/user/docker-compose/1.20.0/docker-compose.yml"]]; then
		before_reboot
	else
		echo "App not installed, please Install it and try again"
		echo "Exiting..."
		exit
else
	before_reboot
fi
