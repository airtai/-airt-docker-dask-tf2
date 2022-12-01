#!/bin/bash
export BRANCH=$(git branch --show-current)

export AIRT_DOCKER=ghcr.io/airtai/airt-docker-dask-tf2

if [ "$BRANCH" == "main" ]
then
    export TAG=latest
else
    export TAG=$BRANCH
fi

echo Building $AIRT_DOCKER
docker build --build-arg UBUNTU_VERSION=20.04 --cache-from $AIRT_DOCKER:$TAG -t $AIRT_DOCKER:`date -u +%Y.%m.%d-%H.%M.%S` -t $AIRT_DOCKER:$TAG .

./check_docker.sh
