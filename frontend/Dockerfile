FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY public/ /usr/share/nginx/html/

# The CI pipeline passes the image tag here; the page displays it.
ARG APP_VERSION=dev
RUN printf '{"version":"%s"}\n' "$APP_VERSION" > /usr/share/nginx/html/version.json

EXPOSE 80
