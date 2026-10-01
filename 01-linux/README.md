# 01 — Linux Foundation

> **Môi trường:** [lab-env](../lab-env/README.md) (vm1, vm2)

## Mục tiêu

Sau module này bạn sẽ:
- Thao tác thành thạo trên terminal: file, process, package, log.
- Quản lý user/group, phân quyền file/thư mục (chmod, chown, setgid, sticky bit, umask, ACL).
- Viết được Bash script có xử lý input, lỗi, log, chạy định kỳ.
- Hiểu network cơ bản (IP, port, DNS, routing, firewall) và tự troubleshoot được.
- Quản lý service bằng systemd, đọc log bằng journalctl.

## Lý thuyết cần tự học

- `Linux_Tutorial_ASP2024.pdf` — file đính kèm trên Wiki DevOps-Training (trang *Devops Training*)
- Linux Foundation — Introduction to Linux: https://training.linuxfoundation.org/training/introduction-to-linux/
- 90DaysOfDevOps — [Knowing Linux basics](https://github.com/MichaelCade/90DaysOfDevOps/blob/main/2022.md#knowing-linux-basics) & [Understand networking](https://github.com/MichaelCade/90DaysOfDevOps/blob/main/2022.md#understand-networking)
- Basic Linux commands: https://www.geeksforgeeks.org/linux-unix/basic-linux-commands/
- Linux file permissions: https://linuxhandbook.com/linux-file-permissions/

Checklist kiến thức:
- [ ] Cấu trúc thư mục (`/etc`, `/var`, `/home`, `/opt`, `/usr`, `/proc`, `/tmp`)
- [ ] File & text: `ls, cp, mv, rm, find, grep, sed, awk, cut, sort, uniq, wc, head, tail, less, tar`
- [ ] User/group: `useradd, usermod, groupadd, passwd, id, su, sudo, /etc/passwd, /etc/group, /etc/shadow`
- [ ] Permission: `rwx`, số octal, `chmod, chown, chgrp, umask`, SUID/SGID/sticky bit, ACL
- [ ] Process: `ps, top/htop, kill, nice, &, jobs, nohup`, signal
- [ ] Package: `apt`, repository, `dpkg`
- [ ] Disk: `df, du, lsblk, mount`
- [ ] Network: `ip, ss, ping, traceroute, dig, curl, /etc/hosts, /etc/resolv.conf, ufw`
- [ ] Service: `systemctl, journalctl`, unit file, timer, `cron`
- [ ] Bash: biến, tham số `$1 $# $@`, `if/case/for/while`, function, exit code, redirect `> >> 2>&1`, pipe

## Danh sách lab

| Lab | Nội dung | Bắt buộc |
|-----|----------|----------|
| [lab-01-file-permissions](lab-01-file-permissions/README.md) | User/group, phân quyền file cơ bản | ✅ |
| [lab-02-project-directory](lab-02-project-directory/README.md) | Phân quyền thư mục dự án, setgid, kế thừa quyền | ✅ |
| [lab-03-acl](lab-03-acl/README.md) | ACL, default ACL, backup/restore | ✅ |
| [lab-04-bash-scripting](lab-04-bash-scripting/README.md) | 6 bài Bash script (BT1–BT6) | ✅ |
| [lab-05-networking](lab-05-networking/README.md) | Network cơ bản & troubleshoot theo lớp | ✅ |
| [lab-06-systemd-service](lab-06-systemd-service/README.md) | systemd unit, journalctl, timer | ✅ |

## Câu hỏi tự kiểm tra cuối module
Tự trả lời, ghi vào một file `devops-training/<module>/NOTES.md`. Câu nào chưa trả lời được thì quay lại lý thuyết/lab tương ứng.

1. Khi chạy `cat file.txt` bị `Permission denied`, kernel kiểm tra quyền theo thứ tự nào (owner/group/others/ACL)? Root có bị kiểm tra không?
2. Quyền `x` trên thư mục nghĩa là gì? Thư mục có `r` mà không có `x` thì sao? Có `x` mà không có `r` thì sao?
3. Muốn xóa một file cần quyền gì trên file và trên thư mục chứa nó? Sticky bit giải quyết vấn đề gì (ví dụ `/tmp`)?
4. SGID trên thư mục khác SGID trên file thực thi thế nào? SUID nguy hiểm ở đâu?
5. `umask 027` thì file mới và thư mục mới có quyền gì? Vì sao file mới không bao giờ có `x` mặc định?
6. ACL mask là gì? Vì sao sau khi `chmod g-w` thì ACL user cũng mất quyền ghi?
7. `su -` khác `su` và `sudo -i` thế nào? `/etc/sudoers` nên sửa bằng lệnh gì, vì sao?
8. `2>&1 > file` khác `> file 2>&1` thế nào?
9. Một script chạy tay thì được nhưng chạy bằng cron thì lỗi — kể 3 nguyên nhân thường gặp.
10. `curl http://vm1:8080` báo `Connection refused` khác `Connection timed out` khác `Could not resolve host` thế nào? Mỗi lỗi ở lớp nào?
11. `systemctl enable` khác `systemctl start`? `daemon-reload` dùng khi nào?
12. Process zombie và orphan là gì? `kill -9` khác `kill -15`?

## Bài tự luyện debug (break & fix)

Sau khi xong các lab, chụp snapshot vm1 (`vagrant snapshot save vm1 before-break`), rồi **tự cố tình làm hỏng** từng mục dưới đây (mỗi lần một lỗi). Quan sát triệu chứng như một người dùng gặp lỗi, tự chẩn đoán bằng công cụ đã học, sửa lại, và ghi vào `devops-training/01-linux/BREAK-FIX.md` theo bảng: **Lỗi đã cài → Triệu chứng → Cách chẩn đoán (lệnh) → Nguyên nhân → Cách sửa**. Nhờ một bạn intern khác cài lỗi giúp sẽ sát thực tế hơn.

- Bỏ quyền `x` của thư mục cha (`chmod o-x /projects`) → user không vào được thư mục con dù thư mục con `777`.
- Set ACL mask `m::r--` trên `/projects/web` → developers mất quyền ghi dù `getfacl` vẫn hiện `group:developers:rwx`.
- Đổi shell của user thành `/usr/sbin/nologin` → `su - john` không vào được.
- Lưu một script với CRLF (`\r\n`) → `/usr/bin/env: 'bash\r': No such file or directory`.
- Thêm entry sai vào `/etc/hosts` (`10.0.0.99 vm2`) → ping theo tên thất bại nhưng ping IP được.
- `ufw deny 8080` → `curl` từ vm2 bị timeout.
- Unit systemd có `User=` trỏ tới user không tồn tại / `ExecStart` dùng đường dẫn tương đối → service fail, đọc `journalctl -u` để tìm.
- Làm đầy disk (`fallocate -l <dung-lượng> /var/tmp/big`) → service không ghi được log. Nhớ xóa file sau khi xong.

Xong thì `vagrant snapshot restore vm1 before-break` để trả máy về trạng thái tốt.
