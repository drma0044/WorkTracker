import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui'; // مهم عشان تفعيل السحب بالماوس
import 'package:flutter/foundation.dart'; // مهم عشان فحص إذا كنا على الويب أو التلفون

void main() {
  runApp(const WorkTrackerApp());
}

class WorkTrackerApp extends StatelessWidget {
  const WorkTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WorkTracker',
      theme: ThemeData(
        primaryColor: const Color(0xFF4F46E5),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      // هذا الجزء يحل مشكلة السكرول بالماوس في محاكي الويب
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown
        },
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const MainScreen(),
    );
  }
}

// ==========================================
// 1. الشاشة الرئيسية للتطبيق
// ==========================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  TimeOfDay? punchInTime;
  int workHours = 8;
  bool hasPermissions = false;

  List<Map<String, String>> attendanceHistory = [];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // حل مشكلة الصلاحيات: إذا كنا نجرب على الويب، نتخطى الطلب عشان ما يطلع إيرور
    if (kIsWeb) {
      setState(() {
        hasPermissions = true;
      });
      return;
    }

    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
      Permission.notification,
    ].request();

    setState(() {
      hasPermissions = statuses[Permission.locationWhenInUse]!.isGranted &&
          statuses[Permission.notification]!.isGranted;
    });
  }

  String _getArabicDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'الإثنين';
      case 2:
        return 'الثلاثاء';
      case 3:
        return 'الأربعاء';
      case 4:
        return 'الخميس';
      case 5:
        return 'الجمعة';
      case 6:
        return 'السبت';
      case 7:
        return 'الأحد';
      default:
        return '';
    }
  }

  void _recordPunchIn() {
    setState(() {
      punchInTime = TimeOfDay.now();
      DateTime now = DateTime.now();

      attendanceHistory.add({
        'day': _getArabicDayName(now.weekday),
        'date':
            '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}',
        'punchIn': _formatTime(punchInTime!),
        'punchOut': _calculatePunchOut(),
      });
    });
  }

  String _calculatePunchOut() {
    if (punchInTime == null) return '--:--';

    int totalMinutes =
        punchInTime!.hour * 60 + punchInTime!.minute + (workHours * 60);
    int outHour = (totalMinutes ~/ 60) % 24;
    int outMinute = totalMinutes % 60;

    String period = outHour >= 12 ? 'م' : 'ص';
    int displayHour =
        outHour > 12 ? outHour - 12 : (outHour == 0 ? 12 : outHour);

    return '${displayHour.toString().padLeft(2, '0')}:${outMinute.toString().padLeft(2, '0')} $period';
  }

  String _formatTime(TimeOfDay time) {
    String period = time.hour >= 12 ? 'م' : 'ص';
    int displayHour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    return '${displayHour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 0,
        title: const Text(
          'WorkTracker',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            tooltip: 'سجل الحضور',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HistoryScreen(history: attendanceHistory),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!hasPermissions)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'يرجى منح صلاحيات الموقع والإشعارات ليعمل التطبيق وتلقي إشعار الوصول للمبنى بشكل صحيح.',
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            const Text(
              'مرحباً بك!',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 8),
            const Text(
              'قم بتسجيل حضورك ليقوم النظام بحساب وقت الانصراف المتوقع بدقة.',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'كم عدد ساعات عملك اليوم؟',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF374151)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: _buildHourOption(index + 1),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: _buildTimeCard(
                    title: 'وقت الحضور',
                    time: punchInTime != null
                        ? _formatTime(punchInTime!)
                        : '--:--',
                    icon: Icons.login_rounded,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildTimeCard(
                    title: 'الانصراف المتوقع',
                    time: _calculatePunchOut(),
                    icon: Icons.logout_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: punchInTime == null ? _recordPunchIn : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: punchInTime == null ? 8 : 0,
                shadowColor: const Color(0xFF4F46E5).withOpacity(0.5),
              ),
              child: Text(
                punchInTime == null
                    ? 'تسجيل الدخول (بصمة)'
                    : 'تم تسجيل الحضور بنجاح',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      punchInTime == null ? Colors.white : Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildHourOption(int hours) {
    bool isSelected = workHours == hours;
    return GestureDetector(
      onTap: () {
        setState(() {
          workHours = hours;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$hours',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                  fontSize: 20,
                ),
              ),
              Text(
                'ساعات',
                style: TextStyle(
                  color: isSelected ? Colors.white70 : const Color(0xFF9CA3AF),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCard(
      {required String title,
      required String time,
      required IconData icon,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              time,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color),
              textDirection: TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. شاشة سجل الحضور (History Screen)
// ==========================================
class HistoryScreen extends StatelessWidget {
  final List<Map<String, String>> history;

  const HistoryScreen({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'سجل الحضور',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4F46E5),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off_rounded,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 15),
                  Text(
                    'لا يوجد سجل حضور متاح حالياً.',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final record = history[history.length - 1 - index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded,
                                  color: Color(0xFF4F46E5), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '${record['day']}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF374151)),
                              ),
                            ],
                          ),
                          Text(
                            '${record['date']}',
                            style: const TextStyle(
                                fontSize: 14, color: Color(0xFF6B7280)),
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, thickness: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('الحضور',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF9CA3AF))),
                              const SizedBox(height: 4),
                              Text(
                                '${record['punchIn']}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981)),
                                textDirection: TextDirection.ltr,
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('الانصراف المتوقع',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF9CA3AF))),
                              const SizedBox(height: 4),
                              Text(
                                '${record['punchOut']}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF59E0B)),
                                textDirection: TextDirection.ltr,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
