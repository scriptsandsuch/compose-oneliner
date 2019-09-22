#!/usr/bin/env bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi
## Deploy
args=("$@")
for item in "${args[@]}"
do
    case $item in
        "-b"|"--branch")
            BRANCH="${args[((i+1))]}"
        ;;
        "-p"|"--product")
            PRODUCT="${args[((i+1))]}"
        ;;
    esac
    ((i++))
done

if [[ -z ${BRANCH} ]] ; then
    echo "Branch must be specified!"
    exit 1
fi

if [ -z $PRODUCT ]; then
    echo "assuming product is BT..."
    PRODUCT="BT"
fi

if [ -x "$(command -v apt-get)" ]; then

	# install git
	echo "Installing git"
	git --version > /dev/null 2>&1
	if [ $? != 0 ]; then
	    set -e
	    apt-get -qq update > /dev/null
	    apt-get -qq install -y --no-install-recommends git curl > /dev/null
	    set +e
	fi
elif [ -x "$(command -v yum)" ]; then
     echo "Installing git"
     yum install -y git
fi

[ -d /opt/Post-Install ] && rm -rf /opt/Post-Install

git clone --recurse-submodules  https://github.com/OriBenHur-Any/Post-Install.git -b On_linener  /opt/Post-Install

pushd /opt/Post-Install && chmod u+x /opt/Post-Install/Post-Install.sh

exec ./Post-Install.sh ${BRANCH} ${PRODUCT}
if [ $? -ne 0 ] ; then 
	echo "Something went wrong contact support"
	exit 99
fi
