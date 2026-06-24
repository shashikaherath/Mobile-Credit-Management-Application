// ------------------------------------------------------------------------------
// File: manage_feedback_screen.dart
// Purpose: Communication and quality control interface for User Feedback.
// Rationale: Centralizes feedback items across categories (Error, Improvement,
//   General). Implements hierarchical grouping by date and supports status-based
//   filtering to prioritize system fixes and owner concerns.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // UI: Material framework
import 'package:provider/provider.dart'; // State: State management consumption
import 'package:google_fonts/google_fonts.dart'; // Styling: Typography tokens
import 'package:frontend/features/account/presentation/providers/feedback_provider.dart'; // State: Feedback data stream
import 'package:frontend/features/account/domain/entities/feedback.dart'; // Domain: Feedback entity model
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system colors
import 'package:frontend/shared/widgets/shimmer_loading.dart'; // UI: Loading skeletons
import 'package:frontend/shared/widgets/tactile_scale.dart'; // UI: Physics-based touch feedback
import 'package:intl/intl.dart'; // Utils: Date/Time formatting
import 'package:animate_do/animate_do.dart'; // UI: Transition effects

class ManageFeedbackScreen extends StatefulWidget {
  const ManageFeedbackScreen({super.key});

  @override
  State<ManageFeedbackScreen> createState() => _ManageFeedbackScreenState();
}

class _ManageFeedbackScreenState extends State<ManageFeedbackScreen> {
  String _selectedFilter =
      'All'; // Active Filter: (All, Feedback, Error, Improvement, Guest Support)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedbackProvider>().fetchAllFeedback();
    });
  }

  String _getDateCategory(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final feedbackDate = DateTime(date.year, date.month, date.day);

    if (feedbackDate == today) return 'Today';
    if (feedbackDate == yesterday) return 'Yesterday';
    return DateFormat('MMMM d, y').format(date);
  }

  Map<String, List<UserFeedback>> _groupFeedback(List<UserFeedback> feedbacks) {
    // Hierarchical grouping: Organizes feedback by date categories (Today, Yesterday, etc.) for UI readability.
    final Map<String, List<UserFeedback>> grouped = {};
    for (var feedback in feedbacks) {
      final category = _getDateCategory(feedback.createdAt);
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(feedback);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final feedbackProvider = context.watch<FeedbackProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('User Feedback'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterBar(feedbackProvider),
            Expanded(
              child:
                  feedbackProvider.isLoading &&
                      feedbackProvider.feedbacks.isEmpty
                  ? _buildFeedbackShimmer()
                  : feedbackProvider.feedbacks.isEmpty
                  ? _buildEmptyState()
                  : _buildFeedbackList(feedbackProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({bool isFilter = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFilter ? Icons.search_off_outlined : Icons.feedback_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            isFilter
                ? 'No ${_selectedFilter.toLowerCase()} feedback yet'
                : 'No feedback received yet',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(FeedbackProvider provider) {
    // Strategy: Fixed taxonomy for simplified admin triage.
    final filters = ['All', 'Feedback', 'Error', 'Improvement', 'Guest Support'];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TactileScale(
              onTap: () {
                setState(() => _selectedFilter = filter);
              },
              child: ChoiceChip(
                label: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textMedium,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() => _selectedFilter = filter);
                },
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.grey[200]!,
                  ),
                ),
                showCheckmark: false,
                elevation: 0,
                pressElevation: 0,
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildFeedbackList(FeedbackProvider provider) {
    // Strategy: Multi-dimensional filtering across categories and user types.
    var filteredFeedbacks = provider.feedbacks;

    final publicCategories = ['Account Recovery', 'Password Reset Issue', 'Login Trouble', 'Other'];

    // Strategy: Mutually exclusive filtering between internal categories and public support channel.
    if (_selectedFilter == 'Guest Support') {
      filteredFeedbacks = filteredFeedbacks
          .where((f) => f.ownerName == 'External User' || publicCategories.contains(f.category))
          .toList();
    } else if (_selectedFilter != 'All') {
      filteredFeedbacks = filteredFeedbacks
          .where(
            (f) =>
                f.category.toLowerCase() == _selectedFilter.toLowerCase() &&
                f.ownerName != 'External User' &&
                !publicCategories.contains(f.category),
          )
          .toList();
    }

    if (filteredFeedbacks.isEmpty) {
      return _buildEmptyState(isFilter: true);
    }

    final grouped = _groupFeedback(filteredFeedbacks);
    final sortedKeys = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: () => provider.fetchAllFeedback(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final dateKey = sortedKeys[index];
          final feedbacks = grouped[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                child: Text(
                  dateKey,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...feedbacks.indexed.map(
                (entry) => FadeInUp(
                  duration: const Duration(milliseconds: 400),
                  delay: Duration(milliseconds: entry.$1 * 100),
                  child: _buildFeedbackCard(entry.$2, provider),
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeedbackShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerLoading(
          isLoading: true,
          child: ShimmerSkeleton(height: 120, borderRadius: 16),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(UserFeedback feedback, FeedbackProvider provider) {
    Color categoryColor;
    IconData categoryIcon;

    // Category-based UI mapping: Dynamically choosing icons and colors based on feedback severity.
    switch (feedback.category.toLowerCase()) {
      case 'error':
        categoryColor = Colors.red;
        categoryIcon = Icons.error_outline;
        break;
      case 'improvement':
        categoryColor = Colors.blue;
        categoryIcon = Icons.lightbulb_outline;
        break;
      default:
        categoryColor = Colors.green;
        categoryIcon = Icons.chat_bubble_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  // Data sanitization: Masking external user IDs with a readable label.
                  (feedback.ownerName == 'External User' || (feedback.ownerName == 'Unknown User' && ['Account Recovery', 'Password Reset Issue', 'Login Trouble', 'Other'].contains(feedback.category)))
                      ? 'Unregistered Owner'
                      : feedback.ownerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (feedback.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      ElasticIn(
                        child: const Icon(
                          Icons.verified,
                          color: Colors.green,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: GoogleFonts.poppins(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /**
               * Data Attribution: Channel Labeling.
               * Visual cues to distinguish between 'Internal Reports' (authenticated)
               * and 'Public Channels' (recovery stream).
               */
              Row(
                children: [
                  Text(
                    feedback.category,
                    style: TextStyle(
                      color: categoryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    (feedback.ownerName == 'External User' || ['Account Recovery', 'Password Reset Issue', 'Login Trouble', 'Other'].contains(feedback.category))
                        ? 'Public Channel'
                        : 'Internal Report',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
              if (feedback.claimedShopName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Claimed Shop: ${feedback.claimedShopName}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              if (feedback.contactInfo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Contact: ${feedback.contactInfo}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          trailing: Text(
            DateFormat('h:mm a').format(feedback.createdAt),
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                feedback.message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMedium,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _confirmDelete(feedback, provider),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(UserFeedback feedback, FeedbackProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feedback?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteFeedback(feedback.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
