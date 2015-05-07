FROM dockerregistry.protorz.net/ubuntu:latest

# ENV DOKKU_TAG v0.3.17
ENV DOKKU_REPO https://github.com/protonet/dokku.git
ENV DOKKU_BRANCH master
ENV DOKKU_ROOT /data

RUN apt-get update -qq -y && \
  apt-get install -qq -y supervisor openssh-server && \
  rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos "" --home /data dokku

ADD https://raw.githubusercontent.com/protonet/dokku/master/bootstrap.sh /tmp/bootstrap.sh
RUN /tmp/bootstrap.sh && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /logs
RUN mkdir -p /var/run/sshd

COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf

RUN mv /usr/bin/docker /usr/bin/docker-original
RUN echo "dokku ALL=(ALL) NOPASSWD: /usr/bin/docker-original" >> /etc/sudoers
COPY docker-wrapper.sh /usr/bin/docker

COPY prepare_dokku.sh /usr/local/bin/prepare_dokku
COPY start.sh /usr/local/bin/start_dokku

CMD ["start_dokku"]

EXPOSE 22 80
