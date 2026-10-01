# Lab 03 — Debug lỗi liên quan đến biến môi trường

> **Module:** 07 Docker

## Mục tiêu
- Đọc và debug file compose có lỗi cấu hình biến môi trường.
- Hiểu cú pháp list vs map của `environment:`, cách Compose interpolate biến, DNS giữa các service.

## Kiến thức cần có
- Lab 02.

## Môi trường
- File lỗi: [`starter/docker-compose.yml`](starter/docker-compose.yml).

## Trường hợp
Bây giờ anh có file `docker-compose.yml` sau nhưng ứng dụng không nhận được giá trị biến môi trường đúng:

```yaml
version: '3.8'
services:
  app:
    image: node:18-alpine
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/mydb
      - API_KEY=${API_KEY}
      - DEBUG_MODE=true
      - SECRET_KEY="my-secret-key"
      - REDIS_URL=redis://cache:6379
    command: node -e "console.log(process.env)"
```

### Vấn đề cần tìm
1. Tại sao `API_KEY` luôn rỗng?
2. Tại sao `SECRET_KEY` có dấu ngoặc kép trong giá trị?
3. Service `db` và `cache` chưa được định nghĩa - điều gì sẽ xảy ra?

## Yêu cầu
1. Chạy file gốc, quan sát output và warning của Compose. Ghi lại.
2. Trả lời 3 câu hỏi trên, mỗi câu kèm bằng chứng (output, lệnh kiểm tra).
3. Sửa file `docker-compose.yml` để hoạt động đúng:
   - `API_KEY` nhận giá trị từ nguồn bên ngoài file compose, và Compose **báo lỗi rõ ràng** nếu thiếu.
   - `SECRET_KEY` không dính dấu ngoặc kép, không hardcode trong file.
   - Định nghĩa `db` (PostgreSQL) và `cache` (Redis); app chỉ start khi chúng sẵn sàng.
   - Bỏ những thứ đã obsolete.
4. Chứng minh app thực sự **kết nối** được tới `db` và `cache` bằng hostname trong URL (không chỉ in env).

## Kết quả cần nộp
Nộp vào `devops-training/07-docker/lab-03-debug-env-vars/`:
- `docker-compose.yml` đã sửa, `.env.example`
- `NOTES.md`: output trước khi sửa, phân tích từng nguyên nhân, output sau khi sửa

## Tiêu chí đạt
- [ ] Giải thích đúng nguyên nhân của cả 3 vấn đề, có bằng chứng
- [ ] Chạy `docker compose up` thiếu `API_KEY` → lỗi rõ ràng thay vì chạy với giá trị rỗng
- [ ] Output env sau khi sửa: `SECRET_KEY` không có dấu `"`
- [ ] Từ container `app`, kết nối được tới `db:5432` và `cache:6379`
- [ ] Không còn warning từ Compose

## Câu hỏi tự kiểm tra

Tự trả lời các câu hỏi sau và ghi câu trả lời vào `NOTES.md`.
1. Biến `${VAR}` trong compose được thay giá trị **lúc nào** và **ở đâu** (host hay container)?
2. Cú pháp list `- KEY="value"` và map `KEY: "value"` xử lý dấu ngoặc kép khác nhau thế nào?
3. Nếu hostname `db` không tồn tại, lỗi sẽ xuất hiện lúc `docker compose up` hay lúc app kết nối? Vì sao?
4. `$$` trong compose dùng để làm gì?

<details>
<summary>Gợi ý</summary>

- `docker compose config` là công cụ đầu tiên nên chạy khi debug compose.
- Đọc kỹ warning Compose in ra khi `up`.
- Thử `nslookup`/`getent hosts` từ trong container.

</details>

## Tài liệu tham khảo
- https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/
- https://docs.docker.com/reference/compose-file/services/#environment
