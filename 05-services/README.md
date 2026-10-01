# 05 — Services khác: Redis, RabbitMQ *(optional)*

> **Không bắt buộc** · **Môi trường:** vm1 (192.168.56.11) chạy Redis/RabbitMQ, vm2 (192.168.56.12) chạy app

Module này không bắt buộc để hoàn thành lộ trình, nhưng Redis và message queue xuất hiện trong hầu hết dự án thực tế. Nếu bạn còn thời gian sau module 04, hãy làm ít nhất lab Redis.

## Mục tiêu

- Cài đặt và bảo mật Redis: xác thực, giới hạn bind, persistence.
- Dùng Redis làm cache cho API, hiểu TTL và cache invalidation.
- Cài đặt RabbitMQ, quản lý vhost/user/permission, hiểu mô hình producer → exchange → queue → consumer.

## Lý thuyết cần tự học

- Redis: kiểu dữ liệu (string, hash, list, set, sorted set), TTL/`EXPIRE`, eviction policy (`maxmemory-policy`), persistence RDB vs AOF, ACL (Redis 6+), `protected-mode`
- Cache pattern: cache-aside, write-through, cache stampede, cache invalidation
- RabbitMQ: AMQP 0-9-1, exchange (direct, fanout, topic), queue, binding, routing key, ack/nack, durable queue, persistent message, prefetch
- Port: Redis `6379`, RabbitMQ AMQP `5672`, management UI `15672`

Tài liệu: https://redis.io/docs/latest/operate/oss_and_stack/management/ · https://www.rabbitmq.com/tutorials · https://www.rabbitmq.com/docs/access-control

## Danh sách lab

| Lab | Nội dung | Bắt buộc |
|-----|----------|----------|
| [lab-01-redis](lab-01-redis/README.md) | Cài đặt, bảo mật, persistence, cache cho Flask API | ⭐ |
| [lab-02-rabbitmq](lab-02-rabbitmq/README.md) | Cài đặt, vhost/user/permission, producer/consumer | ⭐ |

## Câu hỏi tự kiểm tra cuối module

Tự trả lời các câu dưới đây vào `devops-training/05-services/module-questions.md` sau khi xong các lab.

1. Vì sao Redis để mở ra Internet không có mật khẩu là một trong những sự cố bảo mật phổ biến nhất? Kẻ tấn công có thể làm gì?
2. RDB và AOF khác nhau thế nào? Mất điện đột ngột thì mỗi loại mất bao nhiêu dữ liệu?
3. Khi Redis đầy bộ nhớ thì chuyện gì xảy ra với từng `maxmemory-policy`?
4. Cache-aside hoạt động thế nào? Dữ liệu trong DB thay đổi thì cache xử lý ra sao?
5. Message queue giải quyết bài toán gì mà gọi HTTP trực tiếp giữa 2 service không giải quyết được?
6. Consumer chết giữa chừng khi đang xử lý message — message có mất không? Phụ thuộc vào cấu hình nào?
7. Vì sao nên xóa/vô hiệu user `guest` của RabbitMQ?

## Bài tự luyện debug (break & fix)

Tự làm hỏng từng điểm, quan sát, chẩn đoán và sửa. Ghi vào `devops-training/05-services/break-and-fix.md` theo bảng: **Kịch bản → Triệu chứng → Cách chẩn đoán → Nguyên nhân → Cách sửa**.

- Đổi password Redis nhưng không cập nhật env file của app — API phản ứng thế nào? App nên xử lý lỗi cache ra sao để API vẫn chạy?
- Đặt `bind 127.0.0.1` trên Redis rồi kết nối từ vm2.
- Đặt `maxmemory 1mb` + `maxmemory-policy noeviction` rồi ghi dữ liệu liên tục.
- Xóa permission của user app trên vhost RabbitMQ rồi chạy producer.
- Chạy consumer với `auto_ack=True`, kill consumer giữa chừng — đếm số message bị mất.
