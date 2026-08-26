enum JobPriority {
  low,
  normal,
  high,
  urgent;

  String get label => switch (this) {
        JobPriority.low => 'Low',
        JobPriority.normal => 'Normal',
        JobPriority.high => 'High',
        JobPriority.urgent => 'Urgent',
      };

  static JobPriority fromString(String value) => switch (value) {
        'low' => JobPriority.low,
        'normal' => JobPriority.normal,
        'high' => JobPriority.high,
        'urgent' => JobPriority.urgent,
        _ => JobPriority.normal,
      };

  String get apiValue => name;
}
