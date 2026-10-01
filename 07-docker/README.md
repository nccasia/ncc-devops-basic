# 07 — Docker

> **Điều kiện:** đã pass module 01–06

## Mục tiêu

Sau module này bạn sẽ:
- Hiểu bản chất image, container, layer và cách Docker cô lập process (namespace, cgroup).
- Viết được `Dockerfile` gọn, an toàn, tận dụng cache; viết `docker-compose.yml` cho ứng dụng nhiều service.
- Biết dùng volume, network, biến môi trường đúng cách.
- Tự debug được container không chạy / không truy cập được / sai cấu hình.
- Đóng gói được ứng dụng 3 tầng (FE + BE + DB) bằng Docker — chuẩn bị cho capstone.

## Lý thuyết tự học

| Chủ đề | Nội dung cần nắm |
|--------|------------------|
| Khái niệm | Container vs VM, namespace, cgroup, Docker Engine / containerd / runc, OCI image |
| Image & layer | Layer read-only, union filesystem (overlay2), container layer (read-write), tag vs digest |
| Dockerfile | `FROM`, `RUN`, `COPY` vs `ADD`, `WORKDIR`, `ENV` vs `ARG`, `EXPOSE`, `USER`, `CMD` vs `ENTRYPOINT`, `HEALTHCHECK`, build cache, multi-stage build |
| Container lifecycle | `run`, `start/stop/kill`, `rm`, restart policy, `exec`, `logs`, `inspect`, exit code |
| Storage | Volume vs bind mount vs tmpfs, dữ liệu mất khi nào |
| Network | bridge mặc định vs user-defined bridge, host, none; DNS nội bộ; publish port (`-p`) |
| Compose | services, networks, volumes, `depends_on` + `condition`, healthcheck, `.env` và biến interpolation, profiles. Trường `version:` **đã obsolete** trong Compose v2 — không cần khai báo |
| Registry | Docker Hub, private registry, `login/tag/push/pull`, `save/load` |
| Bảo mật cơ bản | Chạy bằng **non-root user**, `.dockerignore`, **không bake secret** vào image (kể cả qua `ARG`/`ENV`), pin version base image, image tối thiểu, quét lỗ hổng (`docker scout`, `trivy`) |

Tài liệu:
- https://docs.docker.com/get-started/
- https://docs.docker.com/reference/dockerfile/
- https://docs.docker.com/build/building/best-practices/
- https://docs.docker.com/compose/
- https://github.com/MichaelCade/90DaysOfDevOps/blob/main/2022.md#containers

## Cài Docker Engine trên Ubuntu

Cài theo tài liệu chính thức (không dùng gói `docker.io` cũ của Ubuntu): https://docs.docker.com/engine/install/ubuntu/

```bash
# After installing, allow the current user to run docker without sudo
sudo usermod -aG docker $USER
newgrp docker

docker version
docker compose version   # Compose v2 is a plugin: "docker compose", not "docker-compose"
docker run --rm hello-world
```

> Lưu ý: thêm user vào group `docker` tương đương cấp quyền root trên máy — hãy tự tìm hiểu vì sao (câu 10 bên dưới).

## Danh sách lab

