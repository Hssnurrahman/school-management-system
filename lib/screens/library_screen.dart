import 'package:flutter/material.dart';
import '../models/library_book.dart';
import '../services/database_service.dart';
import '../utils/app_snackbar.dart';
import '../widgets/app_bottom_sheet.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<LibraryBook> _books = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    try {
      final books = await dbService.getBooks();
      final cats = {'All', ...books.map((b) => b.category)}.toList();
      if (!mounted) return;
      setState(() {
        _books = books;
        _categories = cats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackBar(context, 'Failed to load: $e');
    }
  }

  void _showAddBookSheet() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final isbnController = TextEditingController();
    final categoryController = TextEditingController();

    showAppBottomSheet(
      context: context,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: 20),
            const Text('Add New Book', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            TextFormField(controller: titleController, decoration: const InputDecoration(labelText: 'Book Title', prefixIcon: Icon(Icons.book_rounded)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            TextFormField(controller: authorController, decoration: const InputDecoration(labelText: 'Author', prefixIcon: Icon(Icons.person_outline_rounded)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 14),
            TextFormField(controller: isbnController, decoration: const InputDecoration(labelText: 'ISBN', prefixIcon: Icon(Icons.qr_code_rounded))),
            const SizedBox(height: 14),
            TextFormField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_rounded)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final book = LibraryBook(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    author: authorController.text,
                    isbn: isbnController.text.isEmpty ? 'N/A' : isbnController.text,
                    category: categoryController.text,
                  );
                  final nav = Navigator.of(context);
                  await dbService.insertBook(book);
                  if (context.mounted) nav.pop();
                  await _loadBooks();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
              child: const Text('Add Book'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredBooks = _selectedCategory == 'All' ? _books : _books.where((b) => b.category == _selectedCategory).toList();

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF1D4ED8),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Library', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)])),
                child: Center(child: Icon(Icons.local_library_rounded, color: Colors.white.withValues(alpha: 0.12), size: 120)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 64,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF3B82F6) : (isDark ? const Color(0xFF141E30) : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE8EDF5))),
                        ),
                        child: Text(cat, style: TextStyle(color: isSelected ? Colors.white : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)), fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _BookCard(book: filteredBooks[index], isDark: isDark, onToggle: () => _toggleAvailability(filteredBooks[index])),
                  childCount: filteredBooks.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBookSheet,
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Book', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _toggleAvailability(LibraryBook book) async {
    final updated = book.copyWith(
      isAvailable: !book.isAvailable,
      dueDate: !book.isAvailable ? null : DateTime.now().add(const Duration(days: 14)),
    );
    await dbService.updateBook(updated);
    await _loadBooks();
  }
}

class _BookCard extends StatelessWidget {
  final LibraryBook book;
  final bool isDark;
  final VoidCallback onToggle;

  const _BookCard({required this.book, required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141E30) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE8EDF5)),
      ),
      child: Row(
        children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.book_rounded, color: Color(0xFF3B82F6), size: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text('by ${book.author}', style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(children: [
                  _Tag(label: book.category, color: const Color(0xFF3B82F6)),
                  const SizedBox(width: 6),
                  _Tag(label: book.isAvailable ? 'Available' : 'Borrowed', color: book.isAvailable ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                ]),
                if (!book.isAvailable && book.dueDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Due: ${book.dueDate!.year}-${book.dueDate!.month.toString().padLeft(2, '0')}-${book.dueDate!.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: book.isAvailable ? const Color(0xFFEF4444).withValues(alpha: 0.08) : const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(book.isAvailable ? 'Borrow' : 'Return', style: TextStyle(color: book.isAvailable ? const Color(0xFFEF4444) : const Color(0xFF10B981), fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
