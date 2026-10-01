# Lab 04 — Bash Script (BT1–BT6)

> **Module:** 01 Linux

## Mục tiêu
- Viết Bash script có cấu trúc: nhận tham số, kiểm tra input, xử lý lỗi, trả exit code đúng.
- Xử lý file, text, ngày giờ; ghi log; tự động hóa tác vụ quản trị (tạo user, backup, monitor).
- Chạy script định kỳ bằng `cron`.

## Kiến thức cần có
- Biến, tham số `$0 $1 $# $@ $?`, `read`, `if/case/for/while`, function, `exit`.
- Redirect `> >> 2> 2>&1`, pipe, `tee`, here-doc.
- `find`, `stat`, `du`, `awk`, `sort`, `date`, `tar`, `crontab`.

## Môi trường
- vm1. BT4 cần `sudo`. BT5 cần một cách gửi thông báo (xem BT5).

## Quy định chung cho mọi bài

- Dòng đầu `#!/usr/bin/env bash`, bật `set -euo pipefail` (hoặc giải thích vì sao không dùng).
- Có hàm `usage()` in hướng dẫn khi gọi sai hoặc với `-h`/`--help`.
- Thông báo lỗi in ra **stderr**, exit code ≠ 0 khi lỗi.
- Biến luôn được quote (`"$var"`), không parse `ls`.
- Chạy `shellcheck` sạch cảnh báo (`sudo apt install shellcheck`).
- File dùng LF line ending (không CRLF), có quyền thực thi.

---

## BT1 — Lời chào (`bt1-greeting.sh`)

Yêu cầu:
- Viết script nhận tên người dùng và in ra lời chào.
- Lưu output ra file.
- Xử lý trường hợp không có input.

Chi tiết:
- Nhận tên qua tham số `$1`. Nếu không có tham số → hỏi bằng `read`. Nếu vẫn rỗng (hoặc chỉ toàn khoảng trắng) → báo lỗi, exit 1.
- Lời chào kèm thời gian. Vừa in ra màn hình vừa **append** vào `greeting.log` (đường dẫn file có thể đổi bằng option `-o <file>`).

```text
$ ./bt1-greeting.sh Quang
Hello, Quang! It is 09:15:02 on 2026-10-01.
$ ./bt1-greeting.sh
Enter your name:
Error: name must not be empty
$ echo $?
1
$ cat greeting.log
[2026-10-01 09:15:02] Hello, Quang! ...
```

Tiêu chí: ☐ có tham số ☐ không tham số → hỏi ☐ rỗng → exit 1 ☐ ghi file đúng (append, không ghi đè) ☐ tên có dấu cách (`"Nguyen Van A"`) vẫn đúng.

---

## BT2 — Máy tính (`bt2-calc.sh`)

Yêu cầu:
- Nhận 2 số từ tham số dòng lệnh.
- Thực hiện các phép tính `+`, `-`, `*`, `/`.
- Kiểm tra input có phải là số không.
- In kết quả định dạng đẹp.

Chi tiết:
- Hỗ trợ số nguyên âm và số thực (`-3`, `2.5`). Gợi ý: `bc` hoặc `awk`.
- Thiếu tham số / sai định dạng → in usage, exit 1. Chia cho 0 → báo lỗi phép chia nhưng vẫn in các phép còn lại.
- Phép chia làm tròn 2 chữ số thập phân.

```text
$ ./bt2-calc.sh 10 3
+------------+----------+
| Operation  | Result   |
+------------+----------+
| 10 + 3     |       13 |
| 10 - 3     |        7 |
| 10 * 3     |       30 |
| 10 / 3     |     3.33 |
+------------+----------+
$ ./bt2-calc.sh 10 abc
Error: 'abc' is not a number
```

Tiêu chí: ☐ đúng với số nguyên, số âm, số thực ☐ bắt input không phải số (`abc`, `1.2.3`, `--5`, chuỗi rỗng) ☐ chia cho 0 ☐ căn bảng thẳng hàng (`printf`).

---

## BT3 — Thống kê file trong thư mục (`bt3-filestats.sh`)

Yêu cầu:
- Tạo script liệt kê tất cả file trong thư mục.
- Phân loại file theo đuôi mở rộng.
- Tính tổng dung lượng các file.
- Tìm file lớn nhất/nhỏ nhất.

Chi tiết:
- Tham số: đường dẫn thư mục (mặc định thư mục hiện tại). Option `-r` để quét đệ quy.
- File không có đuôi xếp vào nhóm `(no ext)`. File ẩn (`.bashrc`) coi là không có đuôi.
- Dung lượng hiển thị dạng dễ đọc (KB/MB — gợi ý `numfmt --to=iec`).
- Phải đúng với tên file có **dấu cách, ký tự tiếng Việt, dấu `*`**.
- Thư mục không tồn tại / không có quyền đọc → lỗi, exit 1. Thư mục rỗng → thông báo, exit 0.

