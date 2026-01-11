#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod db;
mod http_server;

use db::Database;
use parking_lot::Mutex;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tauri::{
    CustomMenuItem, Manager, SystemTray, SystemTrayEvent, SystemTrayMenu, SystemTrayMenuItem,
};
use std::time::Duration;

#[derive(Clone, Serialize, Deserialize)]
pub struct Course {
    pub id: String,
    pub name: String,
    pub subject: String,
    pub url_pattern: String,
}

#[derive(Clone, Serialize, Deserialize)]
pub struct StudyLog {
    pub id: String,
    pub course_id: String,
    pub date: String,
    pub duration: i64,
}

#[derive(Clone, Serialize, Deserialize)]
pub struct CurrentSession {
    pub course_name: String,
    pub duration: i64,
}

#[derive(Clone, Serialize, Deserialize)]
pub struct CourseStat {
    pub course_id: String,
    pub course_name: String,
    pub subject: String,
    pub duration: i64,
    pub percent: f64,
}

#[derive(Clone, Serialize, Deserialize)]
pub struct DailyStat {
    pub date: String,
    pub duration: i64,
    pub goal_met: bool,
}

#[derive(Clone, Serialize, Deserialize)]
pub struct Statistics {
    pub subjects: Vec<String>,
    pub course_stats: Vec<CourseStat>,
    pub daily_stats: Vec<DailyStat>,
}

pub struct AppState {
    pub db: Database,
    pub current_course_id: Option<String>,
    pub session_start: Option<i64>,
    pub last_report_time: Option<i64>,
}

type SharedState = Arc<Mutex<AppState>>;

#[tauri::command]
fn get_courses(state: tauri::State<SharedState>) -> Vec<Course> {
    state.lock().db.get_courses()
}

#[tauri::command]
#[allow(non_snake_case)]
fn add_course(state: tauri::State<SharedState>, name: String, subject: String, urlPattern: String) {
    state.lock().db.add_course(&name, &subject, &urlPattern);
}

#[tauri::command]
#[allow(non_snake_case)]
fn update_course(state: tauri::State<SharedState>, id: String, name: String, subject: String, urlPattern: String) {
    state.lock().db.update_course(&id, &name, &subject, &urlPattern);
}

#[tauri::command]
fn delete_course(state: tauri::State<SharedState>, id: String) {
    state.lock().db.delete_course(&id);
}

#[tauri::command]
fn get_daily_goal(state: tauri::State<SharedState>) -> i64 {
    state.lock().db.get_daily_goal()
}

#[tauri::command]
fn set_daily_goal(state: tauri::State<SharedState>, seconds: i64) {
    state.lock().db.set_daily_goal(seconds);
}

#[tauri::command]
fn get_today_studied(state: tauri::State<SharedState>) -> i64 {
    let today = chrono::Local::now().format("%Y-%m-%d").to_string();
    state.lock().db.get_studied_duration(&today)
}

#[tauri::command]
fn get_current_session(state: tauri::State<SharedState>) -> Option<CurrentSession> {
    let s = state.lock();
    if let (Some(course_id), Some(start)) = (&s.current_course_id, s.session_start) {
        let now = chrono::Utc::now().timestamp();
        let duration = now - start;
        if let Some(course) = s.db.get_course(course_id) {
            return Some(CurrentSession {
                course_name: course.name,
                duration,
            });
        }
    }
    None
}

#[tauri::command]
fn get_statistics(
    state: tauri::State<SharedState>,
    start_date: Option<String>,
    end_date: Option<String>,
    subject: Option<String>,
) -> Statistics {
    state.lock().db.get_statistics(start_date, end_date, subject)
}

#[tauri::command]
fn get_exam_date(state: tauri::State<SharedState>) -> Option<String> {
    state.lock().db.get_exam_date()
}

#[tauri::command]
fn set_exam_date(state: tauri::State<SharedState>, date: String) {
    state.lock().db.set_exam_date(&date);
}

#[tauri::command]
fn get_sync_config(state: tauri::State<SharedState>) -> (Option<String>, Option<String>) {
    let s = state.lock();
    (s.db.get_setting("sync_url"), s.db.get_setting("user_id"))
}

#[tauri::command]
fn get_auto_sync_config(state: tauri::State<SharedState>) -> (bool, i64, bool) {
    let s = state.lock();
    let auto_sync_enabled = s.db.get_setting("auto_sync_enabled")
        .map(|v| v == "true")
        .unwrap_or(false);
    let auto_sync_interval = s.db.get_setting("auto_sync_interval")
        .and_then(|v| v.parse().ok())
        .unwrap_or(300); // 默认5分钟
    let sync_on_pause = s.db.get_setting("sync_on_pause")
        .map(|v| v == "true")
        .unwrap_or(false);
    (auto_sync_enabled, auto_sync_interval, sync_on_pause)
}

#[tauri::command]
#[allow(non_snake_case)]
fn set_auto_sync_config(state: tauri::State<SharedState>, autoSyncEnabled: bool, autoSyncInterval: i64, syncOnPause: bool) {
    let s = state.lock();
    s.db.set_setting("auto_sync_enabled", if autoSyncEnabled { "true" } else { "false" });
    s.db.set_setting("auto_sync_interval", &autoSyncInterval.to_string());
    s.db.set_setting("sync_on_pause", if syncOnPause { "true" } else { "false" });
}

#[tauri::command]
fn get_notifications_enabled(state: tauri::State<SharedState>) -> bool {
    state.lock().db.get_setting("notifications_enabled")
        .map(|v| v == "true")
        .unwrap_or(true)
}

#[tauri::command]
fn set_notifications_enabled(state: tauri::State<SharedState>, enabled: bool) {
    state.lock().db.set_setting("notifications_enabled", if enabled { "true" } else { "false" });
}

