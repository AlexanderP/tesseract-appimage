FROM opensuse/leap:15.3
RUN zypper up -y
RUN zypper refresh
RUN zypper install -y fuse libfuse2 

RUN mkdir /build
WORKDIR /build
VOLUME ["/build"]
