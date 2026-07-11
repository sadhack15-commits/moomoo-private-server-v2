# Hướng dẫn deploy Moomoo Private Server lên Back4App Containers

App của bạn: https://containers.back4app.com/apps/a4ef0f23-c46e-4f8b-b2fe-09857b3e42ae

## 1. Đưa code lên GitHub

Back4App Containers build trực tiếp từ một repo GitHub, nên trước tiên push toàn bộ thư mục này (đã có sẵn `Dockerfile` ở thư mục gốc) lên một repo GitHub của bạn.

```bash
git init
git add .
git commit -m "Back4App container build"
git branch -M main
git remote add origin https://github.com/<user>/<repo>.git
git push -u origin main
```

## 2. Kết nối repo trên Back4App

1. Vào https://containers.back4app.com
2. Chọn app đã có sẵn (link ở trên) hoặc **Create new app → Containers as a Service**.
3. Kết nối tài khoản GitHub, chọn repo bạn vừa push.
4. Chọn **branch** (thường là `main`) và **root directory** — nếu Dockerfile nằm ở gốc repo thì để `/`.

## 3. Cấu hình App Settings

Trong phần cấu hình app trên Back4App, thiết lập:

| Setting | Giá trị |
|---|---|
| **Port** | `1234` (khớp với `EXPOSE 1234` trong Dockerfile — Back4App sẽ tự inject biến `PORT` tương ứng khi chạy container) |
| **Environment Variables** | Không bắt buộc, có thể thêm nếu bạn cần custom (ví dụ `NODE_ENV=production` đã có sẵn trong Dockerfile) |
| **Auto Deploy** | Bật nếu muốn mỗi lần push code là tự deploy lại |

> Lưu ý: Back4App sẽ tự set biến môi trường `PORT` khi chạy container. `index.js` trong project đã đọc `process.env.PORT || 1234` nên không cần sửa gì thêm.

## 4. Deploy

Nhấn **Create App** / **Deploy**. Back4App sẽ:
1. Build image theo `Dockerfile` (multi-stage: cài dependency bằng `npm ci --omit=dev`, sau đó copy vào image runtime `node:20-alpine`).
2. Chạy container, expose cổng, và cấp cho bạn 1 domain dạng `https://<tên-app>.b4a.run`.

## 5. Kiểm tra WebSocket

Moomoo private server dùng WebSocket (thư viện `ws`) để giao tiếp giữa client và server qua `server.on("upgrade", ...)`. Back4App Containers **hỗ trợ đầy đủ WebSocket** (kể cả qua HTTPS/WSS), nên client game có thể kết nối bình thường tới domain Back4App cấp cho bạn — chỉ cần đổi URL server trong client từ `ws://...` / `wss://...` sang domain mới, ví dụ:

```js
wss://<tên-app>.b4a.run
```

## 6. Theo dõi log & health

- Back4App có **Logbox** để xem log real-time của container — hữu ích để debug nếu server không start được.
- Dockerfile đã có sẵn `HEALTHCHECK` gọi vào `/` (route đã trả về text `"Moomoo private server is running."`) để Back4App biết container còn sống.

## Các thay đổi so với bản gốc

- `Dockerfile` được viết lại theo dạng **multi-stage build** trên nền `node:20-alpine` (nhẹ hơn `node:20-slim`), dùng `npm ci` thay vì `npm install` để build ổn định/lặp lại được.
- Container chạy bằng user `node` (không phải root) — an toàn hơn khi deploy.
- Thêm `HEALTHCHECK` để Back4App giám sát trạng thái app.
- Không đổi bất kỳ logic game nào trong `index.js` / `src/` — server hoạt động y hệt bản gốc, chỉ khác cách đóng gói & chạy container.
