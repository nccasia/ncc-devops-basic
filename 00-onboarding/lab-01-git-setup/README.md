# Lab 01 — Git setup & quy trình làm việc

> **Module:** 00 Onboarding

## Mục tiêu
- Cấu hình Git đúng danh tính, phân biệt cấu hình global và theo repo.
- Dùng SSH key để làm việc với GitHub.
- Thực hiện được quy trình branch → commit → push → Pull Request.

## Yêu cầu
1. Tạo SSH key (`ed25519`) có passphrase, add public key vào GitHub. Kiểm tra bằng `ssh -T git@github.com`.
2. Cấu hình `user.name`, `user.email` **global** bằng email bạn dùng cho khóa học.
3. Giả lập tình huống một dự án yêu cầu danh tính riêng: tạo một repo local `~/customer-demo`, cấu hình `user.email` **riêng cho repo này** là `you@customer.example`. Chứng minh commit trong repo đó dùng email này, còn repo khác dùng email global.
4. ⭐ Dùng `includeIf` trong `~/.gitconfig` để tự động đổi danh tính theo thư mục (VD mọi repo trong `~/customers/` dùng email `you@customer.example`).
5. Viết `check-identity.sh`: chạy trong một repo bất kỳ, in ra `user.name`, `user.email`, remote URL và cảnh báo (exit code ≠ 0) nếu email không khớp với domain truyền vào tham số. Ví dụ: `./check-identity.sh example.com`.
6. Tạo repo cá nhân `devops-training` theo [quy trình làm & nộp bài](../submission.md) (private, có `.gitignore`, `README.md` bảng tiến độ). Nộp lab này bằng PR đầu tiên trong repo đó.

## Kết quả cần nộp
`devops-training/00-onboarding/lab-01-git-setup/`:
- `NOTES.md`: các lệnh đã chạy, output `git config --list --show-origin | grep user`, output `git log --format='%an <%ae>'` ở 2 repo
- `check-identity.sh`

## Tiêu chí đạt
- [ ] SSH tới GitHub thành công, private key **không** nằm trong repo
- [ ] Chứng minh được cấu hình repo-level ghi đè global
- [ ] `check-identity.sh` trả exit code 1 khi email sai domain, 0 khi đúng
- [ ] Repo cá nhân đúng cấu trúc, PR đúng format tiêu đề, mentor đã được mời review

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. Thứ tự ưu tiên của git config: system / global / local / worktree?
2. Đổi `user.email` sau khi đã commit thì các commit cũ có đổi không? Sửa email của commit cũ bằng cách nào và rủi ro gì?
3. `git pull` khác `git fetch` thế nào? `merge` khác `rebase` thế nào?
4. Vì sao không nên `git push --force` lên branch người khác đang dùng? `--force-with-lease` khác gì?
5. Lỡ `git add .env` và commit (chưa push) thì xử lý thế nào? Nếu đã push?

## Tài liệu tham khảo
- https://git-scm.com/book/en/v2
- https://docs.github.com/en/authentication/connecting-to-github-with-ssh
- https://git-scm.com/docs/git-config#_conditional_includes
