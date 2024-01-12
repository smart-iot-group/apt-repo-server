FROM ubuntu:14.04.3
MAINTAINER Tristan Jakobi <t.jakobi@smart-iot.solutions>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get install -y --force-yes --no-install-recommends dpkg-dev nginx inotify-tools supervisor python-gevent openssh-server \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd
RUN useradd -m myuser && echo "myuser:mypassword" | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

ADD supervisord.conf /etc/supervisor/
ADD nginx.conf /etc/nginx/sites-enabled/default
ADD startup.sh /
ADD scan.py /

EXPOSE 80
EXPOSE 22  # Expose SSH port
VOLUME /data
CMD ["/usr/bin/supervisord"]
