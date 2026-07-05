FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies, SSH server, and rsync
RUN mkdir /usr/src/ScarletDME && \
	dpkg --add-architecture i386 && \
	apt-get update && \
	apt-get install -y \
		gcc-multilib \
		make \
		libcrypt-dev:i386 \
		openssh-server \
		rsync \
		sudo \
	&& rm -rf /var/lib/apt/lists/*

# Create users and groups
RUN groupadd qmusers && \
	useradd -G qmusers -d /usr/qmsys -s /bin/bash -m qmsys && \
	echo 'qmsys:qmsys' | chpasswd && \
	usermod -a -G qmusers root

# Configure SSH: allow password auth, allow qmsys login, create run directory
RUN mkdir -p /var/run/sshd && \
	sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
	sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
	echo "AllowUsers qmsys root" >> /etc/ssh/sshd_config && \
	ssh-keygen -A

# Copy source into build context (build context is ScarletDME root)
COPY / /usr/src/ScarletDME
RUN chown -R qmsys:qmusers /usr/src/ScarletDME

# Create install root and place runtime config
RUN mkdir -p /usr/qmsys && chown -R qmsys:qmusers /usr/qmsys
RUN cp /usr/src/ScarletDME/scarlet.conf /etc/scarlet.conf && \
	chown qmsys:qmusers /etc/scarlet.conf

# Build and install as qmsys (matches ownership requirements in the Makefile)
USER qmsys:qmusers
RUN cd /usr/src/ScarletDME && (make clean || true) && make && make install datafiles
WORKDIR /usr/qmsys
USER root:root

# Entrypoint: starts sshd then qm daemon
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 4242 = qm telnet sessions, 4243 = qm client API, 22 = SSH/rsync
EXPOSE 4242 4243 22

ENTRYPOINT ["/entrypoint.sh"]
