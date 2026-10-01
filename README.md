# NCC DevOps Basic — Bộ bài tập training cho Intern DevOps

Bộ bài tập thực hành đi kèm lộ trình **DevOps Training**.
Mỗi module gồm phần lý thuyết cần tự học, các lab có tiêu chí đạt rõ ràng, câu hỏi tự kiểm tra và bài tự luyện debug. **Hoàn thành module trước rồi mới chuyển sang module sau.**

> Trước khi bắt đầu, bắt buộc đọc [00-onboarding](00-onboarding/README.md): tư duy làm việc, thói quen làm việc an toàn và quy trình làm & nộp bài.

## Lộ trình

| # | Module | Nội dung chính |
|---|--------|----------------|
| 00 | [Onboarding](00-onboarding/README.md) | Thói quen làm việc an toàn, Git, cách nộp bài |
| 01 | [Linux Foundation](01-linux/README.md) | Command, user/group, permission, ACL, Bash script, network cơ bản, service |
| 02 | [Database](02-database/README.md) | PostgreSQL/MySQL: cài đặt, user & quyền, remote access, giới hạn theo IP, backup |
| 03 | [Nginx](03-nginx/README.md) | Static site, virtual host, reverse proxy, HTTPS self-signed |
| 04 | [Deploy App Server](04-app-deploy/README.md) | Python Flask, .NET, Java Spring Boot với systemd + Nginx |
| 05 | [Services khác](05-services/README.md) *(optional)* | Redis, RabbitMQ |
| 06 | [Frontend Static](06-frontend-static/README.md) | Build & deploy React/Vue/Angular, SPA routing |
| 07 | [Docker](07-docker/README.md) | Dockerfile, docker compose, network, debug, tối ưu image |
| 08 | [CI/CD](08-cicd/README.md) | Jenkins, GitHub Actions, pipeline build-test-deploy |
| 09 | [Capstone](09-capstone/README.md) | BE + FE + DB, deploy 2 cách, HTTPS, Jenkins, versioning & rollback |

Tự sắp xếp tiến độ theo khả năng của bạn. Lab đánh dấu ⭐ là bài nâng cao, không bắt buộc.

## Cấu trúc repo

```
ncc-devops-basic/
├── 00-onboarding/        # Thói quen làm việc, Git, quy trình nộp bài
├── 01-linux/ … 09-capstone/
│   ├── README.md         # Mục tiêu module, lý thuyết cần học, danh sách lab, câu hỏi tự kiểm tra
│   └── lab-XX-<tên>/
│       ├── README.md     # Đề bài theo template chung
│       ├── starter/      # (nếu có) file khởi đầu / file lỗi cần debug
│       └── check.sh      # (nếu có) script tự kiểm tra kết quả
├── lab-env/              # Vagrantfile dựng VM lab (vm1, vm2, vm3) cho VirtualBox, VMware, Hyper-V
└── docs/                 # Template lab, tiêu chuẩn bài đạt
```

## Cách làm bài

Repo này chỉ chứa đề bài: bạn **clone về để đọc**, không push vào đây. Bài làm nằm trong **repo cá nhân** của bạn — xem [quy trình làm & nộp bài](00-onboarding/submission.md).

1. Clone repo này và tạo repo cá nhân `devops-training`.
2. Dựng môi trường lab: [lab-env/README.md](lab-env/README.md) (Vagrant với VirtualBox / VMware / Hyper-V, hoặc VM cloud được cấp).
3. Đọc README của module → tự học phần lý thuyết → làm lần lượt các lab.
4. Mỗi lab: làm theo **Yêu cầu**, tự kiểm tra bằng **Tiêu chí đạt** (và `check.sh` nếu có).
5. Tự trả lời **Câu hỏi tự kiểm tra**, rà lại bài theo [tiêu chuẩn bài đạt](docs/definition-of-done.md).
6. Push bài vào repo cá nhân, tạo Pull Request trong repo đó và mời mentor review.
7. Hết module: làm **Bài tự luyện debug (break & fix)** trong README module để chắc chắn đã nắm vững.
