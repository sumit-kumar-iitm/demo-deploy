#!/bin/bash -e
set -x

whoami

echo "Runing git log to show the last 10 changes"
git log -n10

export MAVEN_OPTS="-Xmx1024m"
export JAVA_OPTS="-Xms512m -Xmx2048m -XX:MaxPermSize=1024m"

commit=$(git rev-parse HEAD)

echo "Last commit id ${commit}"

# Define params based on whether this is a snapshot or Release build
# Make it case insensitive (Release or release)
if [[ $GIT_BRANCH == */release* ]]; then

	echo "Running a Release build"

#   	export VERSION_SRC_DIR=`dirname $0`
#   	. $VERSION_SRC_DIR/build.properties
#   	if [ -z $RELEASE_VERSION  ]; then
#		echo "Make sure build.properties is present in the root directory\
# 		of the git repo and contains value for variable RELEASE_VERSION"
#		exit 1
#	else
#		num_digits=$(echo $RELEASE_VERSION | tr '.' '\n' | wc -l)
#		if [ $num_digits != 3 ]; then
#			echo "Give only three digits for variable RELEASE_VERSION, example 1.2.3"
#			exit 1
#		fi
#	fi
#
#	export FINAL_VERSION=$RELEASE_VERSION.$BUILD_NUMBER
#	echo "Building version $FINAL_VERSION"

    #find . -type f -name "pom.xml" -exec sed -i -e "s/0\.0\.1-SNAPSHOT/${FINAL_VERSION}/g" {} +

   export MVN_TARGETS="release:clean release:prepare release:perform -Djavax.xml.accessExternalSchema=all"

   # All maven commands in this scrip must use the -s option
   export MAVEN_COMMAND="./mvnw -B -s settings.xml"

   # build and publish/install to nexus app artifact (CI Build)
   $MAVEN_COMMAND $MVN_TARGETS #$MVNPARAMS
fi