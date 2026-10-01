# Lab 04 — Debug ứng dụng NodeJS không hoạt động trong Docker

> **Module:** 07 Docker

## Mục tiêu
- Debug có phương pháp một container "chạy nhưng không truy cập được".
- Hiểu network namespace của container và cơ chế publish port.

## Kiến thức cần có
- `docker run -p`, `docker exec`, `docker logs`.
- Network cơ bản: interface, địa chỉ lắng nghe, `ss`/`netstat`.

## Môi trường
- File có vấn đề: [`starter/Dockerfile`](starter/Dockerfile), [`starter/server.js`](starter/server.js), [`starter/package.json`](starter/package.json).

### File có vấn đề

```dockerfile
# Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
CMD ["node", "server.js"]
```

```javascript
// server.js
const http = require('http');

const server = http.createServer((req, res) => {
  res.end('Hello World');
});

server.listen(3000, '127.0.0.1', () => {
  console.log('Server running on port 3000');
});
```

### Vấn đề
- Build thành công
- Container chạy không lỗi
- Nhưng không thể truy cập từ host: `curl localhost:3000` timeout

## Yêu cầu
1. Build và chạy lại để tái hiện lỗi (tự chọn lệnh `docker run` hợp lý).
2. Tìm nguyên nhân — ghi lại **quá trình debug** từng bước: kiểm tra gì, lệnh gì, kết quả gì, loại trừ giả thuyết nào.
3. Sửa lỗi.
4. Giải thích tại sao.
5. Sửa sao cho địa chỉ/port lắng nghe cấu hình được qua biến môi trường.
6. Ngoài lỗi chính, rà soát Dockerfile và liệt kê các điểm chưa tốt khác (bảo mật, cache, thiếu file…), sửa luôn.

## Kết quả cần nộp
Nộp vào `devops-training/07-docker/lab-04-debug-network-binding/`:
- `Dockerfile`, `server.js`, `package.json`, `.dockerignore` đã sửa
- `NOTES.md`: nhật ký debug, nguyên nhân, giải thích, danh sách điểm cải tiến

## Tiêu chí đạt
- [ ] Nhật ký debug có ít nhất 3 bước kiểm tra với lệnh và output thật
- [ ] `curl localhost:3000` từ host trả về `Hello World`
- [ ] Giải thích đúng bằng khái niệm network namespace / interface
- [ ] Host/port cấu hình được qua env
- [ ] Container chạy non-root

## Câu hỏi tự kiểm tra

Tự trả lời các câu hỏi sau và ghi câu trả lời vào `NOTES.md`.
1. Lỗi `Connection reset` / `Empty reply` khác `Connection refused` và `timeout` thế nào? Mỗi loại gợi ý nguyên nhân gì?
2. Bên trong container, `localhost` là của ai? Khác `localhost` của host thế nào?
3. Docker chuyển traffic từ port host vào container bằng cơ chế nào (`docker-proxy`, iptables NAT)?
4. Vì sao `curl` từ **bên trong** container lại thành công?
5. Khi chạy app trực tiếp trên VM (không Docker) sau Nginx, bind `127.0.0.1` lại là lựa chọn tốt — vì sao?

<details>
<summary>Gợi ý</summary>

- So sánh kết quả `curl` từ host và từ `docker exec` vào trong container.
- Xem container đang lắng nghe trên địa chỉ nào: image alpine có sẵn `netstat` (busybox).
- `docker port <container>` và `docker ps` cho biết gì về port mapping?

</details>

## Tài liệu tham khảo
- https://docs.docker.com/engine/network/
- https://docs.docker.com/engine/network/packet-filtering-firewalls/
- https://nodejs.org/api/net.html#serverlisten
