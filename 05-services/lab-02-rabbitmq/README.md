# Lab 02 ⭐ — RabbitMQ: cài đặt, phân quyền, producer/consumer

> **Module:** 05 Services · **Không bắt buộc**

## Mục tiêu
- Cài đặt RabbitMQ, bật management UI.
- Quản lý vhost, user, permission theo nguyên tắc quyền tối thiểu.
- Chạy producer/consumer, hiểu exchange, queue, routing key, ack và durability.

## Kiến thức cần có
- Linux, systemd, Python cơ bản.

## Môi trường
- vm1 (`192.168.56.11`): RabbitMQ. vm2 (`192.168.56.12`): chạy producer/consumer.
- Script mẫu: [`starter/`](starter/) — `producer.py`, `consumer.py`, `requirements.txt`.

## Yêu cầu

### Phần A — Cài đặt & quản trị
1. Cài RabbitMQ (repo chính thức hoặc repo Ubuntu), chạy bằng systemd. Bật plugin `rabbitmq_management`.
2. Truy cập management UI tại `http://192.168.56.11:15672` từ máy host. User `guest` mặc định chỉ đăng nhập được từ localhost — giải thích vì sao.
3. Tạo user `admin` (tag `administrator`) để dùng UI, sau đó **xóa user `guest`**.
4. Tạo vhost `/training`. Tạo user `orders_app` chỉ có quyền trên vhost `/training`: configure/write/read giới hạn với tài nguyên có tên bắt đầu bằng `orders` (regex).
5. Firewall trên vm1: port `5672` chỉ cho vm2, port `15672` chỉ cho máy host.

### Phần B — Producer/Consumer
6. Trên vm2, chạy `starter/consumer.py` và `starter/producer.py` với thông tin kết nối qua biến môi trường. Gửi 10 message, quan sát trên UI (Queues → `orders.created`: Ready, Unacked, message rate).
7. Chạy 2 consumer song song, gửi 20 message — message được chia thế nào? Thử thay đổi `prefetch_count` và quan sát.
8. Durability: dừng consumer, gửi 5 message, `systemctl restart rabbitmq-server` → message còn không? Sửa producer/queue để message không mất sau restart (durable queue + persistent message).
9. Ack: sửa consumer để giả lập lỗi (VD message có `"fail": true` thì không ack, hoặc `basic_nack` với `requeue=False`). ⭐ Cấu hình dead-letter exchange `orders.dlx` để message lỗi đi vào queue `orders.dead`.
10. ⭐ Chạy consumer như systemd service (user riêng, `Restart=on-failure`, env file).

## Kết quả cần nộp
`devops-training/05-services/lab-02-rabbitmq/`:
- `NOTES.md`: các bước, output `rabbitmqctl list_users`, `list_permissions -p /training`, ảnh chụp UI, kết quả thí nghiệm bước 7–9
- `producer.py`, `consumer.py` đã sửa, (nếu có) unit file consumer

## Tiêu chí đạt
- [ ] User `guest` đã bị xóa, UI đăng nhập bằng user riêng
- [ ] `orders_app` không tạo được queue tên `payments` (bị `ACCESS_REFUSED`)
- [ ] Message không mất sau khi restart RabbitMQ
- [ ] Giải thích được phân phối message giữa nhiều consumer và tác dụng của `prefetch_count`
- [ ] Không hardcode password trong script

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. Exchange, queue, binding, routing key là gì? Producer gửi message vào đâu?
2. Direct, fanout, topic exchange khác nhau thế nào? Default exchange (`""`) hoạt động ra sao?
3. Durable queue và persistent message — cần cả hai hay một là đủ?
4. `auto_ack=True` nguy hiểm thế nào? Khi nào message bị giao lại (redelivered)?
5. `prefetch_count=1` ảnh hưởng thế nào tới thông lượng và độ công bằng?
6. Vhost dùng để làm gì? So sánh với việc dùng nhiều instance RabbitMQ riêng.
7. Ba quyền configure/write/read của RabbitMQ áp dụng cho thao tác nào?

<details>
<summary>Gợi ý</summary>

- `rabbitmq-plugins enable rabbitmq_management`
- `rabbitmqctl add_vhost`, `add_user`, `set_permissions -p <vhost> <user> <conf> <write> <read>`, `set_user_tags`.
- Quyền tối thiểu cho producer/consumer dùng default exchange vẫn cần quyền với exchange `amq.default` — đọc kỹ bảng quyền trong tài liệu access control.
- Persistent message trong `pika`: `pika.BasicProperties(delivery_mode=pika.DeliveryMode.Persistent)`.

</details>

## Tài liệu tham khảo
- https://www.rabbitmq.com/docs/install-debian
- https://www.rabbitmq.com/docs/access-control
- https://www.rabbitmq.com/tutorials/tutorial-two-python
- https://www.rabbitmq.com/docs/dlx
- https://pika.readthedocs.io/
