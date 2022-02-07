ARG BASETAG=20.04

FROM ubuntu:${BASETAG} as stage-ubuntu

MAINTAINER talank baral

RUN sed -i'' 's/archive\.ubuntu\.com/us\.archive\.ubuntu\.com/' /etc/apt/sources.list

### 'apt-get clean' runs automatically
RUN apt-get update --fix-missing && apt-get install -y apt-transport-https

RUN echo 'APT::Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries

RUN apt-get install -y python-gi \
            python-is-python3 \
            python-nautilus \
            nano \
            apport
    #     inetutils-ping \
    #     lsb-release \
    #     net-tools \
    #     sudo \
    #     unzip \
    #     vim \
    #     zip \
    #     curl \
    #     gdebi-core \
    #     wget \
    #     nano \
    #     python-gi \
    #     python-nautilus \
    #     zlib1g-dev \
    #     libsqlite3-dev \
    #     libssl-dev \
    #     libcmocka-dev \
    #     python-is-python3 \
    # && apt-get -y autoremove \
    # && rm -rf /var/lib/apt/lists/*

# FROM mcr.microsoft.com/dotnet/core/aspnet:3.1-bionic
# COPY dotnet.service /lib/systemd/system/
RUN apt-get update && apt-get install -y --no-install-recommends \
    systemd \
    init \
    apport \
    python3-systemd && rm -rf /var/lib/apt/lists/*
# RUN sed -i "s/enabled=0/enabled=1/g" /etc/default/apport && \
#     sed -i "s/'problem_types'/#'problem_types'/g" /etc/apport/crashdb.conf && \
#     sed -i "s/ConditionVirtualization=container//g" /lib/systemd/system/apport-forward.socket
# RUN systemctl enable apport-forward.socket && \
#     systemctl enable dotnet.service