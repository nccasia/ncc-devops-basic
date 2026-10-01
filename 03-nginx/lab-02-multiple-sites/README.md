# Lab 02 — Multiple Sites & Private DNS

> **Module:** 03 Nginx

## Mục tiêu
- Cấu hình nhiều website (virtual host) trên cùng một server dựa vào `server_name`.
- Hiểu cách Nginx chọn server block, vai trò `default_server`.
- Dựng private DNS nội bộ và cấu hình phân giải tên phía client.

## Kiến thức cần có
- Lab 01. DNS cơ bản: A record, resolver, `/etc/hosts`, `/etc/resolv.conf`, `systemd-resolved`.

## Môi trường
- vm2 (`192.168.56.12`): Nginx web server.
- vm1 (`192.168.56.11`) hoặc vm3: DNS server (dnsmasq hoặc bind9).
- vm3 (`192.168.56.13`) + máy host: client.

## Yêu cầu
1. Cấu hình 2 website khác nhau trên vm2:
   - `site1.local` → hiển thị **"Welcome to Site 1"**
   - `site2.local` → hiển thị **"Welcome to Site 2"**
   - Mỗi site có thư mục riêng (`/var/www/site1`, `/var/www/site2`), file config riêng, log riêng.
2. **Cách 1 — file hosts:** thêm bản ghi vào file hosts của client (máy host Windows/macOS và vm3) để truy cập được 2 site bằng trình duyệt/`curl`.
3. **Cách 2 — private DNS:** dựng DNS server nội bộ (dnsmasq hoặc bind9) phân giải `site1.local`, `site2.local` (và `*.local` nếu muốn) về `192.168.56.12`. Cấu hình vm3 dùng DNS server này (xóa bản ghi trong hosts đi để chứng minh DNS hoạt động).
4. Xử lý **Host lạ**: request tới IP trực tiếp hoặc với `Host` không khớp site nào phải nhận về `444` (đóng kết nối) hoặc một trang mặc định do bạn quyết định — không được rơi nhầm vào site1/site2.
5. Kiểm tra bằng `curl -H "Host: ..."` cho cả 3 trường hợp: site1, site2, host lạ.

## Kết quả cần nộp
`devops-training/03-nginx/lab-02-multiple-sites/`:
- `NOTES.md`: các bước, output `dig`/`nslookup`, output `curl` 3 trường hợp, ảnh chụp trình duyệt
- `site1.conf`, `site2.conf`, `default.conf`
- File cấu hình DNS (`dnsmasq.conf` hoặc zone file bind9)

## Tiêu chí đạt
- [ ] `curl http://site1.local` và `curl http://site2.local` từ vm3 trả đúng nội dung
- [ ] `dig site1.local @<dns-server-ip>` trả về `192.168.56.12`
- [ ] vm3 phân giải được tên mà **không** cần bản ghi trong `/etc/hosts`
- [ ] Host lạ / truy cập bằng IP không hiển thị nội dung site1 hoặc site2
- [ ] Chỉ có đúng 1 `default_server` cho mỗi `listen`

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. Thuật toán Nginx chọn server block: `listen` trước hay `server_name` trước? Nếu không khớp `server_name` nào thì sao?
2. Nếu không khai báo `default_server`, server block nào được dùng làm mặc định?
3. Thứ tự phân giải tên trên Linux: `/etc/hosts` hay DNS trước? Cấu hình ở file nào (`nsswitch.conf`)?
4. Vì sao dùng đuôi `.local` có thể gây xung đột (mDNS/Avahi)? Nên dùng đuôi nào cho môi trường nội bộ?
5. `systemd-resolved` và `/etc/resolv.conf` liên quan thế nào? Đổi DNS server đúng cách trên Ubuntu (netplan/resolvectl)?
6. `return 444` khác `return 404` thế nào?

<details>
<summary>Gợi ý</summary>

- dnsmasq: tìm hiểu option `address=/domain/ip`, `listen-address`, `no-resolv`, `server=`. Lưu ý dnsmasq có thể xung đột port 53 với `systemd-resolved`.
- bind9: cần `named.conf.local` khai báo zone và một zone file có SOA, NS, A record. Kiểm tra bằng `named-checkconf`, `named-checkzone`.
- File hosts trên Windows: `C:\Windows\System32\drivers\etc\hosts` (mở bằng quyền Administrator).
- `resolvectl status` để xem vm3 đang dùng DNS server nào.

</details>

## Tài liệu tham khảo
- https://nginx.org/en/docs/http/request_processing.html
- https://nginx.org/en/docs/http/server_names.html
- https://thekelleys.org.uk/dnsmasq/doc.html
- https://bind9.readthedocs.io/
