FROM tensorflow/tensorflow:2.1.0-gpu-py3-jupyter

# ACCESS TOKEN
ARG ACCESS_REP_TOKEN 
# ENV ACCESS_REP_TOKEN=$ACCESS_REP_TOKEN 

# needed to suppress tons of debconf messages
ENV DEBIAN_FRONTEND noninteractive

# update system
RUN apt update --fix-missing
RUN apt-mark hold libcudnn7 cuda-compat-10-1
# RUN apt upgrade --assume-yes --fix-missing

# snappy compression is needed by Parquet and graphviz for visualization of execution graphs by Dask
RUN apt install --assume-yes libsnappy-dev graphviz vim figlet fish htop tmux cmake libncurses5-dev libncursesw5-dev git zip wget nano

# customize bash welcome message
ADD bash.bashrc /etc

# nvtop is locally compiled
ADD nvtop /usr/local/bin

# install requirements
RUN pip3 install --upgrade pip setuptools wheel
ADD top_level_requirements.txt .
RUN pip3 install -r top_level_requirements.txt

# install jupyter theme with airt theme
RUN ls -l
RUN echo curl -L --header Private-Token:$ACCESS_REP_TOKEN  https://gitlab.com/api/v4/projects/15104297/jobs/artifacts/master/raw/dist/jupyterthemes-0.20.0-py2.py3-none-any.whl?job=wheel_build -o jupyterthemes-0.20.0-py2.py3-none-any.whl
RUN curl -L --header Private-Token:$ACCESS_REP_TOKEN  https://gitlab.com/api/v4/projects/15104297/jobs/artifacts/master/raw/dist/jupyterthemes-0.20.0-py2.py3-none-any.whl?job=wheel_build -o jupyterthemes-0.20.0-py2.py3-none-any.whl
RUN ls -l
RUN pip3 install jupyterthemes-0.20.0-py2.py3-none-any.whl

# customize your jupyter notebook
ADD airt-neg-trans.png .
RUN jt -t airt -cellw 90% -N -T --logo airt-neg-trans.png
RUN rm airt-neg-trans.png

# cleanup
RUN ls -al
RUN rm jupyterthemes-0.20.0-py2.py3-none-any.whl top_level_requirements.txt

# Oh my fish
RUN curl -L https://get.oh-my.fish > install_omf
RUN chmod 777 install_omf
RUN ./install_omf --noninteractive
RUN rm install_omf
RUN echo omf install bobthefish | fish
RUN echo set -Ux theme_powerline_fonts no | fish
RUN echo omf theme bobthefish | fish

# we will run Docker in user mode so everything in the root directory must be accessible
RUN chmod -R 777 /root

# needed for shell to operate properly
ENV USER skymon
ENV HOME /root

# default shell is fish
ENV SHELL /usr/bin/fish
SHELL ["/usr/bin/fish", ""]

