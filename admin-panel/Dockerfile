FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/dist ./dist
RUN npm install -g serve

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 reactapp && \
    chown -R reactapp:nodejs /app
USER reactapp

EXPOSE 3001
CMD ["serve", "-s", "dist", "-l", "3001"]
