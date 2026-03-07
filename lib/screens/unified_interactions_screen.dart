import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import 'lead_details_screen.dart';
import 'customer_details_screen.dart';

class UnifiedInteractionsScreen extends StatefulWidget {
  const UnifiedInteractionsScreen({super.key});

  @override
  State<UnifiedInteractionsScreen> createState() => _UnifiedInteractionsScreenState();
}

class _UnifiedInteractionsScreenState extends State<UnifiedInteractionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  String _selectedFilter = 'all'; // all, leads, customers

  // تفاصيل العميل المحدد
  dynamic _selectedContact;
  List<dynamic> _interactions = [];
  bool _isLoadingInteractions = false;
  String _detailTypeFilter = 'All'; // All, Call, Visit, WhatsApp

  // 🔍 البحث عن جهات الاتصال
  Future<void> _searchContacts(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final data = await ApiService.get(
        'interactions/search?query=$query&type=$_selectedFilter',
      );
      if (mounted) {
        setState(() {
          _searchResults = data is List ? data : [];
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // 📥 جلب سجل التواصل لعميل محدد
  Future<void> _loadInteractions(dynamic contact) async {
    setState(() {
      _selectedContact = contact;
      _isLoadingInteractions = true;
      _interactions = [];
    });

    try {
      final isLead = contact['ContactType'] == 'Lead';
      final id = contact['ID'];
      String params = isLead ? 'leadId=$id' : 'customerId=$id';

      final data = await ApiService.get('interactions/person?$params');

      if (mounted) {
        setState(() {
          _interactions = data is List ? data : [];
          _isLoadingInteractions = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingInteractions = false);
    }
  }

  // 🚀 الانتقال لملف العميل
  void _goToProfile() async {
    if (_selectedContact == null) return;
    
    final id = _selectedContact['ID'];
    final isLead = _selectedContact['ContactType'] == 'Lead';

    Widget targetScreen;
    if (isLead) {
      final leadData = await ApiService.get('leads/$id');
      targetScreen = LeadDetailsScreen(lead: leadData);
    } else {
      final custData = await ApiService.get('customers/$id');
      targetScreen = CustomerDetailsScreen(customer: custData);
    }

    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen))
          .then((_) => _loadInteractions(_selectedContact));
    }
  }

  void _resetSelection() {
    setState(() {
      _selectedContact = null;
      _interactions = [];
      _searchController.clear();
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('سجل التواصل الموحد'),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        leading: _selectedContact != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _resetSelection)
            : null,
      ),
      body: Column(
        children: [
          if (_selectedContact == null) _buildSearchSection(isDark),
          Expanded(
            child: _selectedContact == null
                ? _buildSearchResults(isDark)
                : _buildInteractionsList(isDark),
          ),
        ],
      ),
      floatingActionButton: _selectedContact != null ? _buildFAB() : null,
    );
  }

  Widget _buildSearchSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (val == _searchController.text) _searchContacts(val);
              });
            },
            decoration: InputDecoration(
              hintText: 'بحث بالاسم أو الموبايل...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('الكل', 'all', const Color(0xFF6366F1)),
                const SizedBox(width: 8),
                _buildFilterChip('العملاء المحتملين', 'leads', const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _buildFilterChip('العملاء الفعليين', 'customers', const Color(0xFF10B981)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
            if (_searchController.text.isNotEmpty) _searchContacts(_searchController.text);
          });
        }
      },
      selectedColor: color,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    if (_isSearching) return const Center(child: CircularProgressIndicator());
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('ابحث لعرض سجل التواصل الموحد', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        final isLead = item['ContactType'] == 'Lead';
        final color = isLead ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
        
        return Card(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(isLead ? Icons.person_outline : Icons.person, color: color),
            ),
            title: Text(item['FullName'] ?? '---', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item['Phone'] ?? ''),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(isLead ? 'محتمل' : 'فعلي', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            onTap: () => _loadInteractions(item),
          ),
        );
      },
    );
  }

  Widget _buildInteractionsList(bool isDark) {
    if (_isLoadingInteractions) return const Center(child: CircularProgressIndicator());

    final filteredInteractions = _detailTypeFilter == 'All' 
      ? _interactions 
      : _interactions.where((i) => i['InteractionType'] == _detailTypeFilter).toList();

    return Column(
      children: [
        // 👤 Header
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? const Color(0xFF252836) : Colors.white,
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                child: Text(_selectedContact['FullName']?[0].toUpperCase() ?? '?', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedContact['FullName'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(_selectedContact['Phone'] ?? '', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.account_circle_outlined, color: Color(0xFF6366F1), size: 30),
                onPressed: _goToProfile,
                tooltip: 'عرض الملف الكامل',
              ),
            ],
          ),
        ),
        
        // 🔍 Internal Filter
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildDetailFilterChip('الكل', 'All'),
              _buildDetailFilterChip('مكالمات', 'Call'),
              _buildDetailFilterChip('واتساب', 'WhatsApp'),
              _buildDetailFilterChip('زيارات', 'Visit'),
            ],
          ),
        ),

        const Divider(height: 1),

        // 📋 Interactions
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadInteractions(_selectedContact),
            child: filteredInteractions.isEmpty
                ? const Center(child: Text('لا توجد تفاعلات بهذا التصنيف'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredInteractions.length,
                    itemBuilder: (context, index) => _buildInteractionCard(filteredInteractions[index], isDark),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailFilterChip(String label, String value) {
    final isSelected = _detailTypeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12)),
        backgroundColor: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
        onPressed: () => setState(() => _detailTypeFilter = value),
        shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[300]!)),
      ),
    );
  }

  Widget _buildInteractionCard(dynamic inter, bool isDark) {
    final type = inter['InteractionType'];
    final color = _getTypeColor(type);
    final date = DateTime.tryParse(inter['InteractionDate'] ?? '')?.toLocal();
    final dateStr = date != null ? DateFormat('EEEE، d MMMM yyyy • hh:mm a', 'ar').format(date) : '';

    return Card(
      color: isDark ? const Color(0xFF252836) : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: color.withOpacity(0.2))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getTypeIcon(type), color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(inter['Subject'] ?? 'بدون عنوان', style: const TextStyle(fontWeight: FontWeight.bold))),
                if (inter['Outcome'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(inter['Outcome'], style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(inter['Details'] ?? '', style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700], height: 1.4)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateStr, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                if (inter['userAdd'] != null)
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(inter['userAdd'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
  return FloatingActionButton(
    backgroundColor: const Color(0xFF6366F1),
    child: const Icon(Icons.add_comment_rounded, color: Colors.white),
    onPressed: () => _showAddInteractionSheet(),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ➕ إضافة تواصل جديد
// ═══════════════════════════════════════════════════════════════════════════

void _showAddInteractionSheet() {
  final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;
  
  String _interactionType = 'Call';
  final _subjectController = TextEditingController();
  final _detailsController = TextEditingController();
  String _outcome = 'Pending';
  bool _isSaving = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.add_comment_rounded,
                          color: Color(0xFF6366F1),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إضافة تواصل جديد',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              _selectedContact?['FullName'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // نوع التواصل
                        Text(
                          'نوع التواصل',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildTypeOption(
                              icon: Icons.call_rounded,
                              label: 'مكالمة',
                              value: 'Call',
                              selected: _interactionType,
                              color: const Color(0xFF10B981),
                              isDark: isDark,
                              onTap: () => setModalState(() => _interactionType = 'Call'),
                            ),
                            const SizedBox(width: 10),
                            _buildTypeOption(
                              icon: Icons.chat_rounded,
                              label: 'واتساب',
                              value: 'WhatsApp',
                              selected: _interactionType,
                              color: const Color(0xFF25D366),
                              isDark: isDark,
                              onTap: () => setModalState(() => _interactionType = 'WhatsApp'),
                            ),
                            const SizedBox(width: 10),
                            _buildTypeOption(
                              icon: Icons.meeting_room_rounded,
                              label: 'زيارة',
                              value: 'Visit',
                              selected: _interactionType,
                              color: const Color(0xFFF59E0B),
                              isDark: isDark,
                              onTap: () => setModalState(() => _interactionType = 'Visit'),
                            ),
                            const SizedBox(width: 10),
                            _buildTypeOption(
                              icon: Icons.email_rounded,
                              label: 'بريد',
                              value: 'Email',
                              selected: _interactionType,
                              color: const Color(0xFF3B82F6),
                              isDark: isDark,
                              onTap: () => setModalState(() => _interactionType = 'Email'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // الموضوع
                        Text(
                          'الموضوع',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _subjectController,
                          decoration: InputDecoration(
                            hintText: 'مثال: استفسار عن الأسعار',
                            filled: true,
                            fillColor: isDark ? const Color(0xFF252836) : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.subject_rounded, color: Color(0xFF6366F1)),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // التفاصيل
                        Text(
                          'التفاصيل',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _detailsController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'اكتب تفاصيل المحادثة...',
                            filled: true,
                            fillColor: isDark ? const Color(0xFF252836) : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // النتيجة
                        Text(
                          'النتيجة',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _buildOutcomeChip('قيد المتابعة', 'Pending', _outcome, const Color(0xFFF59E0B), isDark, () => setModalState(() => _outcome = 'Pending')),
                            _buildOutcomeChip('مهتم', 'Interested', _outcome, const Color(0xFF10B981), isDark, () => setModalState(() => _outcome = 'Interested')),
                            _buildOutcomeChip('غير مهتم', 'Not Interested', _outcome, const Color(0xFFEF4444), isDark, () => setModalState(() => _outcome = 'Not Interested')),
                            _buildOutcomeChip('معاودة الاتصال', 'Callback', _outcome, const Color(0xFF3B82F6), isDark, () => setModalState(() => _outcome = 'Callback')),
                            _buildOutcomeChip('تم الإغلاق', 'Closed', _outcome, const Color(0xFF8B5CF6), isDark, () => setModalState(() => _outcome = 'Closed')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Save Button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF252836) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              if (_subjectController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('يرجى إدخال موضوع التواصل'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setModalState(() => _isSaving = true);

                              try {
                                final isLead = _selectedContact['ContactType'] == 'Lead';
                                await ApiService.post('interactions', {
  if (isLead) 'leadId': _selectedContact['ID'],
  if (!isLead) 'customerId': _selectedContact['ID'],
  'type': _interactionType,
  'subject': _subjectController.text,
  'details': _detailsController.text,
  'outcome': _outcome,
  'interactionDate': DateTime.now().toIso8601String(),
});

                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.white),
                                          SizedBox(width: 10),
                                          Text('تم إضافة التواصل بنجاح'),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF10B981),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                  // إعادة تحميل التفاعلات
                                  _loadInteractions(_selectedContact);
                                }
                              } catch (e) {
                                setModalState(() => _isSaving = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('فشل الحفظ: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded),
                                SizedBox(width: 10),
                                Text(
                                  'حفظ التواصل',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _buildTypeOption({
  required IconData icon,
  required String label,
  required String value,
  required String selected,
  required Color color,
  required bool isDark,
  required VoidCallback onTap,
}) {
  final isSelected = selected == value;
  return Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : (isDark ? const Color(0xFF252836) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildOutcomeChip(
  String label,
  String value,
  String selected,
  Color color,
  bool isDark,
  VoidCallback onTap,
) {
  final isSelected = selected == value;
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? color : (isDark ? const Color(0xFF252836) : Colors.grey[100]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? color : (isDark ? const Color(0xFF3A3A4A) : Colors.grey[300]!),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
      ),
    ),
  );
}

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'Call': return const Color(0xFF10B981);
      case 'Visit': return const Color(0xFFF59E0B);
      case 'WhatsApp': return const Color(0xFF25D366);
      default: return const Color(0xFF6366F1);
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'Call': return Icons.call;
      case 'Visit': return Icons.meeting_room;
      case 'WhatsApp': return Icons.chat;
      default: return Icons.info;
    }
  }
}