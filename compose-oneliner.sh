#!/usr/bin/env bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Absolute path to this script
SCRIPT=$(readlink -f "$0")
# Absolute path to the script directory
BASEDIR=$(dirname "$SCRIPT")
HOME_DIR=`eval echo ~$(logname)`
DOCKER_COMPOSE_DIR=${HOME_DIR}/docker-compose
COMPOSE_BASH_URL="https://github.com/AnyVisionltd"
BRANCH=$1
TOKEN=$2
PRODUCT=$3
COMPOSE_REPO_GIT="${4:-docker-compose}.git"
DASHBOARD=${5:-false}
if [[ $TOKEN != "" ]] && [[ $TOKEN == *".json" ]] && [[ -f $TOKEN ]] ;then
    gcr_user="_json_key" 
    gcr_key="$(cat ${TOKEN} | tr '\n' ' ')"
elif  [[ $TOKEN != "" ]] && [[ ! -f $TOKEN ]] && [[ $TOKEN != *".json" ]]; then
    gcr_user="oauth2accesstoken"
    gcr_key=$TOKEN
fi

COMPOSE_REPO="${COMPOSE_BASH_URL}/${COMPOSE_REPO_GIT}"
[ -d $DOCKER_COMPOSE_DIR ] || mkdir $DOCKER_COMPOSE_DIR
[ -d ${DOCKER_COMPOSE_DIR}/${BRANCH} ] && rm -rf ${DOCKER_COMPOSE_DIR}/${BRANCH}
git clone ${COMPOSE_REPO} -b ${BRANCH} ${DOCKER_COMPOSE_DIR}/${BRANCH}
if [ $? -ne 0 ]; then
    echo "No such branch branch try again"
    exit 1
fi
pushd ${DOCKER_COMPOSE_DIR}/${BRANCH}
DOCKER_COMPOSE_FILE=`find . -type f -regextype posix-extended -regex './docker\-compose\-(local\-)?gpu\.yml'`
ln -s `basename ${DOCKER_COMPOSE_FILE}` docker-compose.yml
popd

# Set Environment
export ANSIBLE_LOCALHOST_WARNING=false
export ANSIBLE_DEPRECATION_WARNINGS=false
export DEBIAN_FRONTEND=noninteractive

echo "=====================================================================" 
echo "== Making sure that all dependencies are installed, please wait... ==" 
echo "=====================================================================" 
## APT update
apt -qq update 
apt -qq install -y software-properties-common 
apt-add-repository --yes --update ppa:ansible/ansible 
apt -qq install -y ansible 
ansible-playbook --become --become-user=root ansible/main.yml -vv

## Fix nvidia-driver bug on Ubuntu 18.04 black screen on login: https://devtalk.nvidia.com/default/topic/1048019/linux/black-screen-after-install-cuda-10-1-on-ubuntu-18-04/post/5321320/#5321320
sed -i -r -e 's/^GRUB_CMDLINE_LINUX_DEFAULT="(.*)?quiet ?(.*)?"/GRUB_CMDLINE_LINUX_DEFAULT="\1\2"/' -e 's/^GRUB_CMDLINE_LINUX_DEFAULT="(.*)?splash ?(.*)?"/GRUB_CMDLINE_LINUX_DEFAULT="\1\2"/' /etc/default/grub
update-grub

echo 'xhost +SI:localuser:root' | tee /etc/profile.d/xhost.sh
usermod -aG docker $(logname)

pushd ${DOCKER_COMPOSE_DIR}/${BRANCH}
ver=`grep -F /api: ${DOCKER_COMPOSE_DIR}/${BRANCH}/docker-compose.yml | grep -Po 'api:\K[^"]+'`
if [ "${DASHBOARD}" == "true" ]; then
    curl -o ${HOME_DIR}/AnyVision-${ver}-linux-x86_64.AppImage https://s3.eu-central-1.amazonaws.com/anyvision-dashboard/${ver}AnyVision-${ver}-linux-x86_64.AppImage
    chmod +x ${HOME_DIR}/AnyVision-${ver}-linux-x86_64.AppImage
fi

chown -R $(logname):$(logname) ${HOME_DIR}
docker login -u "${gcr_user}" -p "${gcr_key}" "https://gcr.io"
docker-compose up -d

echo "Done, Please reboot before continuing."