use crate::{Course, CourseStat, DailyStat, Statistics, StudyLog};
use rusqlite::{Connection, params};
use uuid::Uuid;

pub struct Database {
    conn: Connection,
}

impl Database {
    pub fn new() -> Result<Self, rusqlite::Error> {
        let conn = Connection::open("study_monitor.db")?;
        
        conn.execute(
            "CREATE TABLE IF NOT EXISTS courses (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                subject TEXT NOT NULL,
                url_pattern TEXT NOT NULL
            )",
            [],
        )?;

        conn.execute(
            "CREATE TABLE IF NOT EXISTS study_logs (
                id TEXT PRIMARY KEY,
                course_id TEXT NOT NULL,
                date TEXT NOT NULL,
                duration INTEGER NOT NULL,
                FOREIGN KEY (course_id) REFERENCES courses(id)
            )",
            [],
        )?;

        conn.execute(
            "CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            )",
            [],
        )?;

        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_logs_date ON study_logs(date)",
            [],
        )?;

        Ok(Self { conn })
    }

    pub fn get_courses(&self) -> Vec<Course> {
        let mut stmt = self.conn
            .prepare("SELECT id, name, subject, url_pattern FROM courses")
            .unwrap();
        
        stmt.query_map([], |row| {
            Ok(Course {
                id: row.get(0)?,
                name: row.get(1)?,
                subject: row.get(2)?,
                url_pattern: row.get(3)?,
            })
        })
        .unwrap()
        .filter_map(|r| r.ok())
        .collect()
    }

    pub fn get_course(&self, id: &str) -> Option<Course> {
        self.conn
            .query_row(
                "SELECT id, name, subject, url_pattern FROM courses WHERE id = ?",
                [id],
                |row| {
                    Ok(Course {
                        id: row.get(0)?,
                        name: row.get(1)?,
                        subject: row.get(2)?,
                        url_pattern: row.get(3)?,
                    })
                },
            )
            .ok()
    }

    pub fn add_course(&self, name: &str, subject: &str, url_pattern: &str) {
        let id = Uuid::new_v4().to_string();
        self.conn
            .execute(
                "INSERT INTO courses (id, name, subject, url_pattern) VALUES (?, ?, ?, ?)",
                params![id, name, subject, url_pattern],
            )
            .unwrap();
    }

    pub fn update_course(&self, id: &str, name: &str, subject: &str, url_pattern: &str) {
        self.conn
            .execute(
                "UPDATE courses SET name = ?, subject = ?, url_pattern = ? WHERE id = ?",
                params![name, subject, url_pattern, id],
            )
            .unwrap();
    }

    pub fn delete_course(&self, id: &str) {
        self.conn.execute("DELETE FROM courses WHERE id = ?", [id]).unwrap();
        self.conn.execute("DELETE FROM study_logs WHERE course_id = ?", [id]).unwrap();
    }

    pub fn get_daily_goal(&self) -> i64 {
        self.conn
            .query_row(
                "SELECT value FROM settings WHERE key = 'daily_goal'",
                [],
                |row| row.get::<_, String>(0),
            )
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(7200) // 默认 2 小时
    }

    pub fn set_daily_goal(&self, seconds: i64) {
        self.conn
            .execute(
                "INSERT OR REPLACE INTO settings (key, value) VALUES ('daily_goal', ?)",
                [seconds.to_string()],
            )
            .unwrap();
    }

    pub fn get_studied_duration(&self, date: &str) -> i64 {
        self.conn
            .query_row(
                "SELECT COALESCE(SUM(duration), 0) FROM study_logs WHERE date = ?",
                [date],
                |row| row.get(0),
            )
            .unwrap_or(0)
    }

    pub fn add_study_log(&self, course_id: &str, date: &str, duration: i64) {
        // 先检查课程是否存在
        let course_exists: bool = self.conn
            .query_row(
                "SELECT 1 FROM courses WHERE id = ?",
                [course_id],
                |_| Ok(true),
            )
            .unwrap_or(false);

        if !course_exists {
            return; // 课程不存在，跳过记录
        }

        // 尝试更新现有记录
        let updated = self.conn
            .execute(
                "UPDATE study_logs SET duration = duration + ? WHERE course_id = ? AND date = ?",
                params![duration, course_id, date],
            )
            .unwrap_or(0);

        // 如果没有更新到记录，插入新记录
        if updated == 0 {
            let id = Uuid::new_v4().to_string();
            let _ = self.conn
                .execute(
                    "INSERT INTO study_logs (id, course_id, date, duration) VALUES (?, ?, ?, ?)",
                    params![id, course_id, date, duration],
                );
        }
    }


    pub fn get_statistics(
        &self,
        start_date: Option<String>,
        end_date: Option<String>,
        subject: Option<String>,
    ) -> Statistics {
        let start = start_date.unwrap_or_else(|| "1970-01-01".to_string());
        let end = end_date.unwrap_or_else(|| "2099-12-31".to_string());

        // 获取所有科目
        let mut subjects: Vec<String> = self.conn
            .prepare("SELECT DISTINCT subject FROM courses")
            .unwrap()
            .query_map([], |row| row.get(0))
            .unwrap()
            .filter_map(|r: Result<String, _>| r.ok())
            .collect();
        subjects.sort();

        // 按课程统计
        let rows: Vec<(String, String, String, i64)> = if let Some(ref subj) = subject {
            let mut stmt = self.conn.prepare(
                "SELECT c.id, c.name, c.subject, COALESCE(SUM(l.duration), 0) as total
                 FROM courses c
                 LEFT JOIN study_logs l ON c.id = l.course_id AND l.date BETWEEN ?1 AND ?2
                 WHERE c.subject = ?3
                 GROUP BY c.id"
            ).unwrap();
            stmt.query_map(params![&start, &end, subj], |row| {
                Ok((row.get(0)?, row.get(1)?, row.get(2)?, row.get(3)?))
            })
            .unwrap()
            .filter_map(|r: Result<(String, String, String, i64), _>| r.ok())
            .collect()
        } else {
            let mut stmt = self.conn.prepare(
                "SELECT c.id, c.name, c.subject, COALESCE(SUM(l.duration), 0) as total
                 FROM courses c
                 LEFT JOIN study_logs l ON c.id = l.course_id AND l.date BETWEEN ?1 AND ?2
                 GROUP BY c.id"
            ).unwrap();
            stmt.query_map(params![&start, &end], |row| {
                Ok((row.get(0)?, row.get(1)?, row.get(2)?, row.get(3)?))
            })
            .unwrap()
            .filter_map(|r: Result<(String, String, String, i64), _>| r.ok())
            .collect()
        };

        let total: i64 = rows.iter().map(|r| r.3).sum();
        let course_stats: Vec<CourseStat> = rows
            .into_iter()
            .filter(|r| r.3 > 0)
            .map(|(id, name, subj, duration)| CourseStat {
                course_id: id,
                course_name: name,
                subject: subj,
                duration,
                percent: if total > 0 { (duration as f64 / total as f64) * 100.0 } else { 0.0 },
            })
            .collect();

        // 按日期统计
        let daily_goal = self.get_daily_goal();
        let daily_stats: Vec<DailyStat> = if let Some(ref subj) = subject {
            let mut stmt = self.conn.prepare(
                "SELECT l.date, SUM(l.duration) as total
                 FROM study_logs l
                 JOIN courses c ON l.course_id = c.id
                 WHERE l.date BETWEEN ?1 AND ?2 AND c.subject = ?3
                 GROUP BY l.date
                 ORDER BY l.date DESC"
            ).unwrap();
            stmt.query_map(params![&start, &end, subj], |row| {
                let duration: i64 = row.get(1)?;
                Ok(DailyStat {
                    date: row.get(0)?,
                    duration,
                    goal_met: duration >= daily_goal,
                })
            })
            .unwrap()
            .filter_map(|r: Result<DailyStat, _>| r.ok())
            .collect()
        } else {
            let mut stmt = self.conn.prepare(
                "SELECT date, SUM(duration) as total
                 FROM study_logs
                 WHERE date BETWEEN ?1 AND ?2
                 GROUP BY date
                 ORDER BY date DESC"
            ).unwrap();
            stmt.query_map(params![&start, &end], |row| {
                let duration: i64 = row.get(1)?;
                Ok(DailyStat {
                    date: row.get(0)?,
                    duration,
                    goal_met: duration >= daily_goal,
                })
            })
            .unwrap()
            .filter_map(|r: Result<DailyStat, _>| r.ok())
            .collect()
        };

        Statistics {
            subjects,
            course_stats,
            daily_stats,
        }
    }

    pub fn get_exam_date(&self) -> Option<String> {
        self.conn
            .query_row(
                "SELECT value FROM settings WHERE key = 'exam_date'",
                [],
                |row| row.get::<_, String>(0),
            )
            .ok()
    }

    pub fn set_exam_date(&self, date: &str) {
        self.conn
            .execute(
                "INSERT OR REPLACE INTO settings (key, value) VALUES ('exam_date', ?)",
                [date],
            )
            .unwrap();
    }

    pub fn get_setting(&self, key: &str) -> Option<String> {
        self.conn
            .query_row(
                "SELECT value FROM settings WHERE key = ?",
                [key],
                |row| row.get::<_, String>(0),
            )
            .ok()
    }

    pub fn set_setting(&self, key: &str, value: &str) {
        self.conn
            .execute(
                "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)",
                params![key, value],
            )
            .unwrap();
    }

    pub fn get_all_study_logs(&self) -> Vec<StudyLog> {
        let mut stmt = self.conn
            .prepare("SELECT id, course_id, date, duration FROM study_logs")
            .unwrap();
        
        stmt.query_map([], |row| {
            Ok(StudyLog {
                id: row.get(0)?,
                course_id: row.get(1)?,
                date: row.get(2)?,
                duration: row.get(3)?,
            })
        })
        .unwrap()
        .filter_map(|r| r.ok())
        .collect()
    }
}
