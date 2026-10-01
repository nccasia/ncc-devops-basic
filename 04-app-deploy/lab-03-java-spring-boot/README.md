# Lab 03 — Deploy Java Spring Boot với systemd + Nginx

> **Module:** 04 Deploy App Server

## Mục tiêu
- Build ứng dụng Spring Boot thành fat jar bằng Maven.
- Chạy jar như systemd service với JVM options phù hợp tài nguyên máy.
- Externalized configuration qua biến môi trường, đặt Nginx phía trước.

## Kiến thức cần có
- Module 01, 02, 03. Java cơ bản.

## Môi trường
- Máy build: cài JDK 17 + Maven. Server vm2: chỉ cần **JRE** 17 (`openjdk-17-jre-headless`).
- vm1: PostgreSQL `trainingdb`.
- Source: [`starter/`](starter/) — `pom.xml`, `src/`, `app.env.example`. Config đọc env tại `src/main/resources/application.properties`.

## Yêu cầu
1. Build bằng `mvn clean package` (có thể chạy Maven trong container nếu không muốn cài). Xác định file jar output, giải thích vì sao jar chạy được độc lập (`unzip -l` để xem cấu trúc `BOOT-INF/`).
2. Chạy thử: `java -jar target/employees-api-1.0.0.jar` với env DB, `curl` được `/health` và `/api/employees`.
3. Trên vm2: cài JRE 17, tạo system user `springapp`, copy jar vào `/opt/springapp/employees-api.jar`.
4. Env file `/etc/springapp/springapp.env` chứa thông tin DB và `JAVA_OPTS` (VD `-Xms128m -Xmx256m`).
5. Viết systemd unit `springapp.service`: `User`, `EnvironmentFile`, `ExecStart=/usr/bin/java $JAVA_OPTS -jar ...`, `SuccessExitStatus=143`, `Restart=on-failure`.
6. Cấu hình Nginx `spring.training.local` → `127.0.0.1:8080`. Cấu hình Spring nhận header forward (`server.forward-headers-strategy`).
7. Đo tài nguyên: thời gian khởi động (log "Started ... in X seconds"), RSS memory (`ps -o rss`) với 2 mức `-Xmx` khác nhau. So sánh với app Flask/.NET nếu đã làm.
8. Thử `kill -9`, reboot, tắt DB như lab 01. Thử đặt `-Xmx` lớn hơn RAM VM và quan sát.
9. Chạy `../check.sh http://spring.training.local springapp 8080` trên vm2.

## Kết quả cần nộp
`devops-training/04-app-deploy/lab-03-java-spring-boot/`:
- `NOTES.md`: các bước, bảng đo startup time/memory, output `check.sh`, log `journalctl`
- `springapp.service`, `spring.training.local.conf`, `springapp.env.example`

## Tiêu chí đạt
- [ ] `check.sh` PASS toàn bộ
- [ ] Server chỉ cài JRE, không cài JDK/Maven
- [ ] JVM heap được giới hạn qua `JAVA_OPTS` trong env file
- [ ] `systemctl stop springapp` không bị đánh dấu `failed` (giải thích exit code 143)
- [ ] Không commit `target/`, không có password trong repo

## Câu hỏi tự kiểm tra
Tự trả lời và ghi câu trả lời vào `NOTES.md`.
1. JDK và JRE khác nhau thế nào? Vì sao server chỉ cần JRE?
2. Fat jar của Spring Boot khác jar thường thế nào? Tomcat nằm ở đâu?
3. Vì sao cần `SuccessExitStatus=143`? 143 = 128 + ? 
4. Heap, metaspace, stack — `-Xmx` có giới hạn toàn bộ bộ nhớ của JVM không?
5. Thứ tự ưu tiên externalized configuration của Spring Boot (properties file, env var, command line arg)? `SPRING_DATASOURCE_URL` ánh xạ thế nào?
6. HikariCP là gì? `maximum-pool-size` ảnh hưởng gì tới PostgreSQL `max_connections`?
7. Vì sao app Java khởi động chậm hơn Python/.NET? Có những cách nào cải thiện?

<details>
<summary>Gợi ý</summary>

- Build bằng container: `docker run --rm -v "$PWD":/src -w /src maven:3.9-eclipse-temurin-17 mvn -q clean package`
- Biến trong `ExecStart` của systemd: `$JAVA_OPTS` (không ngoặc) sẽ được tách thành nhiều đối số, `${JAVA_OPTS}` thì không.
- `server.forward-headers-strategy=native` hoặc `framework`.

</details>

## Tài liệu tham khảo
- https://docs.spring.io/spring-boot/reference/deployment/installing.html
- https://docs.spring.io/spring-boot/reference/features/external-config.html
- https://docs.spring.io/spring-boot/how-to/webserver.html#howto.webserver.use-behind-a-proxy-server
- https://github.com/brettwooldridge/HikariCP
