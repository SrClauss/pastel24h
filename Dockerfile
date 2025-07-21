# Estágio 1: Instalação de dependências de produção
# Usamos uma imagem slim para manter o tamanho final pequeno.
FROM node:20-slim AS deps
WORKDIR /app

# Copia apenas os arquivos de definição de pacotes
COPY package.json package-lock.json ./
# Instala somente as dependências de produção para aproveitar o cache do Docker
RUN npm ci --omit=dev

# Estágio 2: Build da aplicação
FROM node:20-slim AS builder
WORKDIR /app

# Copia todo o código-fonte e os arquivos de pacotes
COPY . .
# Instala TODAS as dependências (incluindo as de desenvolvimento) para o build
RUN npm ci
# Roda o script de build que gera a pasta 'dist'
RUN npm run build

# Estágio 3: Imagem final de produção
FROM node:20-slim AS runner
WORKDIR /app

ENV NODE_ENV=production

# Copia as dependências de produção do estágio 'deps'
COPY --from=deps /app/node_modules ./node_modules
# Copia a aplicação buildada do estágio 'builder'
COPY --from=builder /app/dist ./dist
# Copia o package.json para que o script 'npm run start' funcione
COPY package.json .

# Cria o diretório 'data' onde o banco de dados SQLite será armazenado
RUN mkdir -p data

# Expõe a porta em que a aplicação roda
EXPOSE 5000

# Comando para iniciar a aplicação
CMD [ "npm", "run", "start" ]