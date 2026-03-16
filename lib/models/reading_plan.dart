/// نمط خطة القراءة — Reading Plan Type
enum ReadingPlanType {
  fullQuran, // ختمة كاملة
  customRange, // نطاق مخصص (سور أو أجزاء)
  dailyPages, // عدد صفحات يومي بدون نطاق محدد
}

/// موديل خطة القراءة — Reading Plan Model
class ReadingPlan {
  final String id;
  final String title;
  final ReadingPlanType type;
  final DateTime startDate;
  final DateTime? targetDate;
  final int? targetDays;
  final int startPage;
  final int endPage;
  int pagesRead;
  final List<int> reminderTimes; // Hours of the day (e.g., [8, 20])
  bool isActive;

  ReadingPlan({
    required this.id,
    required this.title,
    required this.type,
    required this.startDate,
    this.targetDate,
    this.targetDays,
    this.startPage = 1,
    this.endPage = 604,
    this.pagesRead = 0,
    this.reminderTimes = const [],
    this.isActive = true,
  });

  int get totalPages => (endPage - startPage + 1).abs();
  double get progress => (pagesRead / totalPages).clamp(0.0, 1.0);
  int get remainingPages => (totalPages - pagesRead).clamp(0, totalPages);
  
  bool get isCompleted => pagesRead >= totalPages;

  int get daysPassed => DateTime.now().difference(startDate).inDays;
  
  int get totalTargetDays {
    if (targetDays != null) return targetDays!;
    if (targetDate != null) return targetDate!.difference(startDate).inDays;
    return 30; // Default
  }

  int get dailyTarget {
    return (totalPages / totalTargetDays).ceil();
  }

  int get pagesNeededToday {
    final idealProgress = (daysPassed + 1) * dailyTarget;
    return (idealProgress - pagesRead).clamp(0, remainingPages);
  }

  bool get isOnTrack => pagesRead >= (daysPassed * dailyTarget);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.index,
    'startDate': startDate.toIso8601String(),
    'targetDate': targetDate?.toIso8601String(),
    'targetDays': targetDays,
    'startPage': startPage,
    'endPage': endPage,
    'pagesRead': pagesRead,
    'reminderTimes': reminderTimes,
    'isActive': isActive,
  };

  factory ReadingPlan.fromJson(Map<String, dynamic> json) => ReadingPlan(
    id: json['id'],
    title: json['title'],
    type: ReadingPlanType.values[json['type']],
    startDate: DateTime.parse(json['startDate']),
    targetDate: json['targetDate'] != null ? DateTime.parse(json['targetDate']) : null,
    targetDays: json['targetDays'],
    startPage: json['startPage'] ?? 1,
    endPage: json['endPage'] ?? 604,
    pagesRead: json['pagesRead'] ?? 0,
    reminderTimes: List<int>.from(json['reminderTimes'] ?? []),
    isActive: json['isActive'] ?? true,
  );
}
