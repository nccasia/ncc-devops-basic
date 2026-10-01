# Lab 02 — Phân quyền thư mục dự án

> **Module:** 01 Linux

## Mục tiêu
- Thiết kế quyền cho một thư mục dự án dùng chung giữa nhiều nhóm.
- Hiểu và dùng SGID trên thư mục, `umask`, default ACL để file mới **tự kế thừa** quyền.
- Giới hạn một thư mục con chỉ cho owner truy cập.

## Kiến thức cần có
- Hoàn thành [lab-01](../lab-01-file-permissions/README.md) (đã có user `john`, `mary`, group `developers`, `testers`).
- SUID/SGID/sticky bit, `umask`, `setfacl -d` (default ACL).

## Môi trường
- vm1, đã chạy `../lab-01-file-permissions/setup.sh`.

## Yêu cầu

```bash
# Create the directory structure
sudo mkdir -p /projects/web/{public,private,config}
```

1. Group `developers` có **full quyền** (`rwx`) trong `/projects/web/` và mọi thư mục con (trừ `config`, xem mục 4).
2. Group `testers` chỉ có quyền **đọc và thực thi** (`r-x`) — đọc được file, liệt kê/đi vào được thư mục, không tạo/sửa/xóa.
3. Các file/thư mục **mới tạo** trong `/projects/web` **tự động kế thừa** quyền của thư mục cha:
   - group owner luôn là `developers` (dù người tạo có primary group khác),
   - developers vẫn `rwx` (thư mục) / `rw-` (file), testers vẫn đọc được.
   Phải đúng **kể cả khi người tạo có `umask 077`**.
4. `config/` **chỉ cho phép owner truy cập** (owner do bạn chọn — ví dụ `john` — và ghi rõ lý do). Developers khác, testers, others đều không vào được.
5. Others không có quyền gì trên `/projects/web`.
6. ⭐ Developers không được xóa file của developer khác trong `public/` (chỉ owner file mới xóa được). Gợi ý: sticky bit.

Kiểm chứng: `sudo ./check.sh` phải PASS toàn bộ.

## Kết quả cần nộp
`devops-training/01-linux/lab-02-project-directory/`:
- `solution.sh`: tái hiện toàn bộ cấu hình trên VM sạch (sau `lab-01/setup.sh`), idempotent.
- `NOTES.md`: output `ls -ld`, `getfacl -R /projects/web`, output `check.sh`, giải thích vì sao chọn SGID/default ACL/umask.

## Tiêu chí đạt
- [ ] Group của `/projects/web` và các thư mục con là `developers`, có bit SGID
- [ ] Developers tạo/sửa/xóa được file trong `public`, `private`
- [ ] Testers đọc được file, không tạo/xóa được
- [ ] File mới do `john` (umask 077) tạo vẫn có group `developers`, `mary` đọc được
- [ ] `config/` chỉ owner truy cập được
- [ ] Others không truy cập được
- [ ] `check.sh` pass toàn bộ

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. SGID trên thư mục làm gì? Nó có làm file mới có quyền `g+w` không? Vì sao chỉ SGID là chưa đủ cho yêu cầu 3?
2. `umask` là thuộc tính của ai — file, thư mục hay process? Vì sao không thể "đặt umask cho một thư mục"?
3. Default ACL tương tác với `umask` như thế nào khi tạo file mới?
4. Khi `cp` và `mv` một file từ `/tmp` vào `/projects/web`, file có kế thừa quyền không? Khác nhau thế nào?
5. Root có bị chặn bởi quyền của `config/` không? Vậy "chỉ owner truy cập" thực tế nghĩa là gì?
6. Sticky bit trên thư mục hoạt động thế nào? Tại sao `/tmp` có quyền `1777`?
7. Muốn testers chỉ đọc mà không cần đặt group là testers — cách nào?

<details>
<summary>Gợi ý</summary>

- Một thư mục chỉ có một group owner. Group thứ hai (testers) cần ACL.
- Có hai loại ACL: access ACL (`setfacl -m`) và default ACL (`setfacl -d -m`) — default ACL chỉ có trên thư mục và là "khuôn" cho con mới tạo.
- Thử nghiệm: `sudo -u john bash -c 'umask 077; touch /projects/web/public/t.txt'` rồi `getfacl` file đó.
- Default ACL ở thư mục cha cũng sẽ "lan" xuống `config/` nếu tạo sau — thứ tự thao tác quan trọng.

</details>

## Tài liệu tham khảo
- https://linuxhandbook.com/suid-sgid-sticky-bit/
- `man setfacl`, `man acl` (mục *OBJECT CREATION AND DEFAULT ACLs*)
