// docker bake configuration

// Variables used in this file, docker-compose and Dockerfile
variable "REPO" {
    default = "perfsonar-patch-snapshot"
}
variable "OSimage" {
    default = "debian:buster"
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
target "single_build" {
    inherits = ["deb_build"]
    output = ["type=docker"]
}
target "dual_build" {
    inherits = ["deb_build"]
    platforms = ["linux/amd64", "linux/arm64"]
    tags = ["build.${REPO}/${OSimage}"]
}
target "full_build" {
    inherits = ["deb_build"]
    platforms = ["linux/amd64", "linux/arm64", "linux/386", "linux/arm/v5", "linux/arm/v7"]
    tags = ["build.${REPO}/${OSimage}"]
}
target "single_test" {
    inherits = ["deb_test"]
    output = ["type=docker"]
}


