#!/bin/bash

source git-bash-utils.sh

getProjects "optflux_projects.in"
runCommand gitClone ${#PROJECTS[@]} 1 "${PROJECTS[@]}" "git://git.code.sf.net/p/optflux"
