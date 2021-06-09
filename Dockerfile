# perfSONAR build machine image

### Globally scoped ARG, defined here to be available to use in FROM statements
# Do we want to use a proxy?
ARG useproxy=no
# TODO: move to pS provided base OS image
# OS image to use as a base
ARG OSimage=debian:stretch
ARG ARCH=amd64
FROM --platform=${ARCH} ${OSimage} AS bbase

# Some sane defaults
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

# If you want to use a proxy to speed up download both at build time and test time (docker run)
# Trick built on top of https://medium.com/@tonistiigi/advanced-multi-stage-build-patterns-6f741b852fae
FROM bbase AS bproxy-yes
ARG proxy
ENV http_proxy=http://${proxy}
ENV https_proxy=https://${proxy}
ENV no_proxy=localhost,127.0.0.1

FROM bbase AS bproxy-no
ENV http_proxy=
ENV https_proxy=
ENV no_proxy=

### Systemd related setup
# TODO: should be moved to dedicated image
FROM bproxy-${useproxy} AS build-image
RUN echo "Build image proxy is: ${https_proxy:-none}"
RUN apt-get update && apt-get install -y systemd systemd-sysv

# To make systemd work properly
# From https://github.com/j8r/dockerfiles/tree/master/systemd
RUN cd /lib/systemd/system/sysinit.target.wants/ \
    && ls | grep -v systemd-tmpfiles-setup | xargs rm -f $1

# List for D9, D10, U16, U18 and U20
RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/anaconda.target.wants/* \
    /lib/systemd/system/basic.target.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/plymouth* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
    /lib/systemd/system/systemd-update-utmp*

# Shared volume needed for systemd
VOLUME /sys/fs/cgroup

# Work around a Debian/Ubuntu Docker issue
# https://stackoverflow.com/questions/46247032/how-to-solve-invoke-rc-d-policy-rc-d-denied-execution-of-start-when-building
RUN printf '#!/bin/sh\nexit 0' > /usr/sbin/policy-rc.d

### Repositories configuration and tools setup
# Contrib and backport repositories are also needed for up to date build tools
RUN sed -i 's| main$| main contrib|' /etc/apt/sources.list
RUN echo 'deb http://deb.debian.org/debian stretch-backports main contrib' >> /etc/apt/sources.list

# Building and repository mgmt tools needed for the build
RUN apt-get update && apt-get install -y \
        apt-utils \
        git-buildpackage \
        gnupg \
        vim && \
    apt-get -t stretch-backports install -y \
        lintian

# Configure perfSONAR repository (given as argument) and GPG key
ARG REPO=perfsonar-minor-snapshot
RUN echo "Adding perfSONAR repository: $REPO"
RUN if [ "$REPO" = "perfsonar-release" ] ; \
    then curl http://downloads.perfsonar.net/debian/perfsonar-official.gpg.key | apt-key add - ; \
    else curl http://downloads.perfsonar.net/debian/perfsonar-snapshot.gpg.key | apt-key add - ; \
    fi
RUN curl -o /etc/apt/sources.list.d/$REPO.list http://downloads.perfsonar.net/debian/$REPO.list

# Some APT cleanup
RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Shared volume for builds
VOLUME /mnt/build

# Create build user
RUN useradd -d /home/psbuild -G sudo -m -p public -s /bin/bash psbuild

# Copy build scripts
COPY ./ps-source-builder /usr/local/bin/ps-source-builder
COPY ./ps-binary-builder /usr/local/bin/ps-binary-builder

# Start systemd
CMD ["/lib/systemd/systemd"]

