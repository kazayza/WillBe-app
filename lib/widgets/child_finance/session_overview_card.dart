import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/finance_theme.dart';
import '../../models/child_finance_browser_model.dart';

class SessionOverviewCard extends StatefulWidget {
  final SessionOverviewModel session;
  final VoidCallback onTap;
  const SessionOverviewCard({super.key, required this.session, required this.onTap});

  @override
  State<SessionOverviewCard> createState() => _SessionOverviewCardState();
}

class _SessionOverviewCardState extends State<SessionOverviewCard> {
  bool _isPressed = false;
  String _formatNumber(double value) => NumberFormat('#,##0.##', 'ar').format(value);
  String _formatDate(DateTime? date) => date == null ? '—' : DateFormat('yyyy/MM/dd', 'ar').format(date);
  double get _studyPercent => widget.session.studyTotal + widget.session.busTotal > 0 ? (widget.session.studyTotal / (widget.session.studyTotal + widget.session.busTotal)) : 0;

  @override
  Widget build(BuildContext context) {
    final total = widget.session.studyTotal + widget.session.busTotal;
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        decoration: BoxDecoration(
          color: FinanceTheme.card(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: FinanceTheme.borderCtx(context).withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isPressed ? 0.02 : 0.08),
              blurRadius: _isPressed ? 4 : 20,
              offset: Offset(0, _isPressed ? 1 : 6),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(children: [
          // الهيدر المتدرج
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 18),
            decoration: const BoxDecoration(
              gradient: FinanceTheme.cardHeaderGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.session.sessionName, style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w800, color: Colors.white, height: 1.35, letterSpacing: -0.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.child_care_rounded, size: 14, color: Colors.white), const SizedBox(width: 5), Text('${widget.session.uniqueChildrenCount} طفل', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600))]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatNumber(total), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('إجمالي المستحقات', style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          
          // المحتوى
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              children: [
                // شريط التوزيع المحسن
                _buildDistributionBar(),
                const SizedBox(height: 20),
                
                // شبكة الإحصائيات
                _buildStatsGrid(),
                const SizedBox(height: 16),
                
                Divider(height: 1, thickness: 0.5, color: FinanceTheme.divider),
                const SizedBox(height: 14),
                
                // التذييل
                _buildFooter(),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildDistributionBar() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 8, // زيادة السُمك عشان يبان أحلى
            child: Stack(
              children: [
                Container(decoration: BoxDecoration(color: FinanceTheme.divider, borderRadius: BorderRadius.circular(8))),
                FractionallySizedBox(
                  widthFactor: _studyPercent.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [FinanceTheme.info, Color(0xFF3498DB)]),
                      borderRadius: BorderRadius.horizontal(left: const Radius.circular(8), right: _studyPercent >= 1.0 ? const Radius.circular(8) : Radius.zero),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLegendDot(FinanceTheme.info, 'الدراسة'),
            _buildLegendDot(FinanceTheme.accent, 'الباص'),
            Text('${_formatNumber(widget.session.studyTotal)} / ${_formatNumber(widget.session.busTotal)}', style: TextStyle(fontSize: 11.5, color: FinanceTheme.textSec(context), fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text(label, style: TextStyle(fontSize: 11.5, color: FinanceTheme.textSec(context), fontWeight: FontWeight.w600)),
  ]);

  Widget _buildStatsGrid() {
    final stats = [
      _StatItem('نشط', widget.session.activeChildrenCount, Icons.check_circle_rounded, FinanceTheme.success),
      _StatItem('منسحب', widget.session.withdrawnChildrenCount, Icons.person_remove_rounded, FinanceTheme.error),
      _StatItem('دراسة', widget.session.studyCount, Icons.menu_book_rounded, FinanceTheme.info),
      _StatItem('باص', widget.session.busCount, Icons.directions_bus_rounded, FinanceTheme.accent),
    ];
    return Row(
      children: stats.map((s) {
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: s.color.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: s.color.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(s.icon, size: 16, color: s.color),
                ),
                const SizedBox(height: 8),
                Text('${s.value}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: FinanceTheme.text(context), letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text(s.label, style: TextStyle(fontSize: 10.5, color: FinanceTheme.textSec(context), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildDateChip('البداية', _formatDate(widget.session.firstSubDate), Icons.play_arrow_rounded),
              const SizedBox(width: 16),
              _buildDateChip('النهاية', _formatDate(widget.session.lastSubDate), Icons.stop_rounded),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: FinanceTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FinanceTheme.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('التفاصيل', style: TextStyle(color: FinanceTheme.primary, fontWeight: FontWeight.w800, fontSize: 12.5)),
              const SizedBox(width: 6),
              Icon(Icons.arrow_back_ios_new, size: 12, color: FinanceTheme.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateChip(String label, String date, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: FinanceTheme.textHint),
          const SizedBox(width: 5),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 9.5, color: FinanceTheme.textHint, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                Text(date, style: TextStyle(fontSize: 11.5, color: FinanceTheme.textSec(context), fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem { final String label; final int value; final IconData icon; final Color color; _StatItem(this.label, this.value, this.icon, this.color); }