use crate::{Course, SharedState};
use serde::{Deserialize, Serialize};
use std::convert::Infallible;
use std::sync::atomic::{AtomicBool, Ordering};
use warp::Filter;
use winrt_notification::{Duration, Sound, Toast};

// 全局标志：是否需要触发同步
pub static SYNC_TRIGGER: AtomicBool = AtomicBool::new(false);

pub fn should_sync() -> bool {
    SYNC_TRIGGER.swap(false, Ordering::SeqCst)
}

#[derive(Deserialize)]
struct StatusReport {
    course_id: String,
    active: bool,
    timestamp: i64,
    #[allow(dead_code)]
    url: String,
}

#[derive(Serialize)]
struct CourseRule {
    id: String,
    name: String,
    subject: String,
    url_pattern: String,
}

impl From<Course> for CourseRule {
    fn from(c: Course) -> Self {
        Self {
            id: c.id,
            name: c.name,
            subject: c.subject,
            url_pattern: c.url_pattern,
        }
    }
}

#[derive(Serialize)]
struct ApiResponse<T> {
    success: bool,
    data: Option<T>,
    message: Option<String>,
}

fn with_state(
    state: SharedState,
) -> impl Filter<Extract = (SharedState,), Error = Infallible> + Clone {
    warp::any().map(move || state.clone())
}

fn send_notification(title: &str, body: &str, state: &SharedState) {
    // 检查是否启用通知
    let enabled = state.lock().db.get_setting("notifications_enabled")
        .map(|v| v == "true")
        .unwrap_or(true); // 默认开启
    
    if !enabled {
        return;
    }
    
    let _ = Toast::new(Toast::POWERSHELL_APP_ID)
        .title(title)
        .text1(body)
        .duration(Duration::Short)
        .sound(Some(Sound::Default))
        .show();
}

pub fn start_server(state: SharedState) {
    let rt = tokio::runtime::Runtime::new().unwrap();
    rt.block_on(async {
        let cors = warp::cors()
            .allow_any_origin()
            .allow_methods(vec!["GET", "POST", "OPTIONS"])
            .allow_headers(vec!["Content-Type"]);

        // GET /courses
        let get_courses = warp::path("courses")
            .and(warp::get())
            .and(with_state(state.clone()))
            .map(|state: SharedState| {
                let courses: Vec<CourseRule> = state
                    .lock()
                    .db
                    .get_courses()
                    .into_iter()
                    .map(|c| c.into())
                    .collect();
                warp::reply::json(&ApiResponse {
                    success: true,
                    data: Some(courses),
                    message: None,
                })
            });

        // POST /status
        let post_status = warp::path("status")
            .and(warp::post())
            .and(warp::body::json())
            .and(with_state(state.clone()))
            .map(|report: StatusReport, state: SharedState| {
                let mut s = state.lock();
                let today = chrono::Local::now().format("%Y-%m-%d").to_string();

                if report.active {
                    let switched_course = s.current_course_id.as_ref() != Some(&report.course_id);
                    let is_new_session = s.session_start.is_none();
                    
                    // 切换课程时，保存之前课程的学习时长
                    if switched_course && !is_new_session {
                        if let (Some(prev_id), Some(start)) = (&s.current_course_id, s.session_start) {
                            let duration = report.timestamp - start;
                            if duration > 0 {
                                s.db.add_study_log(prev_id, &today, duration);
                            }
                        }
                    }
                    
                    // 发送通知（仅在开始或切换时）
                    if is_new_session || switched_course {
                        if let Some(course) = s.db.get_course(&report.course_id) {
                            if is_new_session {
                                drop(s);
                                send_notification("开始学习", &format!("正在学习：{}", course.name), &state);
                                s = state.lock();
                            } else {
                                drop(s);
                                send_notification("切换课程", &format!("正在学习：{}", course.name), &state);
                                s = state.lock();
                            }
                        }
                        // 只在开始或切换时重置 session_start
                        s.session_start = Some(report.timestamp);
                    }
                    
                    s.current_course_id = Some(report.course_id.clone());
                    s.last_report_time = Some(report.timestamp);
                    
                } else {
                    if let (Some(course_id), Some(start)) = (&s.current_course_id, s.session_start) {
                        if course_id == &report.course_id {
                            let duration = report.timestamp - start;
                            if duration > 0 {
                                s.db.add_study_log(course_id, &today, duration);
                                
                                if let Some(course) = s.db.get_course(course_id) {
                                    let total_today = s.db.get_studied_duration(&today);
                                    let mins = total_today / 60;
                                    let msg = format!("{}：今日已学习 {} 分钟", course.name, mins);
                                    drop(s);
                                    send_notification("学习暂停", &msg, &state);
                                    s = state.lock();
                                }
                                
                                // 检查是否启用暂停时同步
                                let sync_on_pause = s.db.get_setting("sync_on_pause")
                                    .map(|v| v == "true")
                                    .unwrap_or(false);
                                if sync_on_pause {
                                    SYNC_TRIGGER.store(true, Ordering::SeqCst);
                                }
                            }
                            s.current_course_id = None;
                            s.session_start = None;
                            s.last_report_time = None;
                        }
                    }
                }

                warp::reply::json(&ApiResponse::<()> {
                    success: true,
                    data: None,
                    message: Some("Status updated".to_string()),
                })
            });

        let health = warp::path("health")
            .and(warp::get())
            .map(|| warp::reply::json(&ApiResponse::<()> {
                success: true,
                data: None,
                message: Some("OK".to_string()),
            }));

        let routes = get_courses
            .or(post_status)
            .or(health)
            .with(cors);

        println!("HTTP API server running on http://127.0.0.1:23333");
        warp::serve(routes).run(([127, 0, 0, 1], 23333)).await;
    });
}
