
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
	echo "[+] creating prepare log on $SRC_BUILD/mvn.prepare.log"

	echo "[+] changing jecoli to branch dev"
	./git-generic-jecoli.sh checkout dev >> $SRC_BUILD/mvn.release.log
	echo "[+] changing mew to branch dev"
	./git-generic-mew.sh checkout dev >> $SRC_BUILD/mvn.release.log
	
	echo "[+] changing version $PREVIOUS_MEW_VERSION to $DEPLOY_VERSION"
	replace_mew_version . $PREVIOUS_MEW_VERSION $DEPLOY_VERSION >> $SRC_BUILD/mvn.release.log
	
	echo "[+] commit version in local repos"
	__commit_deploy__version ./git-generic-jecoli.sh
	__commit_deploy__version ./git-generic-mew.sh 
	
	echo "[+] changing version $DEPLOY_VERSION to $NEXT_MEW_VERSION"
	replace_mew_version . $DEPLOY_VERSION $NEXT_MEW_VERSION

	echo "[+] commit version in local repos"
	__commit_snapshot__version ./git-generic-mew.sh
	__commit_snapshot__version ./git-generic-jecoli.sh

	echo "[?] PREPARE WAS CONCLUDED!! verify git history projects on folder: $SRC_BUILD"
	echo "[?] perform submit to commit the changes on server"
	echo "[?] perform reset to revert the process"
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
    echo "[+] Creating new config file:"
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

    echo "[+] configurations file created in $conf"
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

	echo "[+] creating deploy repository"
	mvn3 -s ~/.deploym2/settings.xml -P release-oss-repo -DopenedRepositoryMessageFormat='MEW_NEXT_NEXUX_REPOSITORY: %s' nexus-staging:rc-open >> $SRC_BUILD/mvn.deploy.log
	[ $? != 0 ]  && echo "[!] PROBLEM opening next nexus repository see file $SRC_BUILD/mvn.deploy.log"  && exit
	DEPLOY_REPO=`cat $SRC_BUILD/mvn.deploy.log | grep "MEW_NEXT_NEXUX_REPOSITORY: " | sed 's/.*\(ptuminhocebbiosystems.*\)/\1/'` 
	[ $? != 0 ]  && echo "[!] PROBLEM retriving the next nexux repository" && exit

	cd $OLD_DIR
}


function nexus_deploy(){

	M2_HOME=$HOME/.deploym2
	[ ! -f "$conf" ] && echo "[!] Config file not found" && create_conf && exit
	source $conf && echo "[+] import configurations from $conf"
	configure_deploy

	source $BUILD_FOLDER/git-utils/jecoli_projects.in
	ALL_PROJECTS=(${PROJECTS[@]})
	source $BUILD_FOLDER/git-utils/mew_projects.in
	ALL_PROJECTS=(${ALL_PROJECTS[@]} ${PROJECTS[@]})

	echo -en "MAVEN_DEPLOY_LOG:\n"> $SRC_BUILD/mvn.deploy.log 
	echo "[+] create maven log in: "$SRC_BUILD/mvn.deploy.log
	set_deploy_repo $ALL_PROJECTS
	
	OLD_PATH=`pwd`
	for p in "${ALL_PROJECTS[@]}"
	do
		_proj=$SRC_BUILD/$p
		echo "[+] deploy $p to $DEPLOY_REPO"
		cd $_proj && 
		$MAVEN_COMMAND -s ${M2_HOME}/settings.xml -Dmaven.repo.local=$M2REPOSITORY -DskipTests=true -Dgpg.useagent=false -Dgpg.passphrase=$GPG_PASSPHRASE -DstagingRepositoryId=$DEPLOY_REPO -Dcplex.jar.path=${CPLEX_JAR} -P gpg,release-oss-repo clean deploy >> $SRC_BUILD/mvn.deploy.log
		[ $? != 0 ] && tail $SRC_BUILD/mvn.deploy.log && echo "[!] PROBLEM $p see file $SRC_BUILD/mvn.deploy.log"  &&exit
	done
	cd $OLD_PATH
	#rm -rf $M2_HOME
}




function mew_release(){
	OLD_DIR=`pwd`
	cd $SRC_BUILD
	echo -en "RELEASE LOG:\n"> $SRC_BUILD/mvn.release.log 
	echo "[+] creating release log on $SRC_BUILD/mvn.release.log"
	release ./git-generic-jecoli.sh
	release ./git-generic-mew.sh
	cd $OLD_DIR
	
}

function release(){
	GIT=$1
	echo "[+] pushing master using $GIT"
	$GIT push origin master >> $SRC_BUILD/mvn.release.log 
	[ $? != 0 ]  && echo "[!] PROBLEM pushing master using $GIT" && exit
	echo "[+] pushing tags using $GIT"
	$GIT push origin --tags >> $SRC_BUILD/mvn.release.log 
	[ $? != 0 ]  && echo "[!] PROBLEM pushing tags using $GIT" && exit
	$GIT push origin dev >> $SRC_BUILD/mvn.release.log 
	echo "[+] pushing dev using $GIT"
	[ $? != 0 ]  && echo "[!] PROBLEM pushing dev using $GIT" && exit
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
	 
	$GIT add -A
	
	MESSAGE="[DEPLOY]$DEPLOY_VERSION" 
	$GIT commit -m $MESSAGE

	$GIT checkout master &&  $GIT merge dev -m $MESSAGE
	$GIT tag -fa $DEPLOY_VERSION -m "release" 
	$GIT checkout dev
}

function __commit_snapshot__version(){
	GIT=$1
	
	$GIT add -A
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
	
	echo "[+] forder to search $1"
	echo "[+] searching $2"
	echo "[+] changing to $3"
	
	SED_INPUT="s,$2,$3,g"
	echo "-[+]sed input $SED_INPUT"
	grep -rli --include pom.xml $2 $1 | xargs sed -i -e "$SED_INPUT"
}

