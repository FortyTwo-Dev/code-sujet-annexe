FROM golang:1.26.1-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go .

RUN go build -o app

FROM builder AS dev

WORKDIR /app

RUN apk add --no-cache curl

EXPOSE 8080

CMD ["go", "run", "main.go"]

FROM alpine:3.20 AS prod

WORKDIR /app

RUN adduser -D appuser && chown -R appuser /app

COPY --from=builder --chown=appuser:appuser /app/app .

EXPOSE 8080

USER appuser

CMD ["./app"]