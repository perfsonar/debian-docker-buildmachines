#!/usr/bin/env bash

# Constants
BUILD_DIR='multiarch_build'
FULL_BUILD_DIR=`pwd`"/$BUILD_DIR"
RESULTS_DIR='unibuild-repo'

# Variables
export OS=d10

# Launch all containers
ARCHES='linux/amd64 linux/arm64 linux/armv7 linux/ppc64le'
docker compose down
docker volume prune -f
for ARCH in ${ARCHES[@]}; do
    LARCH=${ARCH#*\/}
    docker compose run -d --rm ${OS}_$LARCH
done

# Prepare the containers with repository
for ARCH in ${ARCHES[@]}; do
    LARCH=${ARCH#*\/}
    LARCH=${LARCH/\/}
    # TODO: can we run all builds in parallel?
    docker compose exec -T ${OS}_${LARCH} bash -c "\
        curl -s http://downloads.perfsonar.net/debian/$REPO.gpg.key | apt-key add - && \
        curl -s -o /etc/apt/sources.list.d/$REPO.list http://downloads.perfsonar.net/debian/$REPO.list && \
        apt-get update \
        "
done

# Make the master build with unibuild (on amd64 container)
docker compose exec -T ${OS}_amd64 unibuild build

echo 
echo "*** Unibuild: done! ***"
echo

# Then loop on all packages from the unibuild/build-order file
for p in `cat ${RESULTS_DIR}/unibuild/debian-package-order`; do
    # Extract source package
    # sudoers configuration needed for this to work
    sudo /bin/rm -rf $FULL_BUILD_DIR
    mkdir -p $BUILD_DIR
    echo "Extracting ${p} in ${BUILD_DIR} to see if we must build it."
    if head -1 ${RESULTS_DIR}/${p}*.dsc | grep -q '(native)' ; then
        echo "This is a Debian native package, there is no orig tarball."
        cat ${RESULTS_DIR}/${p}*.tar.xz | tar -Jx -C $BUILD_DIR --strip-components 1 -f -
    else
        cat ${RESULTS_DIR}/${p}*.orig.* | tar -zx -C $BUILD_DIR --strip-components 1 -f -
        cat ${RESULTS_DIR}/${p}*.debian.tar.xz | tar -Jx -C $BUILD_DIR -f -
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
                    cd $BUILD_DIR && \
                    mk-build-deps --install --tool 'apt-get --yes --no-install-recommends -o Debug::pkgProblemResolver=yes' --remove && \
                    dpkg-buildpackage -us -uc -i -sa -b && \
                    MYARCH=\$(dpkg --print-architecture) && \
                    cd .. && \
                    pwd && \
                    ls -la *${p}*_\${MYARCH}.* && \
                    find . -name \"*${p}*_\${MYARCH}.deb\" | xargs apt-get -y install && \
                    mv *${p}*_\${MYARCH}.* ${RESULTS_DIR} \
                    "
            else
                # This is needed to make sure dependencies are satisfied
                # Alternative would be to push packages to repository after each build instead of at the very end
                echo -e "\033[1mWe don't need to build ${p} for ${ARCH}\033[0m, but we'll install it in the Docker env."
                docker compose exec ${OS}_${LARCH} bash -c "\
                    cd ${RESULTS_DIR} && \
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
for ARCH in ${ARCHES[@]}; do
    LARCH=${ARCH#*\/}
    docker compose stop ${OS}_$LARCH
done
docker compose down
docker volume prune -f