| Lab | Nội dung |
|-----|----------|
| [lab-01-compose-nodejs](lab-01-compose-nodejs/README.md) | Dockerfile + compose cho Express, Redis, Mongo |
| [lab-02-environment-variables](lab-02-environment-variables/README.md) | 3 cách truyền biến môi trường, thứ tự ưu tiên |
| [lab-03-debug-env-vars](lab-03-debug-env-vars/README.md) | Debug compose sai biến môi trường |
| [lab-04-debug-network-binding](lab-04-debug-network-binding/README.md) | Debug app chạy nhưng không truy cập được |
| [lab-05-image-export](lab-05-image-export/README.md) | `save/load` vs `export/import` |
| [lab-06-container-naming](lab-06-container-naming/README.md) | Xử lý conflict tên container |
| [lab-07-copy-files-into-container](lab-07-copy-files-into-container/README.md) | `docker cp`, persist dữ liệu |
| [lab-08-image-metadata](lab-08-image-metadata/README.md) | Lấy metadata image ra JSON |
| [lab-09-container-networking](lab-09-container-networking/README.md) | Ping/pong giữa container, DNS |
| [lab-10-inspect](lab-10-inspect/README.md) | `docker inspect --format` |
| [lab-11-extract-layers](lab-11-extract-layers/README.md) | Bóc tách layer của image |
| [lab-12-containers-in-pipelines](lab-12-containers-in-pipelines/README.md) | Build/test/package/push bằng container |
| [lab-13-cmd-vs-entrypoint](lab-13-cmd-vs-entrypoint/README.md) | CMD vs ENTRYPOINT |
| [lab-14-logs-events-history](lab-14-logs-events-history/README.md) | Logs, events, history, alert container crash |
| [lab-15-image-optimization](lab-15-image-optimization/README.md) | Tối ưu image < 10MB |
| [lab-16-dockerize-3-tier](lab-16-dockerize-3-tier/README.md) | Dockerize FE + BE + PostgreSQL + Nginx (**bắt buộc**, cầu nối capstone) |

## Câu hỏi tự kiểm tra cuối module

Tự trả lời trước khi tạo PR cuối module; ghi câu trả lời vào `devops-training/07-docker/NOTES.md`.

1. Container khác VM ở đâu? Container có kernel riêng không? Vì sao image Linux không chạy "native" trên Windows?
2. Image layer được tạo bởi những instruction nào? Vì sao thứ tự `COPY package*.json` → `RUN npm install` → `COPY . .` giúp build nhanh hơn?
3. Xóa file ở một `RUN` sau có làm image nhỏ đi không? Vì sao?
4. `CMD` vs `ENTRYPOINT`, dạng shell vs exec form — ảnh hưởng thế nào tới việc nhận signal `SIGTERM` khi `docker stop`?
5. `ARG` vs `ENV`? Vì sao truyền secret qua `ARG` vẫn bị lộ? Cách đúng để dùng secret lúc build?
6. Volume vs bind mount: khi nào dùng cái nào? `docker compose down -v` làm gì?
7. Vì sao container trên default bridge không gọi nhau bằng tên được, còn trên user-defined network thì được?
8. `-p 8080:80` và `-p 127.0.0.1:8080:80` khác gì? Docker publish port có bỏ qua `ufw` không?
9. `depends_on` có đảm bảo database đã sẵn sàng nhận kết nối không? Làm sao để đảm bảo?
10. Vì sao nên chạy container bằng non-root user? Thêm user vào group `docker` có rủi ro gì?
11. Container restart thì dữ liệu trong container layer còn không? `docker rm` thì sao?
12. Tag `latest` có nghĩa là "mới nhất" không? Vì sao production nên pin version/digest?

## Bài tự luyện debug (break & fix)

Sau khi stack của [lab-16](lab-16-dockerize-3-tier/README.md) chạy ổn, bạn tự cố tình làm hỏng từng thứ một, rồi tự chẩn đoán và sửa **như thể không biết mình đã làm gì**: đọc triệu chứng, dùng `docker compose ps/logs`, `docker inspect`, `docker exec` để khoanh vùng. Mỗi lần ghi lại vào `NOTES.md` theo mẫu **Triệu chứng → Cách chẩn đoán → Nguyên nhân → Cách sửa**.

Gợi ý các kiểu làm hỏng:
- Đổi app sang bind `127.0.0.1` bên trong container.
- Đổi tên service trong connection string (VD `DB_HOST=postgres` trong khi service tên `db`), hoặc đưa 2 service sang 2 network khác nhau.
- Mount volume DB sai đường dẫn rồi `down`/`up` lại — dữ liệu còn không?
- Xóa `.dockerignore`, để `node_modules` của host lọt vào image.
- Mount một file từ host thuộc `root` với quyền `600` vào container chạy non-root.
- Đổi healthcheck sang dùng một lệnh không có trong image (VD `curl` trong image không cài `curl`).
- Làm đầy disk bằng log/image thừa, rồi tìm thủ phạm bằng `docker system df` và cấu hình log rotation.

> Cách luyện hiệu quả hơn: nhờ một intern khác làm hỏng giúp bạn mà không nói đã sửa gì.
