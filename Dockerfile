FROM alpine:3.8

LABEL maintainer="mritd <mritd1234@gmail.com>"

ARG TZ='Asia/Shanghai'

ENV TZ $TZ
ENV SS_LIBEV_VERSION 3.2.3
ENV SS_DOWNLOAD_URL https://github.com/shadowsocks/shadowsocks-libev/releases/download/v${SS_LIBEV_VERSION}/shadowsocks-libev-${SS_LIBEV_VERSION}.tar.gz
ENV OBFS_DOWNLOAD_URL https://github.com/shadowsocks/simple-obfs.git

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
	&& apk upgrade \
	&& apk add bash tzdata libsodium rng-tools privoxy \
	&& apk add --virtual .build-deps \
	autoconf \
	automake \
	xmlto \
	build-base \
	wget \
	c-ares-dev \
	libev-dev \
	libtool \
	linux-headers \
	udns-dev \
	libsodium-dev \
	mbedtls-dev \
	pcre-dev \
	udns-dev \
	tar \
	git \
	&& wget --no-check-certificate ${SS_DOWNLOAD_URL} \
	&& tar -zxf shadowsocks-libev-${SS_LIBEV_VERSION}.tar.gz \
	&& (cd shadowsocks-libev-${SS_LIBEV_VERSION} \
	&& ./configure --prefix=/usr --disable-documentation \
	&& make install) \
	&& git clone ${OBFS_DOWNLOAD_URL} \
	&& (cd simple-obfs \
	&& git submodule update --init --recursive \
	&& ./autogen.sh && ./configure --disable-documentation\
	&& make && make install) \
	&& ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
	&& echo ${TZ} > /etc/timezone \
	&& runDeps="$( \
	scanelf --needed --nobanner /usr/bin/ss-* /usr/local/bin/obfs-* \
	| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
	| xargs -r apk info --installed \
	| sort -u \
	)" \
	&& apk add --virtual .run-deps $runDeps \
	&& apk del .build-deps \
	&& rm -rf shadowsocks-libev-${SS_LIBEV_VERSION}.tar.gz \
	shadowsocks-libev-${SS_LIBEV_VERSION} \
	simple-obfs \
	/var/cache/apk/*

ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]