```text
$ ./bt3-filestats.sh -r /var/log
Extension   Files     Size
log              23       4.1M
gz               12       1.2M
(no ext)          8       320K
-----------------------------------
Total           43 files   5.6M
Largest  : /var/log/syslog (2.3M)
Smallest : /var/log/lastlog (0B)
```

Tiêu chí: ☐ phân loại đúng ☐ tổng dung lượng khớp `du -cb` (sai số do block size phải giải thích) ☐ tên file đặc biệt ☐ có/không đệ quy.

---

## BT4 — Tạo user hàng loạt từ CSV (`bt4-create-users.sh`)

Yêu cầu:
- Tạo script tự động tạo nhiều user từ file CSV.
- Set password và add vào group.
- Kiểm tra user đã tồn tại.
- Log lại các thao tác.

Chi tiết:
- Input mẫu: [`starter/users.csv`](starter/users.csv) (`username,fullname,group,password`, dòng đầu là header). File mẫu cố tình có dòng lỗi.
- Bắt buộc chạy với root (kiểm tra `$EUID`).
- Username không hợp lệ (có dấu cách, ký tự đặc biệt) → bỏ qua, log lỗi.
- User đã tồn tại → **không** sửa, log `SKIP`.
- Group chưa có → tự tạo.
- Password trống → sinh ngẫu nhiên (`openssl rand`), bắt buộc đổi ở lần login đầu (`chage -d 0`). Password sinh ra ghi vào file riêng quyền `600`, **không** in ra log.
- Đặt password không lộ trên process list (dùng `chpasswd` qua stdin, không truyền password làm tham số lệnh).
- Log mỗi thao tác: `[timestamp] [INFO|SKIP|ERROR] message` vào `/var/log/bt4-create-users.log`.
- Option `--dry-run`: chỉ in ra sẽ làm gì, không tạo gì.
- Cuối cùng in tổng kết: số user tạo mới / bỏ qua / lỗi.

```text
$ sudo ./bt4-create-users.sh starter/users.csv
[2026-10-01 10:00:01] [INFO]  Created user dev01 (group developers)
[2026-10-01 10:00:01] [INFO]  Created group ops
[2026-10-01 10:00:02] [SKIP]  User john already exists
[2026-10-01 10:00:02] [ERROR] Line 8: invalid username 'bad user'
...
Summary: 6 created, 1 skipped, 1 error
```

Tiêu chí: ☐ chạy lại lần 2 không lỗi, toàn bộ SKIP (idempotent) ☐ password không xuất hiện trong log/`ps` ☐ `--dry-run` không thay đổi hệ thống ☐ xử lý dòng cuối không có newline, file có CRLF.

---

## BT5 — Backup thư mục (`bt5-backup.sh`)

Yêu cầu:
- Tạo backup của thư mục chỉ định.
- Nén file backup với timestamp.
- Tự động xóa backup cũ sau X ngày.
- Gửi email thông báo kết quả.

Chi tiết:
- Tham số: `bt5-backup.sh -s <source_dir> -d <dest_dir> [-k <days>]` (mặc định giữ 7 ngày).
- Tên file: `<tên-thư-mục>_YYYYmmdd_HHMMSS.tar.gz`.
- Kiểm tra: source tồn tại, dest ghi được, **đủ dung lượng trống** trước khi backup.
- Sau khi nén: kiểm tra file backup hợp lệ (`tar -tzf`), ghi kèm checksum (`sha256sum`).
- Xóa backup cũ hơn X ngày — **chỉ xóa file đúng pattern backup** của source đó, không xóa nhầm file khác trong dest.
- Thông báo kết quả (thành công/thất bại, kích thước, thời gian chạy, số file cũ đã xóa). Chọn **một** cách:
  - Email qua `msmtp` / `mailutils` (SMTP Gmail App Password hoặc Mailtrap) — **không commit password**, đọc từ file config quyền `600` hoặc biến môi trường.
  - Hoặc webhook: Mattermost/Slack/Discord/Telegram bằng `curl`.
- Có thông báo cả khi **thất bại** (gợi ý: `trap ... ERR`).
- Script sẽ được chạy định kỳ bằng systemd timer ở [lab-06](../lab-06-systemd-service/README.md).

Tiêu chí: ☐ backup restore được (giải nén ra và so sánh với `diff -r`) ☐ retention đúng (tạo file giả có mtime cũ bằng `touch -d "10 days ago"` để test) ☐ nhận được thông báo khi thành công và khi lỗi ☐ không có secret trong script.

---

## BT6 — Monitor tài nguyên (`bt6-monitor.sh`)

