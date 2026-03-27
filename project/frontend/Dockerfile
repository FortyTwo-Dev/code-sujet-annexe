FROM nginx:1.29.6 AS builder

WORKDIR /usr/share/nginx/html

COPY . .

FROM nginx:1.29.6-alpine AS prod

WORKDIR /usr/share/nginx/html

COPY . .