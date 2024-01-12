FROM ubuntu:14.04.3
MAINTAINER Doro Wu <fcwu.tw@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

# Install required packages including OpenSSH Server
RUN apt-get update \
    && apt-get install -y --force-yes --no-install-recommends dpkg-dev nginx inotify-tools supervisor python-gevent openssh-server \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

# SSH setup
# Create SSH run directory
RUN mkdir /var/run/sshd
# Add a user for SSH access (replace 'myuser' and 'mypassword' with your desired username and password)
RUN useradd -m myuser && echo "myuser:mypassword" | chpasswd
# Update SSH configuration to allow user login (modify as necessary for your security requirements)
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# [The rest of your existing Dockerfile instructions]
ADD supervisord.conf /etc/supervisor/
ADD nginx.conf /etc/nginx/sites-enabled/default
ADD startup.sh /
ADD scan.py /

EXPOSE 80
EXPOSE 22  # Expose SSH port
VOLUME /data
# Use Supervisor to manage multiple services (including SSHD)
CMD ["/usr/bin/supervisord"]
