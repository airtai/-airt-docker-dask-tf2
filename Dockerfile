FROM tensorflow/tensorflow:2.10.0-gpu-jupyter

# needed to suppress tons of debconf messages
ENV DEBIAN_FRONTEND noninteractive

# make sure we don't upgrade cuda installed by TF because everything t likely ill break
RUN apt-mark hold cuda-compat-11-2

# needed for TF serving
# RUN echo "deb [arch=amd64] http://storage.googleapis.com/tensorflow-serving-apt stable tensorflow-model-server tensorflow-model-server-universal" | tee /etc/apt/sources.list.d/tensorflow-serving.list \
#     && curl https://storage.googleapis.com/tensorflow-serving-apt/tensorflow-serving.release.pub.gpg | apt-key add -

# needed for python3.8
#RUN add-apt-repository ppa:deadsnakes/ppa

# RUN rm /etc/apt/sources.list.d/cuda.list && rm /etc/apt/sources.list.d/nvidia-ml.list

# install security updates
RUN apt update --fix-missing
RUN apt install --assume-yes unattended-upgrades
# Enable unattended-upgrades
RUN dpkg-reconfigure --priority=low unattended-upgrades
# The above command will create a config file in /etc/apt/apt.conf.d/20auto-upgrades.
# Printing the contents of the configuration file. 
# If the configuration for Unattended-Upgrade is "1" then the unattended upgrade will run every 1 day. If the number is "0" then unattended upgrades are disabled.
RUN cat /etc/apt/apt.conf.d/20auto-upgrades
# The below command will check and run upgrade only once while building
RUN unattended-upgrade -d



RUN apt install --assume-yes --fix-missing --no-install-recommends\
      wget alien libaio-dev libsnappy-dev graphviz vim figlet fish htop tmux cmake libncurses5-dev \
      libncursesw5-dev git zip nano make less sudo \
      alien libaio-dev build-essential zlib1g-dev ssh-client openssh-client libmysqlclient-dev \
      unattended-upgrades \
    && apt purge --auto-remove && apt clean && rm -rf /var/lib/apt/lists/*

# use Python 3.9 as default
#RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1
#RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 2
#RUN update-alternatives --config python3
RUN python3 -V
RUN pip install --upgrade pip
#RUN python -m pip install --upgrade pip

# Jupyter notebook has following vulnerability CVE-2022-29238, so manually installing version with fix
# Please remove once the recent version is included in tensorflow docker image
RUN pip install notebook==6.4.12

# Install oracle client library
#RUN wget -O oracle-client-19.9.rpm https://download.oracle.com/otn_software/linux/instantclient/199000/oracle-instantclient19.9-basic-19.9.0.0.0-1.x86_64.rpm \
#    && alien -i --scripts oracle-client-19.9.rpm \
#    && rm oracle-client-19.9.rpm

#RUN gem install jekyll bundler

#ADD Gemfile .
#RUN bundle install && rm Gemfile

# customize bash welcome message
COPY bash.bashrc /etc

# nvtop is locally compiled
ARG UBUNTU_VERSION
COPY nvtop-${UBUNTU_VERSION} /usr/local/bin/nvtop

# install requirements
#RUN conda install --name rapids nb_conda_kernels # pip 
#ENV PATH /opt/conda/envs/rapids/bin:$PATH
#RUN source activate rapids && pip install --no-cache-dir setuptools wheel jupyter matplotlib jupyter_http_over_ws ipykernel nbformat

#RUN pip install --no-cache-dir setuptools==58.0.4 wheel six==1.15.0
COPY top_level_requirements.txt .
RUN pip install --no-cache-dir -r top_level_requirements.txt && rm top_level_requirements.txt
RUN jupyter serverextension enable --py jupyter_http_over_ws

# Install azure cli
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# install jupyter theme with airt theme
RUN pip install --no-cache-dir git+https://github.com/airtai/jupyter-themes.git

# customize your jupyter notebook
COPY airt-neg-trans-small.png /root
#ADD infobip-small*.png /root/
COPY airt_favicons /root/airt_favicons
RUN jt -t airtd -cellw 90% -N -T --logo /root/airt-neg-trans-small.png --fav_icon_dir /root/airt_favicons
RUN rm -rf /root/airt-neg-trans-small.png /root/airt_favicons

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
COPY config.fish /root/.config/fish/config.fish


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

