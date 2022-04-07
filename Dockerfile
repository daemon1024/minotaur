### Builder

FROM golang:1.17.5-alpine3.15 as builder

RUN apk --no-cache update
RUN apk add --no-cache bash git wget python3 linux-headers build-base clang clang-dev libc-dev

RUN mkdir /app
ADD . /app
WORKDIR /app
RUN go build -o minotaur .

### Make executable image

FROM alpine:3.15

RUN apk --no-cache update && \
    apk --no-cache add bash git rsync && \
    apk --no-cache add coreutils findutils && \
    apk --no-cache add llvm clang go make gcc && \
    apk --no-cache add musl-dev && \
    apk --no-cache add linux-headers && \
    apk --no-cache add elfutils-dev && \
    apk --no-cache add libelf-static && \
    apk --no-cache add zlib-static

COPY --from=builder /app/entrypoint.sh /app/entrypoint.sh
COPY --from=builder /app/minotaur /app/minotaur
COPY --from=builder /app/Makefile /app/Makefile
COPY --from=builder /app/minotaur.c /app/minotaur.c
COPY --from=builder /app/libbpf /app/libbpf/

ENTRYPOINT ["/app/entrypoint.sh"]