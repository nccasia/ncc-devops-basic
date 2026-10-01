# Employees FE — app mẫu (Vite, vanilla JS)

App tối giản để luyện build & deploy, không phụ thuộc framework:

- `/` — gọi `GET /api/employees` và hiển thị bảng
- `/about` — trang con dùng client-side routing (History API) để thử SPA fallback

## Chạy

```bash
npm install       # first time: generates package-lock.json (commit the lock file with your work)
npm ci            # later runs / on CI: install exact versions from the lock file
npm run dev       # dev server http://localhost:5173, proxy /api -> http://127.0.0.1:5000
npm run build     # output: dist/
npm run preview   # preview the production build
```

Đổi backend cho dev server: `API_TARGET=http://192.168.56.12 npm run dev`.

## Muốn dùng framework thật?

Tạo app mới và làm theo cùng yêu cầu của lab (gọi `/api/employees`, có ít nhất 2 route):

```bash
npm create vite@latest my-fe -- --template react   # or vue, svelte...
# Angular: npx @angular/cli new my-fe
```

React/Vue cần thêm router (`react-router`, `vue-router`) để có route `/about`.
