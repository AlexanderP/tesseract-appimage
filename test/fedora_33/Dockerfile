FROM fedora:33
RUN yum update -y
RUN yum -y install fuse fuse-libs

RUN mkdir /build
WORKDIR /build
VOLUME ["/build"]