Yêu cầu:
- Monitor CPU, RAM, Disk usage.
- Cảnh báo khi vượt ngưỡng.
- Lưu log theo format cụ thể.

Chi tiết:
- Ngưỡng cấu hình được qua file `bt6-monitor.conf` hoặc option (mặc định CPU 80%, RAM 80%, Disk 90%).
- CPU: % sử dụng thực tế trong khoảng lấy mẫu (gợi ý: đọc `/proc/stat` 2 lần, hoặc `top -bn2`, `mpstat`), không dùng load average thay thế.
- RAM: tính theo `MemAvailable` (giải thích vì sao không dùng `MemFree`).
- Disk: tất cả mount point thật (bỏ `tmpfs`, `squashfs`, `overlay`).
- Log format (mỗi lần chạy 1 dòng, dễ parse bằng `awk`):

```text
2026-10-01T10:05:00+07:00 host=vm1 level=OK   cpu=12.5 mem=43.1 disk_root=27
2026-10-01T10:10:00+07:00 host=vm1 level=WARN cpu=91.2 mem=45.0 disk_root=27 msg="CPU above 80% threshold"
```

- Khi vượt ngưỡng: ghi `level=WARN` và gửi cảnh báo (tái sử dụng cách gửi ở BT5). Tránh spam: cùng một cảnh báo không gửi lại trong 30 phút.
- Chạy mỗi 5 phút bằng **cron** (nộp dòng crontab). Log xoay vòng bằng `logrotate` ⭐.
- Test: tạo tải giả bằng `stress-ng --cpu 1 --timeout 120` hoặc `yes > /dev/null &`, `fallocate -l` file lớn.

Tiêu chí: ☐ số liệu khớp với `top`/`free`/`df` (sai số nhỏ) ☐ cảnh báo đúng khi vượt ngưỡng ☐ không spam ☐ chạy được trong cron (đường dẫn tuyệt đối, PATH).

---

## Kết quả cần nộp
`devops-training/01-linux/lab-04-bash-scripting/`:
- `bt1-greeting.sh`, `bt2-calc.sh`, `bt3-filestats.sh`, `bt4-create-users.sh`, `bt5-backup.sh`, `bt6-monitor.sh`
- `bt6-monitor.conf`, `crontab.txt`, file cấu hình mẫu cho email/webhook dạng `*.example`
- `NOTES.md`: output chạy thử từng bài (cả trường hợp lỗi), output `shellcheck`.

## Tiêu chí đạt
- [ ] 6 script chạy đúng các ví dụ và các tiêu chí riêng của từng bài
- [ ] `shellcheck` không còn cảnh báo (hoặc có `# shellcheck disable=` kèm lý do)
- [ ] Mọi lỗi đều in ra stderr và exit code ≠ 0
- [ ] Không commit password/token/webhook URL thật
- [ ] BT6 chạy bằng cron có log thực tế ít nhất 1 giờ

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. `set -e`, `set -u`, `set -o pipefail` làm gì? Nêu một trường hợp `set -e` **không** dừng script dù lệnh lỗi.
2. `$@` khác `$*` thế nào, khi nào khác nhau? Vì sao phải quote `"$@"`?
3. Vì sao `for f in $(ls)` sai? Cách đúng để duyệt file có tên chứa dấu cách/newline?
4. `[ ]` khác `[[ ]]` khác `(( ))` thế nào?
5. Vì sao truyền password qua tham số lệnh (`useradd -p ...`, `echo pass | ...` trong tham số) là không an toàn?
6. Cron chạy với môi trường thế nào (PATH, shell, thư mục làm việc)? Output của cron job đi đâu?
7. CPU usage % được tính từ `/proc/stat` như thế nào? Load average khác CPU usage ra sao?
8. `MemFree` khác `MemAvailable`? Vì sao Linux "dùng hết RAM" mà vẫn bình thường?

<details>
<summary>Gợi ý</summary>

- Kiểm tra số: regex với `[[ $x =~ ^-?[0-9]+([.][0-9]+)?$ ]]`.
- Duyệt file an toàn: `find ... -print0 | while IFS= read -r -d '' f; do ...; done`.
- Đọc CSV: `while IFS=, read -r user name group pass; do ...; done < <(tail -n +2 file | tr -d '\r')`.
- Đuôi file: parameter expansion `${f##*.}`, tên file `${f##*/}`.
- Chống spam cảnh báo: lưu thời điểm gửi gần nhất vào một state file.

</details>

## Tài liệu tham khảo
- https://www.gnu.org/software/bash/manual/
- https://mywiki.wooledge.org/BashGuide và https://mywiki.wooledge.org/BashPitfalls
- https://www.shellcheck.net/
- https://crontab.guru/
