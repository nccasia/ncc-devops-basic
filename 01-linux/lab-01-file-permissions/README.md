# Lab 01 — User, group & phân quyền file cơ bản

> **Module:** 01 Linux

## Mục tiêu
- Tạo và quản lý user, group; thêm user vào group.
- Đọc và đặt quyền `rwx` cho owner/group/others bằng `chmod` (dạng ký hiệu và octal), `chown`, `chgrp`.
- Hiểu giới hạn của mô hình owner/group/others khi cần cấp quyền cho **một user cụ thể** không cùng group.

## Kiến thức cần có
- `useradd`, `groupadd`, `usermod -aG`, `id`, `su -`
- `ls -l`, `stat`, `chmod`, `chown`, `chgrp`

## Môi trường
- 1 VM Ubuntu (vm1), user có quyền `sudo`.

## Yêu cầu

### Phần 0 — Tạo user và group
Chạy `sudo ./setup.sh` hoặc tự gõ các lệnh dưới đây (nên tự gõ để hiểu):

```bash
# Create 2 users: john and mary (with home directory, bash shell)
sudo useradd -m -s /bin/bash john
sudo useradd -m -s /bin/bash mary

# Create 2 groups: developers and testers
sudo groupadd developers
sudo groupadd testers

# Add users to groups
sudo usermod -aG developers john
sudo usermod -aG testers mary
```

Kiểm tra bằng `id john`, `id mary`, `getent group developers testers`.

### Phần 1 — Phân quyền file cơ bản

```bash
# John creates project.txt
sudo su - john
touch project.txt
echo "Hello World" > project.txt
```

Yêu cầu với file `/home/john/project.txt`:
1. Cấp quyền **đọc** cho `mary`.
2. Cấp quyền **ghi** cho group `developers`.
3. **Không** cho phép others truy cập.

Lưu ý: `mary` không thuộc group `developers` và cũng không phải owner — hãy suy nghĩ xem chỉ dùng `chmod`/`chown` có đáp ứng đủ cả 3 yêu cầu được không. Nếu không, chọn giải pháp phù hợp (gợi ý: lab-03 sẽ học sâu về nó) và **giải thích lựa chọn** trong `NOTES.md`.

4. Đảm bảo `mary` thực sự đọc được file — tức là `mary` phải "đi qua" được thư mục `/home/john`. Chỉ mở **tối thiểu** quyền cần thiết trên `/home/john`, không `chmod 755`/`777` cả home.

### Phần 2 — Kiểm chứng
Chạy `sudo ./check.sh` và đảm bảo tất cả PASS. Tự kiểm tra thêm bằng tay:

```bash
sudo -u mary cat /home/john/project.txt              # must succeed
sudo -u mary sh -c 'echo x >> /home/john/project.txt' # must be denied
```

## Kết quả cần nộp
`devops-training/01-linux/lab-01-file-permissions/`:
- `NOTES.md`: lệnh đã chạy, output `ls -l` / `getfacl /home/john/project.txt`, output `check.sh`, giải thích lựa chọn ở Phần 1.
- `solution.sh`: script tái hiện toàn bộ phân quyền (chạy được trên VM sạch sau `setup.sh`).

## Tiêu chí đạt
- [ ] `john ∈ developers`, `mary ∈ testers`, `mary ∉ developers`
- [ ] Owner của `project.txt` là `john`, group là `developers`
- [ ] `mary` đọc được, không ghi được
- [ ] Thành viên `developers` (không phải john) ghi được
- [ ] User khác (others) không đọc được
- [ ] Không mở quyền thừa trên `/home/john`
- [ ] `check.sh` pass toàn bộ

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. `chmod 640` nghĩa là gì? Viết lại bằng dạng ký hiệu (`u=…,g=…,o=…`).
2. Vì sao `usermod -G developers john` (thiếu `-a`) nguy hiểm?
3. Sau khi `usermod -aG`, vì sao session đang mở của john chưa thấy group mới? Làm sao áp dụng ngay?
4. Muốn mary đọc được file trong `/home/john` thì `/home/john` cần quyền gì cho mary? `r` hay `x` hay cả hai — vì sao?
5. Chỉ với owner/group/others, có cách nào cho mary đọc mà others không đọc mà không đổi group của mary không? Ưu/nhược điểm của các cách?
6. `/etc/passwd`, `/etc/shadow`, `/etc/group` chứa những gì? Vì sao `/etc/shadow` không cho user thường đọc?
7. `useradd` khác `adduser` thế nào trên Ubuntu?

<details>
<summary>Gợi ý</summary>

- Mô hình UGO chỉ có **một** group cho mỗi file. Khi có 2 "nhóm đối tượng" khác nhau cần quyền khác nhau, xem lại `setfacl`.
- Quyền đi qua thư mục là `x`. Có thể cấp `x` cho riêng mary trên `/home/john` mà không cho others.
- Dùng `namei -l /home/john/project.txt` để thấy quyền từng cấp đường dẫn.

</details>

## Tài liệu tham khảo
- https://linuxhandbook.com/linux-file-permissions/
- `man chmod`, `man useradd`, `man namei`
