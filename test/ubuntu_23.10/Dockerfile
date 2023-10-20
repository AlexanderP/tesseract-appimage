FROM ubuntu:23.10
RUN apt-get update && apt-get dist-upgrade -y
RUN apt-get install -y libfuse2 fuse

RUN mkdir /build
WORKDIR /build
VOLUME ["/build"]
