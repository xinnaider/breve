FROM node:22-alpine AS build
WORKDIR /src
COPY landing/package.json landing/package-lock.json /src/landing/
RUN cd /src/landing && npm ci
COPY assets /src/assets
COPY landing /src/landing
RUN cd /src/landing && npm run build

FROM nginx:1.27-alpine
COPY landing/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /src/landing/dist /usr/share/nginx/html
EXPOSE 80
