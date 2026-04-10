class LibraryBook {
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String category;
  final bool isAvailable;
  final String? dueDate;

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
    String? dueDate,
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
        'isAvailable': isAvailable ? 1 : 0,
        'dueDate': dueDate,
      };

  factory LibraryBook.fromJson(Map<String, dynamic> json) => LibraryBook(
        id: json['id'],
        title: json['title'],
        author: json['author'],
        isbn: json['isbn'],
        category: json['category'],
        isAvailable: json['isAvailable'] == 1 || json['isAvailable'] == true,
        dueDate: json['dueDate'],
      );
}
