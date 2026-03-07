import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ✨ Shimmer Loading for CRM KPI Dashboard
// ═══════════════════════════════════════════════════════════════════════════

class CRMKPIShimmerLoading extends StatefulWidget {
  final bool isDark;

  const CRMKPIShimmerLoading({super.key, required this.isDark});

  @override
  State<CRMKPIShimmerLoading> createState() => _CRMKPIShimmerLoadingState();
}

class _CRMKPIShimmerLoadingState extends State<CRMKPIShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Filter Bar Shimmer
              _buildShimmerBox(height: 56, borderRadius: 16),
              const SizedBox(height: 20),

              // KPI Cards Shimmer
              Row(
                children: [
                  Expanded(child: _buildShimmerBox(height: 140, borderRadius: 24)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildShimmerBox(height: 140, borderRadius: 24)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildShimmerBox(height: 140, borderRadius: 24)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildShimmerBox(height: 140, borderRadius: 24)),
                ],
              ),
              const SizedBox(height: 24),

              // Chart Shimmer
              _buildShimmerBox(height: 300, borderRadius: 32),
              const SizedBox(height: 24),

              // Donut Chart Shimmer
              _buildShimmerBox(height: 240, borderRadius: 32),
              const SizedBox(height: 24),

              // Leaderboard Shimmer
              _buildShimmerBox(height: 350, borderRadius: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({
    required double height,
    double? width,
    double borderRadius = 16,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(_animation.value, 0),
          end: Alignment(_animation.value + 1, 0),
          colors: widget.isDark
              ? [
                  const Color(0xFF1E293B),
                  const Color(0xFF334155),
                  const Color(0xFF1E293B),
                ]
              : [
                  const Color(0xFFE2E8F0),
                  const Color(0xFFF8FAFC),
                  const Color(0xFFE2E8F0),
                ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🔲 Single Shimmer Box (for reuse)
// ═══════════════════════════════════════════════════════════════════════════

class ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;
  final bool isDark;

  const ShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 12,
    required this.isDark,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: widget.isDark
                  ? [
                      const Color(0xFF1E293B),
                      const Color(0xFF334155),
                      const Color(0xFF1E293B),
                    ]
                  : [
                      const Color(0xFFE2E8F0),
                      const Color(0xFFF8FAFC),
                      const Color(0xFFE2E8F0),
                    ],
            ),
          ),
        );
      },
    );
  }
}