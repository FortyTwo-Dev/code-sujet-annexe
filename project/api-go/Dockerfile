FROM golang:1.26.1

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

#RUN go mod tidy

COPY *.go ./

RUN go build -o app

EXPOSE 8080

CMD ["./app"]