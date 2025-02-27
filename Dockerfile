# Etapa 1: Backend
FROM python:3.13.1 AS backend-builder

WORKDIR ./
COPY requirements.txt ./
RUN python -m venv .venv && .venv/bin/pip install --upgrade pip && .venv/bin/pip install -r requirements.txt

# Etapa 2: Frontend con Vite
FROM node:22.13.1 AS frontend-builder

WORKDIR ./
COPY package.json package-lock.json ./

RUN npm install

COPY . .  # <- Esto copia todo el frontend, incluyendo `index.html`

RUN npm run build
RUN npm prune --omit=dev

# Etapa 3: Configurar el contenedor final con Nginx y FastAPI
FROM nginx:alpine

WORKDIR ./

# Instalar Python y pip en Alpine Linux
RUN apk add --no-cache python3 py3-pip

# Copiar la aplicación del backend desde la Etapa 1
COPY --from=backend-builder /backend /app

# Crear un entorno virtual dentro del contenedor final
RUN python3 -m venv /app/.venv
RUN ./.venv/bin/pip install --upgrade pip
RUN ./.venv/bin/pip install --no-cache-dir -r /app/requirements.txt

# Copiar el frontend desde la Etapa 2
COPY --from=frontend-builder ./dist /usr/share/nginx/html  # <- Ajustar ruta

# Configurar Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Exponer los puertos
EXPOSE 80
EXPOSE 8000

# Ejecutar FastAPI y Nginx
CMD ["sh", "-c", "/app/.venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000 & nginx -g 'daemon off;'"]
