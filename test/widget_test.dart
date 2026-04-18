import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schoolify/models/attendance_model.dart' show Attendance;
import 'package:schoolify/models/class_model.dart';
import 'package:schoolify/models/exam_model.dart';
import 'package:schoolify/models/fee_model.dart';
import 'package:schoolify/models/homework_model.dart';
import 'package:schoolify/models/lesson_model.dart';
import 'package:schoolify/models/library_book.dart';
import 'package:schoolify/models/transport_route.dart';
import 'package:schoolify/models/user_model.dart';
import 'package:schoolify/models/user_role.dart';
import 'package:schoolify/utils/app_snackbar.dart';
import 'package:schoolify/utils/date_utils.dart';
import 'package:schoolify/utils/grade_utils.dart';
import 'package:schoolify/widgets/app_bottom_sheet.dart';
import 'package:schoolify/widgets/confirm_delete_dialog.dart';
import 'package:schoolify/widgets/empty_state.dart';
import 'package:schoolify/widgets/stat_badge.dart';

void main() {
  // ── Models ─────────────────────────────────────────────────────────────────

  group('UserModel', () {
    test('fromJson/toJson roundtrip', () {
      final user = UserModel(
        id: 'u1',
        name: 'Alice',
        email: 'alice@school.com',
        primaryRole: UserRole.teacher,
        additionalRoles: [UserRole.principal],
      );
      final json = user.toJson();
      final restored = UserModel.fromJson(json);
      expect(restored.id, 'u1');
      expect(restored.name, 'Alice');
      expect(restored.primaryRole, UserRole.teacher);
      expect(restored.additionalRoles, [UserRole.principal]);
    });

    test('allRoles includes primary and additional', () {
      final user = UserModel(
        id: 'u2',
        name: 'Bob',
        email: 'bob@school.com',
        primaryRole: UserRole.principal,
        additionalRoles: [UserRole.teacher],
      );
      expect(user.allRoles, contains(UserRole.principal));
      expect(user.allRoles, contains(UserRole.teacher));
      expect(user.allRoles.length, 2);
    });

    test('role getter returns primaryRole', () {
      final user = UserModel(
        id: 'u3',
        name: 'Carol',
        email: 'carol@school.com',
        primaryRole: UserRole.student,
      );
      expect(user.role, UserRole.student);
    });

    test('fromJson backward-compat: comma-separated additionalRoles', () {
      final json = {
        'id': 'u4',
        'name': 'Dan',
        'email': 'dan@school.com',
        'role': 'teacher',
        'additionalRoles': 'principal,teacher',
        'isActive': true,
      };
      final user = UserModel.fromJson(json);
      expect(user.additionalRoles.length, 2);
      expect(user.additionalRoles, contains(UserRole.principal));
    });

    test('copyWith preserves unchanged fields', () {
      final user = UserModel(
        id: 'u5',
        name: 'Eve',
        email: 'eve@school.com',
        primaryRole: UserRole.parent,
      );
      final updated = user.copyWith(name: 'Eve Updated');
      expect(updated.id, 'u5');
      expect(updated.name, 'Eve Updated');
      expect(updated.email, 'eve@school.com');
      expect(updated.primaryRole, UserRole.parent);
    });

    test('isActive defaults to true when null', () {
      final json = {
        'id': 'u6',
        'name': 'Frank',
        'email': 'frank@school.com',
        'role': 'teacher',
        'isActive': null,
      };
      final user = UserModel.fromJson(json);
      expect(user.isActive, true);
    });
  });

  group('ClassModel', () {
    test('fromJson/toJson roundtrip', () {
      final cls = ClassModel(
        id: 'c1',
        name: 'Grade 5A',
        teacherName: 'Mr. Smith',
        studentCount: 30,
        roomNumber: '101',
      );
      final json = cls.toJson();
      final restored = ClassModel.fromJson(json);
      expect(restored.id, 'c1');
      expect(restored.name, 'Grade 5A');
      expect(restored.studentCount, 30);
    });
  });

  group('Attendance', () {
    test('fromJson/toJson roundtrip', () {
      final record = Attendance(
        studentId: 's1',
        studentName: 'Alice',
        date: DateTime(2025, 9, 1),
        isPresent: true,
      );
      final json = record.toJson();
      final restored = Attendance.fromJson(json);
      expect(restored.studentId, 's1');
      expect(restored.isPresent, true);
      expect(restored.date.year, 2025);
    });

    test('isLate defaults to false', () {
      final record = Attendance(
        studentId: 'x',
        studentName: 'X',
        date: DateTime.now(),
        isPresent: true,
      );
      expect(record.isLate, false);
    });

    test('absent record serializes isPresent as 0', () {
      final record = Attendance(
        studentId: 'x',
        studentName: 'X',
        date: DateTime.now(),
        isPresent: false,
      );
      final json = record.toJson();
      expect(json['isPresent'], 0);
    });
  });

  group('Fee', () {
    test('fromJson/toJson roundtrip', () {
      final fee = Fee(
        id: 'f1',
        title: 'Tuition Q1',
        amount: 500.0,
        dueDate: DateTime(2025, 9, 30),
        isPaid: false,
        category: FeeCategory.tuition,
        studentName: 'Alice',
      );
      final json = fee.toJson();
      final restored = Fee.fromJson(json);
      expect(restored.amount, 500.0);
      expect(restored.category, FeeCategory.tuition);
      expect(restored.isPaid, false);
    });

    test('copyWith updates isPaid', () {
      final fee = Fee(
        id: 'f2',
        title: 'Library',
        amount: 50.0,
        dueDate: DateTime.now(),
        isPaid: false,
        category: FeeCategory.library,
        studentName: 'Bob',
      );
      final paid = fee.copyWith(isPaid: true);
      expect(paid.isPaid, true);
      expect(paid.id, 'f2');
    });
  });

  group('Homework', () {
    test('fromJson/toJson roundtrip', () {
      final hw = Homework(
        subject: 'Math',
        title: 'Chapter 5 exercises',
        dueDate: DateTime(2025, 10, 15),
        description: 'Do all odd problems',
        className: 'Grade 5',
        isCompleted: false,
      );
      final json = hw.toJson();
      final restored = Homework.fromJson(json);
      expect(restored.subject, 'Math');
      expect(restored.title, 'Chapter 5 exercises');
      expect(restored.isCompleted, false);
    });

    test('copyWith toggles isCompleted', () {
      final hw = Homework(
        subject: 'Science',
        title: 'Lab report',
        dueDate: DateTime.now(),
        description: 'Write up the experiment',
        className: 'Grade 6',
      );
      final done = hw.copyWith(isCompleted: true);
      expect(done.isCompleted, true);
      expect(done.subject, 'Science');
    });
  });

  group('TransportRoute', () {
    test('fromJson with List stops', () {
      final json = {
        'id': 'r1',
        'routeName': 'Route A',
        'driverName': 'John',
        'driverPhone': '555-0001',
        'vehicleNumber': 'BUS-01',
        'stops': ['School', 'Park', 'Market'],
        'status': 'Active',
      };
      final route = TransportRoute.fromJson(json);
      expect(route.stops.length, 3);
      expect(route.stops.first, 'School');
    });

    test('fromJson backward-compat: pipe-separated stops string', () {
      final json = {
        'id': 'r2',
        'routeName': 'Route B',
        'driverName': 'Jane',
        'driverPhone': 'N/A',
        'vehicleNumber': 'BUS-02',
        'stops': 'School|Park|Market',
        'status': 'Active',
      };
      final route = TransportRoute.fromJson(json);
      expect(route.stops.length, 3);
      expect(route.stops[1], 'Park');
    });

    test('toJson serializes stops as list', () {
      final route = TransportRoute(
        id: 'r3',
        routeName: 'Route C',
        driverName: 'Pete',
        driverPhone: '555-0003',
        vehicleNumber: 'BUS-03',
        stops: ['Stop A', 'Stop B'],
      );
      final json = route.toJson();
      expect(json['stops'], isA<List>());
      expect((json['stops'] as List).length, 2);
    });
  });

  group('LibraryBook', () {
    test('fromJson/toJson with null dueDate', () {
      final book = LibraryBook(
        id: 'b1',
        title: 'Dart Programming',
        author: 'John Doe',
        isbn: '978-0-123456',
        category: 'Technology',
      );
      final json = book.toJson();
      final restored = LibraryBook.fromJson(json);
      expect(restored.title, 'Dart Programming');
      expect(restored.dueDate, isNull);
      expect(restored.isAvailable, true);
    });

    test('fromJson/toJson with dueDate', () {
      final book = LibraryBook(
        id: 'b2',
        title: 'Flutter in Action',
        author: 'Eric Windmill',
        isbn: '978-1-234567',
        category: 'Technology',
        isAvailable: false,
        dueDate: DateTime(2025, 12, 31),
      );
      final json = book.toJson();
      final restored = LibraryBook.fromJson(json);
      expect(restored.isAvailable, false);
      expect(restored.dueDate?.year, 2025);
    });
  });

  group('Lesson', () {
    test('fromJson/toJson roundtrip', () {
      final lesson = Lesson(
        id: 'l1',
        title: 'Photosynthesis',
        description: 'How plants make food',
        subject: 'Biology',
        className: 'Grade 7',
        teacherName: 'Ms. Green',
        date: DateTime(2025, 9, 15),
      );
      final json = lesson.toJson();
      final restored = Lesson.fromJson(json);
      expect(restored.title, 'Photosynthesis');
      expect(restored.date.month, 9);
    });
  });

  group('ExamResult', () {
    test('grade computed from marksObtained', () {
      final result = ExamResult(
        id: 'er1',
        examId: 'e1',
        studentId: 's1',
        studentName: 'Alice',
        marksObtained: 90,
        totalMarks: 100,
      );
      expect(result.grade, isNotEmpty);
      expect(result.grade, isNot('-'));
    });

    test('grade is dash when marksObtained is null', () {
      final result = ExamResult(
        id: 'er2',
        examId: 'e1',
        studentId: 's2',
        studentName: 'Bob',
        totalMarks: 100,
      );
      expect(result.grade, '-');
    });

    test('percentages below 33 get failing grade', () {
      final grade = GradeUtils.fromMarks(30, 100);
      expect(grade, equals('F'));
    });
  });

  // ── Utils ──────────────────────────────────────────────────────────────────

  group('GradeUtils', () {
    test('fromPercentage: 95+ is A+', () {
      expect(GradeUtils.fromPercentage(95), 'A+');
      expect(GradeUtils.fromPercentage(100), 'A+');
    });

    test('fromPercentage: 80-89 is A', () {
      expect(GradeUtils.fromPercentage(85), 'A');
      expect(GradeUtils.fromPercentage(80), 'A');
    });

    test('fromPercentage: 70-79 is B+', () {
      expect(GradeUtils.fromPercentage(75), 'B+');
    });

    test('fromPercentage: 60-69 is B', () {
      expect(GradeUtils.fromPercentage(65), 'B');
    });

    test('fromPercentage: 50-59 is C', () {
      expect(GradeUtils.fromPercentage(50), 'C');
    });

    test('fromPercentage: 33-49 is D', () {
      expect(GradeUtils.fromPercentage(49), 'D');
      expect(GradeUtils.fromPercentage(33), 'D');
    });

    test('fromPercentage: below 33 is F', () {
      expect(GradeUtils.fromPercentage(32), 'F');
      expect(GradeUtils.fromPercentage(0), 'F');
    });

    test('fromMarks delegates to fromPercentage', () {
      expect(GradeUtils.fromMarks(95, 100), 'A+');
      expect(GradeUtils.fromMarks(50, 100), 'C');
      expect(GradeUtils.fromMarks(0, 100), 'F');
    });

    test('fromMarks handles zero total without throwing', () {
      expect(() => GradeUtils.fromMarks(0, 0), returnsNormally);
    });

    test('colorForGrade returns a Color', () {
      for (final grade in ['A+', 'A', 'B', 'C', 'D', 'F']) {
        expect(GradeUtils.colorForGrade(grade), isA<Color>());
      }
    });
  });

  group('AppDateUtils', () {
    test('monthName returns full name', () {
      expect(AppDateUtils.monthName(1), 'January');
      expect(AppDateUtils.monthName(12), 'December');
    });

    test('monthShort returns abbreviated name', () {
      expect(AppDateUtils.monthShort(1), 'Jan');
      expect(AppDateUtils.monthShort(6), 'Jun');
    });

    test('formatYMD pads single-digit month and day', () {
      final d = DateTime(2025, 3, 5);
      expect(AppDateUtils.formatYMD(d), '2025-03-05');
    });

    test('formatMDY formats correctly', () {
      final d = DateTime(2025, 3, 5);
      expect(AppDateUtils.formatMDY(d), 'Mar 5, 2025');
    });

    test('formatDM formats correctly', () {
      final d = DateTime(2025, 11, 20);
      expect(AppDateUtils.formatDM(d), '20 Nov');
    });
  });

  // ── Widgets ────────────────────────────────────────────────────────────────

  group('EmptyState widget', () {
    testWidgets('renders icon and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              message: 'Nothing here yet',
            ),
          ),
        ),
      );
      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              message: 'Nothing here yet',
              subtitle: 'Add some items to get started',
            ),
          ),
        ),
      );
      expect(find.text('Add some items to get started'), findsOneWidget);
    });

    testWidgets('omits subtitle when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(icon: Icons.inbox, message: 'Empty'),
          ),
        ),
      );
      expect(find.text('Add some items to get started'), findsNothing);
    });
  });

  group('StatBadge widget', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatBadge(label: 'Present', color: Colors.green),
          ),
        ),
      );
      expect(find.text('Present'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatBadge(
              label: '42',
              color: Colors.blue,
              icon: Icons.people_rounded,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.people_rounded), findsOneWidget);
    });

    testWidgets('omits icon widget when icon is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatBadge(label: 'No icon', color: Colors.red),
          ),
        ),
      );
      expect(find.byType(Icon), findsNothing);
    });
  });

  group('SheetHandle widget', () {
    testWidgets('renders as a small centered container', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SheetHandle()),
        ),
      );
      expect(find.byType(SheetHandle), findsOneWidget);
    });
  });

  group('showConfirmDeleteDialog', () {
    testWidgets('shows title and message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showConfirmDeleteDialog(
                context: context,
                title: 'Delete Item?',
                message: 'Remove this item permanently?',
              ),
              child: const Text('Delete'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Item?'), findsOneWidget);
      expect(find.text('Remove this item permanently?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('dismisses on Cancel tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showConfirmDeleteDialog(
                context: context,
                message: 'Are you sure?',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Are you sure?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Are you sure?'), findsNothing);
    });

    testWidgets('calls onConfirm when Delete is tapped', (tester) async {
      bool confirmed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showConfirmDeleteDialog(
                context: context,
                message: 'Remove?',
                onConfirm: () async {
                  confirmed = true;
                },
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
    });
  });

  group('showAppBottomSheet', () {
    testWidgets('shows child content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAppBottomSheet(
                context: context,
                child: const Text('Sheet Content'),
              ),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet Content'), findsOneWidget);
    });
  });

  group('showSuccessSnackBar / showErrorSnackBar', () {
    testWidgets('showSuccessSnackBar shows message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showSuccessSnackBar(context, 'Saved!'),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pump();
      expect(find.text('Saved!'), findsOneWidget);
    });

    testWidgets('showErrorSnackBar shows message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showErrorSnackBar(context, 'Error occurred'),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pump();
      expect(find.text('Error occurred'), findsOneWidget);
    });
  });
}
