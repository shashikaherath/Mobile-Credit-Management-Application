// ------------------------------------------------------------------------------
// File: payment_success_screen.dart
// Purpose: Post-transaction Confirmation and Revenue Feedback.
// Rationale: Delivers a high-fidelity visual celebration (confetti, gradients) 
//   to reinforce successful revenue capture. Orchestrates immediate post-sale 
//   actions including PDF receipt generation, native sharing, and smooth 
//   navigational return to the core dashboard.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:provider/provider.dart'; // State: Access global AuthProvider
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // State: Access global AuthProvider
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:frontend/features/sales/presentation/utils/invoice_pdf_utils.dart'; // Export: PDF generator
import 'package:frontend/shared/main_shell.dart'; // Navigation: Dashboard return point
import 'package:animate_do/animate_do.dart'; // Animation: Declarative transitions
import 'dart:ui'; // Platform: BackdropFilter for glassmorphism

class PaymentSuccessScreen extends StatefulWidget {
  final Map<String, dynamic> saleDetails;

  const PaymentSuccessScreen({super.key, required this.saleDetails});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {

  @override
  Widget build(BuildContext context) {
    final saleDetails = widget.saleDetails;
    final totalAmount = (saleDetails['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final invoiceId = (saleDetails['id'] ?? saleDetails['_id'])?.toString() ?? 'N/A';
    final paymentMethod = saleDetails['paymentMethod']?.toString() ?? 'cash';
    final itemsCount = (saleDetails['items'] as List?)?.length ?? 0;

    return Scaffold(
      backgroundColor: Colors.black, // Stark base to make the mesh gradient pop
      body: Stack(
        children: [
          // 1. Dynamic Mesh Gradient Background: Immersive premium visual layer
          _buildMeshGradient(),

          // 2. Main Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const Spacer(flex: 2),

                            // 3. Animated Success Icon: Multiple layers of motion for "wow" factor
                            _buildAnimatedSuccessIcon(),

                            const SizedBox(height: 32),

                            // 4. Success Message Header
                            FadeInDown(
                              duration: const Duration(milliseconds: 600),
                              child: Column(
                                children: [
                                  Text(
                                    'Payment Successful', // Primary confirmation
                                    style: GoogleFonts.poppins(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildStatusBadge(), // Real-time state tag
                                ],
                              ),
                            ),

                            const Spacer(flex: 2),

                            // 5. Glassmorphic Receipt Card: Frosted glass effect for high-fidelity feel
                            _buildGlassReceiptCard(
                              totalAmount: totalAmount,
                              invoiceId: invoiceId,
                              paymentMethod: paymentMethod,
                              itemsCount: itemsCount,
                            ),

                            const Spacer(flex: 3),

                            // 6. Action Buttons: Guided navigation and record preservation
                            _buildActionButtons(context, saleDetails),
                            
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Generates organic glowing blobs behind a heavy blur filter
  Widget _buildMeshGradient() {
    return Stack(
      children: [
        Container(color: AppColors.primaryDark), // Base dark canvas
        Positioned(
          top: -100,
          right: -50,
          child: _buildBlob(300, AppColors.primary, 0.6), // Primary brand glow
        ),
        Positioned(
          bottom: 100,
          left: -100,
          child: _buildBlob(400, AppColors.accentGreen, 0.4), // Accent green highlight
        ),
        Positioned(
          top: 200,
          left: 50,
          child: _buildBlob(250, Colors.white, 0.1), // Subtle light diffusion
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), // Converts blobs into smooth mesh
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
                // Vignette effect to focus center content
              gradient: RadialGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.2),
                ],
                center: Alignment.center,
                radius: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlob(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  // Multi-layer pulse and elastic icons for feedback
  Widget _buildAnimatedSuccessIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Pulse(
          infinite: true,
          duration: const Duration(seconds: 4),
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
          ),
        ),
        ElasticIn(
          duration: const Duration(milliseconds: 1200),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 56,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // Small capsule tag for transaction integrity
  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.accentGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGreen,
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'COMPLETED', // Immutable final state
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // Core receipt data module with local frosted glass effect
  Widget _buildGlassReceiptCard({
    required double totalAmount,
    required String invoiceId,
    required String paymentMethod,
    required int itemsCount,
  }) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      delay: const Duration(milliseconds: 300),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Column(
              children: [
                  Text(
                    'Total Amount', // Summary label
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${totalAmount.toStringAsFixed(2)}', // Final settlement value
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                ),
                // Sequential staggered entry for record details
                _buildGlassDetailRow('Invoice', '#${invoiceId.toUpperCase()}', delay: 600),
                const SizedBox(height: 18),
                _buildGlassDetailRow('Method', paymentMethod.toUpperCase(), delay: 750),
                const SizedBox(height: 18),
                _buildGlassDetailRow('Items', '$itemsCount Items', delay: 900),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassDetailRow(String label, String value, {required int delay}) {
    return FadeInLeft(
      duration: const Duration(milliseconds: 500),
      delay: Duration(milliseconds: delay),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Primary calls-to-action for post-transaction flow
  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> saleDetails) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      delay: const Duration(milliseconds: 1000),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: () {
                // Return to main application hub
                MainShell.switchToTab(context, 0);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: Text(
                'Back to Dashboard',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // PDF Record generation trigger
              Expanded(
                child: _buildGhostButton(
                  icon: Icons.download_rounded,
                  label: 'Receipt',
                  onTap: () {
                    final owner = context.read<AuthProvider>().currentOwner;
                    InvoicePdfUtils.generateAndDownloadInvoice(
                      saleDetails: saleDetails,
                      owner: owner,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // External sharing trigger (WhatsApp, Email, etc.)
              Expanded(
                child: _buildGhostButton(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  onTap: () {
                    final owner = context.read<AuthProvider>().currentOwner;
                    InvoicePdfUtils.shareInvoice(
                      saleDetails: saleDetails,
                      owner: owner,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Translucent border-only button for secondary actions
  Widget _buildGhostButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

