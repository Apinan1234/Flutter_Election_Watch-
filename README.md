# Election Watch — Final66112772

แอปพลิเคชันรายงานเหตุการณ์การเลือกตั้ง  
วิชา เทคโนโลยีการเขียนโปรแกรมสำหรับอุปกรณ์พกพา | มหาวิทยาลัยวลัยลักษณ์

---

## รหัสนักศึกษา: 66112772

---

## หน้าจอในแอปพลิเคชัน

| หน้าจอ | ไฟล์ | คะแนน |
|---|---|---|
| 🏠 Home Dashboard | `lib/screens/home.dart` | 4 |
| 📸 Report Incident | `lib/screens/report.dart` | 4 |
| ✏️ Edit Polling Station | `lib/screens/edit_station.dart` | 4 |
| 📋 Incident List | `lib/screens/list_screen.dart` | 4 |
| 🔍 Search & Filter | `lib/screens/search_screen.dart` | 4 |

---

## Database Schema

```
polling_station  (station_id PK, station_name, zone, province)
violation_type   (type_id PK, type_name, severity)
incident_report  (report_id PK AUTO, station_id FK, type_id FK,
                  reporter_name, description, evidence_photo,
                  timestamp, ai_result, ai_confidence)
```

---

## Dependencies

```yaml
sqflite: ^2.3.0
path: ^1.8.3
image_picker: ^1.0.7
firebase_core: ^2.27.0
cloud_firestore: ^4.15.0
```

---

## วิธีรัน

```bash
flutter pub get
flutter run
```

> ⚠️ ต้องใส่ `google-services.json` ใน `android/app/` ก่อนรัน Firebase

---

## GitHub Repository

[https://github.com/Apinan1234/Flutter_Election_Watch-](https://github.com/Apinan1234/Flutter_Election_Watch-)
