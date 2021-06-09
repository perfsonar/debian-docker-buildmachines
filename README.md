# Debian/Ubuntu build and testing containers
This directoy needs to be at the same level as the other perfSONAR repositories that you want to build package for.  It provides some scripts and a Docker setup to build Debian/Ubuntu packages out of a perfSONAR source repository.

## Build packages
To build a Debian/Ubuntu package, run something like:

./build-in-docker -b 4.4.0 toolkit

 * args and environment variables:
 ** `-b` the branch of the repository you want to build (snapshot package)
 ** `-t` the tag of the repository you want to build (staging/release package)
 ** `ARCHES` can be set to a list of architectures to build for

TODO: make it also work for pScheduler

The resulting packages will be located in a new directory at the same level as the other repositories called `build_results`

The build will use the information from the `debian/gbp.conf` file to know on which distro the package should be built and with which perfSONAR repository the dependencies should be solved.

## Test packages
To test the installation of a resulting package, run something like:

This project provides ways of testing installation of perfSONAR DEB package-based bundles on Debian-based systems using Docker containers.

Fully Supported:
 * Debian 9 Stretch
 * Debian 10 Buster
 * Ubuntu 16 Xenial Xerus
 * Ubuntu 18 Bionic Beaver

You can run the tests by executing `test_install_instructions.sh $REPO $OS $BUNDLE` (with all args optional but the previous one always required) where:

 * `$REPO` is one of these (default is to use production):
 ** `perfsonar-release` (production)
 ** `perfsonar-patch-snapshot`
 ** `perfsonar-minor-snapshot`
 ** `perfsonar-patch-staging`
 * `$OS` is one of these (default to test all):
 ** `debian:stretch`
 ** `debian:buster`
 ** `ubuntu:xenial`
 ** `ubuntu:bionic`

