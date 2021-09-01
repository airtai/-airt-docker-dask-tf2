ARG UBUNTU_VERSION=18.04

ARG ARCH
ARG CUDA=11.2

FROM rapidsai/rapidsai:0.19-cuda${CUDA}-base-ubuntu${UBUNTU_VERSION}-py3.8

######################################################################################
######################################################################################
######################################################################################
#
# BEGIN part from from TF 2.5.0-rc1 Dockerfile
#
# see https://github.com/tensorflow/tensorflow/blob/v2.5.0-rc1/tensorflow/tools/dockerfiles/dockerfiles/gpu-jupyter.Dockerfile

ARG ARCH
ARG CUDA
ARG CUDNN=8.1.0.77-1
ARG CUDNN_MAJOR_VERSION=8
ARG LIB_DIR_PREFIX=x86_64
ARG LIBNVINFER=7.2.2-1
ARG LIBNVINFER_MAJOR_VERSION=7

# Needed for string substitution
SHELL ["/bin/bash", "-c"]
# Pick up some TF dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cuda-command-line-tools-${CUDA/./-} \
        libcublas-${CUDA/./-} \
        cuda-nvrtc-${CUDA/./-} \
        libcufft-${CUDA/./-} \
        libcurand-${CUDA/./-} \
        libcusolver-${CUDA/./-} \
        libcusparse-${CUDA/./-} \
        curl \
        libcudnn8=${CUDNN}+cuda${CUDA} \
        libfreetype6-dev \
        libhdf5-serial-dev \
        libzmq3-dev \
        pkg-config \
        software-properties-common \
        unzip

# Install TensorRT if not building for PowerPC
# NOTE: libnvinfer uses cuda11.1 versions
RUN [[ "${ARCH}" = "ppc64le" ]] || { apt-get update && \
        apt-get install -y --no-install-recommends libnvinfer${LIBNVINFER_MAJOR_VERSION}=${LIBNVINFER}+cuda11.1 \
        libnvinfer-plugin${LIBNVINFER_MAJOR_VERSION}=${LIBNVINFER}+cuda11.1 \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*; }

# For CUDA profiling, TensorFlow requires CUPTI.
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Link the libcuda stub to the location where tensorflow is searching for it and reconfigure
# dynamic linker run-time bindings
RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 \
    && echo "/usr/local/cuda/lib64/stubs" > /etc/ld.so.conf.d/z-cuda-stubs.conf \
    && ldconfig
    
#
# END part from from TF 2.5.0-rc1 Dockerfile
#
######################################################################################
######################################################################################
######################################################################################

# Token to authenticate for jt
ARG CI_JOB_TOKEN
ARG ACCESS_REP_TOKEN

# needed to suppress tons of debconf messages
ENV DEBIAN_FRONTEND noninteractive

RUN apt-mark hold cuda-compat-11-2

# needed for TF serving
RUN echo "deb [arch=amd64] http://storage.googleapis.com/tensorflow-serving-apt stable tensorflow-model-server tensorflow-model-server-universal" | tee /etc/apt/sources.list.d/tensorflow-serving.list \
    && curl https://storage.googleapis.com/tensorflow-serving-apt/tensorflow-serving.release.pub.gpg | apt-key add -

RUN apt update --fix-missing \
    && apt install --assume-yes --fix-missing --no-install-recommends wget alien libaio-dev libsnappy-dev graphviz vim figlet fish htop tmux cmake libncurses5-dev \
    libncursesw5-dev git zip nano make less sudo \
    alien libaio-dev firefox-geckodriver ruby-full build-essential zlib1g-dev ssh-client openssh-client libmysqlclient-dev \
    && apt purge --auto-remove && apt clean && rm -rf /var/lib/apt/lists/*

# Install oracle client library
RUN wget -O oracle-client-19.9.rpm https://download.oracle.com/otn_software/linux/instantclient/199000/oracle-instantclient19.9-basic-19.9.0.0.0-1.x86_64.rpm \
    && alien -i --scripts oracle-client-19.9.rpm \
    && rm oracle-client-19.9.rpm

RUN gem install jekyll bundler

#ADD Gemfile .
#RUN bundle install && rm Gemfile

# customize bash welcome message
ADD bash.bashrc /etc

# nvtop is locally compiled
ARG UBUNTU_VERSION
ADD nvtop-${UBUNTU_VERSION} /usr/local/bin/nvtop

# install requirements
RUN conda install --name rapids nb_conda_kernels # pip 
ENV PATH /opt/conda/envs/rapids/bin:$PATH
RUN source activate rapids && pip install --no-cache-dir setuptools wheel jupyter matplotlib jupyter_http_over_ws ipykernel nbformat

ADD top_level_requirements.txt .
RUN source activate rapids && pip install --no-cache-dir -r top_level_requirements.txt && rm top_level_requirements.txt
RUN jupyter serverextension enable --py jupyter_http_over_ws

# install jupyter theme with airt theme
RUN source activate rapids && if [ -n "$ACCESS_REP_TOKEN" ] ; \
    then pip install --no-cache-dir git+https://oauth2:${ACCESS_REP_TOKEN}@gitlab.com/airt.ai/jupyter-themes.git ; \
    else pip install --no-cache-dir git+https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.com/airt.ai/jupyter-themes.git ; \
    fi

# customize your jupyter notebook
ADD airt-neg-trans-small.png /root
ADD infobip-small*.png /root/ 
RUN source activate rapids && jt -t airtd -cellw 90% -N -T --logo /root/airt-neg-trans-small.png

# Install and enable black python formatter for notebooks
RUN source activate rapids && jupyter nbextension install https://github.com/drillan/jupyter-black/archive/master.zip \
    && jupyter nbextension enable jupyter-black-master/jupyter-black


# Oh my fish
RUN curl -L https://get.oh-my.fish > install_omf \
    && chmod 777 install_omf \
    && ./install_omf --noninteractive \
    && rm install_omf \
    && echo omf install bobthefish | fish
ADD config.fish /root/.config/fish/config.fish


RUN chmod -R 777 /root

# needed for shell to operate properly
ENV USER airt
ENV HOME /root

RUN mkdir -p /root/.local/bin && chmod 777 /root/.local/bin

# default shell is fish
ENV SHELL /usr/bin/fish
SHELL ["conda", "run", "-n", "rapids", "/usr/bin/fish", "-c"]
RUN conda init fish
RUN echo "conda activate rapids" >> /root/.config/fish/config.fish

WORKDIR /tf

ENTRYPOINT []
CMD ["/usr/bin/fish", "-c", "conda activate rapids; jupyter notebook --notebook-dir=/tf --ip 0.0.0.0 --no-browser --allow-root"]

RUN chmod -R 777 /root/.config
