import express from 'express'
import cors from 'cors'
import initSqlJs from 'sql.js'
import { readFileSync, writeFileSync, existsSync } from 'fs'

const app = express()
app.use(cors())
app.use(express.json())

const DB_FILE = 'study_data.db'
let db

async function initDb() {
  const SQL = await initSqlJs()
  
  if (existsSync(DB_FILE)) {
    const buffer = readFileSync(DB_FILE)
    db = new SQL.Database(buffer)
  } else {
    db = new SQL.Database()
  }
  
  db.run(`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      name TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  `)
  db.run(`
    CREATE TABLE IF NOT EXISTS courses (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      name TEXT NOT NULL,
      subject TEXT NOT NULL,
      url_pattern TEXT
    )
  `)
  db.run(`
    CREATE TABLE IF NOT EXISTS study_logs (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      course_id TEXT NOT NULL,
      date TEXT NOT NULL,
      duration INTEGER NOT NULL,
      synced_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  `)
  db.run(`
    CREATE TABLE IF NOT EXISTS settings (
      user_id TEXT NOT NULL,
      key TEXT NOT NULL,
      value TEXT NOT NULL,
      PRIMARY KEY (user_id, key)
    )
  `)
  db.run(`CREATE INDEX IF NOT EXISTS idx_logs_user_date ON study_logs(user_id, date)`)
  saveDb()
}

function saveDb() {
  const data = db.export()
  writeFileSync(DB_FILE, Buffer.from(data))
}

function query(sql, params = []) {
  const stmt = db.prepare(sql)
  stmt.bind(params)
  const results = []
  while (stmt.step()) {
    results.push(stmt.getAsObject())
  }
  stmt.free()
  return results
}

function run(sql, params = []) {
  db.run(sql, params)
  saveDb()
}

function get(sql, params = []) {
  const results = query(sql, params)
  return results[0] || null
}

// 首页返回伪造的nginx 404
const fake404 = `<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx/1.24.0</center>
</body>
</html>`

app.get('/', (req, res) => {
  res.status(404).type('html').send(fake404)
})

app.post('/api/user', (req, res) => {
  const { userId, name } = req.body
  const existing = get('SELECT * FROM users WHERE id = ?', [userId])
  if (!existing) {
    run('INSERT INTO users (id, name) VALUES (?, ?)', [userId, name || 'User'])
  }
  res.json({ success: true, userId })
})

app.post('/api/sync', (req, res) => {
  const { userId, courses, studyLogs, settings } = req.body
  
  const existingUser = get('SELECT * FROM users WHERE id = ?', [userId])
  if (!existingUser) {
    run('INSERT INTO users (id, name) VALUES (?, ?)', [userId, 'User'])
  }
  
  const validCourseIds = new Set((courses || []).map(c => c.id))

  try {
    for (const c of courses || []) {
      run('INSERT OR REPLACE INTO courses (id, user_id, name, subject, url_pattern) VALUES (?, ?, ?, ?, ?)',
        [c.id, userId, c.name, c.subject, c.url_pattern])
    }
    for (const log of studyLogs || []) {
      if (validCourseIds.has(log.course_id)) {
        run('INSERT OR REPLACE INTO study_logs (id, user_id, course_id, date, duration) VALUES (?, ?, ?, ?, ?)',
          [log.id, userId, log.course_id, log.date, log.duration])
      }
    }
    for (const [key, value] of Object.entries(settings || {})) {
      if (value) run('INSERT OR REPLACE INTO settings (user_id, key, value) VALUES (?, ?, ?)', [userId, key, String(value)])
    }
    res.json({ success: true, synced: new Date().toISOString() })
  } catch (e) {
    console.error('Sync error:', e)
    res.status(500).json({ success: false, error: e.message })
  }
})

app.get('/api/data/:userId', (req, res) => {
  const { userId } = req.params
  const { startDate, endDate } = req.query
  
  const courses = query('SELECT * FROM courses WHERE user_id = ?', [userId])
  
  let logsQuery = 'SELECT * FROM study_logs WHERE user_id = ?'
  const params = [userId]
  if (startDate) { logsQuery += ' AND date >= ?'; params.push(startDate) }
  if (endDate) { logsQuery += ' AND date <= ?'; params.push(endDate) }
  logsQuery += ' ORDER BY date DESC'
  
  const studyLogs = query(logsQuery, params)
  const settingsRows = query('SELECT key, value FROM settings WHERE user_id = ?', [userId])
  
  res.json({
    courses,
    studyLogs,
    settings: Object.fromEntries(settingsRows.map(s => [s.key, s.value]))
  })
})

app.get('/api/stats/:userId', (req, res) => {
  const { userId } = req.params
  const { startDate, endDate } = req.query
  
  const start = startDate || '1970-01-01'
  const end = endDate || '2099-12-31'
  
  const today = new Date().toISOString().split('T')[0]
  const todayRow = get('SELECT COALESCE(SUM(duration), 0) as total FROM study_logs WHERE user_id = ? AND date = ?', [userId, today])
  const todayStudied = todayRow?.total || 0
  
  const courseStats = query(`
    SELECT c.id, c.name, c.subject, COALESCE(SUM(l.duration), 0) as duration
    FROM courses c
    LEFT JOIN study_logs l ON c.id = l.course_id AND l.date BETWEEN ? AND ?
    WHERE c.user_id = ?
    GROUP BY c.id
  `, [start, end, userId])
  
  const dailyStats = query(`
    SELECT date, SUM(duration) as duration FROM study_logs
    WHERE user_id = ? AND date BETWEEN ? AND ?
    GROUP BY date ORDER BY date DESC
  `, [userId, start, end])
  
  const settingsRows = query('SELECT key, value FROM settings WHERE user_id = ?', [userId])
  const settingsMap = Object.fromEntries(settingsRows.map(s => [s.key, s.value]))
  
  res.json({
    todayStudied,
    dailyGoal: parseInt(settingsMap.daily_goal) || 7200,
    examDate: settingsMap.exam_date || null,
    courseStats,
    dailyStats
  })
})

const PORT = process.env.PORT || 3000
const HOST = '0.0.0.0'

initDb().then(() => {
  app.listen(PORT, HOST, () => console.log(`API running on http://${HOST}:${PORT}`))
})


// 其他路径也返回伪造的nginx 404
app.use((req, res) => {
  res.status(404).type('html').send(fake404)
})
