FROM ubuntu:14.04.3
MAINTAINER Tristan Jakobi <t.jakobi@smart-iot.solutions>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get install -y --force-yes --no-install-recommends dpkg-dev nginx inotify-tools supervisor python-gevent openssh-server \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd
RUN useradd -m $SSH_USER && echo "$SSH_USER:$SSH_PASSWORD" | chpasswd
RUN sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin $SSH_PERMIT_ROOT_LOGIN/" /etc/ssh/sshd_config

ADD supervisord.conf /etc/supervisor/
ADD nginx.conf /etc/nginx/sites-enabled/default
ADD startup.sh /
ADD scan.py /

# Expose ports and define a volume
EXPOSE 80
EXPOSE 22
VOLUME /data

# Start Supervisor
CMD ["/usr/bin/supervisord"]
