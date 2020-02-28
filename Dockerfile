FROM tensorflow/tensorflow:2.1.0-gpu-py3-jupyter

# ACCESS TOKEN
ARG ACCESS_REP_TOKEN 
# ENV ACCESS_REP_TOKEN=$ACCESS_REP_TOKEN 

# needed to suppress tons of debconf messages
ENV DEBIAN_FRONTEND noninteractive

# update system
RUN apt update
RUN apt-mark hold libcudnn7 cuda-compat-10-1
# RUN apt upgrade --assume-yes --fix-missing

# snappy compression is needed by Parquet and graphviz for visualization of execution graphs by Dask
RUN apt install --assume-yes libsnappy-dev graphviz vim figlet fish htop tmux cmake libncurses5-dev libncursesw5-dev git zip wget
# ADD requirements.txt .
ADD top_level_requirements.txt .

# install requirements
RUN pip3 install --upgrade pip setuptools wheel
RUN pip3 install -r top_level_requirements.txt

# install jupyter theme with airt theme
RUN echo curl -L --header Private-Token:$ACCESS_REP_TOKEN  https://gitlab.com/api/v4/projects/15104297/jobs/artifacts/master/raw/dist/jupyterthemes-0.20.0-py2.py3-none-any.whl?job=wheel_build -o jupyterthemes-0.20.0-py2.py3-none-any.whl
RUN curl -L --header Private-Token:$ACCESS_REP_TOKEN  https://gitlab.com/api/v4/projects/15104297/jobs/artifacts/master/raw/dist/jupyterthemes-0.20.0-py2.py3-none-any.whl?job=wheel_build -o jupyterthemes-0.20.0-py2.py3-none-any.whl
RUN ls -l
RUN pip3 install jupyterthemes-0.20.0-py2.py3-none-any.whl

# customize your jupyter notebook
ADD airt-neg-trans.png .
RUN jt -t airt -cellw 90% -N -T --logo airt-neg-trans.png

# customize bash welcome message
ADD bash.bashrc /etc

# Oh my fish
RUN curl -L https://get.oh-my.fish > install_omf
RUN chmod 777 install_omf
RUN ./install_omf --noninteractive
RUN rm install_omf

# nvtop is locally compiled
ADD nvtop /usr/local/bin

# cleanup
RUN ls -al
RUN rm jupyterthemes-0.20.0-py2.py3-none-any.whl top_level_requirements.txt airt-neg-trans.png

# default shell is bash
ENV SHELL /bin/bash
SHELL ["/bin/bash", ""]

