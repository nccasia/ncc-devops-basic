# Lab 15 — Tối ưu kích thước Docker image

> **Module:** 07 Docker

## Mục tiêu
- Áp dụng multi-stage build và chọn base image phù hợp.
- Đo lường và so sánh thực tế thay vì đoán.
- Cân bằng giữa kích thước, bảo mật và khả năng debug.

## Kiến thức cần có
- Lab 01, 11, 13.

## Môi trường
- VM Ubuntu có Docker. Ngôn ngữ app tùy chọn (Node, Go, Python…).

## Yêu cầu
Tạo image nhỏ nhất có thể cho ứng dụng web đơn giản.

### Gợi ý
1. Multi-stage builds
2. Alpine base images
3. Scratch images
4. Distroless images
5. UPX compression
6. Remove unnecessary files

### Bổ sung
Tạo image < 10MB chứa web server hoạt động được.

### So sánh (Dưới đây chỉ là ví dụ thôi)
| Base Image | Size |
|------------|------|
| node:18 | ~900MB |
| node:18-alpine | ~170MB |
| distroless | ~? |
| scratch | ~? |

Yêu cầu chi tiết:
1. Cùng một app web (có ít nhất endpoint `/` và `/health`), build **ít nhất 4 phiên bản** image với base khác nhau (full, slim/alpine, distroless, scratch hoặc tương đương).
2. Điền bảng so sánh bằng **số đo thật** của bạn: kích thước, số layer, thời gian build (lần đầu và khi chỉ sửa code), số lỗ hổng (`docker scout cves` hoặc `trivy image`), có shell hay không.
3. Có ít nhất 1 image **< 10MB** chạy được web server, trả lời đúng `curl`.
4. Mọi phiên bản chạy bằng non-root user (scratch cũng phải chạy non-root).
5. ⭐ Thử UPX, đo kích thước và thời gian khởi động trước/sau, nêu đánh đổi.

## Kết quả cần nộp
Nộp vào `devops-training/07-docker/lab-15-image-optimization/`:
- Source app, các `Dockerfile.*`, `.dockerignore`, `measure.sh` (script build + đo + in bảng)
- `NOTES.md`: bảng so sánh, phân tích, đề xuất image dùng cho production và lý do

## Tiêu chí đạt
- [ ] ≥ 4 image, tất cả chạy được và trả lời `curl`
- [ ] 1 image < 10MB (theo `docker images`)
- [ ] Bảng so sánh có số đo thật, có cột lỗ hổng
- [ ] Image chạy non-root (chứng minh bằng `docker inspect` `.Config.User` hoặc `ps`)
- [ ] Đề xuất production có cân nhắc debug, bảo mật, chi phí build

## Câu hỏi tự kiểm tra

Tự trả lời các câu hỏi sau và ghi câu trả lời vào `NOTES.md`.
1. Multi-stage build giảm kích thước nhờ cơ chế gì?
2. Image `scratch` thiếu những gì (CA cert, timezone, `/etc/passwd`, shell…)? Ảnh hưởng thế nào và xử lý ra sao?
3. Alpine dùng `musl` thay vì `glibc` — có thể gây vấn đề gì?
4. Debug một container distroless/scratch không có shell như thế nào (`docker debug`, ephemeral container, `nsenter`)?
5. Gộp nhiều `RUN` bằng `&&` giúp gì? Xóa cache package manager phải làm trong cùng `RUN` — vì sao?
6. Image nhỏ hơn có luôn tốt hơn không?

<details>
<summary>Gợi ý</summary>

- Ngôn ngữ biên dịch ra static binary (Go với `CGO_ENABLED=0`) dễ đạt < 10MB nhất; hoặc dùng web server tĩnh nhỏ như `busybox httpd`.
- `docker images --format '{{.Repository}}:{{.Tag}} {{.Size}}'`
- `dive` để xem phần nào chiếm dung lượng.

</details>

## Tài liệu tham khảo
- https://docs.docker.com/build/building/multi-stage/
- https://github.com/GoogleContainerTools/distroless
- https://docs.docker.com/scout/
- https://github.com/aquasecurity/trivy
- https://upx.github.io/
