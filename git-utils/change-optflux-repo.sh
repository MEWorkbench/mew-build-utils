#!/bin/bash

source git-bash-utils.sh

getProjects "optflux_projects.in"
runCommand changeUser ${#PROJECTS[@]} ${#@} "${PROJECTS[@]}" $@
