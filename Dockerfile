FROM ubuntu:20.04
MAINTAINER Tristan Jakobi <t.jakobi@smart-iot.solutions>

ENV DEBIAN_FRONTEND noninteractive
ENV SSH_USER=default_user
ENV SSH_PASSWORD=default_password
ENV SSH_PERMIT_ROOT_LOGIN=no

RUN apt-get update \
    && apt-get install -y --force-yes --no-install-recommends dpkg-dev nginx inotify-tools supervisor python-gevent openssh-server \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd \
    && useradd -m $SSH_USER \
    && echo "$SSH_USER:$SSH_PASSWORD" | chpasswd \
    && sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin $SSH_PERMIT_ROOT_LOGIN/" /etc/ssh/sshd_config

COPY supervisord.conf /etc/supervisor/
COPY nginx.conf /etc/nginx/sites-enabled/default
COPY startup.sh /
COPY scan.py /

RUN chmod +x /startup.sh

EXPOSE 80
EXPOSE 22

VOLUME /data
ENTRYPOINT ["/startup.sh"]
