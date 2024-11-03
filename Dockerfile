#
#  Box64 Instructions from: https://pimylifeup.com/raspberry-pi-x86/
#
FROM debian:stable-slim AS base

############################################

FROM base AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt-get install -y git vim build-essential cmake python3 && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ptitSeb/box64

RUN dpkg --add-architecture armhf && apt-get update

RUN apt-get update && apt-get install -y gcc-arm-linux-gnueabihf libc6:armhf && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y libqt5gui5:armhf libxcb1:armhf libexpat1:armhf libxdmcp6:armhf libx11-xcb1:armhf libfontconfig1:armhf libfreetype6:armhf libdbus-1-3:armhf libx11-6:armhf xkb-data:armhf && rm -rf /var/lib/apt/lists/*

WORKDIR /box64/build

## Raspberry Pi 4,5 (32-Bit)
#RUN cmake .. -DRPI4=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo

## Raspberry Pi 4, 5 (64-Bit)
#RUN cmake .. -DRPI4ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
#RUN cmake .. -DARM_DYNAREC=ON -DRK3399=1 -DCMAKE_BUILD_TYPE=RelWIthDebInfo
#RUN cmake .. -DRPI4ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo # -DRPI4ARM64=1 for Pi4 aarch64 (use `-DRPI3ARM64=1` for a PI3 model)
#RUN cmake .. -D ARM_DYNAREC=ON -D CMAKE_BUILD_TYPE=RelWithDebInf
RUN cmake .. -D RPI4ARM64=1 -D CMAKE_BUILD_TYPE=RelWithDebInfo -D HAVE_TRACE=ON 

## Raspberry pi 3
# RUN cmake .. -DRPI3=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo

## Raspberry Pi 2
# RUN cmake .. -DRPI2=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo

RUN make -j$(nproc)
RUN make install
WORKDIR /

##########################################

FROM base AS installer

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update

RUN apt-get install -y git vim python3 wget gpg

COPY b64apt /root/b64apt
RUN chmod +x /root/b64apt
RUN /root/b64apt
WORKDIR /

################################
## Clean out the build crud
FROM builder AS finalize

RUN if [ -d /box64 ]; then rm -rf /box64; fi
RUN apt-get update; apt-get -y --autoremove --purge purge cmake build-essential git vim wget gpg python3 && apt-get -y clean && apt-get -y autoclean && rm -rf /var/lib/apt/lists/*

FROM scratch
COPY --from=finalize / /

