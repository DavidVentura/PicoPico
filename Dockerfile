FROM debian:bookworm-20230522-slim
ADD dkp.tar.gz /
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
	g++ cmake make git python3 \
	xorg-dev libx11-dev libxinerama-dev libxext-dev mesa-common-dev libglu1-mesa-dev \
	&& rm -rf /var/lib/apt/lists/*
RUN mkdir /src
WORKDIR /src
