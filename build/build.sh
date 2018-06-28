function clean(){
	rm -rf $SRC_BUILD
}


function mew_make(){
	
	
	mkdir -p $SRC_BUILD
	echo TEST:$SRC_BUILD
	
	cp $BUILD_FOLDER/git-utils/* $SRC_BUILD/
	cd $SRC_BUILD
	
	./clone-jecoli.sh
	./clone-mew.sh
	 
	./git-generic-jecoli.sh checkout dev 
	./git-generic-mew.sh checkout dev 
	replace_mew_version . $PREVIOUS_MEW_VERSION $DEPLOY_VERSION
	
	__commit_deploy__version ./git-generic-jecoli.sh
	__commit_deploy__version ./git-generic-mew.sh 
	
	replace_mew_version . $DEPLOY_VERSION $NEXT_MEW_VERSION
	__commit_snapshot__version ./git-generic-mew.sh
	__commit_snapshot__version ./git-generic-jecoli.sh
	

	
}

function mew_release(){
	cd $SRC_BUILD
	release ./git-generic-mew.sh
	release ./git-generic-jecoli.sh
}

function release(){
	GIT=$1
	$GIT push origin master &&
	$GIT push origin --tags &&
	$GIT push origin dev
	
	
}

function mew_reset(){
	cd $SRC_BUILD
	reset ./git-generic-jecoli.sh
	reset ./git-generic-mew.sh
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
	
	echo "forder to search $1"
	echo "Searching $2"
	echo "Changing to $3"
	
	SED_INPUT="s,$2,$3,g"
	echo "sed input $SED_INPUT"
	grep -rli --include pom.xml $2 $1 | xargs sed -i -e "$SED_INPUT"
}

