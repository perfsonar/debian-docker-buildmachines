# bundle-deb-install-tests

This project provides ways of testing installation of perfSONAR DEB package-based bundles on Debian-based systems using Docker containers.

Fully Supported:
 * Debian 9 Stretch
 * Ubuntu 16 Xenial Xerus
 * Ubuntu 18 Bionic Beaver

Partial support:
 * Debian 10 Buster (only `perfsonar-testpoint` bundle)

The script attempts to perform sanity checks using the `sanity-checking` scripts (so those will need to be built with Docker first). See `../../sanity-checking`.

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
 * `$BUNDLE` is one of these (default is to test all)
 ** `perfsonar-tools`
 ** `perfsonar-testpoint`
 ** `perfsonar-core`
 ** `perfsonar-centralmanagement`
 ** `perfsonar-toolkit`

