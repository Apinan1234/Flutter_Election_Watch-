import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  // [1.3] ตรวจสอบว่ามีไฟล์ DB แล้วหรือยัง
  Future<bool> dbExists() async {
    final dbPath = await getDatabasesPath();
    final full = p.join(dbPath, 'election.db');
    return databaseExists(full);
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final full = p.join(dbPath, 'election.db');
    return openDatabase(
      full,
      version: 1,
      onCreate: (db, v) async {
        // [1.4] สร้างตาราง
        await db.execute('''CREATE TABLE polling_station(
          station_id   INTEGER PRIMARY KEY,
          station_name TEXT,
          zone         TEXT,
          province     TEXT
        )''');
        await db.execute('''CREATE TABLE violation_type(
          type_id   INTEGER PRIMARY KEY,
          type_name TEXT,
          severity  TEXT
        )''');
        await db.execute('''CREATE TABLE incident_report(
          report_id      INTEGER PRIMARY KEY AUTOINCREMENT,
          station_id     INTEGER,
          type_id        INTEGER,
          reporter_name  TEXT,
          description    TEXT,
          evidence_photo TEXT,
          timestamp      TEXT,
          ai_result      TEXT,
          ai_confidence  REAL,
          FOREIGN KEY (station_id) REFERENCES polling_station(station_id),
          FOREIGN KEY (type_id)    REFERENCES violation_type(type_id)
        )''');
        
        
        // [1.5] Seed data ตาราง 1 และ 2
        await _seedData(db);
      },
    );
  }

  Future<void> _seedData(Database db) async {
    final stations = [
      [101, 'โรงเรียนวัดพระมหาธาตุ', 'เขต 1', 'นครศรีธรรมราช'],
      [102, 'เต็นท์หน้าตลาดท่าวัง',   'เขต 1', 'นครศรีธรรมราช'],
      [103, 'ศาลากลางหมู่บ้านคีรีวง', 'เขต 2', 'นครศรีธรรมราช'],
      [104, 'หอประชุมอำเภอทุ่งสง',    'เขต 3', 'นครศรีธรรมราช'],
    ];
    for (final s in stations) {
      await db.insert('polling_station', {
        'station_id': s[0], 'station_name': s[1], 'zone': s[2], 'province': s[3]
      });
    }
    final types = [
      [1, 'ซื้อสิทธิ์ขายเสียง (Buying Votes)',       'High'],
      [2, 'ขนคนไปลงคะแนน (Transportation)',           'High'],
      [3, 'หาเสียงเกินเวลา (Overtime Campaign)',       'Medium'],
      [4, 'ทำลายป้ายหาเสียง (Vandalism)',              'Low'],
      [5, 'เจ้าหน้าที่วางตัวไม่เป็นกลาง (Bias Official)', 'High'],
    ];
    for (final t in types) {
      await db.insert('violation_type', {
        'type_id': t[0], 'type_name': t[1], 'severity': t[2]
      });
    }
  }

  // ─── HOME ─────────────────────────────────────────────────
  // [1.6] นับรายงานทั้งหมด
  Future<int> countAllReports() async {
    final db = await database;
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM incident_report');
    return (r.first['c'] as int?) ?? 0;
  }

  // [1.7] TOP 3 หน่วยที่ถูกร้องเรียนมากที่สุด
  Future<List<Map<String, dynamic>>> getTop3Stations() async {
    final db = await database;
    return db.rawQuery('''
      SELECT ps.station_name, COUNT(*) as total
      FROM   incident_report ir
      JOIN   polling_station ps ON ir.station_id = ps.station_id
      GROUP  BY ir.station_id
      ORDER  BY total DESC
      LIMIT  3
    ''');
  }

  // ─── REPORT ───────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllStations() async {
    final db = await database;
    return db.query('polling_station');
  }

  Future<List<Map<String, dynamic>>> getAllTypes() async {
    final db = await database;
    return db.query('violation_type');
  }

  Future<int> insertReport(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('incident_report', data);
  }

  // ─── LIST ─────────────────────────────────────────────────
  // [4.1–4.3] ดึงรายการพร้อม JOIN ชื่อหน่วย + ชื่อประเภท
  Future<List<Map<String, dynamic>>> getAllReports() async {
    final db = await database;
    return db.rawQuery('''
      SELECT ir.*, ps.station_name, vt.type_name, vt.severity
      FROM   incident_report ir
      JOIN   polling_station ps ON ir.station_id = ps.station_id
      JOIN   violation_type  vt ON ir.type_id    = vt.type_id
      ORDER  BY ir.timestamp DESC
    ''');
  }

  // [4.7] ลบรายการ
  Future<int> deleteReport(int id) async {
    final db = await database;
    return db.delete('incident_report', where: 'report_id = ?', whereArgs: [id]);
  }

  // ─── SEARCH ───────────────────────────────────────────────
  // [5.2–5.7] ค้นหาแบบผสม LIKE + JOIN severity
  Future<List<Map<String, dynamic>>> search(String keyword, String? severity) async {
    final db     = await database;
    final params = <dynamic>[];
    String sql = '''
      SELECT ir.*, ps.station_name, vt.type_name, vt.severity
      FROM   incident_report ir
      JOIN   polling_station ps ON ir.station_id = ps.station_id
      JOIN   violation_type  vt ON ir.type_id    = vt.type_id
      WHERE  1=1
    ''';
    if (keyword.trim().isNotEmpty) {
      sql += ' AND (ir.reporter_name LIKE ? OR ir.description LIKE ?)';
      params.addAll(['%${keyword.trim()}%', '%${keyword.trim()}%']);
    }
    if (severity != null) {
      sql += ' AND vt.severity = ?';
      params.add(severity);
    }
    sql += ' ORDER BY ir.timestamp DESC';
    return db.rawQuery(sql, params);
  }

  // ─── EDIT STATION ─────────────────────────────────────────
  // [3.3] เช็คชื่อซ้ำ (exclude ตัวเอง)
  Future<bool> isNameDuplicate(String name, int excludeId) async {
    final db = await database;
    final r  = await db.rawQuery(
      'SELECT COUNT(*) as c FROM polling_station WHERE station_name = ? AND station_id != ?',
      [name, excludeId],
    );
    return ((r.first['c'] as int?) ?? 0) > 0;
  }

  // [3.5] นับเรื่องร้องเรียนของหน่วย
  Future<int> countReportsByStation(int stationId) async {
    final db = await database;
    final r  = await db.rawQuery(
      'SELECT COUNT(*) as c FROM incident_report WHERE station_id = ?',
      [stationId],
    );
    return (r.first['c'] as int?) ?? 0;
  }

  // [3.7] UPDATE station_name
  Future<int> updateStationName(int stationId, String newName) async {
    final db = await database;
    return db.update(
      'polling_station',
      {'station_name': newName},
      where: 'station_id = ?',
      whereArgs: [stationId],
    );
  }
}
