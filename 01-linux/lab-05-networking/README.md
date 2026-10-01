# Lab 05 — Network cơ bản & troubleshoot theo lớp

> **Module:** 01 Linux

## Mục tiêu
- Đọc được cấu hình mạng của máy: IP, subnet, gateway, route, DNS.
- Biết service đang lắng nghe ở đâu (port, địa chỉ bind), ai đang kết nối.
- Mở/đóng port bằng `ufw`.
- Troubleshoot "không kết nối được tới service" có phương pháp: đi từ dưới lên từng lớp.

## Kiến thức cần có
- Mô hình TCP/IP, IP/subnet/CIDR, TCP vs UDP, port, DNS.
- `ip`, `ss`, `ping`, `traceroute`, `dig`/`nslookup`, `curl`, `nc`, `ufw`, `tcpdump` (cơ bản).
- Đọc: [90DaysOfDevOps — Understand networking](https://github.com/MichaelCade/90DaysOfDevOps/blob/main/2022.md#understand-networking)

## Môi trường
- vm1 (192.168.56.11) làm server, vm2 (192.168.56.12) làm client — xem [lab-env](../../lab-env/README.md).

## Yêu cầu

### Phần 1 — Khảo sát mạng (trên vm1)
1. Liệt kê các interface, IP, subnet mask (dạng CIDR) và MAC. Interface nào là NAT, interface nào là private network?
2. Xem bảng route: default gateway là gì? Gói tin tới `192.168.56.12` và tới `8.8.8.8` đi qua interface nào? (gợi ý `ip route get`)
3. DNS server máy đang dùng là gì? Giải thích vai trò `systemd-resolved` và `127.0.0.53`.
4. Liệt kê các port đang LISTEN kèm process. Phân biệt service bind `0.0.0.0`, `127.0.0.1`, `[::]`.

### Phần 2 — DNS & /etc/hosts
5. Dùng `dig` tra bản ghi `A`, `AAAA`, `MX`, `NS`, `CNAME` của một domain public (VD `github.com`, `gmail.com`). Dùng `dig +trace` để thấy quá trình resolve từ root.
6. Trên vm2, thêm `app.lab.local` trỏ về vm1 bằng `/etc/hosts`. Giải thích vì sao `ping app.lab.local` chạy được nhưng `dig app.lab.local` lại không ra kết quả. File nào quyết định thứ tự tra cứu (`/etc/nsswitch.conf`)?

### Phần 3 — Service & port
7. Trên vm1, chạy một HTTP server tạm thời ở port 8080:
   ```bash
   mkdir -p ~/www && echo "hello from vm1" > ~/www/index.html
   cd ~/www && python3 -m http.server 8080 --bind 127.0.0.1
   ```
   Từ vm2 `curl http://vm1:8080` → ghi lại lỗi. Sửa để vm2 truy cập được. Giải thích.
8. Bật `ufw` trên vm1 (**nhớ allow SSH trước** — giải thích vì sao). Chỉ cho phép vm2 truy cập port 8080, chặn mọi IP khác. Kiểm tra từ vm2 (được) và vm3 (không được).
9. Dùng `tcpdump -i <iface> port 8080` trên vm1 quan sát 3-way handshake khi vm2 gọi `curl`. Chụp/dán output, chỉ ra SYN, SYN-ACK, ACK.

### Phần 4 — Troubleshoot theo lớp
10. Viết `net-check.sh <host> <port>`: kiểm tra lần lượt và in PASS/FAIL từng bước, dừng ở bước đầu tiên lỗi kèm gợi ý nguyên nhân:
    1. Resolve DNS / hosts (`getent hosts`)
    2. Có route tới host không (`ip route get`)
    3. Ping (ICMP — lưu ý có thể bị chặn nhưng service vẫn chạy)
    4. TCP port mở không (`nc -zv -w 3` hoặc `/dev/tcp`) — phân biệt **refused** và **timeout**
    5. Nếu port 80/443/8080: gọi HTTP và in status code (`curl -s -o /dev/null -w '%{http_code}'`)
11. Tái hiện và ghi lại output `net-check.sh` cho 4 tình huống, giải thích mỗi lỗi ở lớp nào:
    - Sai tên host (không resolve được)
    - Service không chạy (`Connection refused`)
    - Service chỉ bind `127.0.0.1`
    - Bị `ufw` chặn (`timeout`)

## Kết quả cần nộp
`devops-training/01-linux/lab-05-networking/`:
- `NOTES.md`: trả lời Phần 1–3 kèm output lệnh, output `tcpdump`, bảng 4 tình huống Phần 4.
- `net-check.sh`
- `ufw-rules.txt`: output `sudo ufw status numbered`.

## Tiêu chí đạt
- [ ] Giải thích đúng IP/CIDR/gateway/route/DNS của vm1
- [ ] vm2 truy cập được `vm1:8080`, vm3 bị chặn
- [ ] SSH vẫn hoạt động sau khi bật ufw
- [ ] `net-check.sh` phân biệt đúng 4 tình huống lỗi
- [ ] Chỉ ra được 3-way handshake trong output tcpdump

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. `192.168.56.0/24` có bao nhiêu địa chỉ dùng được? `/24` và `255.255.255.0` liên quan thế nào?
2. `Connection refused` và `Connection timed out` khác nhau ở mức gói tin như thế nào (RST vs không phản hồi)? Mỗi cái thường do nguyên nhân gì?
3. Service bind `127.0.0.1` khác `0.0.0.0` thế nào? Vì sao nhiều service (DB, Redis) mặc định bind localhost?
4. Ping không được có nghĩa là service chết không? Vì sao?
5. Thứ tự tra cứu tên miền trên Linux? `/etc/hosts` có tác dụng với `dig` không?
6. `ufw deny` khác `ufw reject`? Ảnh hưởng gì tới lỗi phía client?
7. Port < 1024 có gì đặc biệt? Vì sao app thường chạy port 3000/8080 và đứng sau Nginx port 80?
8. Mô tả những gì xảy ra khi gõ `curl http://app.lab.local:8080` — từ resolve tên đến khi nhận response.

<details>
<summary>Gợi ý</summary>

- `ss -tlnp` (TCP, listen, numeric, process). `ss -tnp` để xem kết nối đang mở.
- Khi chơi với `ufw`, mở sẵn một phiên SSH thứ hai để không tự khóa mình. Với Vagrant còn có thể vào bằng console VirtualBox.
- `ufw allow from <ip> to any port <port> proto tcp`.
- Trong Bash: `timeout 3 bash -c "</dev/tcp/$host/$port"` — xem exit code và stderr để phân biệt refused/timeout.

</details>

## Tài liệu tham khảo
- https://github.com/MichaelCade/90DaysOfDevOps/blob/main/2022.md#understand-networking
- https://help.ubuntu.com/community/UFW
- `man ip`, `man ss`, `man dig`, `man tcpdump`
