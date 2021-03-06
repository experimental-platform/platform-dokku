FROM quay.io/experimentalplatform/ubuntu:latest

# ENV DOKKU_TAG v0.4.3
ENV DOKKU_REPO https://github.com/experimental-platform/dokku.git
ENV DOKKU_BRANCH master
ENV DOKKU_ROOT /data
ENV PLUGIN_PATH /var/lib/dokku/core-plugins

RUN apt-get update -y && \
    apt-get install -y apt-transport-https ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Packagecloud GPG Key
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 418A7F2FB0E1E6E7EABF6FE8C2E73424D59097AB

RUN echo "deb https://packagecloud.io/dokku/dokku/ubuntu/ trusty main" > /etc/apt/sources.list.d/dokku.list

RUN apt-get update -y && \
  apt-get install -y \
    supervisor \
    openssh-server \
    sshcommand \
    pluginhook \
    help2man \
    man-db \
    rsyslog \
    software-properties-common \
    python-software-properties \
    plugn \
    patch \
  && \
  rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos "" --home /data dokku

ADD https://github.com/experimental-platform/dokku/archive/f13796fa57a619d005be4e4b2868416f3f929c41.zip /tmp/dokku.zip
RUN unzip /tmp/dokku.zip -d /tmp/ && \
    mkdir -p /var/lib/dokku/ && \
    mv /tmp/dokku-f13796fa57a619d005be4e4b2868416f3f929c41/* /var/lib/dokku/ && \
    rm -rf /tmp/dokku-f13796fa57a619d005be4e4b2868416f3f929c41 /tmp/dokku.zip && \
    ln -s /var/lib/dokku/dokku /usr/local/bin/dokku && \
    mkdir -p /var/lib/dokku/core-plugins && \
    mv /var/lib/dokku/plugins /var/lib/dokku/core-plugins/available && ln -s /var/lib/dokku/core-plugins /var/lib/dokku/plugins && \
    touch /var/lib/dokku/core-plugins/config.toml /var/lib/dokku/plugins/config.toml && \
    find /var/lib/dokku/plugins/available/ -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | while read plugin; do touch /var/lib/dokku/core-plugins/available/$plugin/.core; done && \
    chmod 666 /var/lib/dokku/core-plugins/config.toml /var/lib/dokku/plugins/config.toml

# set PLUGIN_PATH on sudo
RUN echo "export PLUGIN_PATH=$PLUGIN_PATH" >> /etc/environment

# this causes dokku to use our buildstep image
RUN sed -i /usr/local/bin/dokku -e 's#gliderlabs/herokuish#experimentalplatform/buildstep:herokuish#'

# move nginx upstream to a separate file
COPY upstream.patch /var/lib/dokku/core-plugins/available/nginx-vhosts/upstream.patch
RUN cd /var/lib/dokku/core-plugins/available/nginx-vhosts/ && patch -p0 < upstream.patch

# trigger generate-urls hook
COPY hook-generate-urls.patch /var/lib/dokku/core-plugins/available/nginx-vhosts/hook-generate-urls.patch
RUN cd /var/lib/dokku/core-plugins/available/nginx-vhosts/ && patch -p0 < hook-generate-urls.patch

# Patch to remove rails-app configuration on deployment failure
RUN sed 's#validate_nginx \&\& restart_nginx#\(validate_nginx \&\& restart_nginx\) \|\| \(rm \$DOKKU_ROOT\/\$APP\/\{nginx\,upstream\}\.conf \&\& exit 1\)#' -i /var/lib/dokku/core-plugins/available/nginx-vhosts/functions

ADD https://github.com/experimental-platform/dokku-linkfile/archive/master.zip /tmp/dokku-linkfile.zip
RUN unzip /tmp/dokku-linkfile.zip -d /tmp/ && \
    mkdir -p /var/lib/dokku/core-plugins/available/linkfile/ && \
    mv /tmp/dokku-linkfile-master/* /var/lib/dokku/core-plugins/available/linkfile/ && \
    rm -rf /tmp/dokku-linkfile-master /tmp/dokku-linkfile.zip

COPY plugins/ /var/lib/dokku/core-plugins/available/
RUN git clone https://github.com/F4-Group/dokku-apt /var/lib/dokku/core-plugins/available/dokku-apt
RUN cd /var/lib/dokku/core-plugins/available/dokku-apt && git checkout 0.4.0

RUN find /var/lib/dokku/core-plugins/available/ -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | while read plugin; do plugn enable $plugin; done
# disable named containers plugin, since it's been problematic so far
RUN plugn disable named-containers

RUN dokku plugin:install-dependencies && dokku plugin:install
RUN sshcommand create dokku /usr/local/bin/dokku

RUN mkdir -p /logs
RUN mkdir -p /var/run/sshd

COPY dokku-restore.sh /dokku-restore.sh
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx.conf.app.template /var/lib/dokku/core-plugins/available/nginx-vhosts/templates/nginx.conf.template
COPY error_pages/ /error_pages/

# we do not need this. Everything important is defined in nginx.conf above.
RUN rm /etc/nginx/conf.d/dokku.conf

COPY prepare_dokku.sh /usr/local/bin/prepare_dokku
COPY start.sh /usr/local/bin/start_dokku

CMD ["start_dokku"]

EXPOSE 22 80
