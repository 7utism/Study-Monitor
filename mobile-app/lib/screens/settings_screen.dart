import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiUrlController = TextEditingController();
  final _userIdController = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await ApiService.init();
    _apiUrlController.text = ApiService.apiUrl;
    _userIdController.text = ApiService.userId ?? '';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ApiService.setApiUrl(_apiUrlController.text.trim());
    await ApiService.setUserId(_userIdController.text.trim());
    setState(() => _saving = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF66BB6A), size: 18),
              SizedBox(width: 10),
              Text('配置已保存', style: TextStyle(color: Colors.white)),
            ],
          ),
          backgroundColor: const Color(0xFF333333),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF555555), strokeWidth: 2));
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('设置', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -1, height: 1)),
                SizedBox(height: 4),
                Text('Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF555555), letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 32),
            
            // 同步配置卡片
            Container(
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.cloud_sync_rounded, color: Color(0xFF888888), size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('云端同步', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          SizedBox(height: 2),
                          Text('与桌面端数据同步', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  
                  _buildInputField(
                    controller: _apiUrlController,
                    label: 'API 地址',
                    hint: 'http://XXX:XX',
                    icon: Icons.link_rounded,
                  ),
                  const SizedBox(height: 20),
                  
                  _buildInputField(
                    controller: _userIdController,
                    label: '用户 ID',
                    hint: '与桌面端相同的 ID',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 28),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: const Color(0xFF444444),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _saving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('保存配置', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 使用说明卡片
            Container(
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
                        child: const Icon(Icons.help_outline_rounded, color: Color(0xFF888888), size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text('使用说明', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildStep('1', '部署 cloud-api 到你的服务器'),
                  _buildStep('2', '在桌面端配置相同的用户 ID'),
                  _buildStep('3', '在此处填入 API 地址和用户 ID'),
                  _buildStep('4', '下拉刷新首页获取最新数据', isLast: true),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 关于卡片
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF303030), width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF303030),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school_rounded, color: Color(0xFF666666), size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Study Monitor', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Text('学习时间追踪工具', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
                      ],
                    ),
                  ),
                  const Text('v1.0', style: TextStyle(color: Color(0xFF555555), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF555555)),
            prefixIcon: Icon(icon, color: const Color(0xFF555555), size: 20),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF333333), width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF333333), width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF555555), width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(String num, String text, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(num, style: const TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text, style: const TextStyle(color: Color(0xFF777777), fontSize: 13, height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _userIdController.dispose();
    super.dispose();
  }
}
