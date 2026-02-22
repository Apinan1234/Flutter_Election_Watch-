class IncidentReport {
  final int?   reportId;
  final int    stationId;
  final int    typeId;
  final String reporterName;
  final String? description;
  final String? evidencePhoto;
  final String  timestamp;
  final String? aiResult;
  final double  aiConfidence;

  IncidentReport({
    this.reportId,
    required this.stationId,
    required this.typeId,
    required this.reporterName,
    this.description,
    this.evidencePhoto,
    required this.timestamp,
    this.aiResult,
    this.aiConfidence = 0.0,
  });

  factory IncidentReport.fromMap(Map<String, dynamic> m) => IncidentReport(
    reportId:      m['report_id']     as int?,
    stationId:     m['station_id']    as int,
    typeId:        m['type_id']       as int,
    reporterName:  m['reporter_name'] as String,
    description:   m['description']   as String?,
    evidencePhoto: m['evidence_photo']as String?,
    timestamp:     m['timestamp']     as String,
    aiResult:      m['ai_result']     as String?,
    aiConfidence:  (m['ai_confidence'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toMap() => {
    if (reportId != null) 'report_id': reportId,
    'station_id':    stationId,
    'type_id':       typeId,
    'reporter_name': reporterName,
    'description':   description,
    'evidence_photo':evidencePhoto,
    'timestamp':     timestamp,
    'ai_result':     aiResult,
    'ai_confidence': aiConfidence,
  };
}
