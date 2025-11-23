FROM node:18-alpine

WORKDIR /app

# Installer les dépendances système pour pg (postgres)
RUN apk add --no-cache python3 make g++

# Configurer npm
RUN npm config set registry https://registry.npmjs.org/ && \
    npm config set fetch-timeout 300000 && \
    npm config set fetch-retries 2

# Copier package.json
COPY package.json ./

# Installer les dépendances de production
RUN npm install --only=production --legacy-peer-deps --no-optional --prefer-offline --no-audit

# Copier le code source
COPY . .

EXPOSE 8080

USER node

CMD ["node", "server.js"]

