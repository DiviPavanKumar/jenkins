# ---- Build Stage ----
FROM node:20-alpine3.21 AS builder
WORKDIR /opt/server

# Copy only package files first (better caching)
COPY package*.json ./
RUN npm ci --only=production

# Copy rest of the application
COPY . .

# ---- Runtime Stage ----
FROM node:20-alpine3.21

# Create non-root user
RUN addgroup -S roboshop && adduser -S roboshop -G roboshop

# Environment variables
ENV NODE_ENV=production \
    MONGO=true \
    MONGO_URL="mongodb://mongodb:27017/catalogue"

WORKDIR /opt/server
USER roboshop

# Copy built artifacts
COPY --from=builder /opt/server /opt/server

# Expose application port
EXPOSE 8080

# Healthcheck (optional)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD curl -f http://localhost:8080/health || exit 1

CMD ["node", "server.js"]


# FROM node:20-alpine
# RUN addgroup -S roboshop && adduser -S roboshop -G roboshop
# WORKDIR /opt/server
# COPY package.json .
# COPY *.js .
# RUN npm install
# RUN chown -R roboshop:roboshop /opt/server
# ENV MONGO="true" \
#     MONGO_URL="mongodb://mongodb:27017/catalogue"
# USER roboshop
# CMD ["node" , "server.js"]
