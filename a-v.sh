#!/usr/bin/env bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi
## Deploy
function show_help(){
    echo -e " \e[92m"
    echo "Compose Oneliner Installer"
    echo ""
    echo "OPTIONS:"
    echo "  [-b|--branch] git branch"
    echo "  [-k|--token] GCR token"
    echo "  [-p|--product] Product name to install"
    echo "  [-g|--git] alterntive git repo (the default is docker-compose.git)"
    echo "  [--download-dashboard] download dashboard"
    echo "  [-d|--debug] enable debug mode"
    echo "  [-h|--help|help] this help menu"
    echo ""
}
args=("$@")
for item in "${args[@]}"
do
    case $item in
        "-b"|"--branch")
            BRANCH="${args[((i+1))]}"
        ;;
        "-k"|"--token")
            TOKEN="${args[((i+1))]}"
        ;;
        "-p"|"--product")
            PRODUCT="${args[((i+1))]}"
        ;;
        "-g"|"--git")
            GIT="${args[((i+1))]}"
        ;;
        "-d"|"--debug")
            EXEC='bash -x'
        ;;
        "--download-dashboard")
            DASHBOARD="true"
        ;;
        "-h"|"--help"|"help")
            show_help
            exit 0
            ;;


    esac
    ((i++))
done

if [[ -z ${BRANCH} ]] ; then
    echo "Branch must be specified!"
    exit 1
fi

if [[ -z ${TOKEN} ]]; then 
    echo "You must privide a docker registry token!"
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

[ -d /opt/compose-oneliner ] && rm -rf /opt/compose-oneliner

git clone --recurse-submodules  https://github.com/AnyVisionltd/compose-oneliner.git /opt/compose-oneliner

pushd /opt/compose-oneliner && chmod u+x /opt/compose-oneliner/compose-oneliner.sh
EXEC="${EXEC:-bash}"
$EXEC ./compose-oneliner.sh ${BRANCH} ${TOKEN} ${PRODUCT} ${GIT} ${DASHBOARD}
if [ $? -ne 0 ] ; then 
	echo "Something went wrong contact support"
	exit 99
fi
