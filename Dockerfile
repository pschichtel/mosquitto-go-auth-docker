ARG MOSQUITTO_VERSION=1.6.11

FROM golang:1.15-buster AS build

ARG MOSQUITTO_VERSION
ARG PLUGIN_VERSION=1.0.0

#Set mosquitto and plugin versions.
#Change them for your needs.
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

#Get mosquitto build dependencies.
RUN apt-get update \
 && apt-get --no-install-recommends install -y libc-ares2 libc-ares-dev openssl libssl-dev uuid uuid-dev build-essential xsltproc docbook-xsl

RUN git clone --depth=1 --branch "v${MOSQUITTO_VERSION}" https://github.com/eclipse/mosquitto.git mosquitto

#Build mosquitto.
RUN cd mosquitto \
 && make \
 && make install

#Build the plugin from local source
RUN git clone --depth 1 --branch "$PLUGIN_VERSION" https://github.com/iegomez/mosquitto-go-auth.git go-auth

ENV CGO_CFLAGS="-I/usr/local/include -fPIC" \
    CGO_LDFLAGS="-shared"

#Build the plugin.
RUN cd go-auth \
 && make

FROM eclipse-mosquitto:${MOSQUITTO_VERSION}

COPY --from=build /app/go-auth/go-auth.so /mosquitto/go-auth.so

