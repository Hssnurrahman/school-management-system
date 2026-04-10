import 'package:flutter/material.dart';
import '../models/mark_model.dart';
import '../services/database_service.dart';

class MarksScreen extends StatefulWidget {
  const MarksScreen({super.key});

  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> {
  List<MarkEntry> _marks = [];
  bool _isLoading = true;
  String _selectedSubject = 'Mathematics';
  final List<String> _subjects = ['Mathematics', 'Science', 'English', 'History', 'Physics'];

  @override
  void initState() {
    super.initState();
    _loadMarks();
  }

  Future<void> _loadMarks() async {
    setState(() => _isLoading = true);
    final marks = await dbService.getMarks(subject: _selectedSubject);
    if (marks.isEmpty) {
      // Seed default students for this subject
      final defaults = [
        MarkEntry(studentId: '101', studentName: 'Alice Smith', subject: _selectedSubject),
        MarkEntry(studentId: '102', studentName: 'Bob Jones', subject: _selectedSubject),
        MarkEntry(studentId: '103', studentName: 'Charlie Brown', subject: _selectedSubject),
        MarkEntry(studentId: '104', studentName: 'David Wilson', subject: _selectedSubject),
        MarkEntry(studentId: '105', studentName: 'Eve Davis', subject: _selectedSubject),
      ];
      for (final m in defaults) {
        await dbService.upsertMark(m);
      }
      setState(() {
        _marks = defaults;
        _isLoading = false;
      });
    } else {
      setState(() {
        _marks = marks;
        _isLoading = false;
      });
    }
  }

  void _showMarkEntrySheet(int index) {
    final entry = _marks[index];
    final marksController = TextEditingController(text: entry.marksObtained?.toString() ?? '');
    final remarksController = TextEditingController(text: entry.remarks ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text('Enter Marks: ${entry.studentName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              TextField(
                controller: marksController,
                decoration: const InputDecoration(labelText: 'Marks Obtained (Max 100)', prefixIcon: Icon(Icons.grade_rounded)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(controller: remarksController, decoration: const InputDecoration(labelText: 'Remarks', prefixIcon: Icon(Icons.notes_rounded))),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  final val = double.tryParse(marksController.text);
                  final updated = MarkEntry(
                    studentId: entry.studentId,
                    studentName: entry.studentName,
                    subject: entry.subject,
                    marksObtained: val,
                    totalMarks: entry.totalMarks,
                    remarks: remarksController.text,
                  );
                  updated.grade = updated.calculateGrade();
                  await dbService.upsertMark(updated);
                  if (context.mounted) Navigator.pop(context);
                  await _loadMarks();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                child: const Text('Save Marks'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marks Entry', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(isDark),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: _marks.length,
                itemBuilder: (context, index) => _MarkListItem(entry: _marks[index], onTap: () => _showMarkEntrySheet(index)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFD97706), Color(0xFFF59E0B)]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Academic Grading', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Subject', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    value: _selectedSubject,
                    dropdownColor: const Color(0xFFD97706),
                    underline: Container(),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedSubject = newValue);
                        _loadMarks();
                      }
                    },
                    items: _subjects.map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.2))),
                child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarkListItem extends StatelessWidget {
  final MarkEntry entry;
  final VoidCallback onTap;

  const _MarkListItem({required this.entry, required this.onTap});

  Color _getGradeColor(String grade) {
    if (grade.startsWith('A')) return Colors.green;
    if (grade.startsWith('B')) return Colors.blue;
    if (grade.startsWith('C')) return Colors.orange;
    if (grade == 'F') return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grade = entry.calculateGrade();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EDF5)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          height: 52, width: 52,
          decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(entry.studentName[0], style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w900, fontSize: 20))),
        ),
        title: Text(entry.studentName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        subtitle: Text('ID: ${entry.studentId}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(entry.marksObtained != null ? '${entry.marksObtained}/100' : 'Pending', style: TextStyle(fontWeight: FontWeight.w800, color: entry.marksObtained != null ? null : Colors.grey.shade400)),
                if (entry.marksObtained != null)
                  Text('Grade: $grade', style: TextStyle(color: _getGradeColor(grade), fontWeight: FontWeight.w900, fontSize: 11)),
              ],
            ),
            const SizedBox(width: 12),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}
