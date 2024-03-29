FROM golang:alpine AS builder
LABEL maintainer="Nicholas Gasior <nicholas@gasior.dev>"

RUN apk add --update git bash openssh make

WORKDIR /go/src/github.com/nicholasgasior/github-webhookd
COPY . .
RUN make tools
RUN make build

FROM alpine:latest
RUN apk --no-cache add ca-certificates

WORKDIR /bin
COPY --from=builder /go/bin/linux/github-webhookd .

ENTRYPOINT ["/bin/github-webhookd"]
