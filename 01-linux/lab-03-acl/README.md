# Lab 03 — Quản lý ACL (Access Control Lists)

> **Module:** 01 Linux

## Mục tiêu
- Cấp quyền đặc biệt cho user/group cụ thể vượt ra ngoài mô hình owner/group/others.
- Đọc hiểu output `getfacl`, cơ chế **mask** và **effective permission**.
- Backup và restore ACL cho cả cây thư mục.

## Kiến thức cần có
- Hoàn thành lab-01, lab-02.
- `getfacl`, `setfacl -m / -x / -b / -k / -d / -R`, `getfacl -R`, `setfacl --restore`.

## Môi trường
- vm1, đã có user `john`, `mary`, group `developers`, `testers`, thư mục `/projects/web` từ lab-02.

```bash
# Install ACL (already installed by the lab-env provisioning)
sudo apt-get install -y acl
# Create extra users for this lab
sudo useradd -m -s /bin/bash alice   # auditor - read only
sudo useradd -m -s /bin/bash bob     # contractor - temporary access
```

## Yêu cầu

### Phần 1 — Cấp quyền đặc biệt cho user cụ thể
1. `alice` (không thuộc group nào của dự án) được **đọc** toàn bộ `/projects/web/public` và `/projects/web/private` (kể cả file tạo sau này), không được ghi.
2. `bob` được **đọc + ghi** chỉ riêng file `/projects/web/private/report.txt` (tạo file này, owner `john`). Bob không được liệt kê nội dung các thư mục khác trong `private/` — chỉ biết đường dẫn file mới truy cập được.
3. Group `testers` được **ghi** vào thư mục `/projects/web/public/uploads` (tạo mới), nhưng vẫn chỉ đọc ở các nơi khác.

### Phần 2 — Kiểm tra và sửa đổi ACL
4. Dùng `getfacl` để in ACL của các đối tượng trên. Giải thích từng dòng (`user::`, `user:alice:`, `group::`, `mask::`, `other::`, `default:`…) trong `NOTES.md`.
5. Thí nghiệm mask: chạy `chmod g-w /projects/web/private/report.txt`, quan sát `#effective:` trong `getfacl` và thử ghi bằng bob. Giải thích hiện tượng, sau đó khôi phục.
6. Hết hợp đồng: **thu hồi** toàn bộ quyền của `bob` (chỉ xóa entry của bob, không ảnh hưởng entry khác). Chứng minh bob không còn truy cập được.
7. Liệt kê tất cả file/thư mục trong `/projects` đang có ACL mở rộng (gợi ý: dấu `+` trong `ls -l`, hoặc `getfacl -R -s`).

### Phần 3 — Backup và restore ACL
8. Backup toàn bộ ACL của `/projects` ra file `acl-backup.txt`.
9. Giả lập sự cố: `sudo setfacl -R -b /projects/web` (xóa sạch ACL).
10. Restore từ file backup, chứng minh quyền trở lại như cũ (so sánh `getfacl -R` trước/sau bằng `diff`).
11. ⭐ Chứng minh `cp` thường làm mất ACL, còn `cp -a` / `tar --acls` / `rsync -A` giữ được ACL.

Kiểm chứng: `sudo ./check.sh` (chạy **sau** bước 6 và 10).

## Kết quả cần nộp
`devops-training/01-linux/lab-03-acl/`:
- `solution.sh`: các lệnh Phần 1 + 6.
- `backup-acl.sh`, `restore-acl.sh`: nhận đường dẫn và file backup làm tham số, có kiểm tra input.
- `NOTES.md`: output `getfacl`, giải thích Phần 2, `diff` Phần 3, output `check.sh`.
- `acl-backup.txt` (file backup mẫu).

## Tiêu chí đạt
- [ ] alice đọc được file cũ **và** file mới tạo trong `public`, `private`; không ghi được
- [ ] bob đã bị thu hồi, không còn entry `user:bob` nào trong `/projects`
- [ ] testers ghi được vào `public/uploads`, không ghi được vào `public`
- [ ] Giải thích đúng cơ chế mask
- [ ] Restore ACL thành công, `diff` trước/sau rỗng
- [ ] `check.sh` pass toàn bộ

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. Vì sao cần ACL khi đã có owner/group/others? Khi nào nên tạo group mới thay vì dùng ACL?
2. Mask là gì, được tính từ đâu? Lệnh `chmod g=...` trên file có ACL thực chất đổi cái gì?
3. Thứ tự kernel đánh giá ACL entry thế nào? User vừa có `user:x:r--` vừa thuộc group có `rwx` thì được quyền gì?
4. Default ACL có tác dụng lên file đã tồn tại không? Áp ACL cho cả cây đã có sẵn thì làm sao?
5. Để bob mở được `/projects/web/private/report.txt` thì các thư mục cha cần quyền gì cho bob? Vì sao `--x` mà không phải `r-x`?
6. `getfacl -R` lưu đường dẫn tương đối hay tuyệt đối? Điều đó ảnh hưởng gì khi restore — phải đứng ở thư mục nào?
7. Filesystem nào hỗ trợ ACL? Copy sang USB FAT32 thì sao?

<details>
<summary>Gợi ý</summary>

- Entry ACL cho thư mục cần cả access ACL và default ACL nếu muốn áp cho file tương lai.
- `X` (chữ hoa) trong `setfacl -R -m u:alice:rX` chỉ thêm `x` cho thư mục (và file đã có x).
- `getfacl` mặc định bỏ `/` đầu đường dẫn — đọc thông báo `Removing leading '/'`.

</details>

## Tài liệu tham khảo
- `man acl`, `man setfacl`, `man getfacl`
- https://www.redhat.com/sysadmin/linux-access-control-lists
