FROM node:24-alpine3.23 AS builder

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm install

COPY . .
RUN npx prisma generate
RUN npm run build

CMD ["sh", "-c", "npx prisma migrate deploy && node dist/src/main.js"]