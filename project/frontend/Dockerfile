FROM nginx:1.29.6 AS dev

WORKDIR /usr/share/nginx/html

COPY . .

CMD ["nginx-debug", "-g", "daemon off;"]

FROM nginx:1.29.6-alpine AS prod

WORKDIR /usr/share/nginx/html

COPY . .