#!/usr/bin/env bash

# Constants
BUILD_DIR=multiarch_build

# Variables
export OS=debian10

# Launch all containers
ARCHES='linux/amd64 linux/arm64 linux/armv7 linux/ppc64le'
CONTAINERS=""
for ARCH in ${ARCHES[@]}; do
    LARCH=${ARCH#*\/}
    if [[ $LARCH != "amd64" ]]; then
        CONTAINERS+="${OS}_${LARCH} "
    fi
done
docker compose down
docker compose up -d $CONTAINERS
# The amd64 container need to be launched separately as it doesn't run systemd
docker compose run -d --rm ${OS}_amd64

# Prepare the containers
for ARCH in ${ARCHES[@]}; do
    LARCH=${ARCH#*\/}
    LARCH=${LARCH/\/}
    # TODO: can we run all builds in parallel?
    # TODO: remove install of curl when it is part of the unibuild images
    docker compose exec -T ${OS}_${LARCH} bash -c "\
        apt-get -y install curl && \
        curl http://downloads.perfsonar.net/debian/$REPO.gpg.key | apt-key add - && \
        curl -o /etc/apt/sources.list.d/$REPO.list http://downloads.perfsonar.net/debian/$REPO.list && \
        apt-get update \
        "
done

# Make the master build with unibuild (on amd64 container)
docker compose exec -T ${OS}_amd64 unibuild build

echo 
echo "*** Unibuild: done! ***"
echo

# Then loop on all packages from the unibuild/build-order file
cd unibuild-repo
mkdir -p $BUILD_DIR
for p in `cat unibuild/debian-package-order`; do
    # Extract source package
    rm -rf $BUILD_DIR/*
    echo "Extracting ${p} in ${BUILD_DIR} to see if we must build it."
    if head -1 ${p}*.dsc | grep -q '(native)' ; then
        echo "This is a Debian native package, there is no orig tarball."
        cat ${p}*.tar.xz | tar -x -C $BUILD_DIR --strip-components 1 -f -
    else
        cat ${p}*.orig.* | tar -x -C $BUILD_DIR --strip-components 1 -f -
        cat ${p}*.debian.tar.xz | tar -x -C $BUILD_DIR -f -
    fi

    for ARCH in ${ARCHES[@]}; do
        LARCH=${ARCH#*\/}
        LARCH=${LARCH/\/}
        if [[ $LARCH != "amd64" ]]; then
            if grep '^Architecture: ' $BUILD_DIR/debian/control | grep -qv 'Architecture: all'; then
                # We need to build this package for all architectures
                echo -e "\n===== Building \033[1mbinary package ${p}\033[0m on \033[1m${ARCH}\033[0m in \033[1m${OS}_${LARCH}\033[0m container ====="
                # TODO: can we run all builds in parallel?
                docker compose exec -T ${OS}_${LARCH} bash -c "\
                    cd /app/unibuild-repo/$BUILD_DIR/ && \
                    mk-build-deps --install --tool 'apt-get --yes --no-install-recommends -o Debug::pkgProblemResolver=yes' --remove && \
                    dpkg-buildpackage -us -uc -i -sa -b && \
                    MYARCH=\$(dpkg --print-architecture) && \
                    cd .. && \
                    pwd && \
                    ls -la *${p}*_\${MYARCH}.deb && \
                    find . -name \"*${p}*_\${MYARCH}.deb\" | xargs apt-get -y install \
                    "
            else
                echo "We don't need to build ${p} for other architectures, but we'll install it in the Docker env."
                docker compose exec ${OS}_${LARCH} bash -c "\
                    cd /app/unibuild-repo/ && \
                    pwd && \
                    ls -la *${p}*.deb && \
                    find . -name \"*${p}*.deb\" | xargs apt-get -y install \
                    "
            fi
        fi
    done
    echo
done

# Shutdown all containers
cd ..
docker compose stop ${OS}_amd64
docker compose down

