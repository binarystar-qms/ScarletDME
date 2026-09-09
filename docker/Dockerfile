FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies, SSH server, xinetd (client/server listeners), and rsync
RUN mkdir /usr/src/ScarletDME && \
	dpkg --add-architecture i386 && \
	apt-get update && \
	apt-get install -y \
		gcc-multilib \
		make \
		libcrypt-dev:i386 \
		openssh-server \
		xinetd \
		rsync \
		sudo \
	&& rm -rf /var/lib/apt/lists/*

# Create users and groups.
#
# QM's own login_user() (gplsrc/linuxio.c) reads /etc/shadow directly and
# only recognises the legacy $1$ (MD5-crypt) hash format -- it never uses
# PAM. Ubuntu's chpasswd generates modern $6$ (SHA-512) hashes by default,
# which QM's 2007-era parser silently rejects, so every QM login fails with
# "Invalid username or password" even with the right password. Force MD5
# specifically for this account so QM's own auth check can actually parse
# it; SSH/PAM still validate $1$ hashes fine, so this doesn't affect SSH.
RUN groupadd qmusers && \
	useradd -G qmusers -d /usr/qmsys -s /bin/bash -m qmsys && \
	usermod -p "$(openssl passwd -1 -salt qmsalt qmsys)" qmsys && \
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

# Wire up xinetd for client access: qmserver (4242, telnet-style sessions)
# and qmclient (4243, the native QMClient wire protocol used by mv.NET's
# ConnectionType=QMClient and similar clients). Neither is started by `qm
# -start` on its own -- that only brings up QM's internal monitor/IPC, not
# a network listener -- so without this nothing is actually bound to either
# port despite the entrypoint claiming otherwise.
RUN cp /usr/src/ScarletDME/xinetd.d/qmserver /etc/xinetd.d/qmserver && \
	cp /usr/src/ScarletDME/xinetd.d/qmclient /etc/xinetd.d/qmclient && \
	grep -q '^qmserver' /etc/services || echo 'qmserver	4242/tcp	# QMServer' >> /etc/services && \
	grep -q '^qmclient' /etc/services || echo 'qmclient	4243/tcp	# QMClient' >> /etc/services

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
