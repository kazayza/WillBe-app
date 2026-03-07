import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/financial_settings_provider.dart';
import '../providers/theme_provider.dart';

class GenericKindsScreen extends StatefulWidget {
  final bool isIncome; 

  const GenericKindsScreen({super.key, required this.isIncome});

  @override
  State<GenericKindsScreen> createState() => _GenericKindsScreenState();
}

class _GenericKindsScreenState extends State<GenericKindsScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Provider.of<FinancialSettingsProvider>(context, listen: false)
          .fetchKinds(widget.isIncome);
    });
  }

  // تجميع البيانات حسب المجموعة
  Map<String, List<dynamic>> _groupItems(List<dynamic> items) {
    Map<String, List<dynamic>> grouped = {};
    for (var item in items) {
      String group = item['kindGroup'] ?? item['KindGroup'] ?? 'عام';
      if (!grouped.containsKey(group)) grouped[group] = [];
      grouped[group]!.add(item);
    }
    return grouped;
  }

  // نافذة الإضافة/التعديل (مع التحسينات)
  void _showDialog({Map<String, dynamic>? item, String? preFilledGroup}) {
    final isEdit = item != null;
    final nameController = TextEditingController(text: isEdit ? (item['incomeKind'] ?? item['expenseKind']) : '');
    
    // لو جاي من زرار المجموعة، نملأ المجموعة تلقائياً
    String initialGroup = isEdit 
        ? (item['kindGroup'] ?? item['KindGroup']) 
        : (preFilledGroup ?? '');
    
    final formKey = GlobalKey<FormState>();
    final existingGroups = _groupItems(Provider.of<FinancialSettingsProvider>(context, listen: false).items).keys.toList();
    String selectedGroup = initialGroup;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? "تعديل النوع" : "إضافة نوع جديد"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Autocomplete للمجموعة
              Autocomplete<String>(
                initialValue: TextEditingValue(text: initialGroup),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') return existingGroups;
                  return existingGroups.where((String option) {
                    return option.contains(textEditingValue.text);
                  });
                },
                onSelected: (String selection) => selectedGroup = selection,
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  textEditingController.addListener(() {
                    selectedGroup = textEditingController.text;
                  });
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: "اسم المجموعة",
                      hintText: "اختر أو اكتب جديد",
                      suffixIcon: Icon(Icons.arrow_drop_down_circle_outlined),
                    ),
                    validator: (v) => v!.isEmpty ? "مطلوب" : null,
                  );
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "اسم النوع"),
                validator: (v) => v!.isEmpty ? "مطلوب" : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final provider = Provider.of<FinancialSettingsProvider>(context, listen: false);
                try {
                  if (isEdit) {
                    await provider.updateKind(widget.isIncome, item['ID'], nameController.text, selectedGroup);
                  } else {
                    await provider.addKind(widget.isIncome, nameController.text, selectedGroup);
                  }
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الحفظ ✅"), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e"), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int id) async {
    final provider = Provider.of<FinancialSettingsProvider>(context, listen: false);
    try {
      await provider.deleteKind(widget.isIncome, id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الحذف ✅"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("فشل الحذف (مستخدم)"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinancialSettingsProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final groupedItems = _groupItems(provider.items);
    final title = widget.isIncome ? "أنواع الإيرادات" : "أنواع المصروفات";
    final color = widget.isIncome ? Colors.green : Colors.red;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      appBar: AppBar(title: Text(title), backgroundColor: color),
      
      // الزر العائم (إضافة عامة)
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        backgroundColor: color,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      
      body: provider.isLoading
          ? Center(child: CircularProgressIndicator(color: color))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: groupedItems.entries.map((entry) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isDark ? const Color(0xFF252836) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Theme(
                    // إزالة الخط الفاصل الافتراضي للـ ExpansionTile
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      // أيقونة المجموعة
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.1),
                        child: Icon(
                          _getGroupIcon(entry.key), // 👈 استدعاء الدالة هنا
                          color: color,
                        ),
                      ),
                      title: Text(
                        entry.key, // اسم المجموعة
                        style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                      ),
                      // زر الإضافة السريع للمجموعة
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.add_circle_outline, color: color),
                            onPressed: () => _showDialog(preFilledGroup: entry.key), // يفتح بإسم المجموعة جاهز
                            tooltip: "إضافة عنصر لهذه المجموعة",
                          ),
                          const Icon(Icons.keyboard_arrow_down), // سهم الفتح
                        ],
                      ),
                      children: entry.value.map((item) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.only(left: 70, right: 16), // إزاحة لليمين (شجري)
                            title: Text(item['incomeKind'] ?? item['expenseKind']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                                  onPressed: () => _showDialog(item: item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  onPressed: () => _deleteItem(item['ID']),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
  // دالة اختيار الأيقونة حسب اسم المجموعة
  IconData _getGroupIcon(String groupName) {
    // توحيد النص للمقارنة السهلة
    final name = groupName.toLowerCase(); 

    // 1. المعدات والمشتريات
    if (name.contains("equipment") || name.contains("مشتريات")) return Icons.shopping_cart_rounded;
    
    // 2. التدريب والكورسات
    if (name.contains("traning") || name.contains("كورس") || name.contains("تعليم")) return Icons.school_rounded;
    
    // 3. الرواتب والأجور والتأمينات
    if (name.contains("أجور") || name.contains("مرتبات") || name.contains("تامينات")) return Icons.groups_rounded;
    
    // 4. الباص والنقل
    if (name.contains("باص")) return Icons.directions_bus_rounded;
    
    // 5. الأنشطة والرحلات والحفلات
    if (name.contains("حفلات") || name.contains("رحلات") || name.contains("انشطة")) return Icons.celebration_rounded;
    
    // 6. الإيجار والأماكن
    if (name.contains("الايجار") || name.contains("ايجار")) return Icons.home_work_rounded;
    
    // 7. الضرائب والديون (أمور قانونية/مالية بحتة)
    if (name.contains("الضرائب") || name.contains("ديون")) return Icons.gavel_rounded;
    
    // 8. الاسترداد والتوزيعات (أسهم/أموال)
    if (name.contains("استرداد") || name.contains("توزيعات")) return Icons.currency_exchange_rounded;
    
    // 9. الفواتير والتشغيل
    if (name.contains("فواتير") || name.contains("تشغيل") || name.contains("عمومية")) return Icons.receipt_long_rounded;
    
    // 10. الأرصدة والمبيعات (خزنة)
    if (name.contains("رصيد") || name.contains("مبيعات")) return Icons.account_balance_wallet_rounded;
    
    // 11. الاشتراكات (فلوس داخلة)
    if (name.contains("اشتراك")) return Icons.card_membership_rounded;

    // الافتراضي (لو مفيش تطابق)
    return Icons.folder_open_rounded;
  }
}