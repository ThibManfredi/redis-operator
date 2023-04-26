# syntax=docker/dockerfile:1
#########################################
#### Arguments (outside build stage) ####
#########################################
ARG GO_VERSION

# Build the manager binary
FROM cellule-gl-go-docker.artifactory.si.francetelecom.fr/go-build:${GO_VERSION} as builder

########################################
#### Arguments (inside build stage) ####
########################################
ARG GITLAB_CI_USER
ARG GITLAB_CI_PASS
ARG CGO_ENABLED
ARG GOOS
ARG GOARCH
ARG GO111MODULE

# Deal with private gitlab repositories
RUN printf \
    "machine gitlab.si.francetelecom.fr\n  login %s\n  password %s\n" \
    "${GITLAB_CI_USER}" \
    "${GITLAB_CI_PASS}" \
    >~/.netrc

WORKDIR /build
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download -x 2>&1

# Copy the go source
COPY . .

# Build
RUN \
    CGO_ENABLED=${CGO_ENABLED} GOOS=${GOOS} GOARCH=${GOARCH} GO111MODULE=${GO111MODULE} \
    go build -o manager

##################
#### From ... ####
##################
# Gets the latest Ubuntu build tag from Artifcatory registry:
#   https://artifactory.packages.install-os.multis.p.fti.net/webapp/#/artifacts/browse/tree/General/all-officialdfy-docker/ubuntu
FROM all-officialdfy-docker.artifactory.si.francetelecom.fr/ubuntu:20.04

#####################
#### Environment ####
#####################
ENV DEBIAN_FRONTEND="noninteractive" \
    INITRD="No" \
    TZ="Europe/Paris" \
    # Sytem user
    SERVICE_USER="hagndaas" \
    SERVICE_GROUP="hagndaas" \
    SERVICE_UID=1001

##################
#### Metadata ####
##################
LABEL org.opencontainers.image.authors="hagndaas.support@orange.com"
LABEL org.opencontainers.image.description="operator-redis image"
LABEL org.opencontainers.image.documentation="https://gitlab.si.francetelecom.fr/hagndaas/k8s/service-redis/operator-redis"
LABEL org.opencontainers.image.source="https://gitlab.si.francetelecom.fr/hagndaas/k8s/service-redis/operator-redis"
LABEL org.opencontainers.image.title="operator-redis"
LABEL org.opencontainers.image.url="https://gitlab.si.francetelecom.fr/hagndaas/k8s/service-redis/operator-redis"
LABEL org.opencontainers.image.vendor="HagnDAAS"
LABEL org.opencontainers.image.version="${GIT_COMMIT}"
LABEL org.opencontainers.image.ref.name="${GIT_BRANCH}"

########################
#### Copying rootfs ####
########################
COPY ./rootfs /tmp/rootfs
COPY --from=builder /build/manager /usr/local/bin/

##################
#### Packages ####
##################
RUN \
    # RootFS
    cp -rv /tmp/rootfs/* / &&\
    chmod +x /usr/local/bin/* &&\
    # Debian packages
    aptinstaller &&\
    # System user
    useradd -l -m -U -s "/bin/sh" -u "${SERVICE_UID}" "${SERVICE_USER}" -c "HagnDAAS User" &&\
    # Clean
    docker_clean 'END'

###################
#### Execution ####
###################
WORKDIR /home/"${SERVICE_USER}"
USER "${SERVICE_USER}"
ENTRYPOINT ["manager"]
