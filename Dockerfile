FROM ubuntu:16.04

RUN apt-get update && apt-get install -y software-properties-common && add-apt-repository -y ppa:alex-p/tesseract-ocr
RUN apt-get update && apt-get install -y debhelper libleptonica-dev automake libtool libarchive-dev libpango1.0-dev libcairo2-dev libicu-dev libpng-dev libjpeg-dev libtiff-dev zlib1g-dev git asciidoc xsltproc docbook-xsl docbook-xml wget libfuse2 fuse

RUN mkdir /build
WORKDIR /build
VOLUME ["/build"]
