import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';

class BusLinesManagementScreen extends StatefulWidget {
  const BusLinesManagementScreen({super.key});

  @override
  State<BusLinesManagementScreen> createState() =>
      _BusLinesManagementScreenState();
}

class _BusLinesManagementScreenState extends State<BusLinesManagementScreen>
    with TickerProviderStateMixin {
  // ═══════════════════════════════════════════════════════════════
  // Controllers & Animation
  // ═══════════════════════════════════════════════════════════════

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  late AnimationController _headerAnimController;
  late Animation<double> _headerAnimation;

  // ═══════════════════════════════════════════════════════════════
  // Data
  // ═══════════════════════════════════════════════════════════════

  List<dynamic> _busLines = [];
  List<dynamic> _filteredBusLines = [];

  // ═══════════════════════════════════════════════════════════════
  // State
  // ═══════════════════════════════════════════════════════════════

  bool _isLoading = true;
  bool _isSaving = false;

  // ═══════════════════════════════════════════════════════════════
  // Colors
  // ═══════════════════════════════════════════════════════════════

  static const _primaryColor = Color(0xFF6366F1);
  static const _successColor = Color(0xFF10B981);
  static const _errorColor = Color(0xFFEF4444);
  static const _busColor = Color(0xFFF97316);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadBusLines();
  }

  void _setupAnimations() {
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    );

    _headerAnimController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // تحميل البيانات
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadBusLines() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.getBusLines();
      setState(() {
        _busLines = result;
        _filteredBusLines = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('فشل تحميل البيانات: $e', isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // فلترة
  // ═══════════════════════════════════════════════════════════════

  String _normalizeArabic(String text) {
    return text
        .replaceAll('ة', 'ه')
        .replaceAll('إ', 'ا')
        .replaceAll('أ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ى', 'ي')
        .toLowerCase()
        .trim();
  }

  void _filterBusLines(String query) {
    if (query.isEmpty) {
      setState(() => _filteredBusLines = _busLines);
    } else {
      final normalizedQuery = _normalizeArabic(query);
      setState(() {
        _filteredBusLines = _busLines.where((line) {
          final name = _normalizeArabic(
            (line['BusLine'] ?? '').toString(),
          );
          return name.contains(normalizedQuery);
        }).toList();
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // إضافة / تعديل Dialog
  // ═══════════════════════════════════════════════════════════════

  Future<void> _showBusLineDialog({Map<String, dynamic>? busLine}) async {
    final isEditing = busLine != null;
    final controller = TextEditingController(
      text: isEditing ? busLine['BusLine'] ?? '' : '',
    );

    HapticFeedback.lightImpact();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor:
                _isDark ? const Color(0xFF1E1E2E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _busColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEditing
                        ? Icons.edit_rounded
                        : Icons.add_road_rounded,
                    color: _busColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isEditing ? 'تعديل خط الباص' : 'إضافة خط باص جديد',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(
                    color: _isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    labelText: 'اسم الخط',
                    labelStyle: TextStyle(
                      color:
                          _isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    hintText: 'مثال: خط المعادي',
                    hintStyle: TextStyle(
                      color:
                          _isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                    prefixIcon: Icon(
                      Icons.directions_bus_rounded,
                      color:
                          _isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    filled: true,
                    fillColor:
                        _isDark ? Colors.grey[800] : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: _busColor, width: 2),
                    ),
                  ),
                ),
                if (_isSaving)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: LinearProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_busColor),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: _isSaving
                    ? null
                    : () => Navigator.pop(context, false),
                child: Text(
                  'إلغاء',
                  style: TextStyle(
                    color: _isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () async {
                        final name = controller.text.trim();
                        if (name.isEmpty) {
                          _showSnackBar('اكتب اسم الخط', isError: true);
                          return;
                        }

                        setDialogState(() => _isSaving = true);
                        setState(() => _isSaving = true);

                        Map<String, dynamic> apiResult;
                        if (isEditing) {
                          apiResult = await ApiService.updateBusLine(
                            busLine['ID'],
                            name,
                          );
                        } else {
                          apiResult =
                              await ApiService.addBusLine(name);
                        }

                        setDialogState(() => _isSaving = false);
                        setState(() => _isSaving = false);

                        if (apiResult['success'] == true) {
                          if (context.mounted) {
                            Navigator.pop(context, true);
                          }
                        } else {
                          _showSnackBar(
                            apiResult['message'] ?? 'حدث خطأ',
                            isError: true,
                          );
                        }
                      },
                icon: Icon(
                  isEditing
                      ? Icons.check_rounded
                      : Icons.add_rounded,
                  size: 20,
                ),
                label: Text(
                  isEditing ? 'حفظ' : 'إضافة',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _busColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      HapticFeedback.heavyImpact();
      _showSnackBar(
        isEditing
            ? 'تم تعديل الخط بنجاح'
            : 'تم إضافة الخط بنجاح',
      );
      _loadBusLines();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SnackBar
  // ═══════════════════════════════════════════════════════════════

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? _errorColor : _successColor,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBusLineDialog(),
        backgroundColor: _busColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'خط جديد',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading ? _buildLoadingWidget() : _buildContent(),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _busColor.withOpacity(0.2),
                  blurRadius: 30,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_busColor),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'جاري تحميل الخطوط...',
            style: TextStyle(
              color: _isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchAndList(),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SLIVER APP BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: _isDark ? const Color(0xFF1A1A2E) : Colors.white,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                _isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: _isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      title: Text(
        'إدارة خطوط الباص',
        style: TextStyle(
          color: _isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF97316),
              Color(0xFFFB923C),
              Color(0xFFFBBF24),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _busColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'خطوط الباص',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_busLines.length} خط',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SEARCH AND LIST
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSearchAndList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(
        children: [
          // Search
          Container(
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                  color: _isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'ابحث عن خط...',
                hintStyle: TextStyle(
                    color:
                        _isDark ? Colors.grey[500] : Colors.grey[500]),
                prefixIcon: Icon(Icons.search,
                    color:
                        _isDark ? Colors.grey[500] : Colors.grey[500]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: _isDark
                                ? Colors.grey[500]
                                : Colors.grey[500]),
                        onPressed: () {
                          _searchController.clear();
                          _filterBusLines('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor:
                    _isDark ? const Color(0xFF1E1E2E) : Colors.white,
              ),
              onChanged: _filterBusLines,
            ),
          ),
          const SizedBox(height: 16),

          // List
          if (_filteredBusLines.isEmpty)
            _buildEmptyState()
          else
            ...List.generate(_filteredBusLines.length, (index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + (index * 60)),
                curve: Curves.easeOutCubic,
                builder: (context, value, widget) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(opacity: value, child: widget),
                  );
                },
                child: _buildBusLineCard(
                    _filteredBusLines[index], index),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _isDark
                  ? Colors.grey[800]!.withOpacity(0.5)
                  : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_bus_rounded,
              size: 60,
              color: _isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد خطوط',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط + لإضافة خط جديد',
            style: TextStyle(
              fontSize: 14,
              color: _isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusLineCard(Map<String, dynamic> busLine, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFFB923C)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  busLine['BusLine'] ?? '',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.tag_rounded,
                      size: 14,
                      color:
                          _isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'كود: ${busLine['ID']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isDark
                            ? Colors.grey[500]
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Edit Button
          GestureDetector(
            onTap: () => _showBusLineDialog(
              busLine: Map<String, dynamic>.from(busLine),
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: _primaryColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}