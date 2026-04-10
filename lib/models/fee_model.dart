enum FeeCategory { tuition, library, exam, transport, sports }

class Fee {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  final FeeCategory category;
  final String? studentName;
  final String? studentId;

  Fee({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.isPaid,
    required this.category,
    this.studentName,
    this.studentId,
  });

  Fee copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    bool? isPaid,
    FeeCategory? category,
    String? studentName,
    String? studentId,
  }) {
    return Fee(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      category: category ?? this.category,
      studentName: studentName ?? this.studentName,
      studentId: studentId ?? this.studentId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'isPaid': isPaid ? 1 : 0,
        'category': category.name,
        'studentName': studentName,
        'studentId': studentId,
      };

  factory Fee.fromJson(Map<String, dynamic> json) => Fee(
        id: json['id'],
        title: json['title'],
        amount: (json['amount'] as num).toDouble(),
        dueDate: DateTime.parse(json['dueDate']),
        isPaid: json['isPaid'] == 1 || json['isPaid'] == true,
        category: FeeCategory.values.firstWhere((e) => e.name == json['category']),
        studentName: json['studentName'],
        studentId: json['studentId'],
      );
}
