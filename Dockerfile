FROM golang:alpine

MAINTAINER Reagan James <reaganjameskirby@gmail.com>

ENV GIN_MODE=release
ENV PORT=8080

WORKDIR /go/src/app

COPY . .

RUN go build -o time time.go

CMD ["./time"]