import 'package:flutter/material.dart';
import '../theme/finance_theme.dart';
import '../models/child_finance_browser_model.dart';
import '../services/child_finance_browser_service.dart';
import '../widgets/child_finance/session_overview_card.dart';
import 'finance_session_details_screen.dart';

class FinanceSessionsScreen extends StatefulWidget {
  const FinanceSessionsScreen({super.key});

  @override
  State<FinanceSessionsScreen> createState() => _FinanceSessionsScreenState();
}

class _FinanceSessionsScreenState extends State<FinanceSessionsScreen> {
  bool _isLoading = true;
  String? _error;
  List<SessionOverviewModel> _allSessions = [];
  List<SessionOverviewModel> _filteredSessions = [];
  final TextEditingController _searchController = TextEditingController();

  // متغير التحكم في فتح وغلق البحث
  bool _isSearchOpen = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadSessions();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applySearch);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ChildFinanceBrowserService.getSessionsOverview();
      if (mounted) {
        setState(() {
          _allSessions = data;
          _filteredSessions = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
    }
  }

  void _applySearch() {
    final query = _searchController.text.trim();
    setState(() {
      _filteredSessions = query.isEmpty
          ? _allSessions
          : _allSessions.where((item) => item.sessionName.contains(query)).toList();
    });
  }

  void _openSession(SessionOverviewModel session) {
    Navigator.push(context, PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) =>
          FinanceSessionDetailsScreen(sessionId: session.sessionId, sessionName: session.sessionName),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: const Offset(0.05, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: tween.animate(animation), child: child);
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FinanceTheme.bg(context),
      body: RefreshIndicator(
        onRefresh: _loadSessions,
        color: FinanceTheme.accent,
        backgroundColor: FinanceTheme.card(context),
        child: CustomScrollView(
          slivers: [
            _buildCompactAppBar(),
            SliverToBoxAdapter(child: _buildBodyContent()),
          ],
        ),
      ),
    );
  }

  // === AppBar مضغوط وأنيق ===
  Widget _buildCompactAppBar() {
    return SliverAppBar(
      expandedHeight: 70.0, // تقليل المسافة بشكل كبير
      floating: true,
      pinned: true,
      backgroundColor: FinanceTheme.primary,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
      ),
      title: const Text(
        'ماليات الأطفال',
        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18, letterSpacing: -0.3),
      ),
      centerTitle: true,
      actions: [
        // أيقونة البحث المتحركة
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: _isSearchOpen
                ? Container(
                    key: const ValueKey('search_field'),
                    width: 200,
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'بحث...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white54),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _isSearchOpen = false);
                          },
                          child: const Icon(Icons.close, size: 18, color: Colors.white54),
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    key: const ValueKey('search_icon'),
                    icon: const Icon(Icons.search_rounded, size: 22, color: Colors.white),
                    onPressed: () => setState(() => _isSearchOpen = true),
                  ),
          ),
        ),
        IconButton(
          onPressed: _loadSessions,
          icon: const Icon(Icons.refresh_rounded, size: 21, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) return _buildLoadingSkeleton();
    if (_error != null) return _buildErrorState();
    if (_filteredSessions.isEmpty) return _buildEmptyState();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      itemCount: _filteredSessions.length,
      itemBuilder: (context, index) {
        final session = _filteredSessions[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 80)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20), // مسافة فاضية بين الكروت
            child: SessionOverviewCard(session: session, onTap: () => _openSession(session)),
          ),
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            height: 200,
            decoration: BoxDecoration(color: FinanceTheme.border.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(24)),
          );
        }),
      ),
    );
  }

  Widget _buildErrorState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 50, color: FinanceTheme.error.withValues(alpha: 0.8)),
              const SizedBox(height: 20),
              Text('تعذر تحميل البيانات', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: FinanceTheme.text(context))),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: FinanceTheme.textSec(context), fontSize: 13.5, height: 1.5)),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _loadSessions,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FinanceTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 350,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.manage_search_rounded, size: 52, color: FinanceTheme.textHint.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('لا توجد نتائج', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: FinanceTheme.text(context))),
          ],
        ),
      ),
    );
  }
}