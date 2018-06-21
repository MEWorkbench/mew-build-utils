#!/bin/bash

source git-bash-utils.sh

getProjects "mew_projects.in"
runCommand changeUser ${#PROJECTS[@]} ${#@} "${PROJECTS[@]}" $@

