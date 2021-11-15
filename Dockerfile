FROM tensorflow/tensorflow:2.6.1-gpu-jupyter

# Token to authenticate for jt
ARG CI_JOB_TOKEN
ARG ACCESS_REP_TOKEN

# needed to suppress tons of debconf messages
ENV DEBIAN_FRONTEND noninteractive

RUN apt-mark hold cuda-compat-11-2

# needed for TF serving
RUN echo "deb [arch=amd64] http://storage.googleapis.com/tensorflow-serving-apt stable tensorflow-model-server tensorflow-model-server-universal" | tee /etc/apt/sources.list.d/tensorflow-serving.list \
    && curl https://storage.googleapis.com/tensorflow-serving-apt/tensorflow-serving.release.pub.gpg | apt-key add -

# needed for python3.8
#RUN add-apt-repository ppa:deadsnakes/ppa


RUN apt update --fix-missing \
    && apt install --assume-yes --fix-missing --no-install-recommends\
      wget alien libaio-dev libsnappy-dev graphviz vim figlet fish htop tmux cmake libncurses5-dev \
      libncursesw5-dev git zip nano make less sudo \
      alien libaio-dev firefox-geckodriver build-essential zlib1g-dev ssh-client openssh-client libmysqlclient-dev \
      python3.8-dev \
    && apt purge --auto-remove && apt clean && rm -rf /var/lib/apt/lists/*

# use Python 3.9 as default
#RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1
#RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 2
#RUN update-alternatives --config python3
RUN python3 -V
RUN pip install --upgrade pip
#RUN python -m pip install --upgrade pip

# Install oracle client library
#RUN wget -O oracle-client-19.9.rpm https://download.oracle.com/otn_software/linux/instantclient/199000/oracle-instantclient19.9-basic-19.9.0.0.0-1.x86_64.rpm \
#    && alien -i --scripts oracle-client-19.9.rpm \
#    && rm oracle-client-19.9.rpm

#RUN gem install jekyll bundler

#ADD Gemfile .
#RUN bundle install && rm Gemfile

# customize bash welcome message
ADD bash.bashrc /etc

# nvtop is locally compiled
ARG UBUNTU_VERSION
ADD nvtop-${UBUNTU_VERSION} /usr/local/bin/nvtop

# install requirements
#RUN conda install --name rapids nb_conda_kernels # pip 
#ENV PATH /opt/conda/envs/rapids/bin:$PATH
#RUN source activate rapids && pip install --no-cache-dir setuptools wheel jupyter matplotlib jupyter_http_over_ws ipykernel nbformat

#RUN pip install --no-cache-dir setuptools==58.0.4 wheel six==1.15.0
ADD top_level_requirements.txt .
RUN pip install --no-cache-dir -r top_level_requirements.txt && rm top_level_requirements.txt
RUN jupyter serverextension enable --py jupyter_http_over_ws

# install jupyter theme with airt theme
RUN if [ -n "$ACCESS_REP_TOKEN" ] ; \
    then pip install --no-cache-dir git+https://oauth2:${ACCESS_REP_TOKEN}@gitlab.com/airt.ai/jupyter-themes.git ; \
    else pip install --no-cache-dir git+https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.com/airt.ai/jupyter-themes.git ; \
    fi

# customize your jupyter notebook
ADD airt-neg-trans-small.png /root
ADD infobip-small*.png /root/ 
RUN jt -t airtd -cellw 90% -N -T --logo /root/airt-neg-trans-small.png

# Install and enable black python formatter for notebooks
RUN jupyter nbextension install https://github.com/drillan/jupyter-black/archive/master.zip \
    && jupyter nbextension enable jupyter-black-master/jupyter-black

RUN jupyter contrib nbextension install
RUN jupyter nbextension enable collapsible_headings/main

# Oh my fish
RUN curl --insecure -L https://get.oh-my.fish > install_omf \
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
#SHELL ["conda", "run", "-n", "rapids", "/usr/bin/fish", "-c"]
#SHELL ["/usr/bin/fish", "-c"]
#RUN conda init fish
#RUN echo "conda activate rapids" >> /root/.config/fish/config.fish

WORKDIR /tf

RUN rm -rf /tf/tensorflow*

ENTRYPOINT []
CMD ["/usr/bin/fish", "-c", "jupyter notebook --notebook-dir=/tf --ip 0.0.0.0 --no-browser --allow-root"]

RUN chmod -R 777 /root/.config

