# Airt AI docker with TensorFlow 2.x and Dask

[![pipeline status](https://gitlab.com/airt.ai/airt-docker-dask-tf2/badges/main/pipeline.svg)](https://gitlab.com/airt.ai/airt-docker-dask-tf2/-/commits/main)

Airt AI Docker container with all tools needed for AI projects including TensorFlow 2.1, Dask, Pandas, Numpy etc.

## Usage

The docker image will be automatically build with each push and, if successful, be available in the container registry:
https://gitlab.com/airt.ai/airt-docker-dask-tf2/container_registry

The easiest way to test the docker on your local machine is to clone the repository, login into contain repository and then start `run_jupyter.sh` script as follows:

```
$ git clone git@gitlab.com:airt.ai/airt-docker-dask-tf2.git
$ cd airt-docker-dask-tf2
$ docker login registry.gitlab.com
$ ./run_jupyter
```

and then open the link in the last line of the console output that should like something like this (token will be different):
```
[C 17:36:29.690 NotebookApp] 
    To access the notebook, open this file in a browser:
        file:///root/.local/share/jupyter/runtime/nbserver-1-open.html
    Or copy and paste one of these URLs:
        http://4dea3c575d28:8888/?token=1d6707220903aa8e2b19b68c9d70dcaa62029fc3c1c98609
     or http://127.0.0.1:8888/?token=1d6707220903aa8e2b19b68c9d70dcaa62029fc3c1c98609
```
