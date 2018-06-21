#!/bin/bash


# $1 project directory
# $@ comand gereric in git
gitGenericCommand(){

	exec="git --git-dir=$1/.git --work-tree=$1 ${@: 2}"
	echo "running command: ${exec}"
	${exec}
	
}

# $1 project name
# $2 repository
gitClone(){
	exec="git clone $2/$1 $1"
	echo "running command: ${exec}"
	${exec}
}


# $1 project name
# $2 repository
changeUser(){
	exec="git --git-dir=$1/.git --work-tree=$1 remote set-url origin $2/$1"
	echo "$exec"
	${exec}
}

#S1 file where the projects are identified
getProjects(){
	source $1
}


#$1 command
#$2 number of projects
#$3 number of arguments 
#$4 projects
#$5 arguments

runCommand(){

	local COMMAND=$1
	local SIZEARRAY1=$2
	local SIZEARRAY2=$3
	
	
	local end1=$(($SIZEARRAY1+3))
	local end2=$(($end1+$SIZEARRAY2))

	
	local PROJECTS=("${@:4:$SIZEARRAY1}")
	local COMMANDPARANS=("${@:$(($end1+1)):$SIZEARRAY2}")
	
	
	echo "$end1 $end2"
	echo $@
	#echo "COMMAND: "$COMMAND
	#echo "PROJECTS: ${PROJECTS[@]}"
	#echo "COMMADPARAMS: ${COMMANDPARANS[@]}"
	
	for p in "${PROJECTS[@]}"
	do
		_proj=($p)
		_params=("${COMMANDPARANS[@]}")
		#echo $COMMAND
		#echo $_proj
		#echo $_params
		heheh="$COMMAND $_proj ${_params[@]}"
		$heheh
		
	done
}

