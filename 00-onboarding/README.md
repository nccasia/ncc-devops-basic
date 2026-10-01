# 00 — Onboarding

Đọc kỹ trang này trước khi làm bất kỳ bài nào.

## Tư duy làm việc

- Chủ động, ham học hỏi.
- **Cẩn thận**, không ngại khó. Với DevOps, một lệnh sai có thể làm sập cả hệ thống — đọc kỹ trước khi Enter.
- **Tự học**, tự tay xử lý những lỗi khó trước khi hỏi người khác. Khi hỏi, chuẩn bị sẵn: đã làm gì, lỗi gì (log/output đầy đủ), đã thử những cách nào.

## Thói quen làm việc an toàn

Những thói quen dưới đây áp dụng cho suốt khóa học và cả khi đi làm dự án thật:

- **Đúng danh tính Git:** luôn kiểm tra `git config user.name` / `user.email` trước khi commit. Mỗi dự án có thể yêu cầu một danh tính khác nhau.
- **Chỉ push lên nơi được phép:** repo đề bài này chỉ clone về để đọc; bài làm push vào repo cá nhân của bạn theo [quy trình làm & nộp bài](submission.md). Không tự ý push code của người khác/dự án khác lên repo cá nhân.
- **Không commit secret:** password, private key, token, file `.env` thật không bao giờ được vào Git. Dùng file mẫu (`.env.example`) và kiểm tra `git diff --cached` trước khi commit.
- **Quyền tối thiểu:** không dùng `root`, `chmod 777` hay superuser DB chỉ để "cho chạy được". Cấp đúng quyền cần thiết và giải thích được vì sao.
- **Có đường lui:** trước khi sửa config/xóa dữ liệu, backup hoặc snapshot VM. Biết cách rollback trước khi thay đổi.
- **Không chắc thì hỏi:** với thao tác khó đảo ngược (xóa dữ liệu, force-push, thay đổi trên môi trường dùng chung), hỏi mentor trước khi làm.

## Lab

| Lab | Nội dung |
|-----|----------|
| [lab-01-git-setup](lab-01-git-setup/README.md) | Cấu hình Git đúng danh tính, SSH key, quy trình branch/PR |
| [Quy trình làm & nộp bài](submission.md) | Tạo repo cá nhân, cấu trúc bài làm, branch/PR để được review |

## Câu hỏi tự kiểm tra
Tự trả lời và ghi vào `NOTES.md` của lab-01.

1. Trước khi push code lên một repo, bạn cần kiểm tra những gì? Kiểm tra bằng lệnh nào?
2. Vì sao không nên fork code của dự án/tổ chức khác về tài khoản cá nhân, kể cả repo private?
3. Lỡ commit password lên Git (đã push) thì phải làm gì? Xóa commit có đủ không?
4. Vì sao không nên chạy ứng dụng bằng `root` hoặc `chmod 777` cho nhanh?
5. Kể 3 thao tác khó đảo ngược mà bạn cần backup/hỏi trước khi làm.
6. Khi bị kẹt một lỗi, trước khi hỏi người khác bạn cần chuẩn bị những thông tin gì?
