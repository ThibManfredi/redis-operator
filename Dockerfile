# syntax=docker/dockerfile:1
#########################################
#### Arguments (outside build stage) ####
#########################################
ARG GO_VERSION

# Build the manager binary
FROM cellule-gl-go-docker.artifactory.si.francetelecom.fr/go-build:${GO_VERSION} as go_builder

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


# WORKDIR /build
# # Copy the Go Modules manifests
# COPY go.mod go.mod
# COPY go.sum go.sum
# # cache deps before building and copying source so that we don't need to re-download as much
# # and so that source changes don't invalidate our downloaded layer
# RUN go mod download -x 2>&1


WORKDIR /build
COPY . .

ARG GIT_COMMIT
ARG GIT_BRANCH
ARG BUILD_TIME
ARG GO_LDFLAGS

RUN mkdir -p build/_output/bin &&\
    go mod vendor 2>&1 &&\
    GOOS=$GOOS GOARCH=$GOARCH CGO_ENABLED=$CGO_ENABLED GO_LDFLAGS=${GO_LDFLAGS} \
    go build -mod=vendor -ldflags "-w -s -X main.GitCommit=$GIT_COMMIT -X main.GitBranch=$GIT_BRANCH -X main.BuildTime=$BUILD_TIME" \
    -o build/_output/bin/manager \
    main.go &&\
    cp -r build/_output/bin/manager /usr/local/bin/manager

##################
#### From ... ####
##################
# Gets the latest Ubuntu build tag from Artifcatory registry:
#   https://artifactory.packages.install-os.multis.p.fti.net/webapp/#/artifacts/browse/tree/General/all-officialdfy-docker/ubuntu
FROM all-officialdfy-docker.artifactory.si.francetelecom.fr/ubuntu:20.04

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

COPY LICENSE /licenses/
COPY --from=go_builder /usr/local/bin/manager /usr/local/bin/manager

USER 2
