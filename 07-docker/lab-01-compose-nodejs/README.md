# Lab 01 — Docker Compose + NodeJS

> **Module:** 07 Docker

## Mục tiêu
- Viết `Dockerfile` cho ứng dụng NodeJS đúng best practice (cache layer, non-root, `.dockerignore`).
- Viết `docker-compose.yml` cho ứng dụng nhiều service: app, cache, database.
- Dùng biến môi trường, `depends_on` + healthcheck, volume.

## Kiến thức cần có
- Dockerfile cơ bản, `docker compose up/down/logs/ps`.
- NodeJS/npm cơ bản.

## Môi trường
- 1 VM Ubuntu đã cài Docker Engine + Compose v2.
- File khởi đầu: [`starter/app.js`](starter/app.js), [`starter/package.json`](starter/package.json).

## Yêu cầu
1. Tạo một ứng dụng Express.js đơn giản với endpoint `/health` trả về `{"status": "ok"}` (dùng file khởi đầu bên dưới).
2. Viết `Dockerfile` cho ứng dụng:
   - Base image có pin version (VD `node:18-alpine` hoặc mới hơn).
   - Tận dụng build cache: copy `package*.json` và cài dependency trước khi copy source.
   - Chạy bằng **non-root user**.
   - Có `.dockerignore` (loại `node_modules`, `.git`, `.env`…).
3. Viết `docker-compose.yml` với các service:
   - `app`: Ứng dụng NodeJS (port 3000)
   - `redis`: Cache server
   - `mongo`: Database
   - Không khai báo `version:` (đã obsolete trong Compose v2).
4. Mở rộng app:
   - Đọc `REDIS_URL` và `MONGO_URL` từ biến môi trường (không hardcode).
   - Thêm endpoint `/health/deps` thử kết nối Redis (`PING`) và Mongo (`ping` command), trả về trạng thái từng dependency, VD `{"redis":"ok","mongo":"ok"}`; trả HTTP 503 nếu một dependency lỗi.
5. `redis` và `mongo` có `healthcheck`; `app` dùng `depends_on` với `condition: service_healthy`.
6. Mongo dùng **named volume** để dữ liệu còn sau khi `docker compose down` rồi `up` lại.
7. Chỉ publish port của `app` ra host; `redis` và `mongo` không publish port.

### File khởi đầu

```javascript
// app.js
const express = require('express');
const app = express();

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(3000);
```

## Kết quả mong đợi
- Chạy `docker compose up` thành công.
- Truy cập `http://localhost:3000/health` trả về JSON.
- `http://localhost:3000/health/deps` trả về trạng thái Redis và Mongo.

## Kết quả cần nộp
Nộp vào `devops-training/07-docker/lab-01-compose-nodejs/`:
- `app.js`, `package.json`, `package-lock.json`, `Dockerfile`, `.dockerignore`, `docker-compose.yml`
- `NOTES.md`: lệnh đã chạy, output `docker compose ps`, `curl` 2 endpoint, chứng minh dữ liệu Mongo còn sau `down`/`up`, kích thước image

## Tiêu chí đạt
- [ ] `docker compose up -d` chạy được từ repo sạch, không cần sửa gì thêm
- [ ] `curl localhost:3000/health` → `{"status":"ok"}`
- [ ] `/health/deps` trả `ok` cho cả 2; stop `redis` thì trả 503
- [ ] `docker compose ps` hiển thị `redis`, `mongo` ở trạng thái `healthy`
- [ ] `docker compose exec app id` cho thấy không chạy bằng root
- [ ] Redis/Mongo không publish port ra host
- [ ] Dữ liệu Mongo còn sau `docker compose down` + `up` (không dùng `-v`)
- [ ] Sửa `app.js` rồi build lại: bước `npm install` dùng cache

## Câu hỏi tự kiểm tra

Tự trả lời các câu hỏi sau và ghi câu trả lời vào `NOTES.md`.
1. Trong compose, app gọi Redis bằng hostname gì? Ai phân giải tên đó?
2. `depends_on` không có `condition` thì đảm bảo được gì và không đảm bảo gì?
3. Vì sao không cần publish port của Mongo/Redis? Nếu publish thì có rủi ro gì?
4. `npm install` vs `npm ci` — nên dùng cái nào trong Dockerfile? Vì sao?
5. `docker compose down` và `docker compose down -v` khác nhau thế nào?
6. Không có `.dockerignore` thì chuyện gì có thể xảy ra với `node_modules`?
7. App gọi `app.listen(3000)` không truyền host — app đang lắng nghe trên địa chỉ nào?

<details>
<summary>Gợi ý</summary>

- Image `node:*-alpine` đã có sẵn user `node`.
- Thư viện gợi ý: `redis` (node-redis v4) và `mongodb` (driver chính thức).
- Healthcheck Redis: `redis-cli ping`; Mongo bản mới có `mongosh`.
- Thử `docker compose build --progress=plain` để thấy bước nào `CACHED`.

</details>

## Tài liệu tham khảo
- https://docs.docker.com/compose/compose-file/
- https://docs.docker.com/compose/how-tos/startup-order/
- https://docs.docker.com/build/concepts/context/#dockerignore-files
- https://github.com/nodejs/docker-node/blob/main/docs/BestPractices.md
