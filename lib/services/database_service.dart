import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';
import '../models/class_model.dart';
import '../models/event_model.dart';
import '../models/exam_model.dart';
import '../models/fee_model.dart';
import '../models/grade_model.dart';
import '../models/homework_model.dart';
import '../models/inventory_item.dart';
import '../models/lesson_model.dart';
import '../models/library_book.dart';
import '../models/notice_model.dart';
import '../models/notification_model.dart';
import '../models/timetable_model.dart';
import '../models/subject_model.dart';
import '../models/transport_route.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final _fs = FirebaseFirestore.instance;

  // ─── HELPERS ─────────────────────────────────────────────────────────────────

  CollectionReference _col(String name) => _fs.collection(name);

  Map<String, dynamic> _snap(DocumentSnapshot doc) =>
      {...(doc.data() as Map<String, dynamic>), 'id': doc.id};

  // ─── USERS ───────────────────────────────────────────────────────────────────

  Future<List<UserModel>> getUsers() async {
    final snap = await _col('users').get();
    return snap.docs.map((d) => UserModel.fromJson(_snap(d))).toList();
  }

  Future<List<UserModel>> getStudentsByClass(String className) async {
    var snap = await _col('users')
        .where('role', isEqualTo: 'student')
        .where('className', isEqualTo: className.trim())
        .get();
    if (snap.docs.isEmpty) {
      snap = await _col('users')
          .where('role', isEqualTo: 'student')
          .get();
    }
    final users = snap.docs.map((d) => UserModel.fromJson(_snap(d))).toList();
    users.sort((a, b) => a.name.compareTo(b.name));
    return users;
  }

  Future<void> insertUser(UserModel user) async {
    await _col('users').doc(user.id).set(user.toJson());
  }

  Future<void> updateUser(UserModel user) async {
    await _col('users').doc(user.id).update(user.toJson());
  }

  Future<void> deleteUser(String id) async {
    final batch = _fs.batch();
    batch.delete(_col('users').doc(id));

    // Cascade: attendance
    final att = await _col('attendance').where('studentId', isEqualTo: id).get();
    for (final d in att.docs) { batch.delete(d.reference); }

    // Cascade: grades
    final grades = await _col('grades').where('studentId', isEqualTo: id).get();
    for (final d in grades.docs) { batch.delete(d.reference); }

    // Cascade: exam_results
    final results = await _col('exam_results').where('studentId', isEqualTo: id).get();
    for (final d in results.docs) { batch.delete(d.reference); }

    // Cascade: teacher_classes
    final tc = await _col('teacher_classes').where('teacherId', isEqualTo: id).get();
    for (final d in tc.docs) { batch.delete(d.reference); }

    // Cascade: teacher_subjects
    final ts = await _col('teacher_subjects').where('teacherId', isEqualTo: id).get();
    for (final d in ts.docs) { batch.delete(d.reference); }

    // Cascade: teacher_class_subjects
    final tcs = await _col('teacher_class_subjects').where('teacherId', isEqualTo: id).get();
    for (final d in tcs.docs) { batch.delete(d.reference); }

    await batch.commit();
  }

  Future<void> refreshCurrentUser() async {}

  // ─── SETTINGS ────────────────────────────────────────────────────────────────

  Future<void> saveSchoolInfo(Map<String, String> info) async {
    final batch = _fs.batch();
    for (final entry in info.entries) {
      batch.set(
        _col('settings').doc('school_${entry.key}'),
        {'key': 'school_${entry.key}', 'value': entry.value},
      );
    }
    await batch.commit();
  }

  Future<Map<String, String>> getSchoolInfo() async {
    final keys = ['name', 'address', 'phone', 'email'];
    final result = <String, String>{};
    for (final key in keys) {
      result[key] = await getSetting('school_$key') ?? '';
    }
    return result;
  }

  Future<String?> getSetting(String key) async {
    final doc = await _col('settings').doc(key).get();
    if (!doc.exists) return null;
    return (doc.data() as Map<String, dynamic>?)?['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    await _col('settings').doc(key).set({'key': key, 'value': value});
  }

  // ─── SUBJECTS ────────────────────────────────────────────────────────────────

  Future<List<SubjectModel>> getSubjects() async {
    final snap = await _col('subjects').orderBy('name').get();
    return snap.docs.map((d) => SubjectModel.fromJson(_snap(d))).toList();
  }

  Future<void> insertSubject(SubjectModel subject) async {
    await _col('subjects').doc(subject.id).set(subject.toJson());
  }

  Future<void> deleteSubject(String id) async {
    await _col('subjects').doc(id).delete();
  }

  // ─── CLASSES ─────────────────────────────────────────────────────────────────

  Future<List<ClassModel>> getClasses() async {
    final snap = await _col('classes').get();
    return snap.docs.map((d) => ClassModel.fromJson(_snap(d))).toList();
  }

  Future<Map<String, int>> getStudentCountPerClass() async {
    final snap = await _col('users')
        .where('role', isEqualTo: 'student')
        .get();
    final result = <String, int>{};
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final cls = data['className'] as String?;
      if (cls != null && cls.isNotEmpty) {
        result[cls] = (result[cls] ?? 0) + 1;
      }
    }
    return result;
  }

  Future<void> insertClass(ClassModel c) async {
    await _col('classes').doc(c.id).set(c.toJson());
  }

  Future<void> deleteClass(String id) async {
    await _col('classes').doc(id).delete();
  }

  // ─── FEES ────────────────────────────────────────────────────────────────────

  Future<List<Fee>> getFees() async {
    final snap = await _col('fees').orderBy('dueDate').get();
    return snap.docs.map((d) => Fee.fromJson(_snap(d))).toList();
  }

  Future<void> insertFee(Fee fee) async {
    await _col('fees').doc(fee.id).set(fee.toJson());
  }

  Future<void> updateFee(Fee fee) async {
    await _col('fees').doc(fee.id).update(fee.toJson());
  }

  Future<void> deleteFee(String id) async {
    await _col('fees').doc(id).delete();
  }

  // ─── RECENT ACTIVITY ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 5}) async {
    final items = <Map<String, dynamic>>[];

    final notices = await _col('notices').orderBy('date', descending: true).limit(limit).get();
    for (final d in notices.docs) {
      final r = d.data() as Map<String, dynamic>;
      items.add({'title': r['title'], 'subtitle': r['content'], 'date': DateTime.parse(r['date']), 'type': 'notice'});
    }

    final events = await _col('events').orderBy('startDate', descending: true).limit(limit).get();
    for (final d in events.docs) {
      final r = d.data() as Map<String, dynamic>;
      items.add({'title': r['title'], 'subtitle': r['description'], 'date': DateTime.parse(r['startDate']), 'type': 'event'});
    }

    final exams = await _col('exams').orderBy('date', descending: true).limit(limit).get();
    for (final d in exams.docs) {
      final r = d.data() as Map<String, dynamic>;
      items.add({'title': r['title'], 'subtitle': '${r['subject']} · ${r['className']}', 'date': DateTime.parse(r['date']), 'type': 'exam'});
    }

    final hw = await _col('homework').orderBy('dueDate', descending: true).limit(limit).get();
    for (final d in hw.docs) {
      final r = d.data() as Map<String, dynamic>;
      items.add({'title': r['title'], 'subtitle': r['subject'], 'date': DateTime.parse(r['dueDate']), 'type': 'homework'});
    }

    items.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return items.take(limit).toList();
  }

  // ─── NOTICES ─────────────────────────────────────────────────────────────────

  Future<List<Notice>> getNotices() async {
    final snap = await _col('notices').orderBy('date', descending: true).get();
    return snap.docs.map((d) => Notice.fromJson(_snap(d))).toList();
  }

  Future<void> insertNotice(Notice notice) async {
    await _col('notices').doc(notice.id).set(notice.toJson());
  }

  Future<void> deleteNotice(String id) async {
    await _col('notices').doc(id).delete();
  }

  // ─── EVENTS ──────────────────────────────────────────────────────────────────

  Future<List<Event>> getEvents() async {
    final snap = await _col('events').orderBy('startDate').get();
    return snap.docs.map((d) => Event.fromJson(_snap(d))).toList();
  }

  Future<void> insertEvent(Event event) async {
    await _col('events').doc(event.id).set(event.toJson());
  }

  Future<void> deleteEvent(String id) async {
    await _col('events').doc(id).delete();
  }

  // ─── INVENTORY ───────────────────────────────────────────────────────────────

  Future<List<InventoryItem>> getInventory() async {
    final snap = await _col('inventory').get();
    return snap.docs.map((d) => InventoryItem.fromJson(_snap(d))).toList();
  }

  Future<void> insertInventoryItem(InventoryItem item) async {
    await _col('inventory').doc(item.id).set(item.toJson());
  }

  Future<void> deleteInventoryItem(String id) async {
    await _col('inventory').doc(id).delete();
  }

  // ─── HOMEWORK ────────────────────────────────────────────────────────────────

  Future<List<Homework>> getHomework() async {
    final snap = await _col('homework').orderBy('dueDate').get();
    return snap.docs.map((d) => Homework.fromJson(_snap(d))).toList();
  }

  Future<void> insertHomework(Homework hw) async {
    await _col('homework').doc(hw.id).set(hw.toJson());
  }

  Future<void> updateHomework(Homework hw) async {
    await _col('homework').doc(hw.id).update(hw.toJson());
  }

  Future<void> deleteHomework(String id) async {
    await _col('homework').doc(id).delete();
  }

  // ─── ATTENDANCE ──────────────────────────────────────────────────────────────

  Future<List<Attendance>> getAttendanceForDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final snap = await _col('attendance').where('date', isGreaterThanOrEqualTo: dateStr).where('date', isLessThan: '${dateStr}Z').get();

    if (snap.docs.isEmpty) return _defaultStudents(date);

    final saved = snap.docs.map((d) => Attendance.fromJson(_snap(d))).toList();
    final savedIds = saved.map((a) => a.studentId).toSet();

    final allStudents = await _col('users').where('role', isEqualTo: 'student').get();
    for (final d in allStudents.docs) {
      final data = d.data() as Map<String, dynamic>;
      final id = d.id;
      if (!savedIds.contains(id)) {
        saved.add(Attendance(
          studentId: id,
          studentName: data['name'] ?? '',
          date: date,
          isPresent: false,
          isLate: false,
        ));
      }
    }
    return saved;
  }

  List<Attendance> _defaultStudents(DateTime date) => [];

  Future<List<Attendance>> getAllStudentsForAttendance(DateTime date) async {
    final snap = await _col('users').where('role', isEqualTo: 'student').get();
    return snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return Attendance(
        studentId: d.id,
        studentName: data['name'] ?? '',
        date: date,
        isPresent: true,
        isLate: false,
      );
    }).toList();
  }

  Future<void> saveAttendance(List<Attendance> records) async {
    final batch = _fs.batch();
    for (final a in records) {
      final id = '${a.studentId}_${a.date.toIso8601String().split('T')[0]}';
      batch.set(_col('attendance').doc(id), a.toJson());
    }
    await batch.commit();
  }

  Future<List<Attendance>> getAttendanceForStudent(String studentId) async {
    final snap = await _col('attendance')
        .where('studentId', isEqualTo: studentId)
        .get();
    final records = snap.docs.map((d) => Attendance.fromJson(_snap(d))).toList();
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  Future<List<Attendance>> getAllAttendance() async {
    final snap = await _col('attendance').get();
    return snap.docs.map((d) => Attendance.fromJson(_snap(d))).toList();
  }

  // ─── TEACHER CLASSES ─────────────────────────────────────────────────────────

  Future<void> saveTeacherClasses(String teacherId, List<String> classNames) async {
    final existing = await _col('teacher_classes').where('teacherId', isEqualTo: teacherId).get();
    final batch = _fs.batch();
    for (final d in existing.docs) { batch.delete(d.reference); }
    for (final cls in classNames) {
      final docId = '${teacherId}_$cls';
      batch.set(_col('teacher_classes').doc(docId), {'teacherId': teacherId, 'className': cls});
    }
    await batch.commit();
  }

  Future<List<String>> getTeacherClasses(String teacherId) async {
    final snap = await _col('teacher_classes').where('teacherId', isEqualTo: teacherId).get();
    return snap.docs.map((d) => (d.data() as Map<String, dynamic>)['className'] as String).toList();
  }

  Future<void> saveTeacherSubjects(String teacherId, List<String> subjects) async {
    final existing = await _col('teacher_subjects').where('teacherId', isEqualTo: teacherId).get();
    final batch = _fs.batch();
    for (final d in existing.docs) { batch.delete(d.reference); }
    for (final s in subjects) {
      final docId = '${teacherId}_$s';
      batch.set(_col('teacher_subjects').doc(docId), {'teacherId': teacherId, 'subject': s});
    }
    await batch.commit();
  }

  Future<List<String>> getTeacherSubjects(String teacherId) async {
    final snap = await _col('teacher_subjects').where('teacherId', isEqualTo: teacherId).get();
    return snap.docs.map((d) => (d.data() as Map<String, dynamic>)['subject'] as String).toList();
  }

  Future<void> saveTeacherClassSubjects(String teacherId, String className, List<String> subjects) async {
    final existing = await _col('teacher_class_subjects')
        .where('teacherId', isEqualTo: teacherId)
        .where('className', isEqualTo: className)
        .get();
    final batch = _fs.batch();
    for (final d in existing.docs) { batch.delete(d.reference); }
    for (final s in subjects) {
      final docId = '${teacherId}_${className}_$s';
      batch.set(_col('teacher_class_subjects').doc(docId), {'teacherId': teacherId, 'className': className, 'subject': s});
    }
    await batch.commit();
  }

  Future<List<String>> getTeacherClassSubjects(String teacherId, String className) async {
    final snap = await _col('teacher_class_subjects')
        .where('teacherId', isEqualTo: teacherId)
        .where('className', isEqualTo: className)
        .get();
    return snap.docs.map((d) => (d.data() as Map<String, dynamic>)['subject'] as String).toList();
  }

  Future<void> clearTeacherClassSubjects(String teacherId) async {
    final snap = await _col('teacher_class_subjects').where('teacherId', isEqualTo: teacherId).get();
    final batch = _fs.batch();
    for (final d in snap.docs) { batch.delete(d.reference); }
    await batch.commit();
  }

  Future<Map<String, List<String>>> getTeacherAllClassSubjects(String teacherId) async {
    final snap = await _col('teacher_class_subjects').where('teacherId', isEqualTo: teacherId).get();
    final result = <String, List<String>>{};
    for (final d in snap.docs) {
      final data = d.data() as Map<String, dynamic>;
      final cls = data['className'] as String;
      result.putIfAbsent(cls, () => []).add(data['subject'] as String);
    }
    return result;
  }

  Future<List<String>> getClassesForUser(String userId, UserRole role) async {
    if (role == UserRole.owner || role == UserRole.principal) {
      final classes = await getClasses();
      return classes.map((c) => c.name).toList();
    } else if (role == UserRole.teacher) {
      return getTeacherClasses(userId);
    }
    return [];
  }

  Future<Map<String, List<Map<String, dynamic>>>> getTeachersPerClass() async {
    final tcSnap = await _col('teacher_classes').get();
    final tcsSnap = await _col('teacher_class_subjects').get();
    final users = await getUsers();
    final userMap = {for (final u in users) u.id: u};

    final classSubjects = <String, List<String>>{};
    for (final d in tcsSnap.docs) {
      final data = d.data() as Map<String, dynamic>;
      final key = '${data['teacherId']}|${data['className']}';
      classSubjects.putIfAbsent(key, () => []).add(data['subject'] as String);
    }

    final result = <String, List<Map<String, dynamic>>>{};
    for (final d in tcSnap.docs) {
      final data = d.data() as Map<String, dynamic>;
      final tid = data['teacherId'] as String;
      final cls = data['className'] as String;
      final user = userMap[tid];
      if (user == null) continue;
      result.putIfAbsent(cls, () => []).add({
        'name': user.name,
        'subjects': classSubjects['$tid|$cls'] ?? [],
      });
    }
    return result;
  }

  // ─── LESSONS ─────────────────────────────────────────────────────────────────

  Future<List<Lesson>> getLessons() async {
    final snap = await _col('lessons').orderBy('date', descending: true).get();
    return snap.docs.map((d) => Lesson.fromJson(_snap(d))).toList();
  }

  Future<void> insertLesson(Lesson lesson) async {
    await _col('lessons').doc(lesson.id).set(lesson.toJson());
  }

  Future<void> deleteLesson(String id) async {
    await _col('lessons').doc(id).delete();
  }

  // ─── LIBRARY ─────────────────────────────────────────────────────────────────

  Future<List<LibraryBook>> getBooks() async {
    final snap = await _col('library_books').get();
    return snap.docs.map((d) => LibraryBook.fromJson(_snap(d))).toList();
  }

  Future<void> insertBook(LibraryBook book) async {
    await _col('library_books').doc(book.id).set(book.toJson());
  }

  Future<void> updateBook(LibraryBook book) async {
    await _col('library_books').doc(book.id).update(book.toJson());
  }

  Future<void> deleteBook(String id) async {
    await _col('library_books').doc(id).delete();
  }

  // ─── TRANSPORT ───────────────────────────────────────────────────────────────

  Future<List<TransportRoute>> getRoutes() async {
    final snap = await _col('transport_routes').get();
    return snap.docs.map((d) => TransportRoute.fromJson(_snap(d))).toList();
  }

  Future<void> insertRoute(TransportRoute route) async {
    await _col('transport_routes').doc(route.id).set(route.toJson());
  }

  Future<void> deleteRoute(String id) async {
    await _col('transport_routes').doc(id).delete();
  }

  // ─── NOTIFICATIONS ───────────────────────────────────────────────────────────

  Future<List<NotificationModel>> getNotifications() async {
    final snap = await _col('notifications').orderBy('timestamp', descending: true).get();
    return snap.docs.map((d) => NotificationModel.fromJson(_snap(d))).toList();
  }

  Future<void> insertNotification(NotificationModel n) async {
    await _col('notifications').doc(n.id).set(n.toJson());
  }

  Future<void> markNotificationRead(String id) async {
    await _col('notifications').doc(id).update({'isRead': true});
  }

  Future<void> markAllNotificationsRead() async {
    final snap = await _col('notifications').where('isRead', isEqualTo: false).get();
    final batch = _fs.batch();
    for (final d in snap.docs) { batch.update(d.reference, {'isRead': true}); }
    await batch.commit();
  }

  // ─── GRADES ──────────────────────────────────────────────────────────────────

  Future<List<Grade>> getGradesForStudent(String studentId) async {
    final snap = await _col('grades').where('studentId', isEqualTo: studentId).get();
    return snap.docs.map((d) {
      final r = d.data() as Map<String, dynamic>;
      return Grade(
        subject: r['subject'] as String,
        score: r['score'] as String,
        grade: r['grade'] as String,
        remarks: r['remarks'] as String,
      );
    }).toList();
  }

  Future<void> upsertGrade(String studentId, Grade grade) async {
    final snap = await _col('grades')
        .where('studentId', isEqualTo: studentId)
        .where('subject', isEqualTo: grade.subject)
        .get();
    final batch = _fs.batch();
    for (final d in snap.docs) { batch.delete(d.reference); }
    final docId = '${studentId}_${grade.subject}';
    batch.set(_col('grades').doc(docId), {
      'studentId': studentId,
      'subject': grade.subject,
      'score': grade.score,
      'grade': grade.grade,
      'remarks': grade.remarks,
    });
    await batch.commit();
  }

  // ─── TIMETABLE ───────────────────────────────────────────────────────────────

  Future<List<TimetableEntry>> getTimetable({String? className}) async {
    Query q = _col('timetable');
    if (className != null) q = q.where('className', isEqualTo: className);
    final snap = await q.get();
    return snap.docs.map((d) {
      final r = d.data() as Map<String, dynamic>;
      return TimetableEntry(
        id: d.id,
        day: r['day'] as String,
        startTime: r['startTime'] as String,
        endTime: r['endTime'] as String,
        subject: r['subject'] as String,
        room: r['room'] as String,
      );
    }).toList();
  }

  Future<void> insertTimetableEntry(TimetableEntry entry, {String className = 'All'}) async {
    await _col('timetable').add({
      'day': entry.day,
      'startTime': entry.startTime,
      'endTime': entry.endTime,
      'subject': entry.subject,
      'room': entry.room,
      'className': className,
    });
  }

  Future<void> deleteTimetableEntry(String id) async {
    await _col('timetable').doc(id).delete();
  }

  // ─── EXAMS ───────────────────────────────────────────────────────────────────

  Future<List<Exam>> getExams({String? className}) async {
    Query q = _col('exams');
    if (className != null) q = q.where('className', isEqualTo: className);
    final snap = await q.get();
    final exams = snap.docs.map((d) => Exam.fromJson(_snap(d))).toList();
    exams.sort((a, b) => a.date.compareTo(b.date));
    return exams;
  }

  Future<List<Exam>> getExamsForClasses(List<String> classNames) async {
    if (classNames.isEmpty) return [];
    final snap = await _col('exams').where('className', whereIn: classNames).get();
    final exams = snap.docs.map((d) => Exam.fromJson(_snap(d))).toList();
    exams.sort((a, b) => a.date.compareTo(b.date));
    return exams;
  }

  Future<void> insertExam(Exam exam) async {
    await _col('exams').doc(exam.id).set(exam.toJson());
  }

  Future<void> updateExam(Exam exam) async {
    await _col('exams').doc(exam.id).update(exam.toJson());
  }

  Future<void> deleteExam(String id) async {
    final results = await _col('exam_results').where('examId', isEqualTo: id).get();
    final batch = _fs.batch();
    batch.delete(_col('exams').doc(id));
    for (final d in results.docs) { batch.delete(d.reference); }
    await batch.commit();
  }

  Future<List<ExamResult>> getExamResults(String examId) async {
    final snap = await _col('exam_results').where('examId', isEqualTo: examId).get();
    return snap.docs.map((d) => ExamResult.fromJson(_snap(d))).toList();
  }

  Future<List<ExamResult>> getExamResultsForStudent(String studentId) async {
    final snap = await _col('exam_results').where('studentId', isEqualTo: studentId).get();
    return snap.docs.map((d) => ExamResult.fromJson(_snap(d))).toList();
  }

  Future<List<ExamResult>> getAllExamResults() async {
    final snap = await _col('exam_results').get();
    return snap.docs.map((d) => ExamResult.fromJson(_snap(d))).toList();
  }

  Future<void> saveExamResults(List<ExamResult> results) async {
    final batch = _fs.batch();
    for (final r in results) {
      batch.set(_col('exam_results').doc(r.id), r.toJson());
    }
    await batch.commit();
  }
}

final dbService = DatabaseService();
