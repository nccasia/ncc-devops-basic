# Thế nào là một bài đạt

Dùng trang này để tự rà bài trước khi tạo Pull Request trong repo cá nhân.

## Một lab được coi là xong khi

- [ ] **Hoàn thành yêu cầu:** tick được toàn bộ mục **Tiêu chí đạt**, `check.sh` (nếu có) chạy PASS hết.
- [ ] **Tái hiện được:** người khác đọc `NOTES.md`/script của bạn và làm lại trên VM sạch ra cùng kết quả. Không có bước "làm tay mà không ghi lại".
- [ ] **Hiểu bản chất:** đã tự trả lời **Câu hỏi tự kiểm tra** trong `NOTES.md`, giải thích được *tại sao*, không chỉ *làm thế nào*.
- [ ] **Chất lượng & an toàn:** script có xử lý lỗi, không hardcode secret, cấp quyền tối thiểu, có comment ở chỗ khó.

## Một module được coi là xong khi

- [ ] Các lab bắt buộc đều đã được review và merge vào `main` của repo cá nhân.
- [ ] Trả lời được câu hỏi tự kiểm tra của module mà không cần mở tài liệu.
- [ ] Đã làm **Bài tự luyện debug (break & fix)** của module: tự làm hỏng môi trường, tự tìm và sửa, ghi lại *triệu chứng → nguyên nhân → cách sửa*.

## Những lỗi khiến bài không đạt ngay

- Commit password / private key / token lên repo.
- `chmod 777`, `chown -R` bừa bãi, tắt firewall để "cho chạy được" mà không giải thích được.
- Chạy app bằng `root` khi đề yêu cầu user riêng.
- Copy lời giải mà không giải thích được.
- Push code lên nơi không được phép, sai danh tính Git (xem [00-onboarding](../00-onboarding/README.md)).

## Mẫu NOTES.md

```markdown
# <Module> — <Lab>

## Môi trường
VM, OS, version phần mềm.

## Các bước thực hiện
1. Mục đích bước → lệnh → output chính (rút gọn)

## Kết quả
Output check.sh / ảnh chụp chứng minh từng tiêu chí đạt.

## Câu hỏi tự kiểm tra
1. Câu trả lời của bạn…

## Vấn đề gặp phải
Lỗi gì, nguyên nhân, cách xử lý. Chỗ còn chưa hiểu.
```
