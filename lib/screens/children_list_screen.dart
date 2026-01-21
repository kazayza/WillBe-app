import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/children_provider.dart';
import '../models/child_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'child_form_screen.dart';
import 'child_details_screen.dart';

class ChildrenListScreen extends StatefulWidget {
  const ChildrenListScreen({super.key});

  @override
  State<ChildrenListScreen> createState() => _ChildrenListScreenState();
}

class _ChildrenListScreenState extends State<ChildrenListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedBranch;
  String? _selectedBranchName;
  int? _selectedSession;
  String? _selectedSessionName;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadData();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  void _loadData() {
    Future.microtask(() {
      final provider = Provider.of<ChildrenProvider>(context, listen: false);
      provider.fetchChildren();
      provider.fetchBranches();
      provider.fetchSessions();
      _animationController.forward();
    });
  }

  Future<void> _refreshData() async {
    HapticFeedback.mediumImpact();
    final provider = Provider.of<ChildrenProvider>(context, listen: false);
    await provider.fetchChildren(
      query: _searchController.text,
      branchId: _selectedBranch,
      sessionId: _selectedSession,
    );
  }

  void _onSearchChanged(String query) {
    Provider.of<ChildrenProvider>(context, listen: false).fetchChildren(
      query: query,
      branchId: _selectedBranch,
      sessionId: _selectedSession,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChildrenProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final canAdd = Provider.of<AuthProvider>(context, listen: false)
        .canAdd('شاشة الأطفال');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF6366F1),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ✨ Custom App Bar
            _buildSliverAppBar(isDark, provider),

            // 📊 Stats Bar
            SliverToBoxAdapter(
              child: _buildStatsBar(provider, isDark),
            ),

            // 🏷️ Active Filters
            if (_selectedBranch != null || _selectedSession != null)
              SliverToBoxAdapter(
                child: _buildActiveFilters(isDark),
              ),

            // 👶 Children List
            provider.isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  )
                : provider.children.isEmpty
                    ? SliverFillRemaining(
                        child: _buildEmptyState(isDark),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final child = provider.children[index];
                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: _buildChildCard(child, isDark, index, provider),
                              );
                            },
                            childCount: provider.children.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),

      // ➕ FAB
      floatingActionButton: canAdd ? _buildFAB() : null,
    );
  }

  // 🎨 Sliver App Bar
  Widget _buildSliverAppBar(bool isDark, ChildrenProvider provider) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF6366F1),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // 🔍 Search Toggle
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _onSearchChanged('');
              }
            });
          },
        ),

        // 🔃 Sort
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sort_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () => _showSortBottomSheet(provider, isDark),
        ),

        // 🔽 Filter
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (_selectedBranch != null || _selectedSession != null)
                  ? Colors.white
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.filter_list_rounded,
              color: (_selectedBranch != null || _selectedSession != null)
                  ? const Color(0xFF6366F1)
                  : Colors.white,
              size: 20,
            ),
          ),
          onPressed: () => _showFilterBottomSheet(provider, isDark),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: 20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 60,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.child_care_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 15),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "شئون الأطفال",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "إدارة بيانات الأطفال",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: _isSearching
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "ابحث باسم الطفل أو الكود...",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // 📊 Stats Bar
  Widget _buildStatsBar(ChildrenProvider provider, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.people_rounded,
              color: Color(0xFF6366F1),
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "عرض ${provider.filteredCount} من ${provider.totalCount}",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  "طفل",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          // Sort indicator
          GestureDetector(
            onTap: () => _showSortBottomSheet(provider, isDark),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sort_rounded,
                    color: Color(0xFF6366F1),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getSortLabel(provider.currentSort),
                    style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🏷️ Active Filters
  Widget _buildActiveFilters(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              "الفلاتر:",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 10),
            
            // Branch Filter Chip
            if (_selectedBranch != null)
              _buildFilterChip(
                icon: Icons.location_on,
                label: _selectedBranchName ?? "فرع",
                onRemove: () {
                  setState(() {
                    _selectedBranch = null;
                    _selectedBranchName = null;
                  });
                  _onSearchChanged(_searchController.text);
                },
              ),
            
            if (_selectedBranch != null && _selectedSession != null)
              const SizedBox(width: 8),
            
            // Session Filter Chip
            if (_selectedSession != null)
              _buildFilterChip(
                icon: Icons.calendar_today_rounded,
                label: _selectedSessionName ?? "سنة",
                onRemove: () {
                  setState(() {
                    _selectedSession = null;
                    _selectedSessionName = null;
                  });
                  _onSearchChanged(_searchController.text);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ],
      ),
    );
  }

  // 👶 Child Card with Swipe
