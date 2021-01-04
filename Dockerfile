FROM ubuntu:18.04

RUN apt update
RUN DEBIAN_FRONTEND=noninteractive apt install -y software-properties-common
RUN add-apt-repository -y ppa:alex-p/tesseract-ocr
RUN DEBIAN_FRONTEND=noninteractive apt install -y debhelper libleptonica-dev automake libtool libarchive-dev libpango1.0-dev libcairo2-dev libicu-dev libpng-dev libjpeg-dev libtiff-dev zlib1g-dev git asciidoc xsltproc docbook-xsl docbook-xml wget libfuse2 fuse

RUN DEBIAN_FRONTEND=noninteractive apt install -y python3-pip python3-setuptools patchelf desktop-file-utils libgdk-pixbuf2.0-dev fakeroot wget
RUN wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O /usr/local/bin/appimagetool
RUN chmod +x /usr/local/bin/appimagetool

#RUN pip3 install appimage-builder

RUN mkdir /build
WORKDIR /build
VOLUME ["/build"]
