#!/bin/bash
export BRANCH=$(git branch --show-current)

export AIRT_DOCKER=registry.gitlab.com/airt.ai/airt-docker-dask-tf2

if [ "$BRANCH" == "master" ]
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
	docker build --build-arg ACCESS_REP_TOKEN -t $AIRT_DOCKER:`date -u +%Y.%m.%d-%H.%M.%S` -t $AIRT_DOCKER:$TAG .
fi

