import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';

class BusLineChildrenScreen extends StatefulWidget {
  const BusLineChildrenScreen({super.key});

  @override
  State<BusLineChildrenScreen> createState() => _BusLineChildrenScreenState();
}

class _BusLineChildrenScreenState extends State<BusLineChildrenScreen>
    with TickerProviderStateMixin {
  // ═══════════════════════════════════════════════════════════════
  // Controllers
  // ═══════════════════════════════════════════════════════════════

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  // ═══════════════════════════════════════════════════════════════
  // Animation Controllers
  // ═══════════════════════════════════════════════════════════════

  late AnimationController _headerAnimController;
  late AnimationController _contentAnimController;
  late Animation<double> _headerAnimation;
  late Animation<double> _contentAnimation;

  // ═══════════════════════════════════════════════════════════════
  // Data
  // ═══════════════════════════════════════════════════════════════

  List<dynamic> _sessions = [];
  List<dynamic> _busLines = [];
  List<dynamic> _children = [];
  List<dynamic> _filteredChildren = [];

  int? _selectedSessionId;
  int? _selectedBusLineId;

  // ═══════════════════════════════════════════════════════════════
  // State
  // ═══════════════════════════════════════════════════════════════

  bool _isLoadingData = true;
  bool _isLoadingChildren = false;

  // ═══════════════════════════════════════════════════════════════
  // Colors
  // ═══════════════════════════════════════════════════════════════

  static const _primaryColor = Color(0xFF6366F1);
  static const _successColor = Color(0xFF10B981);
  static const _warningColor = Color(0xFFF59E0B);
  static const _errorColor = Color(0xFFEF4444);
  static const _busColor = Color(0xFFF97316);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadInitialData();
  }

  void _setupAnimations() {
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    );

    _contentAnimation = CurvedAnimation(
      parent: _contentAnimController,
      curve: Curves.easeOutCubic,
    );

    _headerAnimController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _headerAnimController.dispose();
    _contentAnimController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // تحميل البيانات الأولية
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadInitialData() async {
    try {
      final sessions = await ApiService.get('general/sessions');
      final busLines = await ApiService.getBusLines();
      setState(() {
        _sessions = sessions;
        _busLines = busLines;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      _showSnackBar('فشل تحميل البيانات: $e', isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // تحميل الأطفال
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadChildren() async {
    if (_selectedSessionId == null || _selectedBusLineId == null) return;

    setState(() {
      _isLoadingChildren = true;
      _children = [];
      _filteredChildren = [];
      _searchController.clear();
    });

    try {
      final result = await ApiService.getBusLineChildren(
        busLineId: _selectedBusLineId!,
        sessionId: _selectedSessionId!,
      );

      if (result['success'] == true) {
        setState(() {
          _children = result['data'] ?? [];
          _filteredChildren = _children;
          _isLoadingChildren = false;
        });
        _contentAnimController.reset();
        _contentAnimController.forward();
      } else {
        setState(() {
          _children = [];
          _filteredChildren = [];
          _isLoadingChildren = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingChildren = false);
      _showSnackBar('فشل تحميل البيانات: $e', isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // فلترة الأطفال
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
        .replaceAll('َ', '')
        .replaceAll('ُ', '')
        .replaceAll('ِ', '')
        .replaceAll('ّ', '')
        .replaceAll('ً', '')
        .replaceAll('ٌ', '')
        .replaceAll('ٍ', '')
        .replaceAll('ْ', '')
        .toLowerCase()
        .trim();
  }

  void _filterChildren(String query) {
    if (query.isEmpty) {
      setState(() => _filteredChildren = _children);
    } else {
      final normalizedQuery = _normalizeArabic(query);
      setState(() {
        _filteredChildren = _children.where((child) {
          final name = _normalizeArabic(
            (child['FullNameArabic'] ?? '').toString(),
          );
          return name.contains(normalizedQuery);
        }).toList();
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // الاتصال
  // ═══════════════════════════════════════════════════════════════

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnackBar('لا يمكن الاتصال بهذا الرقم', isError: true);
    }
  }

  Future<void> _openWhatsApp(String number) async {
    String cleanNumber = number.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '2$cleanNumber';
    }
    if (!cleanNumber.startsWith('20')) {
      cleanNumber = '20$cleanNumber';
    }
    final uri = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('لا يمكن فتح واتساب', isError: true);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // عرض أرقام التليفونات
  // ═══════════════════════════════════════════════════════════════

  void _showContactSheet(Map<String, dynamic> child) {
    HapticFeedback.lightImpact();

    final phones = <Map<String, String>>[];

    if (child['MotherMobile1'] != null &&
        child['MotherMobile1'].toString().isNotEmpty) {
      phones.add({
        'label': 'الأم - رقم 1',
        'number': child['MotherMobile1'].toString(),
        'icon': 'mother',
      });
    }
    if (child['MotherMobile2'] != null &&
        child['MotherMobile2'].toString().isNotEmpty) {
      phones.add({
        'label': 'الأم - رقم 2',
        'number': child['MotherMobile2'].toString(),
        'icon': 'mother',
      });
    }
    if (child['FatherMobile1'] != null &&
        child['FatherMobile1'].toString().isNotEmpty) {
      phones.add({
        'label': 'الأب - رقم 1',
        'number': child['FatherMobile1'].toString(),
        'icon': 'father',
      });
    }
    if (child['FatherMobile2'] != null &&
        child['FatherMobile2'].toString().isNotEmpty) {
      phones.add({
        'label': 'الأب - رقم 2',
        'number': child['FatherMobile2'].toString(),
        'icon': 'father',
      });
    }

    if (phones.isEmpty) {
      _showSnackBar('لا توجد أرقام هواتف مسجلة', isError: true);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // Child Name
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _busColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _busColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.child_care_rounded,
                      color: _busColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      child['FullNameArabic'] ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Phone Numbers
            ...phones.map((phone) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _isDark ? Colors.grey[800] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: phone['icon'] == 'mother'
                              ? Colors.pink.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          phone['icon'] == 'mother'
                              ? Icons.woman_rounded
                              : Icons.man_rounded,
                          color: phone['icon'] == 'mother'
                              ? Colors.pink
                              : Colors.blue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              phone['label']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: _isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              phone['number']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    _isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Call Button
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _makeCall(phone['number']!);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.call_rounded,
                            color: _successColor,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // WhatsApp Button
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _openWhatsApp(phone['number']!);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.chat_rounded,
                            color: Color(0xFF25D366),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
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
      body: _isLoadingData ? _buildLoadingWidget() : _buildContent(),
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
            'جاري تحميل البيانات...',
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
              if (_isLoadingChildren) _buildChildrenLoading(),
              if (!_isLoadingChildren && _children.isNotEmpty)
                FadeTransition(
                  opacity: _contentAnimation,
                  child: _buildChildrenSection(),
                ),
              if (!_isLoadingChildren &&
                  _children.isEmpty &&
                  _selectedBusLineId != null &&
                  _selectedSessionId != null)
                _buildEmptyState(),
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
            color: _isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
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
        'أطفال خط الباص',
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
        child: Column(
          children: [
            // أيقونة
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
            const SizedBox(height: 20),

            // العام المالي
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedSessionId,
                  hint: Text(
                    'اختر العام المالي',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: Colors.grey[600]),
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  items: _sessions.map((s) {
                    return DropdownMenuItem<int>(
                      value: s['IDSession'],
                      child: Text(s['Sessions'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedSessionId = value;
                      _children = [];
                      _filteredChildren = [];
                    });
                    _loadChildren();
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // خط الباص
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedBusLineId,
                  hint: Text(
                    'اختر خط الباص',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: Colors.grey[600]),
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  items: _busLines.map((b) {
                    return DropdownMenuItem<int>(
                      value: b['ID'],
                      child: Row(
                        children: [
                          Icon(Icons.directions_bus_rounded,
                              size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(b['BusLine'] ?? ''),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedBusLineId = value;
                      _children = [];
                      _filteredChildren = [];
                    });
                    _loadChildren();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CHILDREN LOADING
  // ═══════════════════════════════════════════════════════════════

  Widget _buildChildrenLoading() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(_busColor),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل الأطفال...',
            style: TextStyle(
              color: _isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════

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
              Icons.no_transfer_rounded,
              size: 60,
              color: _isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'لا يوجد أطفال في هذا الخط',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر خط باص آخر أو عام مالي مختلف',
            style: TextStyle(
              fontSize: 14,
              color: _isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CHILDREN SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildChildrenSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Column(
        children: [
          // Stats Bar
          _buildStatsBar(),
          const SizedBox(height: 16),

          // Search
          _buildSearchBar(),
          const SizedBox(height: 16),

          // Children List
          ..._buildChildrenList(),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final busLineName = _busLines.firstWhere(
      (b) => b['ID'] == _selectedBusLineId,
      orElse: () => {'BusLine': ''},
    )['BusLine'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _busColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: _busColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  busLineName ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_filteredChildren.length} طفل',
                  style: TextStyle(
                    fontSize: 13,
                    color: _isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _busColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_children.length}',
              style: const TextStyle(
                color: _busColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
        style: TextStyle(color: _isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: 'ابحث عن طفل...',
          hintStyle:
              TextStyle(color: _isDark ? Colors.grey[500] : Colors.grey[500]),
          prefixIcon:
              Icon(Icons.search, color: _isDark ? Colors.grey[500] : Colors.grey[500]),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear,
                      color: _isDark ? Colors.grey[500] : Colors.grey[500]),
                  onPressed: () {
                    _searchController.clear();
                    _filterChildren('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
        ),
        onChanged: _filterChildren,
      ),
    );
  }

  List<Widget> _buildChildrenList() {
    return List.generate(_filteredChildren.length, (index) {
      final child = _filteredChildren[index];
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
        child: _buildChildCard(child, index),
      );
    });
  }

  Widget _buildChildCard(Map<String, dynamic> child, int index) {
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
      child: Column(
        children: [
          // Row 1: Name + Index
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFFB923C)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child['FullNameArabic'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.business_rounded,
                            size: 14,
                            color: _isDark
                                ? Colors.grey[500]
                                : Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          child['branchName'] ?? '',
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
              // Call Button
              GestureDetector(
                onTap: () => _showContactSheet(
                    Map<String, dynamic>.from(child)),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.phone_rounded,
                    color: _successColor,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),

          // Address
          if (child['ResidenceAddress'] != null &&
              child['ResidenceAddress'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDark ? Colors.grey[800] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: _errorColor.withOpacity(0.8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      child['ResidenceAddress'].toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: _isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Mother Name
          if (child['MotherName'] != null &&
              child['MotherName'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.woman_rounded,
                    size: 16, color: Colors.pink.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text(
                  'الأم: ${child['MotherName']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}