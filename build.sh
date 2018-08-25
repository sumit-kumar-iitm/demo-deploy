#!/bin/bash -e
set -x

whoami

echo "Runing git log to show the last 10 changes"
git log -n10

export MAVEN_OPTS="-Xmx1024m"
export JAVA_OPTS="-Xms512m -Xmx2048m -XX:MaxPermSize=1024m"

commit=$(git rev-parse HEAD)

function is_tag() {
   set +e
   v=$(git tag --points-at ${commit})
   if [ $? -ne 0 ]; then
      set -e
      echo "Unable to determine if this commit is a tag."
      exit 1
   elif [[ ${v} == "" ]]; then
      set -e
      return 1
   else
      set -e
      return 0
   fi
}

function get_version() {
    if is_tag; then
        echo "$(git tag --points-at ${commit})"
    else
        echo "${commit}"
    fi
}

# Define params based on whether this is a snapshot or Release build
# Make it case insensitive (Release or release)
if [[ $GIT_BRANCH == */release* ]]; then

	echo "Running a Release build"

   	export VERSION_SRC_DIR=`dirname $0`
   	. $VERSION_SRC_DIR/build.properties
   	if [ -z $RELEASE_VERSION  ]; then
		echo "Make sure build.properties is present in the root directory\
 		of the git repo and contains value for variable RELEASE_VERSION"
		exit 1
	else
		num_digits=$(echo $RELEASE_VERSION | tr '.' '\n' | wc -l)
		if [ $num_digits != 3 ]; then
			echo "Give only three digits for variable RELEASE_VERSION, example 1.2.3"
			exit 1
		fi
	fi

	export FINAL_VERSION=$RELEASE_VERSION.$BUILD_NUMBER
    git tag $FINAL_VERSION
    git push origin release $FINAL_VERSION
	echo "Building version $FINAL_VERSION"

    find . -type f -name "pom.xml" -exec sed -i -e "s/0\.0\.1-SNAPSHOT/${FINAL_VERSION}/g" {} +

   #localPath=`pwd`
   #$localPath/checkmarx.sh

   export MVN_TARGETS="clean deploy -Djavax.xml.accessExternalSchema=all"
   #export TargetGTGRepo=ENG.CTG.Intuit-Releases
   #export MVNPARAMS="-Dsource.label=$GIT_COMMIT -Durl=$NEXUS_REPO_URL/$TargetGTGRepo/ -DaltDeploymentRepository=nexusserver::default::$NEXUS_REPO_URL/$TargetGTGRepo/ -Ddev.repo.url=$NEXUS_REPO_URL/$TargetGTGRepo/ -Drelease.repo.url=$NEXUS_REPO_URL/$TargetGTGRepo/ -DSTD_REPO_ID=nexusrelserver"
   #export CICDProfile=scm.build

   # All maven commands in this scrip must use the -s option
   export MAVEN_COMMAND="./mvnw -B -s settings.xml"

   # build and publish/install to nexus app artifact (CI Build)
   $MAVEN_COMMAND $MVN_TARGETS #$MVNPARAMS
fi