#[tauri::command]
fn get_auto_launch() -> bool {
    let auto = auto_launch::AutoLaunchBuilder::new()
        .set_app_name("快学点儿吧")
        .set_app_path(&std::env::current_exe().unwrap().to_string_lossy())
        .build()
        .unwrap();
    auto.is_enabled().unwrap_or(false)
}

#[tauri::command]
fn set_auto_launch(enabled: bool) -> Result<(), String> {
    let auto = auto_launch::AutoLaunchBuilder::new()
        .set_app_name("快学点儿吧")
        .set_app_path(&std::env::current_exe().unwrap().to_string_lossy())
        .build()
        .map_err(|e| e.to_string())?;
    
    if enabled {
        auto.enable().map_err(|e| e.to_string())?;
    } else {
        auto.disable().map_err(|e| e.to_string())?;
    }
    Ok(())
}

#[tauri::command]
#[allow(non_snake_case)]
fn set_sync_config(state: tauri::State<SharedState>, syncUrl: String, userId: String) {
    let s = state.lock();
    s.db.set_setting("sync_url", &syncUrl);
    s.db.set_setting("user_id", &userId);
}

#[tauri::command]
fn get_sync_data(state: tauri::State<SharedState>) -> serde_json::Value {
    let s = state.lock();
    let courses = s.db.get_courses();
    let study_logs = s.db.get_all_study_logs();
    let daily_goal = s.db.get_daily_goal();
    let exam_date = s.db.get_exam_date();
    
    serde_json::json!({
        "courses": courses,
        "studyLogs": study_logs,
        "settings": {
            "daily_goal": daily_goal,
            "exam_date": exam_date.unwrap_or_default()
        }
    })
}

fn main() {
    let db = Database::new().expect("Failed to initialize database");
    let state = Arc::new(Mutex::new(AppState {
        db,
        current_course_id: None,
        session_start: None,
        last_report_time: None,
    }));

    let http_state = state.clone();
    std::thread::spawn(move || {
        http_server::start_server(http_state);
    });

    // 超时检测线程：30秒没收到上报就自动暂停
    let timeout_state = state.clone();
    std::thread::spawn(move || {
        loop {
            std::thread::sleep(Duration::from_secs(10));
            let now = chrono::Utc::now().timestamp();
            let mut s = timeout_state.lock();
            
            if let (Some(course_id), Some(start), Some(last_report)) = 
                (s.current_course_id.clone(), s.session_start, s.last_report_time) 
            {
                // 超过30秒没上报
                if now - last_report > 30 {
                    let today = chrono::Local::now().format("%Y-%m-%d").to_string();
                    let duration = last_report - start;
                    if duration > 0 {
                        s.db.add_study_log(&course_id, &today, duration);
                    }
                    
                    // 检查是否启用暂停时同步
                    let sync_on_pause = s.db.get_setting("sync_on_pause")
                        .map(|v| v == "true")
                        .unwrap_or(false);
                    if sync_on_pause {
                        http_server::SYNC_TRIGGER.store(true, std::sync::atomic::Ordering::SeqCst);
                    }
                    
                    s.current_course_id = None;
                    s.session_start = None;
                    s.last_report_time = None;
                    
                    println!("Session timeout - auto paused");
                }
            }
        }
    });

    // 系统托盘菜单
    let tray_menu = SystemTrayMenu::new()
        .add_item(CustomMenuItem::new("open", "打开"))
        .add_native_item(SystemTrayMenuItem::Separator)
        .add_item(CustomMenuItem::new("quit", "退出"));

    let system_tray = SystemTray::new().with_menu(tray_menu);

    tauri::Builder::default()
        .system_tray(system_tray)
        .on_system_tray_event(|app, event| match event {
            SystemTrayEvent::LeftClick { .. } => {
                if let Some(window) = app.get_window("main") {
                    window.show().unwrap();
                    window.set_focus().unwrap();
                }
            }
            SystemTrayEvent::MenuItemClick { id, .. } => match id.as_str() {
                "open" => {
                    if let Some(window) = app.get_window("main") {
                        window.show().unwrap();
                        window.set_focus().unwrap();
                    }
                }
                "quit" => {
                    std::process::exit(0);
                }
                _ => {}
            },
            _ => {}
        })
        .on_window_event(|event| {
            if let tauri::WindowEvent::CloseRequested { api, .. } = event.event() {
                event.window().hide().unwrap();
                api.prevent_close();
            }
        })
        .manage(state)
        .invoke_handler(tauri::generate_handler![
            get_courses,
            add_course,
            update_course,
            delete_course,
            get_daily_goal,
            set_daily_goal,
            get_today_studied,
            get_current_session,
            get_statistics,
            get_exam_date,
            set_exam_date,
            get_sync_config,
            set_sync_config,
            get_sync_data,
            get_auto_sync_config,
            set_auto_sync_config,
            get_notifications_enabled,
            set_notifications_enabled,
            get_auto_launch,
            set_auto_launch,
        ])
        .build(tauri::generate_context!())
        .expect("error while building tauri application")
        .run(|_app_handle, event| {
            if let tauri::RunEvent::Ready = event {
                // 启动时显示窗口
                if let Some(window) = _app_handle.get_window("main") {
                    window.show().unwrap();
                }
                
                // 启动同步触发检查线程
                let app_handle = _app_handle.clone();
                std::thread::spawn(move || {
                    loop {
                        std::thread::sleep(Duration::from_secs(1));
                        if http_server::should_sync() {
                            let _ = app_handle.emit_all("sync-on-pause", ());
                        }
                    }
                });
            }
        });
}
