# Docker image with the dependencies for building Taarifa Waterpoints.
#
#     https://registry.hub.docker.com/u/taarifa/

FROM phusion/baseimage:0.9.17
MAINTAINER Florian Rathgeber <florian.rathgeber@gmail.com>

# Set up package repos for node.js and MongoDB
RUN curl -sL https://deb.nodesource.com/setup_0.12 | bash - && \
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 && \
    echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.0.list

# Required packages
RUN apt-get -qq update && \
    apt-get -y install \
      git \
      mongodb-org \
      nodejs \
      python-pip \
      python-setuptools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Npm dependencies
RUN npm install -g \
      bower \
      grunt-cli

# Set up user so that we do not run as root
RUN useradd -m -s /bin/bash -G sudo,docker_env taarifa && \
    echo "taarifa:docker" | chpasswd && \
    echo "taarifa ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# See https://github.com/phusion/baseimage-docker/issues/186
RUN touch /etc/service/syslog-forwarder/down

# Start MongoDB
COPY start_mongod.sh /etc/service/mongod/run

# Expose ports we need
EXPOSE 5000 9000 27017

ENV HOME /home/taarifa

# Taarifa install/update script
COPY update_taarifa.sh $HOME/update_taarifa.sh
RUN chown taarifa:taarifa $HOME/update_taarifa.sh

WORKDIR $HOME
ENTRYPOINT ["/sbin/my_init","--quiet","--","/sbin/setuser","taarifa","/bin/sh","-c"]
CMD ["/bin/bash"]
