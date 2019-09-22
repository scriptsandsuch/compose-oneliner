#!/usr/bin/env bash
# Absolute path to this script
SCRIPT=$(readlink -f "$0")
# Absolute path to the script directory
BASEDIR=$(dirname "$SCRIPT")
HOME_DIR=`eval echo ~$(logname)`
DOCKER_COMPOSE_DIR=${HOME_DIR}/docker-compose
COMPOSE_REPO="https://github.com/AnyVisionltd/docker-compose.git"
BRANCH=$1
PRODUCT=$2
mkdir $DOCKER_COMPOSE_DIR
git clone ${COMPOSE_REPO} -b ${BRANCH} ${DOCKER_COMPOSE_DIR}/${BRANCH}
if [ $? -ne 0 ]; then
    echo "No such branch branch try again"
    exit 1
fi
pushd ${DOCKER_COMPOSE_DIR}/${BRANCH}
DOCKER_COMPOSE_FILE=`find . -type f -regextype posix-extended -regex './docker\-compose\-(local\-)?gpu\.yml'`
ln -s `basename ${DOCKER_COMPOSE_FILE}` docker-compose.yml
# Set Environment
popd
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

ansible-playbook --become --become-user=root ansible/main.yml -vvv

## Fix nvidia-driver bug on Ubuntu 18.04 black screen on login: https://devtalk.nvidia.com/default/topic/1048019/linux/black-screen-after-install-cuda-10-1-on-ubuntu-18-04/post/5321320/#5321320
sed -i -r -e 's/^GRUB_CMDLINE_LINUX_DEFAULT="(.*)?quiet ?(.*)?"/GRUB_CMDLINE_LINUX_DEFAULT="\1\2"/' -e 's/^GRUB_CMDLINE_LINUX_DEFAULT="(.*)?splash ?(.*)?"/GRUB_CMDLINE_LINUX_DEFAULT="\1\2"/' /etc/default/grub
update-grub

pushd ${DOCKER_COMPOSE_DIR}/${BRANCH}
docker-compose up -d 

echo "Done"