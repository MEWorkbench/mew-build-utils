
H2_HOME=$HOME/.deploym2

M2REPOSITORY=$H2_HOME/repository
mkdir -p ${M2REPOSITORY}
cp build/oss.sonatype.settings.xml ${H2_HOME}/settings.xml

sed -i s,LOCAL_M2,$H2_HOME,g ${H2_HOME}/settings.xml
sed -i s/OSS_SONATYPE_USER/$OSS_SONATYPE_USER/g ${H2_HOME}/settings.xml
sed -i s/OSS_SONATYPE_PASS/$OSS_SONATYPE_PASS/g ${H2_HOME}/settings.xml
sed -i s/DEPLOYMENT_REPO_ID/$DEPLOYMENT_REPO_ID/g ${H2_HOME}/settings.xml
sed -i s,GPG_EXECUTABLE,$GPG_EXECUTABLE,g ${H2_HOME}/settings.xml
sed -i s,GPG_PASSPHRASE,$GPG_PASSPHRASE,g ${H2_HOME}/settings.xml


echo $GPG_SECRET_KEYS | base64 --decode | $GPG_EXECUTABLE --import
echo $GPG_OWNERTRUST | base64 --decode | $GPG_EXECUTABLE --import-ownertrust

#mvn -s ${H2_HOME}/settings.xml -Dmaven.repo.local=$M2REPOSITORY -P gpg,release-oss-repo help:active-profiles
mvn -s ${H2_HOME}/settings.xml -Dmaven.repo.local=$M2REPOSITORY -Dcplex.jar.path=/data/opt/ibm/ILOG/CPLEX_Studio125/cplex/lib/cplex.jar -P gpg,release-oss-repo deploy 
