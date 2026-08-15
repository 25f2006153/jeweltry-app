import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class CreditTopupSheet extends StatefulWidget {
  final VoidCallback? onPaymentSuccess;

  const CreditTopupSheet({super.key, this.onPaymentSuccess});

  static void show(BuildContext context, {VoidCallback? onPaymentSuccess}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreditTopupSheet(onPaymentSuccess: onPaymentSuccess),
    );
  }

  @override
  State<CreditTopupSheet> createState() => _CreditTopupSheetState();
}

class _CreditTopupSheetState extends State<CreditTopupSheet> {
  String _selectedPlanId = 'credits_12';
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'credits_5',
      'title': '5 Try-On Credits',
      'credits': 5,
      'price_inr': 49,
      'badge': null,
      'is_popular': false,
    },
    {
      'id': 'credits_12',
      'title': '12 Try-On Credits',
      'credits': 12,
      'price_inr': 99,
      'badge': 'MOST POPULAR',
      'is_popular': true,
    },
    {
      'id': 'credits_28',
      'title': '28 Try-On Credits',
      'credits': 28,
      'price_inr': 199,
      'badge': 'BEST VALUE',
      'is_popular': false,
    },
    {
      'id': 'credits_60',
      'title': '60 Try-On Credits',
      'credits': 60,
      'price_inr': 399,
      'badge': 'PRO PACK',
      'is_popular': false,
    },
  ];

  Future<void> _handlePayment() async {
    setState(() => _isProcessing = true);

    // Simulate online UPI / Payment gateway checkout
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    setState(() => _isProcessing = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.burgundy,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.gold, size: 20),
            const SizedBox(width: 10),
            Text(
              'Payment successful! Credits added to your account.',
              style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );

    widget.onPaymentSuccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get More Credits',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Instant AI Virtual Jewelry Try-On',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.burgundySurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.goldLight),
                ),
                child: const Icon(Icons.diamond_outlined, color: AppColors.gold, size: 22),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Plan options list
          ..._plans.map((plan) {
            final isSelected = _selectedPlanId == plan['id'];
            final isPopular = plan['is_popular'] == true;

            return GestureDetector(
              onTap: () => setState(() => _selectedPlanId = plan['id'] as String),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.burgundySurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.burgundy : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected ? AppColors.burgundy.withValues(alpha: 0.1) : AppColors.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Radio indicator
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.burgundy : AppColors.textMuted,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.burgundy,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),

                    // Title & credits
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                plan['title'] as String,
                                style: GoogleFonts.lato(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              if (plan['badge'] != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isPopular ? AppColors.burgundy : AppColors.goldDark,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    plan['badge'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${plan['credits']} full AI try-on generations',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price in INR
                    Text(
                      '₹${plan['price_inr']}',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.burgundy : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Payment CTA Button
          GestureDetector(
            onTap: _isProcessing ? null : _handlePayment,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.burgundyGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.burgundy.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _isProcessing
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt, color: AppColors.gold, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Pay with UPI / Cards',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // Security note
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                '100% Secure Payment • Instant Delivery',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
