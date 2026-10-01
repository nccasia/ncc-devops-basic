# 06 — Deploy Frontend với Static File

> **Môi trường:** vm2 (192.168.56.12): Nginx + backend từ module 04; máy build: máy cá nhân hoặc vm2 (Node.js LTS)

## Mục tiêu

- Hiểu frontend hiện đại (React, Vue, Angular) sau khi build chỉ là **file tĩnh** (HTML, JS, CSS, ảnh).
- Build và serve SPA bằng Nginx, xử lý đúng client-side routing.
- Cấu hình cache và nén phù hợp cho từng loại file.
- Gom FE và BE về cùng origin, hiểu CORS, và dùng **Chrome DevTools** để chẩn đoán request từ FE lên BE.

## Lý thuyết cần tự học

- Node.js, npm: `package.json`, `package-lock.json`, `npm ci` vs `npm install`, `npm run build`
- Bundler (Vite, webpack): output `dist/`, file có hash trong tên (`index-a1b2c3.js`)
- SPA vs MPA, client-side routing (History API), vì sao refresh trang con bị 404
- Biến môi trường lúc build (`VITE_*`, `REACT_APP_*`) vs lúc chạy — FE build xong không đọc được env của server
- HTTP caching: `Cache-Control`, `ETag`, `Last-Modified`, `immutable`; nén `gzip`/`brotli`
- Same-origin policy, CORS (simple request, preflight `OPTIONS`), mixed content
- Chrome DevTools: Network, Console, Application, Security

Tài liệu: https://vite.dev/guide/static-deploy · https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching · https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS · https://developer.chrome.com/docs/devtools/network

## Danh sách lab

| Lab | Nội dung | Bắt buộc |
|-----|----------|----------|
| [lab-01-spa-build-and-serve](lab-01-spa-build-and-serve/README.md) | Build SPA, serve bằng Nginx, SPA fallback, cache, gzip | ✅ |
| [lab-02-fe-be-same-origin-and-devtools](lab-02-fe-be-same-origin-and-devtools/README.md) | FE gọi `/api` cùng origin, tái hiện CORS, chẩn đoán bằng DevTools | ✅ |

## Câu hỏi tự kiểm tra cuối module

Tự trả lời các câu dưới đây vào `devops-training/06-frontend-static/module-questions.md` sau khi xong các lab.

1. Vì sao server production không cần cài Node.js để chạy một app React/Vue đã build?
2. Vì sao truy cập trực tiếp `https://app/employees` (trang con của SPA) bị 404 nếu chỉ cấu hình `root`? Sửa thế nào?
3. Vì sao file JS/CSS có hash được cache rất lâu còn `index.html` thì không? Chuyện gì xảy ra nếu cache `index.html` 1 năm?
4. Biến `VITE_API_URL` được "đóng băng" vào bundle lúc nào? Muốn một bản build chạy được ở nhiều môi trường thì làm sao?
5. CORS do trình duyệt hay server chặn? Vì sao `curl` gọi được API mà trình duyệt thì báo lỗi CORS?
6. Khi nào trình duyệt gửi preflight `OPTIONS`?
7. Mixed content là gì? Vì sao trang HTTPS gọi API HTTP bị chặn?

## Bài tự luyện debug (break & fix)

Tự làm hỏng từng điểm, quan sát bằng trình duyệt + DevTools, chẩn đoán và sửa. Ghi vào `devops-training/06-frontend-static/break-and-fix.md` theo bảng: **Kịch bản → Triệu chứng (ảnh DevTools) → Cách chẩn đoán → Nguyên nhân → Cách sửa**.

- Bỏ `try_files ... /index.html` rồi refresh một trang con.
- Đặt `Cache-Control: max-age=31536000` cho `index.html`, build lại bản mới, deploy — người dùng có thấy bản mới không?
- Deploy bản build mới nhưng xóa thư mục `assets/` cũ trong lúc tab cũ vẫn mở rồi điều hướng trong app.
- Build FE với API URL trỏ sang `http://` trong khi trang chạy `https://`.
- Dừng backend — FE hiển thị gì? DevTools hiển thị status gì?
- Đặt `root` sai thư mục build (VD trỏ vào thư mục source thay vì `dist/`).
