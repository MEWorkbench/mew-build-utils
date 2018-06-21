#!/bin/bash

source git-bash-utils.sh

getProjects "mew_projects.in"
runCommand gitGenericCommand ${#PROJECTS[@]} ${#@} "${PROJECTS[@]}" $@

