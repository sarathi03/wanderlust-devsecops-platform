FROM node:22-alpine

WORKDIR /app
ENV NODE_ENV=production

# Install dependencies first so Docker can cache this layer between builds.
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY src ./src

# The CI pipeline passes the image tag here, so the running app knows its version.
ARG APP_VERSION=dev
ENV APP_VERSION=$APP_VERSION

USER node
EXPOSE 8080
CMD ["node", "src/server.js"]
