PREVIOUS_MEW_VERSION=1.1.0-SNAPSHOT
DEPLOY_VERSION=1.1.0
NEXT_MEW_VERSION=1.1.1-SNAPSHOT

GIT=./git-generic-mew.sh

source ./mew-build-utils/examples/build.sh

$GIT checkout dev
$GIT pull


replace_mew_version . $PREVIOUS_MEW_VERSION $DEPLOY_VERSION
$GIT add *

MESSAGE="[DEPLOY] version $DEPLOY_VERSION"
$GIT comit -m $MESSAGE
$GIT tag -fa $DEPLOY_VERSION

replace_mew_version . $DEPLOY_VERSION $NEXT_MEW_VERSION
$GIT add *
$GIT comit -m "[update] SNAPSHOT VERSION $NEXT_MEW_VERSION"
$GIT push origin dev
$GIT push origin dev --tags

$GIT chechout master
$GIT pull
$GIT merge ${DEPLOY_VERSION}
$GIT push origin master



