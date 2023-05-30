FROM debian:bookworm-20230522-slim
ADD dkp.tar.gz /
ADD android_sdk.tar /android_sdk
RUN apt-get update && \
	apt-get install -y --no-install-recommends gettext-base zip unzip openjdk-17-jre-headless \
	g++ cmake make git python3 gcovr \
	xorg-dev libx11-dev libxinerama-dev libxext-dev mesa-common-dev libglu1-mesa-dev \
	libasound2-dev \
	&& rm -rf /var/lib/apt/lists/*
RUN mkdir /src

WORKDIR /src
