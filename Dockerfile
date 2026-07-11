# ============================================================
# Dockerfile - Moomoo Private Server (bản build cho Back4App Containers)
# App: https://containers.back4app.com/apps/a4ef0f23-c46e-4f8b-b2fe-09857b3e42ae
# ============================================================

# ---- Stage 1: cài dependencies ----
FROM node:20-alpine AS deps
WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci --omit=dev

# ---- Stage 2: image chạy thật ----
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production

# Back4App sẽ set PORT qua biến môi trường ở App Settings.
# Giá trị 1234 chỉ là fallback khi chạy local / build test.
ENV PORT=1234

# Copy node_modules đã cài từ stage deps (tận dụng cache, image nhẹ hơn)
COPY --from=deps /app/node_modules ./node_modules

# Copy toàn bộ source code (đã lọc theo .dockerignore)
COPY . .

# Back4App Containers BẮT BUỘC phải có EXPOSE để biết cổng TCP nào cần route
EXPOSE 1234

# Chạy bằng user "node" có sẵn trong base image (không chạy bằng root) để an toàn hơn
USER node

# Healthcheck để Back4App theo dõi trạng thái container (endpoint "/" trả về text OK)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||1234)).then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "index.js"]
