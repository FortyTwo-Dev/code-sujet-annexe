FROM nginx:1.29.6 AS builder

WORKDIR /usr/share/nginx/html

COPY . .

CMD ["nginx", "-g", "daemon off;"]