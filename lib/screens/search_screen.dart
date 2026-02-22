import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _db         = DatabaseHelper();
  final _searchCtrl = TextEditingController();
  String? _severity;
  List<Map<String, dynamic>> _results = [];
  bool _hasSearched = false;
  bool _searching   = false;

  Future<void> _search() async {
    setState(() => _searching = true);
    final data = await _db.search(_searchCtrl.text, _severity);
    setState(() {
      _results   = data;
      _hasSearched = true;
      _searching = false;
    });
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
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  labelText: 'ค้นหาชื่อผู้แจ้ง / รายละเอียด',
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

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'กรองตามความรุนแรง (Severity)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.filter_list),
                  fillColor: Colors.white, filled: true,
                ),
                initialValue: _severity,
                items: const [
                  DropdownMenuItem(value: null,     child: Text('ทั้งหมด')),
                  DropdownMenuItem(value: 'High',   child: Text('🔴 High')),
                  DropdownMenuItem(value: 'Medium', child: Text('🟠 Medium')),
                  DropdownMenuItem(value: 'Low',    child: Text('🟢 Low')),
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
                            Icon(Icons.list, color: Colors.indigo),
                            const SizedBox(width: 8),
                            Text('พบ ${_results.length} รายการ', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (context, i) {
                              final r = _results[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                elevation: 2,
                                child: ListTile(
                                  leading: Icon(Icons.report_problem, color: _sevColor(r['severity'])),
                                  title: Text(r['reporter_name'] ?? 'ไม่ระบุชื่อ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('${r['type_name']} • ${r['station_name'] ?? '-'}'),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(r['severity'] ?? '-', style: TextStyle(color: _sevColor(r['severity']), fontWeight: FontWeight.bold)),
                                      Text(r['timestamp']?.toString().substring(0, 10) ?? '-', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                  onTap: () {
                                    // [5.9] ไป Detail
                                    Navigator.pushNamed(context, '/detail', arguments: r['report_id']);
                                  },
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