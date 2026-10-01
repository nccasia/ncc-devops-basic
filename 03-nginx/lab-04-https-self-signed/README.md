# Lab 04 — HTTPS với Self-signed CA & một endpoint cho FE + BE

> **Module:** 03 Nginx

## Mục tiêu
- Hiểu PKI cơ bản: CA, certificate, private key, CSR, chain, SAN.
- Tự tạo CA nội bộ và ký certificate cho domain.
- Cấu hình HTTPS trên Nginx, redirect HTTP → HTTPS, giới hạn TLS 1.2/1.3.
- Gom FE và BE về **một domain**: `/api/*` → backend, `/*` → static FE. Đây là kiến trúc dùng lại trong [Capstone](../../09-capstone/README.md).

## Kiến thức cần có
- Lab 01–03. Khái niệm mã hóa bất đối xứng, TLS handshake.

## Môi trường
- vm2 (`192.168.56.12`): Nginx + backend (dùng lại `../lab-03-reverse-proxy/starter/app.py` trên port 3000).
- Client: vm3 + máy host. Domain: `app.training.local` (thêm vào DNS/hosts như lab 02).

## Yêu cầu
1. **Tạo CA nội bộ** bằng `openssl`: private key CA (bảo vệ bằng quyền `600`) + certificate CA (hiệu lực 5 năm).
2. **Tạo certificate cho server**: private key + CSR cho `app.training.local`, ký bằng CA. Certificate phải có **SAN** chứa `app.training.local` (và `192.168.56.12` dạng IP SAN). Hiệu lực ≤ 397 ngày.
3. Cấu hình Nginx:
   - `listen 443 ssl` (bật `http2`), dùng cert/key vừa tạo.
   - Chỉ cho phép `TLSv1.2` và `TLSv1.3`.
   - Port 80 redirect `301` sang HTTPS.
   - `location /api/` → proxy tới backend `127.0.0.1:3000`. Backend nhận được path thế nào (`/api/headers` hay `/headers`)? Chọn một cách, giải thích và làm cho `https://app.training.local/api/headers` hoạt động.
   - `location /` → serve static FE từ `/var/www/app` (một trang HTML gọi `fetch('/api/headers')` và hiển thị kết quả).
   - Header bảo mật: `Strict-Transport-Security` (giá trị nhỏ khi thử nghiệm), `X-Content-Type-Options`.
4. **Trust CA trên client**: import cert CA vào trust store của vm3 (`update-ca-certificates`) và trình duyệt/OS máy host. Sau đó `curl https://app.training.local` không cần `-k` và trình duyệt hiển thị ổ khóa hợp lệ.
5. Kiểm tra TLS bằng `openssl s_client -connect app.training.local:443 -servername app.training.local` và chứng minh TLS 1.1 bị từ chối.
6. Viết script `gen-cert.sh <domain>` tự động hóa bước 2 (dùng lại CA có sẵn).

## Kết quả cần nộp
`devops-training/03-nginx/lab-04-https-self-signed/`:
- `NOTES.md`: các bước, output `openssl x509 -in server.crt -noout -text` (phần SAN, issuer, validity), output `openssl s_client`, `curl -I http://...` (thấy 301), ảnh trình duyệt có ổ khóa và DevTools tab Security
- `gen-cert.sh`, `app.training.local.conf`, file `openssl.cnf`/extension file nếu có
- `ca.crt` (**chỉ** certificate công khai — **TUYỆT ĐỐI không** nộp `*.key`)

## Tiêu chí đạt
- [ ] `curl https://app.training.local/` từ vm3 thành công **không cần** `-k`
- [ ] `curl -I http://app.training.local/` trả `301` về `https://`
- [ ] `https://app.training.local/api/headers` trả JSON từ backend, `X-Forwarded-Proto: https`
- [ ] Trang FE gọi được `/api/...` cùng origin (không lỗi CORS, không mixed content)
- [ ] `openssl s_client -tls1_1 ...` bị từ chối
- [ ] Không có private key trong repo; key trên server có quyền `600`/`640` và owner hợp lý

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. Trình bày các bước TLS 1.2 handshake. TLS 1.3 khác gì?
2. Vì sao trình duyệt hiện đại bỏ qua `CN` mà chỉ kiểm tra `SAN`?
3. Certificate chain là gì? Khi nào cần gộp intermediate vào file cert gửi cho client?
4. Self-signed certificate khác certificate ký bởi CA nội bộ thế nào? Vì sao dựng CA nội bộ tiện hơn khi có nhiều domain?
5. HSTS hoạt động thế nào? Rủi ro khi đặt `max-age` lớn trong lúc thử nghiệm?
6. Vì sao gom FE và BE về cùng một domain lại tránh được CORS?
7. Nếu lộ private key của CA thì hậu quả là gì và xử lý thế nào?

<details>
<summary>Gợi ý</summary>

- SAN cần khai báo qua extension file (`subjectAltName = DNS:app.training.local, IP:192.168.56.12`) khi ký bằng `openssl x509 -req ... -extfile`.
- Certificate CA cần `basicConstraints = critical, CA:TRUE`.
- Ubuntu: copy `ca.crt` vào `/usr/local/share/ca-certificates/` rồi `update-ca-certificates`.
- Chrome trên Windows dùng trust store của Windows (`certmgr.msc` → Trusted Root Certification Authorities). Firefox có trust store riêng.
- Directive: `ssl_certificate`, `ssl_certificate_key`, `ssl_protocols`, `return 301 https://$host$request_uri;`.
- Tham khảo cấu hình: https://ssl-config.mozilla.org/

</details>

## Tài liệu tham khảo
- https://nginx.org/en/docs/http/configuring_https_servers.html
- https://www.openssl.org/docs/manmaster/man1/openssl-x509.html
- https://ssl-config.mozilla.org/
- https://tls13.xargs.org/ (minh họa từng byte TLS 1.3 handshake)
