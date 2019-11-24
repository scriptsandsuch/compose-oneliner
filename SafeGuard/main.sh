
#! /bin/bash
firstIteration() {
if [[ -d "/home/user/" ]]; then
	cd /home/user/Downloads
else
	echo "You have set the wrong username for the ubuntu installation, please reinstall with a user named user"
	exit 1
fi
local token="$1"
local printCyan=$'\e[1;36m'
local printWhite=$'\e[0m'
echo "Token is:"
echo -e "${printCyan}${token}${printWhite}"
if [[ -z ${token} ]]; then 
    echo
    echo "You must provide a docker registry token!"
    echo "Exiting..."
    exit 1; 
fi
dpkg -a --configure
wget https://download.teamviewer.com/download/linux/teamviewer_amd64.deb
wget https://github.com/scriptsandsuch/compose-oneliner/releases/download/SG/FaceSearch-1.20.0-linux-x86_64.AppImage
mv FaceSearch-1.20.0-linux-x86_64.AppImage /home/user/Desktop/SafeGuard.AppImage
chmod +x /home/user/Desktop/SafeGuard.AppImage && chown /home/user/Desktop/SafeGuard.AppImage
apt install vlc curl vim htop net-tools git expect -y -qq > /dev/null && successfulPrint "Utilities"
git clone https://github.com/scriptsandsuch/compose-oneliner > /dev/null && successfulPrint "Repo Cloned"
apt install ./team* -y -qq > /dev/null && successfulPrint "TeamViewer"
mv ./compose-oneliner/SafeGuard/secondIteration.sh /opt/secondIteration.sh
mv ./compose-oneliner/SafeGuard/LaunchAsRoot.sh /

##moxa set up
moxadir=/home/user/moxa-config/
mkdir ${moxadir}
mv /home/user/Downloads/compose-oneliner/SafeGuard/moxa_e1214.sh ${moxadir}
mv /home/user/Downloads/compose-oneliner/SafeGuard/cameraList.json ${moxadir} && successfulPrint "Moxa setup" || failedPrint "Moxa setup"
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
ln -s /home/user/docker-compose/1.20.0/docker-compose-local-gpu.yml /home/user/docker-compose/1.20.0/docker-compose.yml && successfulPrint "Create Symbolic Link" || failedPrint "Create Symbolic Link"
echo "1" > /opt/sg.f ##flag if the script has been run 

##make script auto run after login
tee -a /home/user/.profile <<'EOF' && successfulPrint "Startup added"
gnome-terminal -- sh -c '/opt/LaunchAsRoot.sh'
EOF
}
clean(){
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
apt remove --purge *docker* docker-compose nvidia-container-runtime nvidia-container-toolkit nvidia-docker nvidia* > /dev/null && successfulPrint "Purge drivers and docker"
rm -rfv /home/user/docker-compose/*
rm -rfv /home/user/Downloads/*
rm -rfv /opt/sg.f ##clear iteration flag because everything has been cleaned
rm -rfv /ssd/*
rm -rfv /storage/*
successfulPrint "System Clean"
}
successfulPrint(){
local printGreen=$'\e[1;32m'
local printWhite=$'\e[0m'
	echo -e "=================================================================="
	echo -e "                    $1 ....${green}Success${white}                  "
	echo -e "=================================================================="
}
failedPrint(){
local printRed=$'\e[1;31m'
local printWhite=$'\e[0m'
	echo -e "=================================================================="
	echo -e "                    $1 ....${red}Failed!${white}                  "
	echo -e "=================================================================="
}
##main
red=$'\e[1;31m'
white=$'\e[0m'
if [ "$EUID" -ne 0 ]; then
	echo "Please run this script as root"
	echo "Exiting..."
	exit 1
fi
if grep -q "1" /opt/sg.f; then
	echo "Second Iteration should have been run automatically upon startup"
	read -p "Do you wish to run it manually anyway? [Y/N]" -n 1 -r $yn1
	case "$yn1" in
		y|Y) bash /opt/secondIteration.sh && exit 0;;
		n|N) echo "Exiting..."; exit 0;;
		*) echo "Invalid choice, Exiting.."; exit 1;;
	esac

elif [[ ! -f "/opt/sg.f" ]]; then
	firstIteration "$1"
elif $(grep -q "2" /opt/sg.f) ; then
	echo "Script has been run fully already"
	read -p "Do you wish to clean this pc? [Y/N] ${red}(Warning! this will delete EVERYTHING)${white}" -n 1 -r $yn
	case "$yn" in
		y|Y) clean && exit 0;;
		n|N) echo "Not Cleaning..." ; echo "Exiting..."; exit 1;;
		*) echo "Invalid choice, Exiting.."; exit 1;;
	esac
fi
