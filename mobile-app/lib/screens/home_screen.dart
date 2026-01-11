import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await ApiService.init();
    if (ApiService.userId == null) {
      setState(() => _loading = false);
      return;
    }
    
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    final stats = await ApiService.getStats(
      startDate: weekStart.toIso8601String().split('T')[0],
      endDate: weekEnd.toIso8601String().split('T')[0],
    );
    
    setState(() {
      _stats = stats;
      _loading = false;
    });
    _animController.forward(from: 0);
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  int? _getExamDays() {
    if (_stats?['examDate'] == null || _stats!['examDate'].toString().isEmpty) return null;
    try {
      final exam = DateTime.parse(_stats!['examDate']);
      final now = DateTime.now();
      return exam.difference(DateTime(now.year, now.month, now.day)).inDays;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _loading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF555555), strokeWidth: 2))
        : ApiService.userId == null 
          ? _buildEmptyState()
          : _stats == null 
            ? _buildErrorState()
            : _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.cloud_off_rounded, size: 56, color: Color(0xFF444444)),
            ),
            const SizedBox(height: 32),
            const Text('未配置同步', style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
            const SizedBox(height: 12),
            const Text('请在设置中配置 API 地址和用户 ID', style: TextStyle(color: Color(0xFF666666), fontSize: 14, height: 1.5), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFF444444)),
          ),
          const SizedBox(height: 24),
          const Text('加载失败', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 16)),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _loadData,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF333333),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('重试', style: TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final todayStudied = _stats!['todayStudied'] ?? 0;
    final dailyGoal = _stats!['dailyGoal'] ?? 7200;
    final progress = dailyGoal > 0 ? (todayStudied / dailyGoal * 100).clamp(0.0, 100.0) : 0.0;
    final examDays = _getExamDays();
    final dailyStats = List<Map<String, dynamic>>.from(_stats!['dailyStats'] ?? []);
    final courseStats = List<Map<String, dynamic>>.from(_stats!['courseStats'] ?? []);
    final weekTotal = dailyStats.fold(0, (sum, d) => sum + (d['duration'] as int? ?? 0));
    
    // 按学科汇总
    final subjectMap = <String, int>{};
    for (final c in courseStats) {
      final subject = c['subject'] as String? ?? '未分类';
      final duration = c['duration'] as int? ?? 0;
      subjectMap[subject] = (subjectMap[subject] ?? 0) + duration;
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Colors.white,
      backgroundColor: const Color(0xFF333333),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Study', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -1, height: 1)),
                    Text('Monitor', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: Color(0xFF666666), letterSpacing: -1, height: 1.1)),
                  ],
                ),
                // 考试倒计时徽章
                if (examDays != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252525),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF333333)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flag_rounded, size: 16, color: Color(0xFF888888)),
                        const SizedBox(width: 8),
                        Text('$examDays', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                        const Text(' 天', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            
            // 主进度卡片
            _buildMainProgressCard(todayStudied, dailyGoal, progress),
            const SizedBox(height: 16),
            
            // 统计卡片
            Row(
              children: [
                Expanded(child: _buildMiniStatCard(Icons.timer_outlined, '本周', _formatTime(weekTotal))),
                const SizedBox(width: 12),
                Expanded(child: _buildMiniStatCard(Icons.trending_up_rounded, '进度', '${progress.toStringAsFixed(0)}%')),
              ],
            ),
            const SizedBox(height: 24),
            
            // 图表
            _buildChartCard(dailyStats),
            const SizedBox(height: 24),
            
            // 学科统计
            if (subjectMap.isNotEmpty) _buildSubjectCard(subjectMap),
          ],
        ),
      ),
    );
  }

  Widget _buildMainProgressCard(int todayStudied, int dailyGoal, double progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF2A2A2A), const Color(0xFF222222)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF333333), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('今日学习', style: TextStyle(color: Color(0xFF777777), fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(todayStudied),
                    style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w700, letterSpacing: -1, height: 1),
                  ),
                ],
              ),
              // 圆形进度
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 6,
                        backgroundColor: const Color(0xFF333333),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF333333)),
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return CircularProgressIndicator(
                            value: (progress / 100) * _animController.value,
                            strokeWidth: 6,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation(progress >= 100 ? const Color(0xFF66BB6A) : const Color(0xFF888888)),
                            strokeCap: StrokeCap.round,
                          );
                        },
                      ),
                    ),
                    Text(
                      '${progress.toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: (progress / 100) * _animController.value,
                  backgroundColor: const Color(0xFF333333),
                  valueColor: AlwaysStoppedAnimation(progress >= 100 ? const Color(0xFF66BB6A) : const Color(0xFF666666)),
                  minHeight: 6,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('目标 ${_formatTime(dailyGoal)}', style: const TextStyle(color: Color(0xFF555555), fontSize: 12)),
              if (progress >= 100)
                const Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Color(0xFF66BB6A)),
                    SizedBox(width: 4),
                    Text('已完成', style: TextStyle(color: Color(0xFF66BB6A), fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF303030), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF303030),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF888888)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF666666), fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, int> subjectMap) {
    final sortedSubjects = subjectMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sortedSubjects.fold(0, (sum, e) => sum + e.value);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF303030), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF303030),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pie_chart_outline_rounded, size: 16, color: Color(0xFF888888)),
              ),
              const SizedBox(width: 10),
              const Text('学科分布', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 20),
          ...sortedSubjects.asMap().entries.map((entry) {
            final e = entry.value;
            final percent = total > 0 ? (e.value / total * 100) : 0.0;
            return Padding(
              padding: EdgeInsets.only(bottom: entry.key < sortedSubjects.length - 1 ? 16 : 0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  Expanded(
                    flex: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: percent / 100,
                        backgroundColor: const Color(0xFF333333),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF555555)),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 50,
                    child: Text(_formatTime(e.value), style: const TextStyle(color: Color(0xFF777777), fontSize: 12), textAlign: TextAlign.right),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChartCard(List<Map<String, dynamic>> dailyStats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF303030), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF303030),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.show_chart_rounded, size: 16, color: Color(0xFF888888)),
              ),
              const SizedBox(width: 10),
              const Text('本周趋势', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: _buildChart(dailyStats),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> dailyStats) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final labels = ['一', '二', '三', '四', '五', '六', '日'];
    
    final data = <FlSpot>[];
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i)).toIso8601String().split('T')[0];
      final stat = dailyStats.firstWhere((s) => s['date'] == date, orElse: () => {'duration': 0});
      final mins = (stat['duration'] as int? ?? 0) / 60;
      data.add(FlSpot(i.toDouble(), mins));
    }

    final maxY = data.map((d) => d.y).fold(0.0, (a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 3 : 30,
          getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFF303030), strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final h = value ~/ 60;
                final m = value.toInt() % 60;
                return Text(h > 0 ? '${h}h' : '${m}m', style: const TextStyle(color: Color(0xFF555555), fontSize: 10));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i >= 0 && i < labels.length) {
                  final isToday = i == now.weekday - 1;
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(labels[i], style: TextStyle(color: isToday ? Colors.white : const Color(0xFF555555), fontSize: 11, fontWeight: isToday ? FontWeight.w600 : FontWeight.normal)),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data,
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFF777777),
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: index == now.weekday - 1 ? 5 : 3.5,
                color: index == now.weekday - 1 ? Colors.white : const Color(0xFF777777),
                strokeWidth: 0,
                strokeColor: Colors.transparent,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFF555555).withOpacity(0.2), const Color(0xFF555555).withOpacity(0)],
              ),
            ),
          ),
        ],
        minY: 0,
        maxY: maxY > 0 ? maxY * 1.25 : 60,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: const Color(0xFF404040),
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final mins = spot.y.toInt();
                final h = mins ~/ 60;
                final m = mins % 60;
                return LineTooltipItem(
                  h > 0 ? '${h}h ${m}m' : '${m}m',
                  const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
