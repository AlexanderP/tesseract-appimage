FROM almalinux:9
RUN yum update -y
RUN yum -y install fuse fuse-libs

RUN mkdir /build
WORKDIR /build
VOLUME ["/build"]
