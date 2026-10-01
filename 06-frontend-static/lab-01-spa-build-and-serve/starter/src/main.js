import './style.css'

// API base URL. Defaults to same origin ('' → calls /api/...).
// Can be set at build time: VITE_API_BASE=https://api.example.com npm run build
const API_BASE = import.meta.env.VITE_API_BASE || ''

const app = document.querySelector('#app')

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[c])
}

async function renderEmployees() {
  app.innerHTML = '<h1>Employees</h1><p>Loading…</p>'
  try {
    const res = await fetch(`${API_BASE}/api/employees`)
    if (!res.ok) throw new Error(`HTTP ${res.status} ${res.statusText}`)
    const employees = await res.json()
    const rows = employees.map((e) => `
      <tr>
        <td>${escapeHtml(e.id)}</td>
        <td>${escapeHtml(e.full_name)}</td>
        <td>${escapeHtml(e.email)}</td>
        <td>${escapeHtml(e.department)}</td>
      </tr>`).join('')
    app.innerHTML = `
      <h1>Employees</h1>
      <table>
        <thead><tr><th>ID</th><th>Full name</th><th>Email</th><th>Department</th></tr></thead>
        <tbody>${rows}</tbody>
      </table>`
  } catch (err) {
    console.error('Failed to call API:', err)
    app.innerHTML = `<h1>Employees</h1>
      <p class="error">Error calling API: ${escapeHtml(err.message)}. Open DevTools (F12) → Console/Network for details.</p>`
  }
}

function renderAbout() {
  app.innerHTML = `
    <h1>About</h1>
    <p>This is a sub-page using client-side routing. Try pressing F5 on this page after deploying to Nginx.</p>
    <p>Built at: ${escapeHtml(__BUILD_TIME__)}</p>`
}

const routes = { '/': renderEmployees, '/about': renderAbout }

function render() {
  const view = routes[location.pathname]
  if (view) {
    view()
  } else {
    app.innerHTML = '<h1>404</h1><p>Page not found.</p>'
  }
}

document.addEventListener('click', (event) => {
  const link = event.target.closest('a[data-link]')
  if (!link) return
  event.preventDefault()
  history.pushState(null, '', link.getAttribute('href'))
  render()
})

window.addEventListener('popstate', render)
render()
