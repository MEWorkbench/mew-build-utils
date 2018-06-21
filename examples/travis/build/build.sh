#!/bin/bash

function find_replace(){
	
	echo "forder to search $1"
	echo "Searching $2"
	echo "Changing to $3"
	
	SED_INPUT="s/$2/$3/g"
	echo "sed input $SED_INPUT"
	grep -rli --include "pom.xml" $2 $1 | xargs sed -i $SED_INPUT
}

