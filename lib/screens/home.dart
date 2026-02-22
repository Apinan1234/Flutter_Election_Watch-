import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper();
  int _total = 0;
  List<Map<String, dynamic>> _top3 = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final total = await _db.countAllReports();     // [1.6]
    final top3  = await _db.getTop3Stations();    // [1.7]
    setState(() { _total = total; _top3 = top3; _loading = false; });
  }

  void _goTo(String route) {
    Navigator.pushNamed(context, route).then((_) => _loadStats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Election Watch'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // [1.8] แสดงผลสรุป
                    Card(
                      color: Colors.indigo.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          const Icon(Icons.bar_chart, color: Colors.indigo, size: 32),
                          const SizedBox(width: 16),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('รายงานทั้งหมด (Offline)', style: TextStyle(color: Colors.grey)),
                            Text('$_total เรื่อง', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
                          ]),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('🏆 3 อันดับหน่วยที่ถูกร้องเรียนมากสุด',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._top3.isEmpty
                        ? [const Text('ยังไม่มีข้อมูล', style: TextStyle(color: Colors.grey))]
                        : _top3.asMap().entries.map((e) => Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: [Colors.amber, Colors.grey.shade400, Colors.brown.shade300][e.key],
                                child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(e.value['station_name'] ?? '-'),
                              trailing: Chip(
                                label: Text('${e.value['total']} เรื่อง'),
                                backgroundColor: Colors.indigo.shade100,
                              ),
                            ),
                          )),
                    const SizedBox(height: 24),
                    const Text('เมนูหลัก', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    // [1.1] ปุ่มไป 4 หน้า
                    _menuButton(Icons.report,            'แจ้งเหตุ (Report)',           '/report', Colors.red),
                    _menuButton(Icons.edit_location_alt, 'แก้ไขหน่วยเลือกตั้ง (Edit)', '/edit',   Colors.orange),
                    _menuButton(Icons.list_alt,          'รายการแจ้งเหตุ (List)',       '/list',   Colors.blue),
                    _menuButton(Icons.search,            'ค้นหา (Search)',              '/filter', Colors.green),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _menuButton(IconData icon, String label, String route, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: () => _goTo(route),
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
