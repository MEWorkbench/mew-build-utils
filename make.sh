PREVIOUS_MEW_VERSION=1.1.0-SNAPSHOT
DEPLOY_VERSION=1.1.0
NEXT_MEW_VERSION=1.1.1-SNAPSHOT

UNDO_FOLDER=`pwd`

BUILD_FOLDER=`dirname -- $0`
SRC_BUILD=${BUILD_FOLDER}/build_src

echo "############ CONFIGURATIONS ############"
echo PREVIOUS_MEW_VERSION  $PREVIOUS_MEW_VERSION
echo DEPLOY_VERSION        $DEPLOY_VERSION
echo NEXT_MEW_VERSION      $NEXT_MEW_VERSION
echo BUILD_FOLDER          $BUILD_FOLDER
echo SRC_BUILD             $SRC_BUILD

echo execute command 
source ${BUILD_FOLDER}/build/build.sh

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
	*)
		echo "Use parameter:"
		echo "   prepare: to prepare build"
		echo "   reset  : to reset build"
		echo "   submit : to push to server"
		echo "   clean  : remove src folder $SRC_BUILD"
		echo "   pull   : to pull all repositories"
		echo "   push   : send to git"
esac

# news 
