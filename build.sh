#!/bin/bash
export AIRT_DOCKER=registry.gitlab.com/airt.ai/airt-docker-dask-tf2

if test -z "ACCESS_REP_TOKEN"
then
	echo ERROR: ACCESS_REP_TOKEN must be defined, exiting
	return -1
else
	echo Building $AIRT_DOCKER

	docker build --build-arg ACCESS_REP_TOKEN -t $AIRT_DOCKER:`date -u +%Y.%m.%d-%H.%M.%S` -t $AIRT_DOCKER:latest .
fi

