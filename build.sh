#!/bin/bash
export BRANCH=$(git branch --show-current)

export AIRT_DOCKER=registry.gitlab.com/airt.ai/airt-docker-dask-tf2

if [ "$BRANCH" == "main" ]
then
    export TAG=latest
else
    export TAG=$BRANCH
fi

if test -z "$ACCESS_REP_TOKEN"
then
	echo ERROR: ACCESS_REP_TOKEN must be defined, exiting
	exit -1
else
	echo Building $AIRT_DOCKER
	docker build --build-arg ACCESS_REP_TOKEN --build-arg UBUNTU_VERSION=20.04 --cache-from $AIRT_DOCKER:$TAG -t $AIRT_DOCKER:`date -u +%Y.%m.%d-%H.%M.%S` -t $AIRT_DOCKER:$TAG .
fi
 
# this one is for the full report
trivy image -s CRITICAL,HIGH $AIRT_DOCKER:$TAG
# this one will fail if needed
trivy image --exit-code 1 --ignore-unfixed $AIRT_DOCKER:$TAG
#trivy image --exit-code 1 -s HIGH,CRITICAL,MEDIUM,LOW --ignore-unfixed $AIRT_DOCKER:$TAG

