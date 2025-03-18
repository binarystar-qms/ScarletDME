FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive
RUN mkdir /usr/src/ScarletDME && \
	dpkg --add-architecture i386 && \
	apt-get update && \
	apt-get install -y gcc-multilib make libcrypt-dev:i386 && \
	groupadd qmusers && \
	useradd -G qmusers -d /usr/qmsys qmsys
COPY / /usr/src/ScarletDME
RUN chown -R qmsys:qmusers /usr/src/ScarletDME
RUN (mkdir /usr/qmsys && chown -R qmsys:qmusers /usr/qmsys)
RUN ls -la /usr/src/ScarletDME
RUN cp /usr/src/ScarletDME/scarlet.conf /etc/scarlet.conf
RUN chown qmsys:qmusers /etc/scarlet.conf
RUN usermod -a -G qmusers root
USER qmsys:qmusers
RUN (cd /usr/src/ScarletDME && (make clean || true))
RUN (cd /usr/src/ScarletDME && make)
USER root:root
RUN (cd /usr/src/ScarletDME && make install datafiles)
RUN chmod +x bin/*
WORKDIR /usr/qmsys
USER root:root
