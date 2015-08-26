FROM experimentalplatform/ubuntu:latest

# ENV DOKKU_TAG v0.3.17
ENV DOKKU_REPO https://github.com/protonet/dokku.git
ENV DOKKU_BRANCH master
ENV DOKKU_ROOT /data
ENV PLUGIN_PATH /var/lib/dokku/plugins

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
  && \
  rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos "" --home /data dokku

ADD https://github.com/experimental-platform/dokku/archive/legacy.zip /tmp/dokku.zip
RUN unzip /tmp/dokku.zip -d /tmp/ && \
    mkdir -p /var/lib/dokku/ && \
    mv /tmp/dokku-legacy/* /var/lib/dokku/ && \
    rm -rf /tmp/dokku-legacy /tmp/dokku.zip && \
    ln -s /var/lib/dokku/dokku /usr/local/bin/dokku

ADD https://github.com/experimental-platform/dokku-linkfile/archive/master.zip /tmp/dokku-linkfile.zip
RUN unzip /tmp/dokku-linkfile.zip -d /tmp/ && \
    mkdir -p /var/lib/dokku/plugins/linkfile/ && \
    mv /tmp/dokku-linkfile-master/* /var/lib/dokku/plugins/linkfile/ && \
    rm -rf /tmp/dokku-linkfile-master /tmp/dokku-linkfile.zip

COPY plugins/ /var/lib/dokku/plugins/
RUN git clone https://github.com/F4-Group/dokku-apt /var/lib/dokku/plugins/dokku-apt

RUN dokku plugins-install-dependencies && dokku plugins-install
RUN sshcommand create dokku /usr/local/bin/dokku

RUN mkdir -p /logs
RUN mkdir -p /var/run/sshd

COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx.conf.app.template /var/lib/dokku/plugins/nginx-vhosts/templates/nginx.conf.template
COPY error_pages/ /error_pages/

# we do not need this. Everything important is defined in nginx.conf above.
RUN rm /etc/nginx/conf.d/dokku.conf

COPY prepare_dokku.sh /usr/local/bin/prepare_dokku
COPY start.sh /usr/local/bin/start_dokku

CMD ["start_dokku"]

EXPOSE 22 80
