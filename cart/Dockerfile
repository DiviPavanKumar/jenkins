# ---------- Build Stage ----------
FROM node:20-alpine3.21 AS builder
WORKDIR /opt/server

# Copy and install deps (cache optimized)
COPY package*.json ./
RUN npm ci --omit=dev --unsafe-perm

# Copy application source
COPY . .

# ---------- Runtime Stage ----------
FROM node:20-alpine3.21
RUN addgroup -S roboshop && adduser -S roboshop -G roboshop
USER roboshop
WORKDIR /opt/server

# Environment variables
ENV REDIS_HOST="redis" \
    CATALOGUE_HOST="catalogue" \
    CATALOGUE_PORT="8080"

# Copy app from builder
COPY --from=builder /opt/server /opt/server

# Expose app port
EXPOSE 8080

# Optional healthcheck
# HEALTHCHECK --interval=30s --timeout=5s \
#   CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

CMD ["node", "server.js"]