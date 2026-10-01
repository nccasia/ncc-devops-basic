# Quy trình làm & nộp bài

Repo `ncc-devops-basic` chỉ chứa **đề bài** — bạn clone về để đọc và dùng các file `starter/`, `check.sh`. Bạn **không** push hay tạo Pull Request vào repo này.

Bài làm của bạn nằm trong **repo cá nhân** do bạn tự tạo.

## 1. Chuẩn bị

```bash
# Clone the exercise repo (read-only) — git pull now and then to get updates
git clone https://github.com/nccasia/ncc-devops-basic.git

# Create your personal repo on GitHub/GitLab, suggested name: devops-training
git clone git@github.com:<github-username>/devops-training.git
cd devops-training
git config user.name && git config user.email   # verify your identity
```

- Nên để repo ở chế độ **private**. Để được review, thêm mentor làm collaborator (hoặc gửi link nếu repo public).
- Thêm `.gitignore` ngay từ đầu (secret, `.env`, `node_modules/`, `venv/`, `target/`, `bin/`, `obj/`, `.vagrant/`, file `*.tar`).

## 2. Cấu trúc repo cá nhân

Giữ cấu trúc giống repo đề để dễ đối chiếu:

```
devops-training/
├── README.md               # Bảng tiến độ: module/lab, trạng thái, link PR
├── 00-onboarding/
│   └── lab-01-git-setup/
│       ├── NOTES.md
│       └── check-identity.sh
├── 01-linux/
│   ├── NOTES.md            # Câu hỏi tự kiểm tra + break & fix của module
│   ├── lab-01-file-permissions/
│   │   ├── NOTES.md        # Bắt buộc: các bước, lệnh, output, giải thích
│   │   └── ...             # script, config
│   └── lab-04-bash-scripting/
│       ├── bt1-greeting.sh
│       └── ...
└── ...
```

Mục **Kết quả cần nộp** của mỗi lab ghi đường dẫn dạng `devops-training/<module>/<lab>/` — đó là đường dẫn trong repo cá nhân của bạn. Mẫu `NOTES.md` xem tại [tiêu chuẩn bài đạt](../docs/definition-of-done.md#mẫu-notesmd).

## 3. Mỗi lab một branch + Pull Request

Làm việc theo quy trình giống dự án thật, ngay trong repo cá nhân:

```bash
git switch main && git pull
git switch -c 01-linux/lab-01

# Do the lab, make small and meaningful commits
git add 01-linux/lab-01-file-permissions
git commit -m "01-linux lab-01: file and project directory permissions"

git push -u origin 01-linux/lab-01
# Open a Pull Request into main of your personal repo and request a mentor review
```

- Tiêu đề PR: `<module> <lab> — <mô tả ngắn>`
- Mô tả PR: tick các mục **Tiêu chí đạt** của lab, dán output của `check.sh` (nếu có), ghi những chỗ chưa làm được/chưa hiểu.
- Sửa theo review bằng commit mới (không force-push khi đang review), trả lời từng comment khi đã sửa.
- PR được approve → merge vào `main`, cập nhật bảng tiến độ trong `README.md`, chuyển sang lab tiếp theo.

## Checklist trước khi push

- [ ] `git config user.email` đúng email bạn dùng cho khóa học
- [ ] Không có password, private key, token, file `.env` thật trong commit (`git diff --cached` để kiểm tra)
- [ ] Không commit file build/binary/`node_modules`/`venv`
- [ ] `NOTES.md` đủ để người khác làm lại được
- [ ] Đã tự rà theo [tiêu chuẩn bài đạt](../docs/definition-of-done.md)
- [ ] Nếu repo public: không có IP/domain/thông tin thật của bất kỳ hệ thống nào ngoài VM lab
