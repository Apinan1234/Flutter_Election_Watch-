import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});
  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final _db         = DatabaseHelper();
  final _searchCtrl = TextEditingController();   // [5.1]
  String? _severity;                              // [5.4]
  List<Map<String, dynamic>> _results = [];
  bool _hasSearched = false;
  bool _searching   = false;

  // [5.2, 5.3, 5.5, 5.7] ค้นหาผสม LIKE + JOIN severity
  Future<void> _search() async {
    setState(() => _searching = true);
    final data = await _db.search(_searchCtrl.text, _severity); // [5.5, 5.7]
    setState(() { _results = data; _hasSearched = true; _searching = false; });
  }

  void _reset() {
    setState(() {
      _searchCtrl.clear();
      _severity  = null;
      _results   = [];
      _hasSearched = false;
    });
  }

  Color _sevColor(String? s) {
    switch (s) {
      case 'High':   return Colors.red;
      case 'Medium': return Colors.orange;
      case 'Low':    return Colors.green;
      default:       return Colors.grey;
    }
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ค้นหา / กรอง'),
        // [1.2] กลับ Home
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
        ),
        actions: [TextButton.icon(onPressed: _reset, icon: const Icon(Icons.refresh, color: Colors.white), label: const Text('รีเซ็ต', style: TextStyle(color: Colors.white)))],
      ),
      body: Column(
        children: [
          // ── Filter Zone ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade50,
            child: Column(children: [
              // [5.1] Textbox ค้นหา
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  labelText: 'ค้นหาชื่อผู้แจ้ง / รายละเอียด',  // [5.2, 5.3]
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  fillColor: Colors.white, filled: true,
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _searchCtrl.clear()))
                      : null,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 10),

              // [5.4] Dropdown Severity
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'กรองตามความรุนแรง (Severity)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.filter_list),
                  fillColor: Colors.white, filled: true,
                ),
                value: _severity,
                items: const [
                  DropdownMenuItem(value: null,     child: Text('ทั้งหมด')),
                  DropdownMenuItem(value: 'High',   child: Text('High')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'Low',    child: Text('Low')),
                ],
                onChanged: (v) => setState(() => _severity = v),
              ),
              const SizedBox(height: 10),

              ElevatedButton.icon(
                onPressed: _searching ? null : _search,
                icon: _searching
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search),
                label: Text(_searching ? 'กำลังค้นหา...' : 'ค้นหา'),
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              ),
            ]),
          ),

          // ── Result Zone ──────────────────────────────────
          Expanded(
            child: !_hasSearched
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.manage_search, size: 64, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('กรอกเงื่อนไขแล้วกดค้นหา', style: TextStyle(color: Colors.grey)),
                  ]))
                // [5.8] แสดงข้อความเมื่อไม่พบ
                : _results.isEmpty
                    ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('ไม่พบข้อมูล (No records found)', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ]))
                    : Column(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.indigo.shade50,
                          child: Row(children: [
                            const Icon(Icons.check_circle, size: 16, color: Colors.indigo),
                            const SizedBox(width: 8),
                            Text('พบ ${_results.length} รายการ',
                                style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                        // [5.6] แสดงผล Dropdown filter ถูกต้อง
                        Expanded(
                          child: ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (ctx, i) {
                              final r = _results[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _sevColor(r['severity'] as String?),
                                  child: Text(
                                    (r['reporter_name'] as String? ?? '?').substring(0, 1),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(r['reporter_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r['station_name'] ?? '-', style: const TextStyle(fontSize: 12)),
                                    Text(r['description'] ?? '-', style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                                trailing: Chip(
                                  label: Text(r['severity'] ?? '-',
                                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  backgroundColor: _sevColor(r['severity'] as String?),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              );
                            },
                          ),
                        ),
                      ]),
          ),
        ],
      ),
    );
  }
}
