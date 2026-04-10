import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/attendance_model.dart';
import '../models/class_model.dart';
import '../models/event_model.dart';
import '../models/fee_model.dart';
import '../models/grade_model.dart';
import '../models/homework_model.dart';
import '../models/inventory_item.dart';
import '../models/lesson_model.dart';
import '../models/library_book.dart';
import '../models/mark_model.dart';
import '../models/notice_model.dart';
import '../models/notification_model.dart';
import '../models/timetable_model.dart';
import '../models/transport_route.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'school_management.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        role TEXT NOT NULL,
        isActive INTEGER DEFAULT 1,
        phone TEXT,
        address TEXT,
        profileImageUrl TEXT,
        className TEXT,
        subject TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE classes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        teacherName TEXT NOT NULL,
        studentCount INTEGER NOT NULL,
        roomNumber TEXT NOT NULL,
        subject TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE fees (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        dueDate TEXT NOT NULL,
        isPaid INTEGER NOT NULL,
        category TEXT NOT NULL,
        studentName TEXT,
        studentId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE notices (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        date TEXT NOT NULL,
        author TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT,
        location TEXT NOT NULL,
        category TEXT NOT NULL,
        isAllDay INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE inventory (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE homework (
        id TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        title TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        description TEXT NOT NULL,
        isCompleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE marks (
        studentId TEXT NOT NULL,
        studentName TEXT NOT NULL,
        subject TEXT NOT NULL,
        marksObtained REAL,
        totalMarks REAL DEFAULT 100,
        grade TEXT,
        remarks TEXT,
        PRIMARY KEY (studentId, subject)
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance (
        studentId TEXT NOT NULL,
        studentName TEXT NOT NULL,
        date TEXT NOT NULL,
        isPresent INTEGER NOT NULL,
        PRIMARY KEY (studentId, date)
      )
    ''');

    await db.execute('''
      CREATE TABLE lessons (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        subject TEXT NOT NULL,
        className TEXT NOT NULL,
        teacherName TEXT NOT NULL,
        date TEXT NOT NULL,
        attachmentUrl TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE library_books (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        isbn TEXT NOT NULL,
        category TEXT NOT NULL,
        isAvailable INTEGER DEFAULT 1,
        dueDate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transport_routes (
        id TEXT PRIMARY KEY,
        routeName TEXT NOT NULL,
        driverName TEXT NOT NULL,
        driverPhone TEXT NOT NULL,
        vehicleNumber TEXT NOT NULL,
        stops TEXT NOT NULL,
        status TEXT DEFAULT 'Active'
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        type TEXT NOT NULL,
        isRead INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE grades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId TEXT NOT NULL,
        subject TEXT NOT NULL,
        score TEXT NOT NULL,
        grade TEXT NOT NULL,
        remarks TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE timetable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        subject TEXT NOT NULL,
        room TEXT NOT NULL,
        className TEXT DEFAULT 'All'
      )
    ''');

    // Seed default data
    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // Users
    final users = [
      UserModel(id: '1', name: 'Admin User', email: 'admin@school.com', role: UserRole.admin, phone: '1234567890', address: 'Admin Street 1'),
      UserModel(id: '2', name: 'John Teacher', email: 'teacher@school.com', role: UserRole.teacher, subject: 'Mathematics', phone: '0987654321'),
      UserModel(id: '3', name: 'Alice Smith', email: 'student@school.com', role: UserRole.student, className: 'Grade 10-A'),
      UserModel(id: '4', name: 'Parent User', email: 'parent@school.com', role: UserRole.parent),
      UserModel(id: '5', name: 'Sarah Wilson', email: 'sarah@school.com', role: UserRole.teacher, subject: 'Science'),
      UserModel(id: '6', name: 'Bob Jones', email: 'bob@school.com', role: UserRole.student, className: 'Grade 11-B'),
    ];
    for (final u in users) {
      await db.insert('users', u.toJson());
    }

    // Classes
    final classes = [
      ClassModel(id: '1', name: 'Grade 10-A', teacherName: 'John Teacher', studentCount: 35, roomNumber: 'Room 101', subject: 'Mathematics'),
      ClassModel(id: '2', name: 'Grade 11-B', teacherName: 'Sarah Wilson', studentCount: 28, roomNumber: 'Lab A', subject: 'Science'),
      ClassModel(id: '3', name: 'Grade 9-C', teacherName: 'Mike Johnson', studentCount: 32, roomNumber: 'Room 202', subject: 'History'),
      ClassModel(id: '4', name: 'Grade 12-A', teacherName: 'Emma Davis', studentCount: 25, roomNumber: 'Room 305', subject: 'Physics'),
    ];
    for (final c in classes) {
      await db.insert('classes', c.toJson());
    }

    // Fees
    final fees = [
      Fee(id: '1', title: 'Tuition Fee - Q1', amount: 1500.0, dueDate: DateTime(2024, 10, 15), isPaid: true, category: FeeCategory.tuition, studentName: 'Alice Smith'),
      Fee(id: '2', title: 'Library Fee', amount: 100.0, dueDate: DateTime(2024, 10, 20), isPaid: true, category: FeeCategory.library, studentName: 'Alice Smith'),
      Fee(id: '3', title: 'Tuition Fee - Q2', amount: 1500.0, dueDate: DateTime(2025, 1, 15), isPaid: false, category: FeeCategory.tuition, studentName: 'Alice Smith'),
      Fee(id: '4', title: 'Exam Fee', amount: 200.0, dueDate: DateTime(2024, 12, 10), isPaid: false, category: FeeCategory.exam, studentName: 'Alice Smith'),
      Fee(id: '5', title: 'Transport Fee', amount: 300.0, dueDate: DateTime(2024, 11, 5), isPaid: false, category: FeeCategory.transport, studentName: 'Bob Jones'),
    ];
    for (final f in fees) {
      await db.insert('fees', f.toJson());
    }

    // Notices
    final notices = [
      Notice(id: '1', title: 'Annual Sports Meet 2024', content: 'The annual sports meet will be held on Oct 15th at the city stadium. All students are encouraged to participate.', date: DateTime.now().subtract(const Duration(days: 1)), author: 'Sports Dept.'),
      Notice(id: '2', title: 'Mid-term Exam Schedule', content: 'Mid-term examinations will start from October 25th. Detailed subject-wise timetable is now available.', date: DateTime.now().subtract(const Duration(days: 3)), author: 'Principal Office'),
      Notice(id: '3', title: 'Local Holiday Announcement', content: 'The school will remain closed tomorrow due to the local festival celebrations.', date: DateTime.now().subtract(const Duration(days: 5)), author: 'Admin'),
    ];
    for (final n in notices) {
      await db.insert('notices', n.toJson());
    }

    // Events
    final events = [
      Event(id: '1', title: 'Annual Sports Day', description: 'Join us for a day of athletic competitions and fun activities.', startDate: DateTime.now().add(const Duration(days: 5)), location: 'School Sports Ground', category: 'Sports'),
      Event(id: '2', title: 'Parent-Teacher Conference', description: 'A meeting between parents and teachers to discuss student progress.', startDate: DateTime.now().add(const Duration(days: 2)), location: 'Conference Hall A', category: 'Academic'),
      Event(id: '3', title: 'Science Fair', description: 'Students showcase their innovative science projects.', startDate: DateTime.now().add(const Duration(days: 10)), location: 'Main Auditorium', category: 'Academic'),
    ];
    for (final e in events) {
      await db.insert('events', e.toJson());
    }

    // Inventory
    final inventory = [
      InventoryItem(id: '1', name: 'A4 Paper', category: 'Stationery', quantity: 50, unit: 'Reams', status: InventoryStatus.inStock),
      InventoryItem(id: '2', name: 'Whiteboard Markers', category: 'Stationery', quantity: 5, unit: 'Boxes', status: InventoryStatus.lowStock),
      InventoryItem(id: '3', name: 'Projectors', category: 'Electronics', quantity: 12, unit: 'Units', status: InventoryStatus.inStock),
      InventoryItem(id: '4', name: 'First Aid Kits', category: 'Medical', quantity: 0, unit: 'Kits', status: InventoryStatus.outOfStock),
      InventoryItem(id: '5', name: 'Basket Balls', category: 'Sports', quantity: 20, unit: 'Pcs', status: InventoryStatus.inStock),
    ];
    for (final i in inventory) {
      await db.insert('inventory', i.toJson());
    }

    // Homework
    final homework = [
      Homework(id: 'hw1', subject: 'Mathematics', title: 'Calculus Exercise 1', dueDate: DateTime.now().add(const Duration(days: 2)), description: 'Solve problems 1 to 10 on page 45 of your textbook.'),
      Homework(id: 'hw2', subject: 'History', title: 'French Revolution Essay', dueDate: DateTime.now().add(const Duration(days: 5)), description: 'Write a 500-word essay on the primary causes of the French Revolution.', isCompleted: true),
      Homework(id: 'hw3', subject: 'Physics', title: "Lab Report: Ohm's Law", dueDate: DateTime.now().add(const Duration(days: 1)), description: 'Submit the detailed report including graph and calculations.'),
    ];
    for (final h in homework) {
      await db.insert('homework', h.toJson());
    }

    // Marks
    final marks = [
      MarkEntry(studentId: '101', studentName: 'Alice Smith', subject: 'Mathematics'),
      MarkEntry(studentId: '102', studentName: 'Bob Jones', subject: 'Mathematics', marksObtained: 85),
      MarkEntry(studentId: '103', studentName: 'Charlie Brown', subject: 'Mathematics', marksObtained: 45),
      MarkEntry(studentId: '104', studentName: 'David Wilson', subject: 'Mathematics', marksObtained: 72),
      MarkEntry(studentId: '105', studentName: 'Eve Davis', subject: 'Mathematics'),
    ];
    for (final m in marks) {
      await db.insert('marks', m.toJson());
    }

    // Attendance
    final today = DateTime.now();
    final attendance = [
      Attendance(studentId: '101', studentName: 'Alice Smith', date: today, isPresent: true),
      Attendance(studentId: '102', studentName: 'Bob Jones', date: today, isPresent: true),
      Attendance(studentId: '103', studentName: 'Charlie Brown', date: today, isPresent: false),
      Attendance(studentId: '104', studentName: 'David Wilson', date: today, isPresent: true),
      Attendance(studentId: '105', studentName: 'Eve Davis', date: today, isPresent: true),
      Attendance(studentId: '106', studentName: 'Frank Miller', date: today, isPresent: true),
      Attendance(studentId: '107', studentName: 'Grace Lee', date: today, isPresent: false),
    ];
    for (final a in attendance) {
      await db.insert('attendance', a.toJson());
    }

    // Lessons
    final lessons = [
      Lesson(id: '1', title: 'Introduction to Algebra', description: 'Understanding variables and simple equations.', subject: 'Mathematics', className: 'Grade 10-A', teacherName: 'John Teacher', date: '2024-11-01'),
      Lesson(id: '2', title: 'Chemical Bonding', description: 'Study of ionic and covalent bonds.', subject: 'Science', className: 'Grade 11-B', teacherName: 'Sarah Wilson', date: '2024-11-02'),
      Lesson(id: '3', title: 'World War II Summary', description: 'Overview of major events of the Second World War.', subject: 'History', className: 'Grade 9-C', teacherName: 'Mike Johnson', date: '2024-10-30'),
    ];
    for (final l in lessons) {
      await db.insert('lessons', l.toJson());
    }

    // Library Books
    final books = [
      LibraryBook(id: '1', title: 'The Great Gatsby', author: 'F. Scott Fitzgerald', isbn: '9780743273565', category: 'Fiction'),
      LibraryBook(id: '2', title: 'Brief History of Time', author: 'Stephen Hawking', isbn: '9780553380163', category: 'Science', isAvailable: false, dueDate: '2025-11-25'),
      LibraryBook(id: '3', title: 'Clean Code', author: 'Robert C. Martin', isbn: '9780132350884', category: 'Technology'),
      LibraryBook(id: '4', title: 'The Art of War', author: 'Sun Tzu', isbn: '9781590302255', category: 'Philosophy'),
      LibraryBook(id: '5', title: 'Physics for Scientists', author: 'Raymond Serway', isbn: '9781133947271', category: 'Science', isAvailable: false, dueDate: '2025-11-20'),
    ];
    for (final b in books) {
      await db.insert('library_books', b.toJson());
    }

    // Transport Routes
    final routes = [
      TransportRoute(id: '1', routeName: 'Route A - North', driverName: 'John Doe', driverPhone: '+1234567890', vehicleNumber: 'BUS-001', stops: ['Main Station', 'Green Park', 'North Gate', 'School']),
      TransportRoute(id: '2', routeName: 'Route B - South', driverName: 'Sam Smith', driverPhone: '+1987654321', vehicleNumber: 'BUS-002', stops: ['South Terminal', 'River Side', 'East Square', 'School']),
      TransportRoute(id: '3', routeName: 'Route C - West', driverName: 'Mike Johnson', driverPhone: '+1555444333', vehicleNumber: 'BUS-003', stops: ['West Hub', 'Valley View', 'Sunset Blvd', 'School'], status: 'Maintenance'),
    ];
    for (final r in routes) {
      await db.insert('transport_routes', r.toJson());
    }

    // Notifications
    final notifications = [
      NotificationModel(id: '1', title: 'Leave Request', description: 'John Teacher has requested leave for Oct 25th.', timestamp: DateTime.now().subtract(const Duration(minutes: 30)), type: NotificationType.approval),
      NotificationModel(id: '2', title: 'Low Stock Alert', description: 'A4 Paper supply is below 10 reams. Please restock.', timestamp: DateTime.now().subtract(const Duration(hours: 2)), type: NotificationType.stock),
      NotificationModel(id: '3', title: 'Fee Payment Received', description: 'Alice Smith has paid the Tuition Fee for Q2.', timestamp: DateTime.now().subtract(const Duration(hours: 5)), type: NotificationType.finance, isRead: true),
      NotificationModel(id: '4', title: 'System Update', description: 'App maintenance scheduled for Sunday at 2 AM.', timestamp: DateTime.now().subtract(const Duration(days: 1)), type: NotificationType.system, isRead: true),
    ];
    for (final n in notifications) {
      await db.insert('notifications', n.toJson());
    }

    // Grades (student id '3' = Alice Smith, '6' = Bob Jones)
    final gradeRows = [
      {'studentId': '3', 'subject': 'Mathematics', 'score': '85/100', 'grade': 'A', 'remarks': 'Excellent performance'},
      {'studentId': '3', 'subject': 'Science', 'score': '78/100', 'grade': 'B+', 'remarks': 'Good, keep it up'},
      {'studentId': '3', 'subject': 'English', 'score': '92/100', 'grade': 'A+', 'remarks': 'Outstanding'},
      {'studentId': '3', 'subject': 'History', 'score': '65/100', 'grade': 'C', 'remarks': 'Needs improvement'},
      {'studentId': '3', 'subject': 'Physics', 'score': '88/100', 'grade': 'A', 'remarks': 'Very good'},
      {'studentId': '3', 'subject': 'Chemistry', 'score': '74/100', 'grade': 'B', 'remarks': 'Can do better'},
      {'studentId': '6', 'subject': 'Mathematics', 'score': '72/100', 'grade': 'B+', 'remarks': 'Good effort'},
      {'studentId': '6', 'subject': 'Science', 'score': '90/100', 'grade': 'A+', 'remarks': 'Excellent'},
      {'studentId': '6', 'subject': 'English', 'score': '60/100', 'grade': 'C', 'remarks': 'Needs more practice'},
    ];
    for (final g in gradeRows) {
      await db.insert('grades', g);
    }

    // Timetable
    final timetableRows = [
      {'day': 'Monday', 'startTime': '08:00 AM', 'endTime': '09:00 AM', 'subject': 'Mathematics', 'room': 'Room 101', 'className': 'Grade 10-A'},
      {'day': 'Monday', 'startTime': '09:00 AM', 'endTime': '10:00 AM', 'subject': 'Physics', 'room': 'Lab A', 'className': 'Grade 10-A'},
      {'day': 'Monday', 'startTime': '10:30 AM', 'endTime': '11:30 AM', 'subject': 'English', 'room': 'Room 202', 'className': 'Grade 10-A'},
      {'day': 'Tuesday', 'startTime': '08:00 AM', 'endTime': '09:00 AM', 'subject': 'Chemistry', 'room': 'Lab B', 'className': 'Grade 10-A'},
      {'day': 'Tuesday', 'startTime': '09:00 AM', 'endTime': '10:00 AM', 'subject': 'Biology', 'room': 'Room 105', 'className': 'Grade 10-A'},
      {'day': 'Wednesday', 'startTime': '11:00 AM', 'endTime': '12:00 PM', 'subject': 'History', 'room': 'Room 303', 'className': 'Grade 10-A'},
      {'day': 'Thursday', 'startTime': '08:00 AM', 'endTime': '09:00 AM', 'subject': 'Mathematics', 'room': 'Room 101', 'className': 'Grade 10-A'},
      {'day': 'Thursday', 'startTime': '10:00 AM', 'endTime': '11:00 AM', 'subject': 'English', 'room': 'Room 202', 'className': 'Grade 10-A'},
      {'day': 'Friday', 'startTime': '09:00 AM', 'endTime': '10:00 AM', 'subject': 'Physics', 'room': 'Lab A', 'className': 'Grade 10-A'},
      {'day': 'Friday', 'startTime': '11:00 AM', 'endTime': '12:00 PM', 'subject': 'Chemistry', 'room': 'Lab B', 'className': 'Grade 10-A'},
    ];
    for (final t in timetableRows) {
      await db.insert('timetable', t);
    }
  }

  Future<List<UserModel>> getUsers() async {
    final d = await db;
    final rows = await d.query('users');
    return rows.map(UserModel.fromJson).toList();
  }

  Future<void> insertUser(UserModel user) async {
    final d = await db;
    await d.insert('users', user.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateUser(UserModel user) async {
    final d = await db;
    await d.update('users', user.toJson(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<void> deleteUser(String id) async {
    final d = await db;
    await d.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ─── CLASSES ─────────────────────────────────────────────────────────────────

  Future<List<ClassModel>> getClasses() async {
    final d = await db;
    final rows = await d.query('classes');
    return rows.map(ClassModel.fromJson).toList();
  }

  Future<void> insertClass(ClassModel c) async {
    final d = await db;
    await d.insert('classes', c.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteClass(String id) async {
    final d = await db;
    await d.delete('classes', where: 'id = ?', whereArgs: [id]);
  }

  // ─── FEES ─────────────────────────────────────────────────────────────────────

  Future<List<Fee>> getFees() async {
    final d = await db;
    final rows = await d.query('fees', orderBy: 'dueDate ASC');
    return rows.map(Fee.fromJson).toList();
  }

  Future<void> insertFee(Fee fee) async {
    final d = await db;
    await d.insert('fees', fee.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateFee(Fee fee) async {
    final d = await db;
    await d.update('fees', fee.toJson(), where: 'id = ?', whereArgs: [fee.id]);
  }

  Future<void> deleteFee(String id) async {
    final d = await db;
    await d.delete('fees', where: 'id = ?', whereArgs: [id]);
  }

  // ─── NOTICES ─────────────────────────────────────────────────────────────────

  Future<List<Notice>> getNotices() async {
    final d = await db;
    final rows = await d.query('notices', orderBy: 'date DESC');
    return rows.map(Notice.fromJson).toList();
  }

  Future<void> insertNotice(Notice notice) async {
    final d = await db;
    await d.insert('notices', notice.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteNotice(String id) async {
    final d = await db;
    await d.delete('notices', where: 'id = ?', whereArgs: [id]);
  }

  // ─── EVENTS ──────────────────────────────────────────────────────────────────

  Future<List<Event>> getEvents() async {
    final d = await db;
    final rows = await d.query('events', orderBy: 'startDate ASC');
    return rows.map(Event.fromJson).toList();
  }

  Future<void> insertEvent(Event event) async {
    final d = await db;
    await d.insert('events', event.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteEvent(String id) async {
    final d = await db;
    await d.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  // ─── INVENTORY ───────────────────────────────────────────────────────────────

  Future<List<InventoryItem>> getInventory() async {
    final d = await db;
    final rows = await d.query('inventory');
    return rows.map(InventoryItem.fromJson).toList();
  }

  Future<void> insertInventoryItem(InventoryItem item) async {
    final d = await db;
    await d.insert('inventory', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteInventoryItem(String id) async {
    final d = await db;
    await d.delete('inventory', where: 'id = ?', whereArgs: [id]);
  }

  // ─── HOMEWORK ────────────────────────────────────────────────────────────────

  Future<List<Homework>> getHomework() async {
    final d = await db;
    final rows = await d.query('homework', orderBy: 'dueDate ASC');
    return rows.map(Homework.fromJson).toList();
  }

  Future<void> insertHomework(Homework hw) async {
    final d = await db;
    await d.insert('homework', hw.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateHomework(Homework hw) async {
    final d = await db;
    await d.update('homework', hw.toJson(), where: 'id = ?', whereArgs: [hw.id]);
  }

  Future<void> deleteHomework(String id) async {
    final d = await db;
    await d.delete('homework', where: 'id = ?', whereArgs: [id]);
  }

  // ─── MARKS ───────────────────────────────────────────────────────────────────

  Future<List<MarkEntry>> getMarks({String? subject}) async {
    final d = await db;
    final rows = subject != null
        ? await d.query('marks', where: 'subject = ?', whereArgs: [subject])
        : await d.query('marks');
    return rows.map(MarkEntry.fromJson).toList();
  }

  Future<void> upsertMark(MarkEntry mark) async {
    final d = await db;
    await d.insert('marks', mark.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ─── ATTENDANCE ──────────────────────────────────────────────────────────────

  Future<List<Attendance>> getAttendanceForDate(DateTime date) async {
    final d = await db;
    final dateStr = date.toIso8601String().split('T')[0];
    final rows = await d.query('attendance', where: "date LIKE ?", whereArgs: ['$dateStr%']);
    if (rows.isEmpty) {
      // Return default list if no attendance recorded for this date
      return _defaultStudents(date);
    }
    return rows.map(Attendance.fromJson).toList();
  }

  List<Attendance> _defaultStudents(DateTime date) => [
        Attendance(studentId: '101', studentName: 'Alice Smith', date: date, isPresent: true),
        Attendance(studentId: '102', studentName: 'Bob Jones', date: date, isPresent: true),
        Attendance(studentId: '103', studentName: 'Charlie Brown', date: date, isPresent: false),
        Attendance(studentId: '104', studentName: 'David Wilson', date: date, isPresent: true),
        Attendance(studentId: '105', studentName: 'Eve Davis', date: date, isPresent: true),
        Attendance(studentId: '106', studentName: 'Frank Miller', date: date, isPresent: true),
        Attendance(studentId: '107', studentName: 'Grace Lee', date: date, isPresent: false),
      ];

  Future<void> saveAttendance(List<Attendance> records) async {
    final d = await db;
    final batch = d.batch();
    for (final a in records) {
      batch.insert('attendance', a.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // ─── LESSONS ─────────────────────────────────────────────────────────────────

  Future<List<Lesson>> getLessons() async {
    final d = await db;
    final rows = await d.query('lessons', orderBy: 'date DESC');
    return rows.map(Lesson.fromJson).toList();
  }

  Future<void> insertLesson(Lesson lesson) async {
    final d = await db;
    await d.insert('lessons', lesson.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteLesson(String id) async {
    final d = await db;
    await d.delete('lessons', where: 'id = ?', whereArgs: [id]);
  }

  // ─── LIBRARY ─────────────────────────────────────────────────────────────────

  Future<List<LibraryBook>> getBooks() async {
    final d = await db;
    final rows = await d.query('library_books');
    return rows.map(LibraryBook.fromJson).toList();
  }

  Future<void> insertBook(LibraryBook book) async {
    final d = await db;
    await d.insert('library_books', book.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateBook(LibraryBook book) async {
    final d = await db;
    await d.update('library_books', book.toJson(), where: 'id = ?', whereArgs: [book.id]);
  }

  Future<void> deleteBook(String id) async {
    final d = await db;
    await d.delete('library_books', where: 'id = ?', whereArgs: [id]);
  }

  // ─── TRANSPORT ───────────────────────────────────────────────────────────────

  Future<List<TransportRoute>> getRoutes() async {
    final d = await db;
    final rows = await d.query('transport_routes');
    return rows.map(TransportRoute.fromJson).toList();
  }

  Future<void> insertRoute(TransportRoute route) async {
    final d = await db;
    await d.insert('transport_routes', route.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteRoute(String id) async {
    final d = await db;
    await d.delete('transport_routes', where: 'id = ?', whereArgs: [id]);
  }

  // ─── NOTIFICATIONS ───────────────────────────────────────────────────────────

  Future<List<NotificationModel>> getNotifications() async {
    final d = await db;
    final rows = await d.query('notifications', orderBy: 'timestamp DESC');
    return rows.map(NotificationModel.fromJson).toList();
  }

  Future<void> insertNotification(NotificationModel n) async {
    final d = await db;
    await d.insert('notifications', n.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> markNotificationRead(String id) async {
    final d = await db;
    await d.update('notifications', {'isRead': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markAllNotificationsRead() async {
    final d = await db;
    await d.update('notifications', {'isRead': 1});
  }

  // ─── GRADES ──────────────────────────────────────────────────────────────────

  Future<List<Grade>> getGradesForStudent(String studentId) async {
    final d = await db;
    final rows = await d.query('grades', where: 'studentId = ?', whereArgs: [studentId]);
    return rows.map((r) => Grade(
      subject: r['subject'] as String,
      score: r['score'] as String,
      grade: r['grade'] as String,
      remarks: r['remarks'] as String,
    )).toList();
  }

  Future<void> upsertGrade(String studentId, Grade grade) async {
    final d = await db;
    // Delete existing entry for this student+subject, then insert
    await d.delete('grades', where: 'studentId = ? AND subject = ?', whereArgs: [studentId, grade.subject]);
    await d.insert('grades', {
      'studentId': studentId,
      'subject': grade.subject,
      'score': grade.score,
      'grade': grade.grade,
      'remarks': grade.remarks,
    });
  }

  // ─── TIMETABLE ───────────────────────────────────────────────────────────────

  Future<List<TimetableEntry>> getTimetable({String? className}) async {
    final d = await db;
    final rows = className != null
        ? await d.query('timetable', where: 'className = ?', whereArgs: [className])
        : await d.query('timetable');
    return rows.map((r) => TimetableEntry(
      day: r['day'] as String,
      startTime: r['startTime'] as String,
      endTime: r['endTime'] as String,
      subject: r['subject'] as String,
      room: r['room'] as String,
    )).toList();
  }

  Future<void> insertTimetableEntry(TimetableEntry entry, {String className = 'All'}) async {
    final d = await db;
    await d.insert('timetable', {
      'day': entry.day,
      'startTime': entry.startTime,
      'endTime': entry.endTime,
      'subject': entry.subject,
      'room': entry.room,
      'className': className,
    });
  }

  Future<void> deleteTimetableEntry(int id) async {
    final d = await db;
    await d.delete('timetable', where: 'id = ?', whereArgs: [id]);
  }

  // ─── STUDENT ATTENDANCE VIEW ─────────────────────────────────────────────────

  /// Returns attendance records for a specific student across all dates
  Future<List<Attendance>> getAttendanceForStudent(String studentId) async {
    final d = await db;
    final rows = await d.query('attendance',
        where: 'studentId = ?', whereArgs: [studentId], orderBy: 'date DESC');
    return rows.map(Attendance.fromJson).toList();
  }
}

final dbService = DatabaseService();
