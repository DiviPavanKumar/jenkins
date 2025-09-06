# ---------- Build Stage ----------
FROM node:20.11.1-alpine3.21 AS builder
WORKDIR /opt/server

# Copy dependencies first for better caching
COPY package*.json ./
RUN npm ci --omit=dev --unsafe-perm

# Copy source code
COPY . .

# ---------- Runtime Stage ----------
FROM node:20.11.1-alpine3.21
RUN addgroup -S roboshop && adduser -S roboshop -G roboshop

# Set environment variables
ENV MONGO="true" \
    REDIS_URL="redis://redis:6379" \
    MONGO_URL="mongodb://mongodb:27017/users"

# Switch to non-root user
USER roboshop
WORKDIR /opt/server

# Copy built app from builder stage
COPY --from=builder /opt/server /opt/server

EXPOSE 3000

# Optional healthcheck
# HEALTHCHECK --interval=30s --timeout=5s \
#   CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
