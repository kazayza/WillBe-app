import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/finance_theme.dart';
import '../../models/finance_session_details_model.dart';

class FinanceRecordTile extends StatefulWidget {
  final FinanceRecordModel record;
  final VoidCallback? onTap;
  const FinanceRecordTile({super.key, required this.record, this.onTap});

  @override
  State<FinanceRecordTile> createState() => _FinanceRecordTileState();
}

class _FinanceRecordTileState extends State<FinanceRecordTile> {
  bool _isPressed = false;
  String _formatNumber(double value) => NumberFormat('#,##0.##', 'ar').format(value);
  String _formatDate(DateTime? date) => date == null ? '—' : DateFormat('yyyy/MM/dd', 'ar').format(date);
  bool get _isBus => widget.record.subscriptionKind.contains('الباص');
  Color get _kindColor => _isBus ? FinanceTheme.accent : FinanceTheme.success;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_isPressed ? 0.985 : 1.0),
        decoration: BoxDecoration(
          color: FinanceTheme.card(context),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isPressed ? 0.01 : 0.05),
              blurRadius: _isPressed ? 2 : 12,
              offset: Offset(0, _isPressed ? 0.5 : 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // الشريط الجانبي الملون
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: _kindColor,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(18)),
                ),
              ),
              
              // المحتوى
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.record.childName,
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: FinanceTheme.text(context), letterSpacing: -0.2),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: FinanceTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                            child: Text(_formatNumber(widget.record.amountSub), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: FinanceTheme.primary, letterSpacing: -0.3)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildMiniDetail(Icons.store_rounded, widget.record.branchName, FinanceTheme.info),
                          const SizedBox(width: 14),
                          _buildMiniDetail(_isBus ? Icons.directions_bus_rounded : Icons.school_rounded, widget.record.subscriptionKind, _kindColor),
                          const Spacer(),
                          _buildMiniDetail(Icons.calendar_today_rounded, _formatDate(widget.record.subDate), FinanceTheme.textSec(context)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniDetail(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}