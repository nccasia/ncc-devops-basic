# Chrome DevTools — Hướng dẫn & checklist kiểm tra request FE → BE

DevOps cần đọc được DevTools để phân biệt nhanh lỗi nằm ở **trình duyệt / FE**, **Nginx**, **BE** hay **DB** — trước khi đi đọc log server.

Mở DevTools: `F12` hoặc `Ctrl+Shift+I` (macOS: `Cmd+Opt+I`).

## 1. Tab Network

### Thiết lập trước khi quan sát
- [ ] Bật **Preserve log** (giữ request khi trang reload/redirect)
- [ ] Bật **Disable cache** khi cần loại trừ cache
- [ ] Lọc **Fetch/XHR** để chỉ xem request API; lọc `Doc` để xem request HTML ban đầu
- [ ] Hiển thị thêm cột: *Protocol*, *Remote Address*, *Method* (chuột phải vào header bảng)

### Đọc một request
Click vào request `/api/employees`, kiểm tra:

| Tab con | Cần đọc được |
|---------|--------------|
| **Headers → General** | Request URL, Method, Status Code, Remote Address (IP:port Nginx), Referrer Policy |
| **Headers → Response Headers** | `Server`, `Content-Type`, `Cache-Control`, `Strict-Transport-Security`, `X-Content-Type-Options`, `X-Frame-Options`, `Set-Cookie`, header CORS (nếu có) |
| **Headers → Request Headers** | `Host`, `Origin`, `Authorization`/`Cookie`, `Content-Type`, `Accept` |
| **Payload** | Body JSON gửi đi (POST/PUT), query string |
| **Preview / Response** | Dữ liệu BE trả về; trang lỗi HTML của Nginx hay JSON lỗi của BE |
| **Timing** | Queueing, DNS Lookup, Initial connection, **SSL**, **Waiting (TTFB)**, Content Download |
| **Initiator** | Đoạn code JS nào phát ra request |

### Checklist
- [ ] Chỉ ra request FE → BE đi qua cùng domain `https://capstone.<tên>.local/api/...`
- [ ] Giải thích status code của request thành công (200/201/204)
- [ ] Phân biệt response do **Nginx** trả (trang HTML lỗi, header `Server: nginx`) và response do **BE** trả (JSON)
- [ ] Đọc Timing: TTFB lớn → chậm ở BE/DB; SSL/Initial connection lớn → mạng/TLS
- [ ] **Preflight**: biết khi nào trình duyệt gửi `OPTIONS` trước request thật; chứng minh hệ thống 1 endpoint không phát sinh preflight
- [ ] **Cache**: nhận biết `(memory cache)`, `(disk cache)`, `304 Not Modified`; giải thích header `Cache-Control` cho file `index.html` (không cache lâu) và file JS/CSS có hash (cache lâu)
- [ ] Dùng **Copy → Copy as cURL** để tái hiện request bằng terminal
- [ ] Xem redirect HTTP → HTTPS (status 301/308, header `Location`)

## 2. Tab Security (hoặc click biểu tượng ổ khóa → Certificate)
- [ ] Xem certificate: Subject, Issuer, **SAN**, ngày hết hạn
- [ ] Phiên bản TLS và cipher đang dùng
- [ ] Giải thích vì sao trình duyệt đánh dấu "Not secure" với self-signed cert, và khác biệt khi đã import CA nội bộ vào trust store

## 3. Tab Console
- [ ] Đọc lỗi JS, lỗi CORS, lỗi mixed content, lỗi request thất bại (`net::ERR_...`)
- [ ] Phân biệt lỗi do code FE (exception JS) và lỗi do mạng/server

## 4. Tình huống lỗi cần nhận diện

Với mỗi tình huống: **tự tái hiện** trên hệ thống của bạn, chụp màn hình DevTools, ghi vào `docs/devtools-report.md`: *triệu chứng trên DevTools → nguyên nhân → nơi kiểm tra tiếp (log nào) → cách sửa*.

| Tình huống | Cách tái hiện gợi ý | Dấu hiệu trên DevTools | Kiểm tra tiếp |
|------------|--------------------|------------------------|---------------|
| **401 Unauthorized** | Gọi API cần auth không gửi token/token sai | Status 401, có thể có header `WWW-Authenticate` | Logic auth BE, header `Authorization` có được Nginx chuyển tiếp không |
| **403 Forbidden** | Sai quyền thư mục FE (`chmod 700`) hoặc `deny` trong Nginx | 403, trang lỗi HTML của Nginx | `error.log` Nginx: `permission denied`; quyền thư mục, user chạy Nginx |
| **404 Not Found** | Sai `proxy_pass` (thiếu/thừa `/`), sai path API, thiếu SPA fallback khi F5 ở route con | 404 — xem do Nginx (HTML) hay BE (JSON) | `access.log` Nginx, route BE, `try_files` |
| **502 Bad Gateway** | Dừng BE (`systemctl stop` / `docker compose stop backend`) | 502, `Server: nginx` | `error.log`: `connect() failed (111: Connection refused)`; trạng thái service BE |
| **504 Gateway Timeout** | BE xử lý chậm (sleep) vượt `proxy_read_timeout`, hoặc DB treo | 504 sau đúng ~thời gian timeout, Timing có Waiting rất dài | `error.log`: `upstream timed out`; log BE, kết nối DB |
| **CORS error** | FE gọi BE bằng URL tuyệt đối khác origin (VD `http://IP:8080/api`) | Console: `blocked by CORS policy`; request `OPTIONS` preflight | Vì sao khác origin; sửa về đường dẫn tương đối `/api` thay vì bật `*` |
| **Mixed content** | Trang HTTPS gọi API `http://...` | Console: `Mixed Content: ... was loaded over HTTPS, but requested an insecure resource`; request bị `(blocked:mixed-content)` | Base URL API trong build FE |
| **Cert không tin cậy** | Truy cập khi chưa import CA, sai SAN, cert hết hạn | Trang cảnh báo `NET::ERR_CERT_AUTHORITY_INVALID` / `ERR_CERT_COMMON_NAME_INVALID` / `ERR_CERT_DATE_INVALID` | Tab Security, `openssl s_client -connect host:443 -servername host` |
| ⭐ **ERR_CONNECTION_REFUSED / TIMED_OUT** | Firewall chặn 443 hoặc Nginx dừng | Request thất bại, không có status code | `ufw status`, `ss -tlnp`, `systemctl status nginx` |
| ⭐ **413 Request Entity Too Large** | Upload file lớn hơn `client_max_body_size` | 413 do Nginx trả | Cấu hình `client_max_body_size` |

## 5. Kết quả cần nộp
`docs/devtools-report.md` trong repo capstone:
- [ ] Ảnh chụp + giải thích 1 request thành công (Headers, Payload, Response, Timing)
- [ ] Ảnh chụp tab Security với thông tin certificate
- [ ] Ít nhất **4 tình huống lỗi** trong bảng trên (bắt buộc có 502 và CORS hoặc mixed content), mỗi tình huống đủ 4 ý: triệu chứng → nguyên nhân → log kiểm tra → cách sửa

## Tài liệu tham khảo
- https://developer.chrome.com/docs/devtools/network
- https://developer.chrome.com/docs/devtools/network/reference
- https://developer.chrome.com/docs/devtools/security
- https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
- https://developer.mozilla.org/en-US/docs/Web/Security/Mixed_content
- https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
