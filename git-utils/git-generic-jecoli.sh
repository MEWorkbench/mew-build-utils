#!/bin/bash

source git-bash-utils.sh

getProjects "jecoli_projects.in"
runCommand gitGenericCommand ${#PROJECTS[@]} ${#@} "${PROJECTS[@]}" $@

