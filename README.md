# Debian/Ubuntu build and testing containers
This directoy needs to be at the same level as the other perfSONAR repositories that you want to build package for.  It provides some scripts and a Docker setup to build Debian/Ubuntu packages out of a perfSONAR source repository.  The currently checked-out branch will be built.

These scripts rely heavily on Docker and a working `docker buildx` setup.

## Build packages
To build a Debian/Ubuntu package, run something like:

./build-in-docker toolkit

* args understood (full list in script itself):
  * `-d` don't rebuild Docker images but use locally existing one
  * `-B` don't rebuild source package but use previously build one
  * `-D` debug build, will get you into a shell instead of doing the build
  * `-k` use and keep locally built packages (can be useful to solve build dependencies)
  * `-s` build only the source package

The resulting packages will be located in a new directory at the same level as the other repositories called `build_results`

The build will use the information from the `debian/gbp.conf` file to know on which distro the package should be built and with which perfSONAR repository the dependencies should be solved.

Once you have the `docker buildx` images ready, you can call all subsequent builds with `-d`.

There is provision to use a HTTP proxy to download packages if you need to do so.  See the examples below and in the scripts.

### Examples

* Building `perfsonar-graphs` located in the `../graphs` directory:
```
./build-in-docker graphs
```
* Building `perfsonar-graphs` a second time:
```
./build-in-docker -d graphs
```
* Building `perfsonar-graphs` to debug the binary build and keep the previously localy built packages:
```
./build-in-docker -dBD -k graphs
```
* Building `pscheduler-archiver-rabbitmq` using a local proxy:
```
proxy=172.17.0.1:3128 package=pscheduler-archiver-rabbitmq ./build-in-docker pscheduler
```

## Test packages
To test the installation of a resulting package, run something like:

./test-in-docker package.deb

This project provides ways of testing installation of perfSONAR DEB package-based bundles on Debian-based systems using Docker containers.

Fully Supported:
 * Debian 9 Stretch
 * Debian 10 Buster
 * Ubuntu 16 Xenial Xerus
 * Ubuntu 18 Bionic Beaver

You can run the tests by executing `test_install_instructions.sh $REPO $OS $BUNDLE` (with all args optional but the previous one always required) where:

 * `$REPO` is one of these (default is to use production):
   * `perfsonar-release` (production)
   * `perfsonar-patch-snapshot`
   * `perfsonar-minor-snapshot`
   * `perfsonar-patch-staging`
 * `$OS` is one of these (default to test all):
   * `debian:stretch`
   * `debian:buster`
   * `ubuntu:xenial`
   * `ubuntu:bionic`

