import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../helpers/database_helper.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _db       = DatabaseHelper();
  final _picker   = ImagePicker();

  List<Map<String, dynamic>> _stations = [];
  List<Map<String, dynamic>> _types    = [];
  int?    _selStation;
  int?    _selType;
  String? _imagePath;
  String? _aiLabel;
  double  _aiConf = 0.0;
  bool    _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    final s = await _db.getAllStations();
    final t = await _db.getAllTypes();
    setState(() { _stations = s; _types = t; });
  }

  // [2.1] เลือกรูป
  Future<void> _pickImage(ImageSource src) async {
    final f = await _picker.pickImage(source: src, maxWidth: 800);
    if (f != null) {
      setState(() { _imagePath = f.path; _aiLabel = null; _aiConf = 0.0; });
    }
  }

  // [2.6] บันทึก SQLite
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selStation == null || _selType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกหน่วยเลือกตั้งและประเภทความผิด')),
      );
      return;
    }
    setState(() => _saving = true);

    final ts = DateTime.now().toString().substring(0, 19);

    // [2.6] INSERT SQLite ครบทุกฟิลด์
    await _db.insertReport({
      'station_id':     _selStation,
      'type_id':        _selType,
      'reporter_name':  _nameCtrl.text.trim(),
      'description':    _descCtrl.text.trim(),
      'evidence_photo': _imagePath,
      'timestamp':      ts,
      'ai_result':      _aiLabel,
      'ai_confidence':  _aiConf,
    });

    // [2.7+2.8] Firebase — เปิดใช้เมื่อตั้งค่า Firebase แล้ว
    // bool isUrl = _imagePath?.startsWith('http') ?? false;
    // await FirebaseFirestore.instance.collection('incident_reports').add({
    //   'station_id':    _selStation,
    //   'type_id':       _selType,
    //   'reporter_name': _nameCtrl.text.trim(),
    //   'description':   _descCtrl.text.trim(),
    //   'evidence_photo': isUrl ? _imagePath : 'OFFLINE_ONLY',
    //   'timestamp':     ts,
    //   'ai_result':     _aiLabel,
    //   'ai_confidence': _aiConf,
    // });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกสำเร็จ ✅')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แจ้งเหตุ'),
        // [1.2] กลับ Home ได้ผ่าน AppBar back button
        leading: IconButton(icon: const Icon(Icons.home), onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // [2.2] Dropdown หน่วยเลือกตั้ง
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'หน่วยเลือกตั้ง *', border: OutlineInputBorder()),
              initialValue: _selStation,
              items: _stations.map((s) => DropdownMenuItem<int>(
                value: s['station_id'] as int,
                child: Text('${s['station_name']} (${s['zone']})'),
              )).toList(),
              onChanged: (v) => setState(() => _selStation = v),
              validator: (v) => v == null ? 'กรุณาเลือกหน่วยเลือกตั้ง' : null,
            ),
            const SizedBox(height: 12),

            // [2.2] Dropdown ประเภทความผิด
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'ประเภทความผิด *', border: OutlineInputBorder()),
              initialValue: _selType,
              items: _types.map((t) => DropdownMenuItem<int>(
                value: t['type_id'] as int,
                child: Text(t['type_name']),
              )).toList(),
              onChanged: (v) => setState(() => _selType = v),
              validator: (v) => v == null ? 'กรุณาเลือกประเภทความผิด' : null,
            ),
            const SizedBox(height: 12),

            // [2.1] ชื่อผู้แจ้ง
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'ชื่อผู้แจ้ง *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อ' : null,
            ),
            const SizedBox(height: 12),

            // [2.1] รายละเอียด
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'รายละเอียด', border: OutlineInputBorder(), prefixIcon: Icon(Icons.notes), alignLabelWithHint: true),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            // [2.1] ปุ่มเลือกรูป
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('ถ่ายภาพ'),
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('คลังภาพ'),
              )),
            ]),

            // แสดงรูปที่เลือก
            if (_imagePath != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(_imagePath!), height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            ],

            // [2.3] แสดงผล AI
            if (_aiLabel != null) ...[
              const SizedBox(height: 12),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('🤖 ผล AI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    Text('Label: $_aiLabel'),
                    Text('ความมั่นใจ: ${(_aiConf * 100).toStringAsFixed(1)}%'),
                    LinearProgressIndicator(value: _aiConf, color: Colors.blue, backgroundColor: Colors.grey.shade200),
                  ]),
                ),
              ),
            ],

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
              label: Text(_saving ? 'กำลังบันทึก...' : 'บันทึกรายงาน'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