// 👶 Child Card with Swipe (مع صلاحيات)
Widget _buildChildCard(Child child, bool isDark, int index, ChildrenProvider provider) {
  const Color cardColor = Color(0xFF6366F1);
  
  // 👈 التحقق من الصلاحيات
  final auth = Provider.of<AuthProvider>(context, listen: false);
  final canEdit = auth.canEdit('شاشة الأطفال');
  final canDelete = auth.canDelete('شاشة الأطفال');

  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 400 + (index * 50)),
    curve: Curves.easeOutCubic,
    builder: (context, value, animChild) {
      return Transform.translate(
        offset: Offset(0, 30 * (1 - value)),
        child: Opacity(
          opacity: value,
          child: animChild,
        ),
      );
    },
    child: Dismissible(
      key: Key('child_${child.id}'),
      // 👈 تحديد اتجاه السحب حسب الصلاحيات
      direction: (canEdit || canDelete)
          ? (canEdit && canDelete)
              ? DismissDirection.horizontal
              : canEdit
                  ? DismissDirection.startToEnd
                  : DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Edit
          if (canEdit) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChildFormScreen(childId: child.id),
              ),
            );
          }
          return false;
        } else {
          // Delete
          if (canDelete) {
            return await _showDeleteConfirmation(child, provider);
          }
          return false;
        }
      },
      background: canEdit
          ? Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "تعديل",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox(),
      secondaryBackground: canDelete
          ? Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "حذف",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.delete_rounded, color: Colors.white),
                ],
              ),
            )
          : const SizedBox(),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChildDetailsScreen(
                childId: child.id,
                childName: child.fullNameArabic,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // الخط الجانبي
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          cardColor,
                          cardColor.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ),

                // المحتوى
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Avatar
                      Hero(
                        tag: 'child_avatar_${child.id}',
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                cardColor.withOpacity(0.2),
                                cardColor.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.face_rounded,
                            color: cardColor,
                            size: 35,
                          ),
                        ),
                      ),

                      const SizedBox(width: 15),

                      // البيانات
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    child.fullNameArabic,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // الكود
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "#${child.id}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: cardColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // الرقم القومي
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.badge_outlined,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        child.nationalID?.toString() ?? '---',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                // Swipe hint - يظهر فقط لو عنده صلاحية
                                if (canEdit || canDelete)
                                  Icon(
                                    Icons.swipe_rounded,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // السهم
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: cardColor,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  // 🗑️ Delete Confirmation
// 🗑️ Delete Confirmation (مع صلاحيات)
Future<bool> _showDeleteConfirmation(Child child, ChildrenProvider provider) async {
  // 👈 التحقق من الصلاحية أولاً
  final auth = Provider.of<AuthProvider>(context, listen: false);
  if (!auth.canDelete('شاشة الأطفال')) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.block_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text("ليس لديك صلاحية الحذف"),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return false;
  }

  final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF252836) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_rounded, color: Color(0xFFEF4444)),
          ),
          const SizedBox(width: 10),
          Text(
            "تأكيد الحذف",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
      content: Text(
        "هل أنت متأكد من حذف الطفل\n${child.fullNameArabic}؟",
        style: TextStyle(
          color: isDark ? Colors.grey[300] : Colors.grey[700],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            "إلغاء",
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("حذف", style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  if (result == true) {
    final success = await provider.deleteChild(child.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("تم حذف الطفل بنجاح"),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text("فشل حذف الطفل - قد يكون مرتبط ببيانات أخرى"),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return success;
  }
  return false;
}

  // 📭 Empty State
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.child_care_rounded,
              size: 60,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "لا يوجد أطفال",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "اضغط على + لإضافة طفل جديد",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChildFormScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text("إضافة طفل"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ➕ FAB
  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChildFormScreen()),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
    );
  }

// 🔃 Sort Bottom Sheet
void _showSortBottomSheet(ChildrenProvider provider, bool isDark) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,  // 👈 مهم
    builder: (ctx) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,  // 👈 حد أقصى للارتفاع
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sort_rounded,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "ترتيب حسب",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // 👈 خليناها Scrollable
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSortOption(SortType.nameAsc, "الاسم (أ → ي)", Icons.sort_by_alpha_rounded, provider, isDark),
                    _buildSortOption(SortType.nameDesc, "الاسم (ي → أ)", Icons.sort_by_alpha_rounded, provider, isDark),
                    _buildSortOption(SortType.codeAsc, "الكود (1 → 100)", Icons.tag_rounded, provider, isDark),
                    _buildSortOption(SortType.codeDesc, "الكود (100 → 1)", Icons.tag_rounded, provider, isDark),
                    _buildSortOption(SortType.dateAsc, "الأقدم أولاً", Icons.calendar_today_rounded, provider, isDark),
                    _buildSortOption(SortType.dateDesc, "الأحدث أولاً", Icons.calendar_today_rounded, provider, isDark),
                  ],
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      );
    },
  );
}

  Widget _buildSortOption(SortType sortType, String label, IconData icon, ChildrenProvider provider, bool isDark) {
    final isSelected = provider.currentSort == sortType;

    return GestureDetector(
      onTap: () {
        provider.setSortType(sortType);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withOpacity(0.1)
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF6366F1) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF6366F1),
              ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel(SortType sortType) {
    switch (sortType) {
      case SortType.nameAsc:
        return "أ → ي";
      case SortType.nameDesc:
        return "ي → أ";
      case SortType.codeAsc:
        return "1 → 100";
      case SortType.codeDesc:
        return "100 → 1";
      case SortType.dateAsc:
        return "الأقدم";
      case SortType.dateDesc:
        return "الأحدث";
    }
  }

  // 🔽 Filter Bottom Sheet
  void _showFilterBottomSheet(ChildrenProvider provider, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.filter_list_rounded,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "تصفية النتائج",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Sessions Section
              _buildFilterSection(
                title: "السنة المالية",
                icon: Icons.calendar_today_rounded,
                isDark: isDark,
              ),
              
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.sessions.length,
                  itemBuilder: (ctx, i) {
                    final session = provider.sessions[i];
                    final isSelected = _selectedSession == session['IDSession'];
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSession = session['IDSession'];
                          _selectedSessionName = session['Sessions'];
                        });
                        _onSearchChanged(_searchController.text);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(left: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            session['Sessions'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Branches Section
              _buildFilterSection(
                title: "الفرع",
                icon: Icons.location_on_rounded,
                isDark: isDark,
              ),

              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.branches.length,
                  itemBuilder: (ctx, i) {
                    final branch = provider.branches[i];
                    final isSelected = _selectedBranch == branch['IDbranch'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedBranch = branch['IDbranch'];
                          _selectedBranchName = branch['branchName'];
                        });
                        _onSearchChanged(_searchController.text);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6366F1).withOpacity(0.1)
                              : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF6366F1)
                                    : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                color: isSelected ? Colors.white : Colors.grey,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                branch['branchName'],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF6366F1),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 15),

              // Clear All Filters
              if (_selectedBranch != null || _selectedSession != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedBranch = null;
                        _selectedBranchName = null;
                        _selectedSession = null;
                        _selectedSessionName = null;
                      });
                      Provider.of<ChildrenProvider>(context, listen: false).clearFilters();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.clear_all_rounded),
                    label: const Text("إلغاء كل الفلاتر"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}