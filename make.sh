PREVIOUS_MEW_VERSION=1.1.0-SNAPSHOT
DEPLOY_VERSION=1.1.0
NEXT_MEW_VERSION=1.1.1-SNAPSHOT

UNDO_FOLDER=`pwd`

BUILD_FOLDER=`dirname -- $0`
source ${BUILD_FOLDER}/build/build.sh

BUILD_FOLDER=$(get_absolute_path  ${BUILD_FOLDER})
SRC_BUILD=$(get_absolute_path  ${BUILD_FOLDER}/../build/)

source ${BUILD_FOLDER}/build/build.sh
echo "############ CONFIGURATIONS ############"
echo PREVIOUS_MEW_VERSION  $PREVIOUS_MEW_VERSION
echo DEPLOY_VERSION        $DEPLOY_VERSION
echo NEXT_MEW_VERSION      $NEXT_MEW_VERSION
echo BUILD_FOLDER          $BUILD_FOLDER
echo SRC_BUILD             $SRC_BUILD

conf="$HOME/.mew_deploy_conf"


case "$1" in 
	prepare)
		mew_make
		exit;;
	reset)
		mew_reset
		exit;;
	clean)
		clean
		exit;;
	push)
		mew_release
		exit;;
	pull)
		pull
		exit;;
	compile)
		compile
		exit;;
	nexus_deploy)
		nexus_deploy
		exit;;
	configure_gpg)
		configure_gpg
		exit;;
	configure_java_home_mac)
		configure_java_home_mac
		exit;;
	add_configuration)
		shift
		echo $1 >> $conf
		exit;;
	show_configurations)
		cat $conf
		exit;;
	replace_mew_version)
		shift
		replace_mew_version_2 $1 $SRC_BUILD/log.txt
		rm $SRC_BUILD/log.txt
		exit;;
	*)
		echo "Use parameter:"
		echo "   prepare: to prepare build"
		echo "   reset  : to reset build"
		echo "   submit : to push to server"
		echo "   clean  : remove src folder $SRC_BUILD"
		echo "   pull   : to pull all repositories"
		echo "   push   : send to git"
		echo "   configure_gpg: configure gpg on mac"
		echo "   show_configurations: "
		echo "   nexus_deploy"
esac

# news 
