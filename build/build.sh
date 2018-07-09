# Black        0;30     Dark Gray     1;30
# Red          0;31     Light Red     1;31
# Green        0;32     Light Green   1;32
#Brown/Orange 0;33     Yellow        1;33
#Blue         0;34     Light Blue    1;34
#Purple       0;35     Light Purple  1;35
#Cyan         0;36     Light Cyan    1;36
#Light Gray   0;37     White         1;37

RED='\033[0;31m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

ERROR="$RED[!]$NC"
INFO="$GRAY[+]$NC"
QUESTION="$YELLOW[?]$NC"

function clean(){
	rm -rf $SRC_BUILD
}

function pull(){

	OLD_DIR=`pwd`
	cd $SRC_BUILD
	./git-generic-jecoli.sh pull
	./git-generic-mew.sh pull
	cd $OLD_DIR
}


function clone(){
	OLD_DIR=`pwd`
	mkdir -p $SRC_BUILD
	cp $BUILD_FOLDER/git-utils/* $SRC_BUILD/
	cd $SRC_BUILD
	./clone-jecoli.sh
	./clone-mew.sh
	cd $OLD_DIR
}

function mew_make(){
	

	OLD_DIR=`pwd`
	cd $SRC_BUILD

	echo -en "PREPARE LOG:\n"> $SRC_BUILD/mvn.release.log 
	echo -e "$INFO creating prepare log on $SRC_BUILD/mvn.prepare.log"

	echo -e "$INFO changing jecoli to branch dev"
	./git-generic-jecoli.sh checkout dev >> $SRC_BUILD/mvn.release.log
	echo -e "$INFO changing mew to branch dev"
	./git-generic-mew.sh checkout dev >> $SRC_BUILD/mvn.release.log
	
	echo -e "$INFO changing version $PREVIOUS_MEW_VERSION to $DEPLOY_VERSION"
	replace_mew_version_2 $DEPLOY_VERSION $SRC_BUILD/mvn.release.log
	
	echo -e "$INFO commit version in local repos"
	__commit_deploy__version ./git-generic-jecoli.sh
	__commit_deploy__version ./git-generic-mew.sh 
	
	echo -e "$INFO changing version $DEPLOY_VERSION to $NEXT_MEW_VERSION"
	replace_mew_version_2 $NEXT_MEW_VERSION $SRC_BUILD/mvn.release.log

	echo -e "$INFO commit version in local repos"
	__commit_snapshot__version ./git-generic-mew.sh
	__commit_snapshot__version ./git-generic-jecoli.sh

	echo -e "$QUESTION PREPARE WAS CONCLUDED!! verify git history projects on folder: $SRC_BUILD"
	echo -e "$QUESTION perform submit to commit the changes on server"
	echo -e "$QUESTION perform reset to revert the process"
	cd $OLD_DIR
}

function get_absolute_path() {
	RELATIVE_PATH=$1
	OLD_PATH=`pwd`
	cd $RELATIVE_PATH
	RETURN_PATH=`pwd`
	cd $OLD_PATH
	echo $RETURN_PATH
}

function create_conf(){
    echo -e "$INFO Creating new config file:"
    read -p  "  OSS_SONATYPE_USER: " OSS_SONATYPE_USER
    read -p  "  OSS_SONATYPE_PASS: " OSS_SONATYPE_PASS
    read -p  "  GPG_SECRET_KEYS [64-incoded]: " GPG_SECRET_KEYS
    read -p  "  GPG_PASSPHRASE   : " GPG_PASSPHRASE
    read -p  "  GPG_EXECUTABLE   : " GPG_EXECUTABLE
    read -p  "  GPG_OWNERTRUST [64-incoded]: " GPG_OWNERTRUST
    read -p  "  Maven command    : " MAVEN_COMMAND


    echo -en " export OSS_SONATYPE_USER=$OSS_SONATYPE_USER\n" > $conf 
    echo -en " export OSS_SONATYPE_PASS=$OSS_SONATYPE_PASS\n" >> $conf 
    echo -en " export GPG_EXECUTABLE=$GPG_EXECUTABLE\n" >> $conf 
    echo -en " export GPG_PASSPHRASE=$GPG_PASSPHRASE\n" >> $conf 
    echo -en " export GPG_OWNERTRUST=$GPG_OWNERTRUST\n" >> $conf 
    echo -en " export GPG_SECRET_KEYS=$GPG_SECRET_KEYS\n" >> $conf
    echo -en " export MAVEN_COMMAND=$MAVEN_COMMAND\n" >> $conf

    echo -e "$INFO configurations file created in $conf"
}

function configure_gpg(){
	echo -en "export GPG_TTY=\$(tty)\n" >> $conf
}

function configure_java_home_mac(){
	echo -en "export JAVA_HOME=\$(/usr/libexec/java_home)\n" >> $conf
}

function configure_deploy(){
	
	M2REPOSITORY=$M2_HOME/repository
	mkdir -p ${M2REPOSITORY}
	source $conf

	cp $BUILD_FOLDER/examples/travis/build/oss.sonatype.settings.xml ${M2_HOME}/settings.xml

	sed -i -e s,LOCAL_M2,$M2_HOME,g ${M2_HOME}/settings.xml
	sed -i -e s/OSS_SONATYPE_USER/$OSS_SONATYPE_USER/g ${M2_HOME}/settings.xml
	sed -i -e s/OSS_SONATYPE_PASS/$OSS_SONATYPE_PASS/g ${M2_HOME}/settings.xml
	sed -i -e s/DEPLOYMENT_REPO_ID/$DEPLOYMENT_REPO_ID/g ${M2_HOME}/settings.xml
	sed -i -e s,GPG_EXECUTABLE,$GPG_EXECUTABLE,g ${M2_HOME}/settings.xml
	sed -i -e s,GPG_PASSPHRASE,$GPG_PASSPHRASE,g ${M2_HOME}/settings.xml

	echo $GPG_SECRET_KEYS | base64 --decode | $GPG_EXECUTABLE --import
	echo $GPG_OWNERTRUST | base64 --decode | $GPG_EXECUTABLE --import-ownertrust
}

function set_deploy_repo(){
	OLD_DIR=`pwd`
	PROJECT=$1
	cd $SRC_BUILD/$PROJECT

	echo -e "$INFO creating deploy repository"
	mvn3 -s ~/.deploym2/settings.xml -P release-oss-repo -DopenedRepositoryMessageFormat='MEW_NEXT_NEXUX_REPOSITORY: %s' nexus-staging:rc-open >> $SRC_BUILD/mvn.deploy.log
	[ $? != 0 ]  && echo -e "$ERROR PROBLEM opening next nexus repository see file $SRC_BUILD/mvn.deploy.log"  && exit
	DEPLOY_REPO=`cat $SRC_BUILD/mvn.deploy.log | grep "MEW_NEXT_NEXUX_REPOSITORY: " | sed 's/.*\(ptuminhocebbiosystems.*\)/\1/'` 
	[ $? != 0 ]  && echo -e "$ERROR PROBLEM retriving the next nexux repository" && exit

	cd $OLD_DIR
}

function compile(){


	source $BUILD_FOLDER/git-utils/jecoli_projects.in
	ALL_PROJECTS=(${PROJECTS[@]})
	source $BUILD_FOLDER/git-utils/mew_projects.in
	ALL_PROJECTS=(${ALL_PROJECTS[@]} ${PROJECTS[@]})

	echo -en "MAVEN_DEPLOY_LOG:\n"> $SRC_BUILD/mvn.compile.log 
	echo -e "$INFO create maven log in: "$SRC_BUILD/mvn.compile.log

	OLD_PATH=`pwd`
	for p in "${ALL_PROJECTS[@]}"
	do
		_proj=$SRC_BUILD/$p
		echo -e "$INFO install $p"
		cd $_proj && 
		$MAVEN_COMMAND  -DskipTests=true -Dcplex.jar.path=${CPLEX_JAR} clean install >> $SRC_BUILD/mvn.compile.log
		[ $? != 0 ] && tail $SRC_BUILD/mvn.deploy.log && echo -e "$ERROR PROBLEM $p see file $SRC_BUILD/mvn.deploy.log"  &&exit
	done
	cd $OLD_PATH

}

function nexus_deploy(){

	M2_HOME=$HOME/.deploym2
	[ ! -f "$conf" ] && echo -e "$ERROR Config file not found" && create_conf && exit
	source $conf && echo -e "$INFO import configurations from $conf"
	configure_deploy

	source $BUILD_FOLDER/git-utils/jecoli_projects.in
	ALL_PROJECTS=(${PROJECTS[@]})
	source $BUILD_FOLDER/git-utils/mew_projects.in
	ALL_PROJECTS=(${ALL_PROJECTS[@]} ${PROJECTS[@]})

	echo -en "MAVEN_DEPLOY_LOG:\n"> $SRC_BUILD/mvn.deploy.log 
	echo -e "$INFO create maven log in: "$SRC_BUILD/mvn.deploy.log
	set_deploy_repo $ALL_PROJECTS
	
	OLD_PATH=`pwd`
	for p in "${ALL_PROJECTS[@]}"
	do
		_proj=$SRC_BUILD/$p
		echo -e "$INFO deploy $p to $DEPLOY_REPO"
		cd $_proj && 
		$MAVEN_COMMAND -s ${M2_HOME}/settings.xml -Dmaven.repo.local=$M2REPOSITORY -DskipTests=true -Dgpg.useagent=false -Dgpg.passphrase=$GPG_PASSPHRASE -DstagingRepositoryId=$DEPLOY_REPO -Dcplex.jar.path=${CPLEX_JAR} -P gpg,release-oss-repo clean deploy >> $SRC_BUILD/mvn.deploy.log
		[ $? != 0 ] && tail $SRC_BUILD/mvn.deploy.log && echo -e "$ERROR PROBLEM $p see file $SRC_BUILD/mvn.deploy.log"  &&exit
	done
	cd $OLD_PATH
	#rm -rf $M2_HOME
}


function replace_mew_version_2(){

	OLD_DIR=`pwd`
	VERSION_TO_REPLACE=$1
	LOG_FILE=$2

	source $conf
	source $BUILD_FOLDER/git-utils/jecoli_projects.in
	ALL_PROJECTS=(${PROJECTS[@]})
	source $BUILD_FOLDER/git-utils/mew_projects.in
	ALL_PROJECTS=(${ALL_PROJECTS[@]} ${PROJECTS[@]})

	for p in "${ALL_PROJECTS[@]}"
	do
		_proj=$SRC_BUILD/$p
		echo -e "$INFO changing $p version to $VERSION_TO_REPLACE"
		cd $_proj && 
		$MAVEN_COMMAND versions:set -DnewVersion=$VERSION_TO_REPLACE -Dcplex.jar.path=${CPLEX_JAR} >> $LOG_FILE
		[ $? != 0 ] && tail $LOG_FILE && echo -e "$ERROR chance $p version to $VERSION_TO_RELACE see:$LOG_FILE"  &&exit
		
		echo -e "$INFO changing $p mew dependencies to $VERSION_TO_REPLACE"
		$MAVEN_COMMAND versions:set-property -Dproperty=meworkbench.version -DnewVersion=$VERSION_TO_REPLACE -Dcplex.jar.path=${CPLEX_JAR} >> $LOG_FILE
		[ $? != 0 ] && tail $LOG_FILE && echo -e "$ERROR chance $p version to $VERSION_TO_RELACE see:$LOG_FILE"  &&exit
	done

	cd $OLD_DIR
}


function mew_release(){
	OLD_DIR=`pwd`
	cd $SRC_BUILD
	echo -en "RELEASE LOG:\n"> $SRC_BUILD/mvn.release.log 
	echo -e "$INFO creating release log on $SRC_BUILD/mvn.release.log"
	release ./git-generic-jecoli.sh
	release ./git-generic-mew.sh
	cd $OLD_DIR
	
}

function release(){
	GIT=$1
	echo -e "$INFO pushing master using $GIT"
	$GIT push origin master >> $SRC_BUILD/mvn.release.log 
	[ $? != 0 ]  && echo -e "$ERROR PROBLEM pushing master using $GIT" && exit
	echo -e "$INFO pushing tags using $GIT"
	$GIT push origin --tags >> $SRC_BUILD/mvn.release.log 
	[ $? != 0 ]  && echo -e "$ERROR PROBLEM pushing tags using $GIT" && exit
	$GIT push origin dev >> $SRC_BUILD/mvn.release.log 
	echo -e "$INFO pushing dev using $GIT"
	[ $? != 0 ]  && echo -e "$ERROR PROBLEM pushing dev using $GIT" && exit
}

function mew_reset(){
	OLD_DIR=`pwd`
	cd $SRC_BUILD
	reset ./git-generic-jecoli.sh
	reset ./git-generic-mew.sh
	cd $OLD_DIR
}

function reset(){
	GIT=$1
	
	read -r -p "ARE YOU SURE? [y/N] " response
	
	if [[ $response == "y" ]]
	then
        	BRANCH=`date +%Y%m%d%H%M`
		$GIT reset --hard
        	$GIT branch $BRANCH
        	$GIT checkout $BRANCH
        	$GIT branch -f dev origin/dev
		$GIT checkout dev
        	$GIT branch -D $BRANCH
		$GIT branch -f master origin/master
		$GIT tag -d $DEPLOY_VERSION
		
	else
		exit 0
	fi
}



function __commit_deploy__version(){
	GIT=$1
	 
	$GIT add -u
	
	MESSAGE="[DEPLOY]$DEPLOY_VERSION" 
	$GIT commit -m $MESSAGE

	$GIT checkout master &&  $GIT merge dev -m $MESSAGE
	$GIT tag -fa $DEPLOY_VERSION -m "release" 
	$GIT checkout dev
}

function __commit_snapshot__version(){
	GIT=$1
	
	$GIT add -u
	MESSAGE="[prepare]$NEXT_MEW_VERSION"
	
	$GIT commit -m $MESSAGE 
}




function replace_mew_version(){
	# $1 workspace forder
	# $2 old version
	# $3 new version
	find_replace $1 "<meworkbench.version>$2</meworkbench.version>" "<meworkbench.version>$3</meworkbench.version>"
}

function find_replace(){
	
	echo -e "$INFO forder to search $1"
	echo -e "$INFO searching $2"
	echo -e "$INFO changing to $3"
	
	SED_INPUT="s,$2,$3,g"
	echo -e "-$INFOsed input $SED_INPUT"
	grep -rli --include pom.xml $2 $1 | xargs sed -i -e "$SED_INPUT"
}

