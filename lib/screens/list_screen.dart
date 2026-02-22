import 'dart:io';
import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});
  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final _db = DatabaseHelper();
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // [4.1] ดึงรายการจาก SQLite พร้อม JOIN ชื่อหน่วย + ชื่อประเภท [4.2, 4.3]
  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await _db.getAllReports();
    setState(() { _reports = data; _loading = false; });
  }

  // [4.5–4.8] ลบ + Dialog + setState ทันที
  Future<void> _deleteItem(int index) async {
    final id = _reports[index]['report_id'] as int;

    // [4.6] Dialog ยืนยัน
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ?'),
        content: const Text('ต้องการลบรายการนี้? ไม่สามารถกู้คืนได้'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.deleteReport(id);                    // [4.7] DELETE SQLite
      setState(() => _reports.removeAt(index));       // [4.8] หายทันที
    }
  }

  Color _severityColor(String? s) {
    switch (s) {
      case 'High':   return Colors.red;
      case 'Medium': return Colors.orange;
      case 'Low':    return Colors.green;
      default:       return Colors.grey;
    }
  }

  // [4.4] แสดง Thumbnail จาก path
  Widget _thumb(String? path) {
    if (path == null || path.isEmpty || !File(path).existsSync()) {
      return Container(
        width: 56, height: 56,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.file(File(path), width: 56, height: 56, fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายการแจ้งเหตุ (${_reports.length})'),
        // [1.2] กลับ Home
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  Text('ยังไม่มีรายการ', style: TextStyle(color: Colors.grey)),
                ]))
              : ListView.builder(
                  itemCount: _reports.length,
                  itemBuilder: (ctx, i) {
                    final r = _reports[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            // [4.4] Thumbnail
                            _thumb(r['evidence_photo'] as String?),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['reporter_name'] ?? '-',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  // [4.2] ชื่อหน่วย (ไม่ใช่ ID)
                                  Text(r['station_name'] ?? '-', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  // [4.3] ชื่อประเภท (ไม่ใช่ ID)
                                  Text(r['type_name'] ?? '-', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Chip(
                                    label: Text(r['severity'] ?? '-',
                                        style: const TextStyle(color: Colors.white, fontSize: 11)),
                                    backgroundColor: _severityColor(r['severity'] as String?),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                            ),
                            // [4.5] ปุ่มลบ
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteItem(i),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
