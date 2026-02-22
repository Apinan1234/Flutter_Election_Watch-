import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';

// ─── หน้ารายชื่อหน่วยเลือกตั้ง ───────────────────────────────
class EditStationScreen extends StatefulWidget {
  const EditStationScreen({super.key});
  @override
  State<EditStationScreen> createState() => _EditStationScreenState();
}

class _EditStationScreenState extends State<EditStationScreen> {
  final _db = DatabaseHelper();
  List<Map<String, dynamic>> _stations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() => _loading = true);
    final s = await _db.getAllStations();
    setState(() { _stations = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขหน่วยเลือกตั้ง'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _stations.length,
              itemBuilder: (ctx, i) {
                final st = _stations[i];
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.orange),
                  title: Text(st['station_name'] ?? '-'),
                  subtitle: Text('${st['zone']} — ${st['province']}'),
                  trailing: const Icon(Icons.edit, color: Colors.grey),
                  onTap: () async {
                    // [3.1] กดเลือกเพื่อเข้าฟอร์มแก้ไข
                    final changed = await Navigator.push<bool>(
                      ctx,
                      MaterialPageRoute(builder: (_) => _EditFormScreen(station: st)),
                    );
                    if (changed == true) _loadStations(); // [3.8] refresh
                  },
                );
              },
            ),
    );
  }
}

// ─── ฟอร์มแก้ไขหน่วย ─────────────────────────────────────────
class _EditFormScreen extends StatefulWidget {
  final Map<String, dynamic> station;
  const _EditFormScreen({required this.station});
  @override
  State<_EditFormScreen> createState() => _EditFormScreenState();
}

class _EditFormScreenState extends State<_EditFormScreen> {
  final _db      = DatabaseHelper();
  late TextEditingController _nameCtrl;
  bool _saving = false;

  // [3.2] คำนำหน้าที่ยอมรับได้
  static const _allowedPrefixes = ['โรงเรียน', 'วัด', 'เต็นท์', 'ศาลา', 'หอประชุม'];

  @override
  void initState() {
    super.initState();
    // [3.1] ดึงข้อมูลเดิมมาแสดงในฟอร์ม
    _nameCtrl = TextEditingController(text: widget.station['station_name'] as String? ?? '');
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  bool _isValidPrefix(String name) =>
      _allowedPrefixes.any((p) => name.startsWith(p));

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { _showError('กรุณากรอกชื่อหน่วย'); return; }

    // [3.2] เช็ค prefix
    if (!_isValidPrefix(name)) {
      // [3.4] แจ้งเตือนระบุสาเหตุชัดเจน
      _showError('❌ รูปแบบชื่อไม่ถูกต้อง: ต้องขึ้นต้นด้วย\nโรงเรียน, วัด, เต็นท์, ศาลา หรือ หอประชุม');
      return;
    }

    // [3.3] เช็คชื่อซ้ำ (exclude ตัวเอง)
    final isDup = await _db.isNameDuplicate(name, widget.station['station_id'] as int);
    if (isDup) {
      // [3.4] แจ้งเตือนระบุสาเหตุชัดเจน
      _showError('❌ ชื่อซ้ำ: มีหน่วยเลือกตั้งชื่อนี้อยู่แล้วในระบบ');
      return;
    }

    setState(() => _saving = true);

    // [3.5] COUNT เรื่องร้องเรียนของหน่วยนี้
    final count = await _db.countReportsByStation(widget.station['station_id'] as int);

    if (count > 0) {
      // [3.6] มีร้องเรียง → แสดง Dialog ก่อน
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('⚠️ มีประวัติร้องเรียน'),
          content: Text('หน่วยนี้มีประวัติร้องเรียน $count เรื่อง\nยืนยันการแก้ไขข้อมูลหรือไม่?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (ok != true) { setState(() => _saving = false); return; }
    }

    // [3.7] UPDATE SQLite
    await _db.updateStationName(widget.station['station_id'] as int, name);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกสำเร็จ ✅'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // [3.8] ส่ง true กลับ → trigger refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('แก้ไขหน่วย #${widget.station['station_id']}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ข้อมูลเดิม
            Card(
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('ข้อมูลเดิม', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text('ชื่อ: ${widget.station['station_name']}'),
                  Text('เขต: ${widget.station['zone']}  |  จังหวัด: ${widget.station['province']}'),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            // [3.1] ฟอร์มแก้ไขชื่อ
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'ชื่อหน่วยใหม่ *',
                border: OutlineInputBorder(),
                helperText: 'ต้องขึ้นต้นด้วย: โรงเรียน / วัด / เต็นท์ / ศาลา / หอประชุม',
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_saving ? 'กำลังบันทึก...' : 'บันทึก'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.orange, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
