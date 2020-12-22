FROM tensorflow/tensorflow:2.3.1-gpu-jupyter

# Token to authenticate for jt
ARG CI_JOB_TOKEN
ARG ACCESS_REP_TOKEN

# needed to suppress tons of debconf messages
ENV DEBIAN_FRONTEND noninteractive

# needed for TF serving
RUN echo "deb [arch=amd64] http://storage.googleapis.com/tensorflow-serving-apt stable tensorflow-model-server tensorflow-model-server-universal" | tee /etc/apt/sources.list.d/tensorflow-serving.list && curl https://storage.googleapis.com/tensorflow-serving-apt/tensorflow-serving.release.pub.gpg | apt-key add -


# update system
RUN apt update --fix-missing
RUN apt-mark hold libcudnn7 cuda-compat-10-1
# RUN apt upgrade --assume-yes --fix-missing

RUN apt install --assume-yes wget alien libaio-dev

# Install oracle client library
RUN wget -O oracle-client-19.9.rpm https://download.oracle.com/otn_software/linux/instantclient/199000/oracle-instantclient19.9-basic-19.9.0.0.0-1.x86_64.rpm
RUN alien -i --scripts oracle-client-19.9.rpm

RUN apt install --assume-yes ruby-full build-essential zlib1g-dev

RUN gem install jekyll
RUN gem install bundler:2.0.2

ADD Gemfile .
RUN bundle install
RUN rm Gemfile

# snappy compression is needed by Parquet and graphviz for visualization of execution graphs by Dask
RUN apt install --assume-yes libsnappy-dev graphviz vim figlet fish htop tmux cmake libncurses5-dev \
    libncursesw5-dev git zip nano make ssh-client less sudo \
    openssh-client alien libaio-dev firefox-geckodriver tensorflow-model-server

# customize bash welcome message
ADD bash.bashrc /etc

# nvtop is locally compiled
ADD nvtop /usr/local/bin

# install requirements
RUN pip3 install --upgrade setuptools wheel
ADD top_level_requirements.txt .
RUN pip3 install -r top_level_requirements.txt

RUN ls

# install jupyter theme with airt theme
RUN if [ -n "$ACCESS_REP_TOKEN" ] ; \
    then pip3 install git+https://oauth2:${ACCESS_REP_TOKEN}@gitlab.com/airt.ai/jupyter-themes.git ; \
    else pip3 install git+https://gitlab-ci-token:${CI_JOB_TOKEN}@gitlab.com/airt.ai/jupyter-themes.git ; \
    fi

# customize your jupyter notebook
ADD airt-neg-trans-small.png /root
ADD infobip-small*.png /root/ 
RUN jt -t airtd -cellw 90% -N -T --logo /root/airt-neg-trans-small.png

# Install and enable black python formatter for notebooks
RUN jupyter nbextension install https://github.com/drillan/jupyter-black/archive/master.zip
RUN jupyter nbextension enable jupyter-black-master/jupyter-black

# cleanup
RUN ls -al
RUN rm top_level_requirements.txt oracle-client-19.9.rpm

# Oh my fish
RUN curl -L https://get.oh-my.fish > install_omf
RUN chmod 777 install_omf
RUN ./install_omf --noninteractive
RUN rm install_omf
RUN echo omf install bobthefish | fish
ADD config.fish /root/.config/fish/config.fish


RUN chmod -R 777 /root

# needed for shell to operate properly
ENV USER airt
ENV HOME /root

RUN mkdir -p /root/.local/bin
RUN chmod 777 /root/.local/bin

# default shell is fish
ENV SHELL /usr/bin/fish
SHELL ["/usr/bin/fish", "-c"]

