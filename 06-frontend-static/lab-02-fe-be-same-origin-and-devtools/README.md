# Lab 02 — FE/BE cùng origin, CORS & Chrome DevTools

> **Module:** 06 Frontend Static

## Mục tiêu
- Hiểu vì sao gom FE và BE về cùng một origin (`/` → FE, `/api/*` → BE) là kiến trúc đơn giản và an toàn.
- Tự tái hiện lỗi CORS và mixed content để hiểu bản chất.
- Thành thạo Chrome DevTools để đọc trạng thái request HTTP từ FE lên BE — kỹ năng bắt buộc trong [Capstone](../../09-capstone/README.md).

## Kiến thức cần có
- Lab 01 của module này, module 03 lab-04 (HTTPS self-signed), module 04 (backend).

## Môi trường
- vm2: Nginx + backend Flask (module 04 lab-01) + FE build từ lab 01.
- Trình duyệt Chrome/Edge trên máy host, đã trust CA nội bộ (module 03 lab-04).
- Domain: `app.training.local` (FE + BE cùng origin), `api.training.local` (BE riêng để thử khác origin).

## Yêu cầu

### Phần A — Cùng origin
1. Cấu hình `https://app.training.local`: `/` → FE (`/var/www/frontend`), `/api/` → backend. HTTP redirect sang HTTPS.
2. Mở trang bằng Chrome, mở DevTools (F12) → tab **Network**, bật **Preserve log** và **Disable cache**. Reload và chụp ảnh, giải thích cho request `/api/employees`:
   - Status code, Request URL, Remote Address
   - Request headers (`Host`, `Accept`, `Origin`/`Referer` có hay không, vì sao)
   - Response headers (`Content-Type`, `Cache-Control`, `Server`)
   - Tab **Timing**: DNS lookup, Initial connection, SSL, Waiting for server response (TTFB), Content download
3. Phân biệt trong Network các request: `document`, `script`, `stylesheet`, `fetch`. Lần reload thứ hai (tắt Disable cache) — request nào trả `304` hoặc `(memory cache)/(disk cache)`?

### Phần B — Khác origin & CORS
4. Cấu hình thêm `https://api.training.local` chỉ proxy tới backend.
5. Build lại FE với `VITE_API_BASE=https://api.training.local`, deploy, mở `https://app.training.local`. Chụp lỗi CORS trong **Console** và request tương ứng trong **Network**. Dùng `curl` gọi cùng URL đó — vì sao `curl` thành công?
6. Sửa bằng cách thêm header CORS ở Nginx của `api.training.local`, chỉ cho phép origin `https://app.training.local` (không dùng `*`).
7. Tạo một request kích hoạt **preflight** (VD từ Console: `fetch('https://api.training.local/api/employees', {headers: {'X-Debug': '1'}})`). Chụp request `OPTIONS` trong Network, giải thích các header `Access-Control-Request-*` và `Access-Control-Allow-*`. Cấu hình Nginx trả preflight đúng (`204`).

### Phần C — Chẩn đoán lỗi bằng DevTools
8. Tái hiện và chụp ảnh từng trường hợp, ghi rõ bạn nhìn thấy dấu hiệu ở đâu trong DevTools và nguyên nhân:
   | Trường hợp | Cách tái hiện |
   |-----------|---------------|
   | 404 | Gọi `/api/khong-ton-tai` |
   | 502 | Dừng service backend |
   | 503 | Tắt PostgreSQL trên vm1 (backend trả 503) |
   | 504 | Backend chậm hơn `proxy_read_timeout` (tự thêm endpoint chậm hoặc giảm timeout) |
   | Mixed content | Build FE với `VITE_API_BASE=http://api.training.local` |
   | CORS | Như bước 5 khi chưa sửa |
   | `(failed) net::ERR_CERT_AUTHORITY_INVALID` | Mở bằng trình duyệt/profile chưa trust CA |
9. Dùng **Copy as cURL** trên một request trong Network, chạy lại bằng terminal. Dùng tab **Application** xem có cookie/localStorage nào không.
10. Quay về cấu hình cùng origin (Phần A) và ghi kết luận: vì sao capstone yêu cầu dùng một endpoint cho cả FE và BE.

## Kết quả cần nộp
`devops-training/06-frontend-static/lab-02-fe-be-same-origin-and-devtools/`:
- `NOTES.md`: giải thích từng ảnh chụp theo yêu cầu, bảng chẩn đoán ở bước 8, kết luận bước 10
- `screenshots/` (ảnh PNG, đặt tên theo bước, VD `08-502.png`)
- `app.training.local.conf`, `api.training.local.conf`

## Tiêu chí đạt
- [ ] Giải thích đúng các mốc trong tab Timing của request `/api/employees`
- [ ] Tái hiện được lỗi CORS và sửa bằng header chỉ cho phép đúng origin
- [ ] Bắt được request preflight `OPTIONS` và trả `204` với header phù hợp
- [ ] Đủ 7 trường hợp ở bước 8, mỗi trường hợp chỉ ra đúng dấu hiệu trong DevTools
- [ ] Cấu hình cuối cùng: một origin cho FE + BE, HTTPS

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. Origin gồm những thành phần nào? `https://app.training.local` và `https://app.training.local:8443` có cùng origin không?
2. CORS bảo vệ ai — server hay người dùng? Vì sao CORS không phải cơ chế xác thực API?
3. Vì sao `Access-Control-Allow-Origin: *` không dùng được cùng `credentials: 'include'`?
4. Request nào là "simple request" không cần preflight?
5. Trong Network, request bị CORS chặn có tới được backend không? Kiểm chứng bằng access log của Nginx/backend.
6. Status `(failed)`, `(canceled)`, `(blocked:mixed-content)` trong DevTools khác gì một response `4xx/5xx` thật?
7. TTFB cao thì nghi ngờ phía nào? Content download lâu thì nghi ngờ gì?

<details>
<summary>Gợi ý</summary>

- Header CORS cần tìm hiểu: `Access-Control-Allow-Origin`, `Access-Control-Allow-Methods`, `Access-Control-Allow-Headers`, `Access-Control-Max-Age`, `Vary: Origin`.
- Trong Nginx, xử lý preflight thường dùng `if ($request_method = OPTIONS) { return 204; }` kèm `add_header ... always`. Tìm hiểu vì sao cần `always`.
- Network tab: chuột phải vào tiêu đề cột để hiện thêm cột (Protocol, Remote Address).
- Bộ lọc `Fetch/XHR` giúp chỉ xem request API.

</details>

## Tài liệu tham khảo
- https://developer.chrome.com/docs/devtools/network
- https://developer.chrome.com/docs/devtools/network/reference
- https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
- https://developer.mozilla.org/en-US/docs/Web/Security/Mixed_content
- https://web.dev/articles/ttfb
