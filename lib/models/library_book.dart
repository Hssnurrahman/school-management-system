class LibraryBook {
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String category;
  final bool isAvailable;
  final DateTime? dueDate;

  LibraryBook({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.category,
    this.isAvailable = true,
    this.dueDate,
  });

  LibraryBook copyWith({
    String? id,
    String? title,
    String? author,
    String? isbn,
    String? category,
    bool? isAvailable,
    DateTime? dueDate,
  }) =>
      LibraryBook(
        id: id ?? this.id,
        title: title ?? this.title,
        author: author ?? this.author,
        isbn: isbn ?? this.isbn,
        category: category ?? this.category,
        isAvailable: isAvailable ?? this.isAvailable,
        dueDate: dueDate ?? this.dueDate,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'isbn': isbn,
        'category': category,
        'isAvailable': isAvailable,
        'dueDate': dueDate?.toIso8601String(),
      };

  factory LibraryBook.fromJson(Map<String, dynamic> json) {
    final rawDue = json['dueDate'];
    DateTime? dueDate;
    if (rawDue is String && rawDue.isNotEmpty) {
      dueDate = DateTime.tryParse(rawDue);
    }
    return LibraryBook(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      author: (json['author'] ?? '') as String,
      isbn: (json['isbn'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      isAvailable: json['isAvailable'] == null
          ? true
          : (json['isAvailable'] == 1 || json['isAvailable'] == true),
      dueDate: dueDate,
    );
  }
}
