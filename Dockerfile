FROM debian:stable
MAINTAINER maxencerousset717@gmail.com

ENV VERSION 1.5.9

WORKDIR /usr/local/src/
ADD assets/sha256checksum sha256checksum

RUN apt-get update && apt-get install -qy \
	build-essential \
	tar \
	wget \
	libssl-dev \
	libevent-dev \
	libevent-2.0-5 \
	libexpat1-dev \
	dnsutils \
	python3-pip \
	&& wget http://www.unbound.net/downloads/unbound-${VERSION}.tar.gz -P /usr/local/src/ \
	&& sha256sum -c sha256checksum \
	&& tar -xvf unbound-${VERSION}.tar.gz \
	&& rm unbound-${VERSION}.tar.gz \
	&& cd unbound-${VERSION} \
	&& ./configure --prefix=/usr/local --with-libevent \
	&& make \
	&& make install \
	&& cd ../ \
	&& rm -R unbound-${VERSION} \
	&& apt-get purge -y \
	build-essential \
	gcc \
	gcc-4.8 \
	cpp \
	cpp-4.8 \
	libssl-dev \
	libevent-dev \
	libexpat1-dev \
	&& pip3 install wget \
	&& apt-get autoremove --purge -y \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN useradd --system unbound --home /home/unbound --create-home
ENV PATH $PATH:/usr/local/lib
RUN ldconfig
ADD assets/header.conf /usr/local/etc/unbound/header.conf
ADD assets/footer.conf /usr/local/etc/unbound/footer.conf
ADD assets/block.py /usr/local/etc/unbound/block.py
RUN chown -R unbound:unbound /usr/local/etc/unbound/ \
	&& chmod +x /usr/local/etc/unbound/block.py

USER unbound
RUN unbound-anchor -a /usr/local/etc/unbound/root.key ; true
RUN unbound-control-setup \
	&& wget ftp://FTP.INTERNIC.NET/domain/named.cache -O /usr/local/etc/unbound/root.hints

USER root
ADD start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 53/udp
EXPOSE 53

CMD ["/start.sh"]
