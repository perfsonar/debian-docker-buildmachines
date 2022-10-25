// docker bake configuration

// Variables used in this file, docker-compose and Dockerfile
// See following references:
// https://docs.docker.com/engine/reference/commandline/buildx_bake/#hcl-variables-and-functions
// https://github.com/docker/buildx/blob/master/bake/hclparser/stdlib.go
// https://github.com/zclconf/go-cty/tree/main/cty/function/stdlib

variable "REPO" {
    default = "perfsonar-patch-snapshot"
}
# Debian Buster 10.11 is the latest to have the ppc64le architecture
variable "OSimage" {
    default = "debian:10.11"
}
variable "OSfamily" {
    default = regex_replace("${OSimage}", ":.*", "")
}
variable "useproxy" {
    default = "without"
}
variable "proxy" {
    default = ""
}

// Defaults
group "default" {
    targets = ["single_build", "single_test"]
}

// All the build targets
target "root_build" {
    args = {
        OSimage = OSimage
        REPO = REPO
        useproxy = useproxy
        proxy = proxy
    }
    target = "build-image"
    output = ["type=cacheonly"]
}
target "single_build" {
    inherits = ["root_build"]
    output = ["type=docker"]
    tags = ["psbuild.${REPO}.${OSimage}"]
}
target "dual_build" {
    inherits = ["root_build"]
    platforms = ["linux/amd64", "linux/arm64"]
    output = ["type=registry"]
    tags = ["docker.io/ntw0n/psbuild.${REPO}.${OSfamily}:latest"]
}
target "full_build" {
    inherits = ["root_build"]
    platforms = ["linux/amd64", "linux/arm64", "linux/arm/v7", "linux/ppc64le"]
    output = ["type=registry"]
    tags = ["docker.io/ntw0n/psbuild.${REPO}.${OSfamily}:latest"]
}
target "single_test" {
    inherits = ["root_build"]
    output = ["type=docker"]
    tags = ["pstest.${REPO}.${OSimage}"]
}


