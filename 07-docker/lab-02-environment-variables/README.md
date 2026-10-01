# Lab 02 — Environment Variables

> **Module:** 07 Docker

## Mục tiêu
- Biết các cách truyền biến môi trường vào container và thứ tự ưu tiên giữa chúng.
- Phân biệt biến **trong container** và biến **interpolation** của Compose.
- Biết cách tránh lộ giá trị sensitive.

## Kiến thức cần có
- `docker run`, `docker compose`.

## Môi trường
- VM Ubuntu có Docker. Image `alpine`.

## Yêu cầu
1. Tạo container từ image `alpine` và truyền các biến môi trường sau:
   - `APP_ENV=production`
   - `DB_HOST=localhost`
   - `DB_PORT=5432`
2. Sử dụng 3 cách khác nhau để truyền biến môi trường:
   - Flag `-e`
   - File `.env` (với `docker run --env-file` **và** với Compose)
   - Trong `docker-compose.yml` (`environment:` và `env_file:`)
3. In ra tất cả biến môi trường trong container (`env` / `printenv`).
4. Thí nghiệm thứ tự ưu tiên: đặt **cùng** biến `APP_ENV` với giá trị khác nhau ở: `ENV` trong Dockerfile, `env_file:`, `environment:`, biến shell khi chạy `docker compose run -e`. Ghi lại giá trị cuối cùng container nhận được ở từng tổ hợp.
5. Phân biệt: file `.env` cạnh `docker-compose.yml` dùng để **interpolate** `${VAR}` trong file compose, khác với `env_file:` đưa biến vào container. Chứng minh bằng ví dụ.

### Câu hỏi
- Thứ tự ưu tiên của các cách truyền biến môi trường là gì?
- Làm sao để ẩn giá trị sensitive trong `docker-compose.yml`?

## Kết quả cần nộp
Nộp vào `devops-training/07-docker/lab-02-environment-variables/`:
- `Dockerfile` (nếu dùng), `docker-compose.yml`, `.env.example` (**không** commit `.env` thật có secret)
- `NOTES.md`: lệnh + output của từng cách, bảng kết quả thí nghiệm thứ tự ưu tiên, trả lời 2 câu hỏi trên

## Tiêu chí đạt
- [ ] Demo đủ 3 cách, mỗi cách có output chứng minh
- [ ] Có bảng thứ tự ưu tiên rút ra từ thí nghiệm thực tế (không chỉ chép tài liệu)
- [ ] Giải thích đúng sự khác nhau giữa `.env` (interpolation) và `env_file:`
- [ ] Đề xuất ít nhất 2 cách ẩn secret và nêu hạn chế của từng cách
- [ ] Không có secret thật trong bài nộp

## Câu hỏi tự kiểm tra

Tự trả lời các câu hỏi sau và ghi câu trả lời vào `NOTES.md`.
1. `docker inspect` một container có thấy biến môi trường không? Điều đó nói gì về việc truyền password qua env?
2. `ENV` trong Dockerfile khác `ARG` thế nào? Biến nào còn trong image sau khi build?
3. `${VAR:-default}` và `${VAR:?error}` trong compose nghĩa là gì?
4. Docker secrets (compose `secrets:`) đưa secret vào container dưới dạng gì? Ưu điểm so với env?
5. Vì sao `.env` phải nằm trong `.gitignore` còn `.env.example` thì commit?

<details>
<summary>Gợi ý</summary>

- `docker compose config` cho thấy file compose sau khi đã interpolate.
- Đọc mục "Environment variables precedence" trong tài liệu Compose.

</details>

## Tài liệu tham khảo
- https://docs.docker.com/compose/how-tos/environment-variables/
- https://docs.docker.com/compose/how-tos/environment-variables/envvars-precedence/
- https://docs.docker.com/compose/how-tos/use-secrets/
