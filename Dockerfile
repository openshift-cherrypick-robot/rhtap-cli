#
# Build
#

FROM registry.access.redhat.com/ubi9/go-toolset:latest AS builder

USER root

WORKDIR /workdir/rhtap-cli

COPY installer/ ./installer/

COPY cmd/ ./cmd/
COPY pkg/ ./pkg/
COPY vendor/ ./vendor/

COPY go.mod go.sum Makefile .

RUN make GOFLAGS='-buildvcs=false'

#
# Run
#

FROM registry.access.redhat.com/ubi9-minimal:9.4-1227.1725849298

ARG OC_VERSION=4.14.8

WORKDIR /rhtap-cli

COPY --from=quay.io/codeready-toolchain/oc-client-base:latest /usr/bin/kubectl /usr/bin/

COPY --from=builder /workdir/rhtap-cli/installer .

COPY --from=builder /workdir/rhtap-cli/bin/rhtap-cli /usr/local/bin/rhtap-cli

RUN microdnf install shadow-utils && \
    groupadd --gid 1000 -r rhtap-cli && \
    useradd -r -d /rhtap-cli -g rhtap-cli -s /sbin/nologin --uid 1000 rhtap-cli && \
    microdnf remove -y shadow-utils && \
    microdnf clean all

USER rhtap-cli

ENTRYPOINT ["/rhtap-cli/rhtap-cli"]
