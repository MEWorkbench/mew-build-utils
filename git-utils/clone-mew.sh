#!/bin/bash

source git-bash-utils.sh

getProjects "mew_projects.in"
runCommand gitClone ${#PROJECTS[@]} 1 "${PROJECTS[@]}" "git@github.com:MEWorkbench"


