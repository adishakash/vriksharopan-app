FROM node:20-alpine AS base
WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy source
COPY src/ ./src/

# Create logs directory
RUN mkdir -p logs

# Non-root user for security
RUN addgroup -g 1001 -S nodejs && adduser -S vrisharopan -u 1001
RUN chown -R vrisharopan:nodejs /app
USER vrisharopan

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:5000/health || exit 1

CMD ["node", "src/server.js"]
