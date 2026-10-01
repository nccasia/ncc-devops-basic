# Lab 01 — Build SPA & serve bằng Nginx

> **Module:** 06 Frontend Static

## Mục tiêu
- Build một SPA thành file tĩnh và deploy lên Nginx.
- Xử lý client-side routing bằng `try_files`.
- Cấu hình cache header và nén đúng cho từng loại file.

## Kiến thức cần có
- Module 03 (Nginx), module 04 (backend `/api/employees` đang chạy).

## Môi trường
- Máy build: Node.js LTS (20 hoặc 22). Server: vm2 chỉ cần Nginx.
- App mẫu: [`starter/`](starter/) — app Vite (vanilla JS) tối giản có 2 route `/` và `/about`, trang chủ gọi `/api/employees` và render bảng. Bạn **được khuyến khích** tự tạo app bằng React/Vue/Angular thay cho app mẫu (xem `starter/README.md`).

## Yêu cầu
1. Trên máy build: `npm ci` rồi `npm run build`. Xem thư mục `dist/`: có những file gì, file nào có hash trong tên? Kích thước?
2. Chạy thử dev server (`npm run dev`) với proxy `/api` tới backend — giải thích vì sao dev server có proxy còn production thì cần Nginx.
3. Copy nội dung `dist/` lên vm2 tại `/var/www/frontend/` (dùng `rsync` hoặc `scp`), owner/quyền hợp lý.
4. Cấu hình Nginx site `fe.training.local`:
   - `root /var/www/frontend;`
   - SPA fallback: mọi đường dẫn không phải file thật trả về `index.html` (refresh `/about` không bị 404).
   - Request tới file tĩnh không tồn tại (VD `/assets/khong-co.js`) vẫn phải trả `404`, **không** trả `index.html`.
   - `location /api/` proxy tới backend module 04 (VD Flask `127.0.0.1:5000`).
5. Cache:
   - File trong `/assets/` (có hash): `Cache-Control: public, max-age=31536000, immutable`
   - `index.html`: `Cache-Control: no-cache`
6. Bật `gzip` cho JS, CSS, JSON, SVG. Kiểm tra bằng `curl -H 'Accept-Encoding: gzip' -I`. So sánh kích thước trước/sau nén.
7. Viết `deploy-fe.sh <dist-dir> <server>`: build (tùy chọn), đồng bộ file lên server, **không** làm hỏng người dùng đang mở trang trong lúc deploy (gợi ý: copy assets mới trước, `index.html` sau cùng; hoặc dùng thư mục release + symlink như module 04 lab-04).

## Kết quả cần nộp
`devops-training/06-frontend-static/lab-01-spa-build-and-serve/`:
- `NOTES.md`: các bước, cấu trúc `dist/`, output `curl -I` cho `index.html`, 1 file asset, `/about`, `/assets/khong-co.js`, kết quả gzip
- `fe.training.local.conf`, `deploy-fe.sh`
- Source FE nếu bạn tự tạo app (không commit `node_modules/`, `dist/`)

## Tiêu chí đạt
- [ ] `curl -I http://fe.training.local/about` trả `200` và nội dung là `index.html`
- [ ] `curl -I http://fe.training.local/assets/khong-co.js` trả `404`
- [ ] Asset có hash có header `immutable`, `index.html` có `no-cache`
- [ ] Response JS có `Content-Encoding: gzip` khi client hỗ trợ
- [ ] Trang chủ hiển thị bảng nhân viên lấy từ `/api/employees`
- [ ] Server không cài Node.js

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. `try_files $uri $uri/ /index.html;` hoạt động thế nào, từng bước?
2. Vì sao cần tách `location /assets/` để file không tồn tại trả 404 thay vì `index.html`?
3. `no-cache` khác `no-store` thế nào? Với `no-cache`, trình duyệt có tải lại toàn bộ `index.html` mỗi lần không (ETag/304)?
4. `npm ci` khác `npm install` thế nào? Vì sao CI/CD nên dùng `npm ci`?
5. Vì sao nên commit `package-lock.json`?
6. Nén gzip làm ở Nginx mỗi request có tốn CPU không? `gzip_static` giải quyết thế nào?

<details>
<summary>Gợi ý</summary>

- Nginx directive: `try_files`, `location ^~ /assets/`, `add_header`, `expires`, `gzip`, `gzip_types`, `gzip_min_length`.
- Lưu ý `add_header` trong `location` con sẽ **ghi đè toàn bộ** `add_header` của cấp cha.
- `rsync -avz --delete` có thể nguy hiểm với người dùng đang mở tab cũ — tại sao?

</details>

## Tài liệu tham khảo
- https://vite.dev/guide/build
- https://vite.dev/guide/static-deploy
- https://nginx.org/en/docs/http/ngx_http_gzip_module.html
- https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control
