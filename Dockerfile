FROM --platform=${BUILDPLATFORM} golang:1.20 as build

WORKDIR /build

ARG BUILDPLATFORM TARGETARCH TARGETOS

COPY go.mod ./
COPY go.sum ./
RUN go mod download
RUN go mod verify

COPY . .

FROM build as buildamd64
ONBUILD RUN script/install-libtensorflow

FROM build${TARGETARCH} as build

RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -a -o 'snips.sh'

FROM --platform=${BUILDPLATFORM} ubuntu:20.04 as finalamd64
ONBUILD COPY --from=build /usr/local/lib/libtensorflow.so.2 /usr/local/lib/
ONBUILD COPY --from=build /usr/local/lib/libtensorflow_framework.so.2 /usr/local/lib/

ONBUILD RUN ldconfig

FROM final${TARGETARCH}

COPY --from=build /build/snips.sh /usr/bin/snips.sh

ENV SNIPS_HTTP_INTERNAL=http://0.0.0.0:8080
ENV SNIPS_SSH_INTERNAL=ssh://0.0.0.0:2222

EXPOSE 8080 2222

ENTRYPOINT [ "/usr/bin/snips.sh" ]
