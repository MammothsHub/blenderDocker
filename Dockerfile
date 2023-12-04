FROM ubuntu:22.04

ENV BLENDER_VERSION=4.0.1

ENV TITLE=BlenderDocker

#Firstly we need to update the packages
RUN apt-get update

#Dependancies from the sylabs example for blender
RUN apt-get install -y gnupg clinfo

#Now update the certificates so that we can use curl
RUN apt-get install ca-certificates -y
RUN update-ca-certificates

#Install blender through
RUN apt-get install -y blender
RUN mv /usr/bin/blender /usr/bin/blenderOld

#Install libSM a dependancy unique to blender 4.0.1
RUN apt-get install -y libsm6

#Install libegl in the container so that it works on the V100s
RUN apt install -y libegl1-mesa libegl1

RUN \
  echo "**** install packages ****" && \
  apt-get install --no-install-recommends -y \
    curl \
    ocl-icd-libopencl1 \
    xz-utils && \
  ln -s libOpenCL.so.1 /usr/lib/x86_64-linux-gnu/libOpenCL.so && \
  echo "**** install blender ****" && \
  mkdir /blender && \
  if [ -z ${BLENDER_VERSION+x} ]; then \
    BLENDER_VERSION=$(curl -sL https://mirrors.ocf.berkeley.edu/blender/source/ \
      | awk -F'"|/"' '/blender-[0-9]*\.[0-9]*\.[0-9]*\.tar\.xz/ && !/md5sum/ {print $4}' \
      | tail -1 \
      | sed 's|blender-||' \
      | sed 's|\.tar\.xz||'); \
  fi && \
  BLENDER_FOLDER=$(echo "Blender${BLENDER_VERSION}" | sed -r 's|(Blender[0-9]*\.[0-9]*)\.[0-9]*|\1|') && \
  curl -o \
    /tmp/blender.tar.xz -L \
    "https://mirrors.ocf.berkeley.edu/blender/release/${BLENDER_FOLDER}/blender-${BLENDER_VERSION}-linux-x64.tar.xz" && \
  tar xf \
    /tmp/blender.tar.xz -C \
    /blender/ --strip-components=1 && \
  ln -s \
    /blender/blender \
    /usr/bin/blender

#Run clean up (sometimes not done)
#RUN \
#  echo "**** cleanup ****" && \
#  rm -rf \
#    /tmp/* \
#    /var/lib/apt/lists/* \
#    /var/tmp/*

#now change the permissions of blender to ensure that everyone can run it
RUN chmod ugo+x /usr/bin/blender

# add local files
#COPY /root /

# ports and volumes
EXPOSE 8080

LABEL io.openshift.expose-services 8080/http

USER 1001

VOLUME /config

CMD blender
