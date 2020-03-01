#!/bin/bash

export AIRT_DOCKER=registry.gitlab.com/airt.ai/airt-docker-dask-tf2

if test -z "$AIRT_JUPYTER_PORT"
then
      echo 'AIRT_JUPYTER_PORT variable not set, setting to 8888'
      export AIRT_JUPYTER_PORT=8888
else
    echo AIRT_JUPYTER_PORT variable set to $AIRT_JUPYTER_PORT
fi

if test -z "$AIRT_TB_PORT"
then
      echo 'AIRT_TB_PORT variable not set, setting to 6006'
      export AIRT_TB_PORT=6006
else
    echo AIRT_TB_PORT variable set to $AIRT_TB_PORT
fi

if test -z "$AIRT_DASK_PORT"
then
      echo 'AIRT_DASK_PORT variable not set, setting to 8787'
      export AIRT_DASK_PORT=8787
else
    echo AIRT_DASK_PORT variable set to $AIRT_DASK_PORT
fi

if test -z "$AIRT_DATA"
then
      echo 'AIRT_DATA variable not set, setting to current directory'
      export AIRT_DATA=`pwd`
fi
echo AIRT_DATA variable set to $AIRT_DATA

if test -z "$AIRT_PROJECT"
then
      echo 'AIRT_PROJECT variable not set, setting to current directory'
      export AIRT_PROJECT=`pwd`
fi
echo AIRT_PROJECT variable set to $AIRT_PROJECT

{
    which nvidia-smi &&
    nvidia-smi -L &&
    echo WARNING: Running docker image with all GPU-s &&
    docker run --gpus all --rm -p $AIRT_JUPYTER_PORT:8888 -p $AIRT_TB_PORT:6006 -p $AIRT_DASK_PORT:8787 -v $AIRT_DATA:/work/data -v $AIRT_PROJECT:/tf/project $AIRT_DOCKER
} || {
    echo INFO: INFO: Running docker image without GPU-s
    docker run --rm -p $AIRT_JUPYTER_PORT:8888 -p $AIRT_TB_PORT:6006 -p $AIRT_DASK_PORT:8787 -v $AIRT_DATA:/work/data -v $AIRT_PROJECT:/tf/project $AIRT_DOCKER
}


