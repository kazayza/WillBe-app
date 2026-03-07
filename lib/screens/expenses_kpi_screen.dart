import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expenses_kpi_provider.dart';
import '../widgets/Expense_KPI/kpi_theme.dart';
import '../widgets/Expense_KPI/period_filter_bar.dart';
import '../widgets/Expense_KPI/filter_chips_bar.dart';
import '../widgets/Expense_KPI/summary_cards.dart';
import '../widgets/Expense_KPI/forecast_card.dart';
import '../widgets/Expense_KPI/advanced_metrics_card.dart';
import '../widgets/Expense_KPI/top5_list.dart';
import '../widgets/Expense_KPI/top_increases_list.dart';
import '../widgets/Expense_KPI/top_savings_list.dart';
import '../widgets/Expense_KPI/groups_chart.dart';
import '../widgets/Expense_KPI/group_distribution_chart.dart';
import '../widgets/Expense_KPI/branches_chart.dart';
import '../widgets/Expense_KPI/daily_trend_chart.dart';
import '../widgets/Expense_KPI/weekday_chart.dart';
import '../widgets/Expense_KPI/seasonal_chart.dart';
import '../widgets/Expense_KPI/insights_card.dart';
import '../widgets/Expense_KPI/financial_analysis_card.dart';
import '../widgets/Expense_KPI/pdf_report_button.dart';

class ExpensesKPIScreen extends StatefulWidget {
  const ExpensesKPIScreen({super.key});

  @override
  State<ExpensesKPIScreen> createState() => _ExpensesKPIScreenState();
}

class _ExpensesKPIScreenState extends State<ExpensesKPIScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpensesKPIProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = KPITheme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: _buildAppBar(theme),
        body: Consumer<ExpensesKPIProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && !provider.hasData) {
              return _buildLoadingState(theme);
            }

            if (provider.hasError && !provider.hasData) {
              return _buildErrorState(provider, theme);
            }

            return _buildContent(provider, theme);
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(KPITheme theme) {
    return AppBar(
      title: const Text(
        'مؤشرات أداء المصروفات',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      backgroundColor: theme.appBarBackground,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        Consumer<ExpensesKPIProvider>(
          builder: (context, provider, _) {
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _showFiltersBottomSheet(context, theme),
                ),
                if (provider.hasActiveFilters)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${provider.activeFiltersCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState(KPITheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.info),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل مؤشرات الأداء...',
            style: TextStyle(fontSize: 16, color: theme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ExpensesKPIProvider provider, KPITheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.negative),
            const SizedBox(height: 16),
            Text(
              provider.error ?? 'حدث خطأ غير متوقع',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: theme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.loadAll(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.info,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ExpensesKPIProvider provider, KPITheme theme) {
    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      color: theme.info,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
                  if (provider.hasData)
                    PdfReportButton(data: provider.kpiData!),
              const PeriodFilterBar(),
              if (provider.hasActiveFilters) const FilterChipsBar(),
              if (provider.hasData) const SummaryCards(),
              if (provider.hasData && provider.kpiData!.insights.isNotEmpty)
                const InsightsCard(),
              if (provider.hasData) const ForecastCard(),
              if (provider.hasData) const AdvancedMetricsCard(),
              if (provider.hasData && provider.kpiData!.top5Expenses.isNotEmpty)
                const Top5List(),
              if (provider.hasData && provider.kpiData!.topIncreases.isNotEmpty)
                const TopIncreasesList(),
              if (provider.hasData && provider.kpiData!.topSavings.isNotEmpty)
                const TopSavingsList(),
              if (provider.hasData && provider.kpiData!.groupDistribution.isNotEmpty)
                const GroupDistributionChart(),
              if (provider.hasData && provider.kpiData!.groupsData.isNotEmpty)
                const GroupsChart(),
              if (provider.hasData && provider.kpiData!.branchesData.isNotEmpty)
                const BranchesChart(),
              if (provider.hasData && provider.kpiData!.charts.dailyTrend.current.isNotEmpty)
                const DailyTrendChart(),
              if (provider.hasData && provider.kpiData!.charts.weekdayAnalysis.isNotEmpty)
                const WeekdayChart(),
              if (provider.hasData && provider.kpiData!.charts.seasonalTrend.isNotEmpty)
                const SeasonalChart(),
              if (provider.hasData) const FinancialAnalysisCard(),
            ],
          ),
          if (provider.isLoading && provider.hasData)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: theme.info.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }

  void _showFiltersBottomSheet(BuildContext context, KPITheme theme) {
    final provider = context.read<ExpensesKPIProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الفلاتر',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                    if (provider.hasActiveFilters)
                      TextButton(
                        onPressed: () {
                          provider.clearAllFilters();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'مسح الكل',
                          style: TextStyle(color: theme.negative),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.divider),
              Expanded(
                child: Consumer<ExpensesKPIProvider>(
                  builder: (context, provider, _) {
                    if (provider.isFiltersLoading) {
                      return Center(
                        child: CircularProgressIndicator(color: theme.info),
                      );
                    }
                    if (!provider.hasFilters) {
                      return Center(
                        child: Text(
                          'لا توجد فلاتر متاحة',
                          style: TextStyle(color: theme.textSecondary),
                        ),
                      );
                    }

                    final filters = provider.filtersData!;

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildFilterSection(
                          title: '🏢 الفرع',
                          selectedValue: provider.selectedBranchName,
                          onClear: () => provider.clearBranch(),
                          theme: theme,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: filters.branches.map((branch) {
                              final isSelected = provider.selectedBranchId == branch.id;
                              return ChoiceChip(
                                label: Text(branch.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    provider.setBranch(branch.id, branch.name);
                                  } else {
                                    provider.clearBranch();
                                  }
                                  Navigator.pop(context);
                                },
                                selectedColor: theme.appBarBackground,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : theme.textPrimary,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildFilterSection(
                          title: '📂 المجموعة',
                          selectedValue: provider.selectedGroupName,
                          onClear: () => provider.clearGroup(),
                          theme: theme,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: filters.groups.map((group) {
                              final isSelected = provider.selectedGroupId == group.name;
                              return ChoiceChip(
                                label: Text(group.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    provider.setGroup(group.name, group.name);
                                  } else {
                                    provider.clearGroup();
                                  }
                                  Navigator.pop(context);
                                },
                                selectedColor: theme.info,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : theme.textPrimary,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildFilterSection(
                          title: '📋 نوع المصروف',
                          selectedValue: provider.selectedKindName,
                          onClear: () => provider.clearKind(),
                          theme: theme,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: provider.getKindsByGroup().map((kind) {
                              final isSelected = provider.selectedKindId == kind.id;
                              return ChoiceChip(
                                label: Text(kind.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    provider.setKind(kind.id, kind.name);
                                  } else {
                                    provider.clearKind();
                                  }
                                  Navigator.pop(context);
                                },
                                selectedColor: theme.positive,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : theme.textPrimary,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required String? selectedValue,
    required VoidCallback onClear,
    required KPITheme theme,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            if (selectedValue != null)
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.negativeLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedValue,
                        style: TextStyle(color: theme.negative, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.close, size: 14, color: theme.negative),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}