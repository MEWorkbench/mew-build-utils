#!/bin/bash


source git-bash-utils.sh

getProjects "optflux_projects.in"
runCommand gitGenericCommand ${#PROJECTS[@]} ${#@} "${PROJECTS[@]}" $@
