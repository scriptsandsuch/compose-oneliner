#! /bin/bash
#s6NXKghuKb
before_reboot() {
if [[ -d "/home/user/" ]]; then
	cd /home/user/Downloads
else
	echo "You have set the wrong username for the ubuntu installation, please reinstall with a user named user"
	exit
fi
##Download files and install what is needed
#echo "Do you wish to install the enviroment automatically? [y/n]"
#read yn
#case $yn in
#	[Yy]) install_env;
#        [Nn]) wget https://s3.eu-central-1.amazonaws.com/airgap.anyvision.co/better_environment/betterenvironment-181202-142-linux-x64-installer.run; 
#	*) echo "${red}Invalid Answer"; echo "Exiting...${reset}"; exit;;
#	esac
wget https://s3.eu-central-1.amazonaws.com/airgap.anyvision.co/better_environment/betterenvironment-181202-142-linux-x64-installer.run
dpkg -a --configure
wget https://s3.eu-central-1.amazonaws.com/facesearch.co/installbuilder/1.20.0/FaceRec-1.20.0-66-local-gpu-linux-x64-installer.run 
wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
chmod +x Face*
add-apt-repository --yes --update ppa:graphics-drivers/ppa
apt install nvidia-driver-410 nvidia-modprobe -y && SuccesfulPrint "Nvidia drivers"
apt install vlc curl vim htop net-tools git -y && SuccesfulPrint "Utilities"
git clone https://github.com/scriptsandsuch/sg-script.git
apt install ./team* -y && SuccesfulPrint "TeamViewer"


##moxa set up
moxadir=/home/user/moxa-config/
mkdir ${moxadir}
mv /home/user/Downloads/sg-script/moxa_e1214.sh $moxadir
mv /home/user/Downloads/sg-script/cameraList.json $moxadir
chmod +x /home/user/moxa-config/*

echo "1" > /opt/sg.f ##flag if the script has been run
echo -e "Please reboot your machine, then isntall FaceRec, uncheck \"start services\" and \"start application dashboard\" on the end of the installation after that run this script again"
 
}

Install_env(){
apt install apt-transport-https ca-certificates software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs)  stable" 
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
echo "distro is: " $distribution ##debug
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
apt update
apt install docker-ce=5:18.09.7~3-0~ubuntu-bionic -y && SuccesfulPrint "docker-ce"
curl -L https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose && SuccesfulPrint "docker-compose"
add-apt-repository --yes --update ppa:graphics-drivers/ppa
apt install nvidia-driver-410 nvidia-modprobe -y && SuccesfulPrint "Nvidia drivers"
apt install -y nvidia-docker2 && SuccesfulPrint "Nvidia Docker"
tee /etc/docker/daemon.json <<'EOF' > /dev/null	
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF
echo "${green}Runtime added${reset}"
pkill -SIGHUP dockerd
}




after_reboot(){
##edit env and yml
dockerfile=/home/user/docker-compose/1.20.0/docker-compose.yml
tee -a /home/user/docker-compose/1.20.0/env/broadcaster.env <<'EOF'
## Modbus plugin integration
BCAST_MODBUS_IS_ENABLED=true
BCAST_MODBUS_CMD_PATH=/home/user/moxa-config/moxa_e1214.sh
BCAST_MODBUS_CAMERA_LIST_PATH=/home/user/moxa-config/cameraList.json
EOF
line=$(grep -nF broadcaster.tls.ai /home/user/docker-compose/1.20.0/docker-compose.yml  | awk -F: '{print $1}') ; line=$((line+2))
host=$(hostname)
sed -i "${line}i \      - \/home\/user\/moxa-config:\/home\/user\/moxa-config" ${dockerfile}
sed -i "s|nginx-\${node_name:-localnode}.tls.ai|nginx-$host.tls.ai|g" ${dockerfile}
sed -i "s|api.tls.ai|api-$host.tls.ai|g" ${dockerfile} && SuccesfulPrint "Modify docker files"
echo "2" > /opt/sg.f ##flag if the script has been run

echo "DONE!"
echo "Please reboot your machine"
}

SuccesfulPrint(){
	echo "=================================================================="
	echo "                    $1 ....${green}success${reset}                  "
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
	if [[ -f "/home/user/docker-compose/1.20.0/docker-compose.yml" ]]
	then
		after_reboot
	else
		echo "App not installed, please Install it and try again"
		echo "Exiting..."
		exit
	fi
else
	before_reboot
fi
