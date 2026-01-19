import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import 'child_form_screen.dart';
import 'child_finance_screen.dart';

class ChildDetailsScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const ChildDetailsScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ChildDetailsScreen> createState() => _ChildDetailsScreenState();
}

class _ChildDetailsScreenState extends State<ChildDetailsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> _data = {};

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchDetails();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  void _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.get('children/${widget.childId}');
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 🎨 Hero App Bar
                _buildSliverAppBar(isDark),

                // 📊 Content
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // 🎯 Quick Actions
                            _buildQuickActions(isDark),

                            const SizedBox(height: 20),

                            // 👤 Personal Info Card
                            _buildInfoCard(
                              isDark: isDark,
                              title: "البيانات الشخصية",
                              icon: Icons.person_rounded,
                              color: const Color(0xFF6366F1),
                              delay: 0,
                              children: [
                                _buildInfoRow(
                                  icon: Icons.badge_rounded,
                                  label: "الاسم بالعربي",
                                  value: _data['FullNameArabic'],
                                  isDark: isDark,
                                ),
                                _buildInfoRow(
                                  icon: Icons.language_rounded,
                                  label: "الاسم بالإنجليزي",
                                  value: _data['FullNameEnglish'],
                                  isDark: isDark,
                                ),
                                _buildInfoRow(
                                  icon: Icons.credit_card_rounded,
                                  label: "الرقم القومي",
                                  value: _data['NationalID']?.toString(),
                                  isDark: isDark,
                                  isMonospace: true,
                                ),
                                _buildInfoRow(
                                  icon: Icons.cake_rounded,
                                  label: "تاريخ الميلاد",
                                  value: _formatDate(_data['birthDate']),
                                  isDark: isDark,
                                ),
                                _buildInfoRow(
                                  icon: Icons.store_rounded,
                                  label: "الفرع",
                                  value: _data['BranchName'],
                                  isDark: isDark,
                                  valueColor: const Color(0xFF6366F1),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // 👨‍👩‍👧 Parents Info Card
                            _buildInfoCard(
                              isDark: isDark,
                              title: "بيانات ولي الأمر",
                              icon: Icons.family_restroom_rounded,
                              color: const Color(0xFF10B981),
                              delay: 100,
                              children: [
                                // Father Section
                                _buildSubSectionHeader(
                                  "الأب",
                                  Icons.male_rounded,
                                  const Color(0xFF3B82F6),
                                  isDark,
                                ),
                                _buildInfoRow(
                                  icon: Icons.person_outline_rounded,
                                  label: "الاسم",
                                  value: _data['FatherName'],
                                  isDark: isDark,
                                ),
                                _buildInfoRow(
                                  icon: Icons.phone_rounded,
                                  label: "الموبايل",
                                  value: _data['FatherMobile1'],
                                  isDark: isDark,
                                  isPhone: true,
                                ),

                                const SizedBox(height: 12),

                                // Mother Section
                                _buildSubSectionHeader(
                                  "الأم",
                                  Icons.female_rounded,
                                  const Color(0xFFEC4899),
                                  isDark,
                                ),
                                _buildInfoRow(
                                  icon: Icons.person_outline_rounded,
                                  label: "الاسم",
                                  value: _data['MotherName'],
                                  isDark: isDark,
                                ),
                                _buildInfoRow(
                                  icon: Icons.phone_rounded,
                                  label: "الموبايل",
                                  value: _data['MotherMobile1'],
                                  isDark: isDark,
                                  isPhone: true,
                                ),

                                const SizedBox(height: 12),

                                // Address
                                _buildInfoRow(
                                  icon: Icons.home_rounded,
                                  label: "العنوان",
                                  value: _data['ResidenceAddress'],
                                  isDark: isDark,
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // ⚕️ Additional Info Card
                            _buildInfoCard(
                              isDark: isDark,
                              title: "معلومات إضافية",
                              icon: Icons.info_rounded,
                              color: const Color(0xFFF59E0B),
                              delay: 200,
                              children: [
                                // Tags/Badges
                                _buildTagsRow(isDark),

                                const SizedBox(height: 16),

                                // Emergency
                                if (_data['EmergencyName1'] != null ||
                                    _data['EmergencyNumber1'] != null) ...[
                                  _buildSubSectionHeader(
                                    "الطوارئ",
                                    Icons.emergency_rounded,
                                    const Color(0xFFEF4444),
                                    isDark,
                                  ),
                                  _buildInfoRow(
                                    icon: Icons.contact_phone_rounded,
                                    label: "جهة الاتصال",
                                    value: _data['EmergencyName1'],
                                    isDark: isDark,
                                  ),
                                  _buildInfoRow(
                                    icon: Icons.phone_in_talk_rounded,
                                    label: "رقم الطوارئ",
                                    value: _data['EmergencyNumber1'],
                                    isDark: isDark,
                                    isPhone: true,
                                  ),
                                ],

                                // Notes
                                if (_data['Notes'] != null &&
                                    _data['Notes'].toString().isNotEmpty)
                                  _buildNotesSection(isDark),
                              ],
                            ),

                            const SizedBox(height: 30),

                            // 🔧 Action Buttons Grid
                            _buildActionsGrid(isDark),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // 🎨 Sliver App Bar with Hero Image
  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
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
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Edit Button
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChildFormScreen(childId: widget.childId),
              ),
            );
            _fetchDetails();
          },
        ),
        // More Options
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
          ),
          onPressed: () => _showOptionsSheet(isDark),
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
              // Decorative Circles
              Positioned(
                right: -80,
                top: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -50,
                bottom: 50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),

              // Profile Content
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    // Avatar
                    Hero(
                      tag: 'child_avatar_${widget.childId}',
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.face_rounded,
                            size: 60,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Name
                    Text(
                      _data['FullNameArabic'] ?? widget.childName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 5),

                    // ID Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.qr_code_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "ID: ${widget.childId}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 Quick Actions Bar
  Widget _buildQuickActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickAction(
            icon: Icons.phone_rounded,
            label: "اتصال",
            color: const Color(0xFF10B981),
            onTap: () => _makePhoneCall(),
          ),
          _buildQuickActionDivider(isDark),
          _buildQuickAction(
            icon: Icons.message_rounded,
            label: "رسالة",
            color: const Color(0xFF3B82F6),
            onTap: () {},
          ),
          _buildQuickActionDivider(isDark),
          _buildQuickAction(
            icon: Icons.share_rounded,
            label: "مشاركة",
            color: const Color(0xFF8B5CF6),
            onTap: () {},
          ),
          _buildQuickActionDivider(isDark),
          _buildQuickAction(
            icon: Icons.print_rounded,
            label: "طباعة",
            color: const Color(0xFFF59E0B),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionDivider(bool isDark) {
    return Container(
      height: 40,
      width: 1,
      color: isDark ? Colors.grey[700] : Colors.grey[200],
    );
  }

  // 🎴 Info Card
  Widget _buildInfoCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color color,
    required int delay,
    required List<Widget> children,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📝 Info Row
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String? value,
    required bool isDark,
    bool isMonospace = false,
    bool isPhone = false,
    Color? valueColor,
  }) {
    final displayValue = value ?? "---";
    final hasValue = value != null && value.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF6366F1).withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayValue,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: valueColor ??
                              (hasValue
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : Colors.grey[400]),
                          fontFamily: isMonospace ? 'monospace' : null,
                        ),
                      ),
                    ),
                    if (isPhone && hasValue)
                      GestureDetector(
                        onTap: () {
                          // TODO: Make phone call
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.call_rounded,
                            size: 16,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🏷️ Sub Section Header
  Widget _buildSubSectionHeader(
    String title,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: color.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  // 🏷️ Tags Row
  Widget _buildTagsRow(bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (_data['DidFullTime'] == true)
          _buildTag(
            "يوم كامل",
            Icons.access_time_filled_rounded,
            const Color(0xFF6366F1),
          ),
        if (_data['DoSports'] == true)
          _buildTag(
            "رياضة",
            Icons.sports_soccer_rounded,
            const Color(0xFF10B981),
          ),
        if (_data['WearDiapers'] == true)
          _buildTag(
            "حفاضات",
            Icons.baby_changing_station_rounded,
            const Color(0xFFF59E0B),
          ),
        if (_data['Status'] == true)
          _buildTag(
            "نشط",
            Icons.check_circle_rounded,
            const Color(0xFF10B981),
          )
        else
          _buildTag(
            "غير نشط",
            Icons.cancel_rounded,
            const Color(0xFFEF4444),
          ),
      ],
    );
  }

  Widget _buildTag(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // 📝 Notes Section
  Widget _buildNotesSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey[800]!.withOpacity(0.3)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note_alt_rounded,
                size: 18,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 8),
              Text(
                "ملاحظات",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _data['Notes'] ?? "",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 Actions Grid
  Widget _buildActionsGrid(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.apps_rounded,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "الخدمات",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
          children: [
            _buildActionCard(
              icon: Icons.attach_money_rounded,
              label: "المالية",
              color: const Color(0xFF10B981),
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildFinanceScreen(
                      childId: widget.childId,
                      childName: widget.childName,
                    ),
                  ),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.calendar_month_rounded,
              label: "الحضور",
              color: const Color(0xFFF59E0B),
              isDark: isDark,
              onTap: () {},
            ),
            _buildActionCard(
              icon: Icons.directions_bus_rounded,
              label: "الباص",
              color: const Color(0xFF8B5CF6),
              isDark: isDark,
              onTap: () {},
            ),
            _buildActionCard(
              icon: Icons.receipt_long_rounded,
              label: "الفواتير",
              color: const Color(0xFF3B82F6),
              isDark: isDark,
              onTap: () {},
            ),
            _buildActionCard(
              icon: Icons.medical_services_rounded,
              label: "الصحة",
              color: const Color(0xFFEF4444),
              isDark: isDark,
              onTap: () {},
            ),
            _buildActionCard(
              icon: Icons.history_rounded,
              label: "السجل",
              color: const Color(0xFF6B7280),
              isDark: isDark,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📞 Make Phone Call
  void _makePhoneCall() {
    final phone = _data['FatherMobile1'] ?? _data['MotherMobile1'];
    if (phone != null) {
      // TODO: Implement phone call using url_launcher
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.phone, color: Colors.white),
              const SizedBox(width: 10),
              Text("جاري الاتصال بـ $phone"),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ⚙️ Options Bottom Sheet
  void _showOptionsSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
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
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              _buildOptionItem(
                icon: Icons.edit_rounded,
                label: "تعديل البيانات",
                color: const Color(0xFF6366F1),
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChildFormScreen(childId: widget.childId),
                    ),
                  ).then((_) => _fetchDetails());
                },
              ),

              _buildOptionItem(
                icon: Icons.refresh_rounded,
                label: "تحديث البيانات",
                color: const Color(0xFF10B981),
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _fetchDetails();
                },
              ),

              _buildOptionItem(
                icon: Icons.delete_rounded,
                label: "حذف الطفل",
                color: const Color(0xFFEF4444),
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(isDark);
                },
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: Colors.grey[400],
      ),
    );
  }

  // 🗑️ Delete Confirmation
  void _showDeleteConfirmation(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF252836) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "تأكيد الحذف",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          "هل أنت متأكد من حذف بيانات ${widget.childName}؟\nلا يمكن التراجع عن هذا الإجراء.",
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "إلغاء",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Implement delete
            },
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
  }

  // 📅 Format Date
  String? _formatDate(dynamic date) {
    if (date == null) return null;
    try {
      final dateStr = date.toString().split('T')[0];
      final parts = dateStr.split('-');
      return "${parts[2]}/${parts[1]}/${parts[0]}";
    } catch (e) {
      return date.toString();
    }
  }
}