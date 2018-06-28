#!/bin/bash

function prepare_mew_release(){

	prepare_release $1 $2 $3 ./git-generic-jecoli.sh
	prepare_release $1 $2 $3 ./git-generic-mew.sh
	
}

fuc


function prepare_release(){
	
	PREVIOUS_MEW_VERSION=$1
	DEPLOY_VERSION=$2
	NEXT_MEW_VERSION=$3
	GIT=$4
	
	#$GIT checkout master
	# $GIT pull 
	
	#$GIT checkout dev
	# $GIT pull

	##THIS COMMAND REPLACE all versions in folder
	replace_mew_version . $PREVIOUS_MEW_VERSION $DEPLOY_VERSION 
	$GIT add -A && \
\
	MESSAGE="[DEPLOY]$DEPLOY_VERSION" 
	$GIT commit -m $MESSAGE

	$GIT checkout master &&  $GIT merge dev -m $MESSAGE
	$GIT tag -fa $DEPLOY_VERSION -m "release" 

	$GIT checkout dev
 
	##THIS COMMAND REPLACE all versions in folder
	replace_mew_version . $DEPLOY_VERSION $NEXT_MEW_VERSION 
	$GIT add -A 
	MESSAGE="[update]$NEXT_MEW_VERSION" 
	$GIT commit -m \"$MESSAGE\"

	return 0
}
 

function release_mew(){
	release ./git-generic-jecoli.sh && \
	release ./git-generic-mew.sh
	
}

function release(){
	GIT=$1
	$GIT push origin dev &&
	$GIT push origin master &&
	$GIT push origin --tags
}

function reset_mew(){
	
	reset $1 ./git-generic-mew.sh
	reset $1 ./git-generic-jecoli.sh
}

function reset(){
	TAG_VERSION=$1	
	GIT=$2
	
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
		$GIT tag -d $TAG_VERSION
		
	else
		exit 0
	fi
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


function find_mew_version(){

	PATTER="\<meworkbench.version\>$2\<\/meworkbench.version\>"
	echo "forder to search $1"
	echo "Searching $2"
	grep -rli --include "pom.xml" $2 $1 
}


