# ─────────────────────────────────────────────
# Etapa 1: build
# ─────────────────────────────────────────────
FROM node:18-alpine AS builder

WORKDIR /app

# Copiar sólo los manifiestos primero (cache de capas)
COPY package*.json ./

# Instalar dependencias de producción
RUN npm install --omit=dev

# ─────────────────────────────────────────────
# Etapa 2: imagen final
# ─────────────────────────────────────────────
FROM node:18-alpine

WORKDIR /app

# Usuario sin privilegios
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copiar dependencias desde el builder
COPY --from=builder /app/node_modules ./node_modules

# Copiar código fuente
COPY server.js ./
COPY package*.json ./

# Establecer propietario
RUN chown -R appuser:appgroup /app
USER appuser

# Puerto que expone el backend (Express)
EXPOSE 3000

# Variable de entorno por defecto (sobreescribible desde docker-compose / EC2)
ENV NODE_ENV=production

# Comando de inicio
CMD ["node", "server.js"]