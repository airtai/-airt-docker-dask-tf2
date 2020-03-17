#!/bin/bash

docker build --build-arg ACCESS_REP_TOKEN -t registry.gitlab.com/airt.ai/airt-docker-dask-tf2 .
