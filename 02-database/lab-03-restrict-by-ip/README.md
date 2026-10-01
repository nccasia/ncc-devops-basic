# Lab 03 — Giới hạn kết nối theo máy (IP) (Yêu cầu 2)

> **Module:** 02 Database

## Mục tiêu
- Giới hạn truy cập database theo IP nguồn ở **hai lớp**: lớp ứng dụng (`pg_hba.conf`) và lớp mạng (firewall/security group).
- Phân biệt được mỗi lớp chặn ở đâu, thông báo lỗi phía client khác nhau ra sao.
- Áp dụng nguyên tắc *defense in depth*.

## Kiến thức cần có
- Hoàn thành [lab-02](../lab-02-readonly-remote-access/README.md).
- `pg_hba.conf` (thứ tự dòng, CIDR), `ufw` (xem [01-linux/lab-05](../../01-linux/lab-05-networking/README.md)).

## Môi trường
- VM1 (192.168.56.11): PostgreSQL Server
- VM2 (192.168.56.12): client **được phép**
- VM3 (192.168.56.13): client **bị chặn**

## Yêu cầu

### Yêu cầu 2 — Giới hạn kết nối theo máy (IP)

1. Trên VM1, tạo user `usertest2` với quyền **read-only** trên database `trainingdb` (tái sử dụng cách làm ở lab-02).
2. Cấu hình PostgreSQL và hệ thống mạng (VD: `pg_hba.conf`, firewall, security group, …) để:
   - **Chỉ cho phép VM2** được kết nối đến database trên VM1 bằng user `usertest2`.
3. Kiểm tra:
   - Từ VM2: kết nối thành công và SELECT được dữ liệu bằng `usertest2`.
   - Từ VM3: **không thể** kết nối đến database trên VM1 bằng `usertest2`.

### Làm rõ yêu cầu — thực hiện theo 2 giai đoạn

**Giai đoạn A — chỉ dùng `pg_hba.conf`:**
- Viết dòng `pg_hba.conf` cho `usertest2` chỉ chấp nhận từ `192.168.56.12/32`.
- Đảm bảo không có dòng nào khác (rộng hơn, đứng trước) vô tình cho phép usertest2 từ vm3. Nếu lab-02 đã mở `192.168.56.0/24` cho `all` user thì phải sửa.
- Chạy `check.sh` từ vm2 và vm3, ghi lại **thông báo lỗi phía vm3**.
- Trả lời: lúc này từ vm3 `nc -zv 192.168.56.11 5432` có thành công không? Vì sao? Điều đó nói lên rủi ro gì?

**Giai đoạn B — thêm firewall (`ufw`) trên vm1:**
- Bật `ufw` (giữ SSH!). Port `5432` chỉ cho phép từ `192.168.56.12`.
- Chạy lại `check.sh` từ vm2 và vm3, so sánh thông báo lỗi phía vm3 với giai đoạn A.
- Trả lời: lúc này `usertest1` (lab-02) từ vm3 còn kết nối được không? Nếu yêu cầu là "vm3 vẫn dùng được usertest1 nhưng không dùng được usertest2" thì giải pháp nào đáp ứng — firewall hay `pg_hba.conf`? Vì sao?

**Nếu dùng VM cloud:** thực hiện thêm ở Security Group/Firewall rule của cloud thay cho/bổ sung `ufw`, chụp cấu hình rule.

4. Trong `NOTES.md`, lập bảng so sánh:

| | `pg_hba.conf` | Firewall (`ufw`/SG) |
|---|---|---|
| Chặn ở lớp nào | | |
| Lọc theo được user/database không | | |
| Lỗi phía client khi bị chặn | | |
| Server có ghi log không | | |
| Có cần reload/restart PostgreSQL | | |

### Ghi chú MySQL
- Giới hạn theo host nằm ngay trong account: `CREATE USER 'usertest2'@'192.168.56.12' ...`. Từ vm3 sẽ nhận `Access denied` hoặc `Host '...' is not allowed to connect`.
- Phần firewall làm giống hệt với port `3306`.

