FROM alt:p10
RUN apt-get update && apt-get dist-upgrade -y
RUN apt-get install -y libfuse3 fuse3

RUN mkdir /build
WORKDIR /build
VOLUME ["/build"]
