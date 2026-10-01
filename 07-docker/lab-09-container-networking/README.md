# Lab 09 — Thiết lập network communication giữa các containers

> **Module:** 07 Docker

## Mục tiêu
- Cho các container giao tiếp với nhau qua network.
- Hiểu khác biệt default bridge và user-defined bridge, đặc biệt về DNS.

## Kiến thức cần có
- Network cơ bản (IP, DNS), `docker network`.

## Môi trường
- VM Ubuntu có Docker. Ngôn ngữ cho ping/pong tùy chọn (shell + `curl`/`nc`, Python, Node…).

## Yêu cầu
1. Tạo 2 containers: `ping` và `pong`
2. Container `ping` gửi HTTP request đến `pong` mỗi 5 giây
3. Container `pong` trả về response với timestamp
4. Log communication ở cả 2 containers (xem bằng `docker logs`)
5. Địa chỉ của `pong` truyền vào `ping` qua biến môi trường (VD `PONG_URL`).
6. `ping` không chết khi `pong` tạm thời không phản hồi: log lỗi và thử lại ở lần sau.

### Câu hỏi
- Thử với default bridge network
- Thử với custom network
- So sánh sự khác biệt (DNS resolution)

7. Thêm thí nghiệm: tạo network thứ 2, đặt một container `outsider` ở đó, chứng minh nó **không** gọi được `pong`. Sau đó `docker network connect` để nó gọi được.
8. Viết lại bằng `docker compose` và cho biết compose tạo network gì.

## Kết quả cần nộp
Nộp vào `devops-training/07-docker/lab-09-container-networking/`:
- Source/Dockerfile của `ping` và `pong`, `run-default-bridge.sh`, `run-custom-network.sh`, `docker-compose.yml`
- `NOTES.md`: log 2 phía, bảng so sánh default bridge vs custom network, kết quả thí nghiệm cô lập network

## Tiêu chí đạt
- [ ] Log 2 phía thể hiện request/response mỗi 5 giây có timestamp
- [ ] Trên default bridge: chứng minh không phân giải được tên `pong`, và chỉ ra cách (kém) để vẫn chạy được
- [ ] Trên custom network: gọi được bằng tên container
- [ ] `ping` sống sót khi `docker stop pong` rồi `start` lại
- [ ] Thí nghiệm `outsider` đúng như yêu cầu

## Câu hỏi tự kiểm tra

Tự trả lời các câu hỏi sau và ghi câu trả lời vào `NOTES.md`.
1. Vì sao default bridge không có DNS theo tên container? Ai làm DNS trên custom network (địa chỉ `127.0.0.11`)?
2. `--link` là gì và vì sao không nên dùng nữa?
3. IP của container có cố định không? Vì sao không nên hardcode IP?
4. Container trên 2 network khác nhau mặc định có nói chuyện được không? Cơ chế nào chặn?
5. `--network host` khác bridge thế nào? Khi đó `-p` còn tác dụng không?

<details>
<summary>Gợi ý</summary>

- Image `busybox`/`alpine` đã có `wget`, `nc`, `nslookup`.
- `docker network inspect bridge` để xem IP các container.
- `docker exec ping cat /etc/resolv.conf` trên 2 loại network.

</details>

## Tài liệu tham khảo
- https://docs.docker.com/engine/network/
- https://docs.docker.com/engine/network/drivers/bridge/
- https://docs.docker.com/compose/how-tos/networking/
