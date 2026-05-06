# ── Etapa 1: build ────────────────────────────────────────────
FROM node:18-alpine AS builder

WORKDIR /app

# Copiar manifiestos primero para aprovechar la caché de capas
COPY package*.json ./

# Instalar solo dependencias de producción
RUN npm install --omit=dev

# ── Etapa 2: imagen final ──────────────────────────────────────
FROM node:18-alpine

WORKDIR /app

# Instalar wget para el Healthcheck (Alpine lo trae, pero aseguramos)
RUN apk add --no-cache wget

# Crear usuario no-root por seguridad
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copiar dependencias instaladas desde la etapa builder
COPY --from=builder /app/node_modules ./node_modules

# Copiar código fuente
COPY server.js ./

# Cambiar propietario al usuario no-root
RUN chown -R appuser:appgroup /app
USER appuser

# Exponer el puerto del servidor Express
EXPOSE 3000


# Variables de entorno por defecto
ENV PORT=3000 \
    NODE_ENV=production \
    DB_HOST=db \
    DB_PORT=3306

# Health check: verifica que la API responde
HEALTHCHECK --interval=15s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -qO- http://localhost:3000/ || exit 1

CMD ["node", "server.js"]