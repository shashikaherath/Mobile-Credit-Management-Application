// ------------------------------------------------------------------------------
// File: help_support_screen.dart
// Purpose: Multi-Channel Help Desk for shop owners.
// Rationale: Provides a three-tier support structure:
//   1. Self-Service (Interactive FAQ)
//   2. Direct Communication (Hyper-linked Contact Cards)
//   3. Proactive Feedback (Structured issue reporting)
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:url_launcher/url_launcher.dart'; // Deep Linking: Multi-app communication logic
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:provider/provider.dart'; // State: Dependency injection system
import 'package:frontend/features/account/presentation/providers/feedback_provider.dart'; // State: Support ticket manager
import 'package:frontend/core/utils/snackbar_utils.dart'; // Feedback: Status notification component
import 'package:frontend/shared/widgets/app_back_button.dart'; // Standardized navigation trigger


class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  // --- Form State: Support Ticket Encapsulation ---
  final TextEditingController _feedbackController = TextEditingController(); // Input: Message body
  String _selectedCategory = 'Feedback'; // State: Ticket classification
  final List<String> _categories = ['Feedback', 'Error', 'Improvement']; // Enum: Support taxonomy

  /*
   * Logic: External Communication Launchers.
   * Rationale: Redirects the user to specialized communication apps (Email/WhatsApp)
   * to ensure high-fidelity support interactions.
   */
  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'shopbook.grocery.lk@gmail.com',
      query: _encodeQueryParameters(<String, String>{
        'subject': 'ShopBook Support Request',
      }),
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (mounted) {
        SnackBarUtils.showSnackBar(context, 'Could not launch email app', isError: true);
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    final Uri whatsappUri = Uri.parse('https://wa.me/94701234567'); 

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        SnackBarUtils.showSnackBar(context, 'Could not launch WhatsApp', isError: true);
      }
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  void dispose() {
    _feedbackController.dispose(); // Cleanup: Preventing controller memory leak
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Help & Support'),
        leading: AppBackButton(
          onTap: () => Navigator.pop(context),
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Section 1: Visual Welcome Header ---
              // Rationale: Sets a professional and helpful tone for the interaction.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    // Icon logic: Secondary accent focus for the support persona.
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'How can we help you?',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Search for topics or contact our support team',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- Section 2: Direct Escalation Channels ---
              // Rationale: Low-friction links to live human support.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Us',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Logic: WhatsApp link for instant messaging support.
                        Expanded(
                          child: _buildContactCard(
                            icon: Icons.chat_outlined,
                            title: 'WhatsApp',
                            color: const Color(0xFF25D366),
                            onTap: _launchWhatsApp,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Logic: Email channel for formal/detailed queries.
                        Expanded(
                          child: _buildContactCard(
                            icon: Icons.email_outlined,
                            title: 'Email',
                            color: const Color(0xFFEA4335),
                            onTap: _launchEmail,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- Section 3: Semantic Knowledge Base (FAQ) ---
              // Rationale: Deflects common support queries through context-rich snippets.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frequent Questions',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // logic: Expansion tiles for space-efficient information delivery.
                    _buildFAQItem(
                      'How to add a new product?',
                      'Go to the Products tab and click on the "+" button in the top right corner.',
                    ),
                    _buildFAQItem(
                      'Can I manage multiple shops?',
                      'Currently, ShopBook supports one shop per account for focused management.',
                    ),
                    _buildFAQItem(
                      'How do credit limits work?',
                      'You can set a credit limit for each customer. The system will alert you if they exceed it.',
                    ),
                    _buildFAQItem(
                      'Is my data backed up?',
                      'Yes, all your data is automatically synced to our secure cloud database.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- Section 4: Proactive Issue Submission ---
              // Rationale: Captures structured reports directly into the admin triage system.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share your thoughts',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Have an idea or found a bug? Let us know!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textDark.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Selector: Classifies the intent (Bug vs Feature vs General).
                          Text(
                            'Category',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: _categories.map((category) {
                              final isSelected = _selectedCategory == category;
                              return ChoiceChip(
                                label: Text(category),
                                selected: isSelected,
                                // logic: Reactive category binding.
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedCategory = category);
                                  }
                                },
                                selectedColor: AppColors.primary.withValues(alpha: 0.1),
                                labelStyle: GoogleFonts.poppins(
                                  color: isSelected ? AppColors.primary : AppColors.textMedium,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected ? AppColors.primary : Colors.grey[200]!,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          // Message Body: The core descriptive content of the ticket.
                          Text(
                            'Message',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _feedbackController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Describe your feedback or improvement idea...',
                              hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: Consumer<FeedbackProvider>(
                              builder: (context, feedbackProvider, _) {
                                return ElevatedButton(
                                  // logic: Preventing concurrent submissions during network IO.
                                  onPressed: feedbackProvider.isLoading
                                      ? null
                                      : () async {
                                          if (_feedbackController.text.trim().isEmpty) {
                                            SnackBarUtils.showSnackBar(
                                              context,
                                              'Please enter a message',
                                              isError: true,
                                            );
                                            return;
                                          }
                                          
                                          // logic: Network operation via FeedbackProvider state manager.
                                          final success = await feedbackProvider.submitFeedback(
                                            _selectedCategory,
                                            _feedbackController.text.trim(),
                                          );

                                          if (success && context.mounted) {
                                            // Step: Successful submission workflow.
                                            _feedbackController.clear();
                                            SnackBarUtils.showSnackBar(
                                              context,
                                              'Thank you for your feedback!',
                                            );
                                            FocusScope.of(context).unfocus();
                                          } else if (context.mounted) {
                                            // Step: Failure workflow with error propagation.
                                            SnackBarUtils.showSnackBar(
                                              context,
                                              feedbackProvider.error ?? 'Failed to submit',
                                              isError: true,
                                            );
                                          }
                                        },

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: feedbackProvider.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Submit Feedback',
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                                        ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

            ],
          ),
        ),
      ),
    );
  }

  /*
   * UI Component Builder: Themed Contact escalation widget.
   */
  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*
   * UI Component Builder: FAQ Question + Answer aggregate.
   */
  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          question,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.topLeft,
        children: [
          Text(
            answer,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textMedium,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