## Script kiểm tra

[`check.sh`](check.sh) chạy trên **vm2 và vm3**:

```bash
cd /repo/02-database/lab-03-restrict-by-ip   # the repo is mounted at /repo when using Vagrant
export PGPASSWORD='<password usertest2>'   # never hardcode the password in the script
./check.sh                                 # defaults: host 192.168.56.11, user usertest2, db trainingdb
./check.sh -h 192.168.56.11 -U usertest2 -d trainingdb
```

Script tự nhận biết đang chạy trên máy nào (theo IP) và kiểm tra kỳ vọng tương ứng: vm2 phải SELECT được, vm3 phải bị chặn. Đồng thời in ra lớp nào đang chặn (network hay `pg_hba.conf`).

## Kết quả cần nộp
`devops-training/02-database/lab-03-restrict-by-ip/`:
- `usertest2.sql`
- `pg_hba.conf` (chỉ các dòng không phải comment: `grep -vE '^\s*(#|$)'`)
- `ufw-rules.txt`: output `sudo ufw status numbered`
- `NOTES.md`: output `check.sh` từ vm2 và vm3 ở cả 2 giai đoạn, bảng so sánh, trả lời câu hỏi trong từng giai đoạn, đoạn log PostgreSQL khi vm3 bị từ chối.

## Tiêu chí đạt
- [ ] Từ vm2: `check.sh` PASS (kết nối + SELECT được)
- [ ] Từ vm3: `check.sh` PASS (bị chặn) ở cả giai đoạn A và B
- [ ] `pg_hba.conf` dùng `/32` cho vm2, không có dòng rộng hơn cho usertest2
- [ ] Firewall chỉ mở 5432 cho vm2, SSH vẫn dùng được
- [ ] Giải thích đúng khác biệt lỗi "pg_hba rejects" và "timeout"

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. `pg_hba.conf` được đánh giá theo thứ tự nào? Điều gì xảy ra nếu một dòng `host all all 192.168.56.0/24 scram-sha-256` đứng **trước** dòng dành cho usertest2?
2. `/32`, `/24`, `0.0.0.0/0` nghĩa là gì trong cột ADDRESS?
3. Vì sao chỉ dùng `pg_hba.conf` vẫn chưa đủ an toàn? Port mở công khai có rủi ro gì dù không đăng nhập được?
4. Vì sao chỉ dùng firewall cũng chưa đủ? (gợi ý: nhiều app/user cùng nằm trên vm2, IP spoofing trong cùng mạng, firewall bị tắt nhầm…)
5. Client nhận `timeout`, `Connection refused`, `no pg_hba.conf entry`, `password authentication failed` — mỗi cái nói lên điều gì và cần kiểm tra chỗ nào?
6. Khi app chạy trong Docker/Kubernetes, IP nguồn kết nối tới DB có còn là IP của máy host không? Ảnh hưởng gì tới `pg_hba.conf`?
7. Sửa `pg_hba.conf` xong cần làm gì để có hiệu lực? Kết nối đang mở có bị ngắt không?

<details>
<summary>Gợi ý</summary>

- Xem các dòng `pg_hba.conf` server đang thực sự dùng: `SELECT * FROM pg_hba_file_rules;` — có cả cột `error` nếu dòng nào sai cú pháp.
- `ufw` xử lý rule theo thứ tự — `ufw status numbered` để xem, `ufw insert` để chèn lên trước.
- Theo dõi log server khi thử từ vm3: `sudo tail -f /var/log/postgresql/postgresql-*-main.log`.

</details>

## Tài liệu tham khảo
- https://www.postgresql.org/docs/current/auth-pg-hba-conf.html
- https://www.postgresql.org/docs/current/view-pg-hba-file-rules.html
- https://help.ubuntu.com/community/UFW
