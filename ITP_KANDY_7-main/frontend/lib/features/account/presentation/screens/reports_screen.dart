// ------------------------------------------------------------------------------
// File: reports_screen.dart
// Purpose: Business Analytics Dashboard for aggregated store metrics.
// Rationale: Visualizes financial and inventory health using interactive 
//   time-series charts. Provides shop owners with actionable intelligence 
//   (30-day trends, leaderboards) and supports PDF export for record-keeping.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:frontend/core/network/api_client.dart'; // Infrastructure: Network engine
import 'package:intl/intl.dart'; // Formatting: Currency and date localization
import 'package:frontend/features/account/presentation/utils/report_pdf_utils.dart'; // Export: PDF generation utility
import 'package:fl_chart/fl_chart.dart'; // Charting: Interactive line/bar graphs
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:provider/provider.dart'; // State: Identity source of truth
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // State: Identity source of truth
import 'package:frontend/shared/widgets/modern_pdf_icon.dart'; // Shared UI: PDF action icon
import 'package:frontend/shared/widgets/screen_header.dart'; // Shared UI: Reusable header bar

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _reportData;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fetchReportData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchReportData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Data acquisition: Fetching aggregated business metrics from the dedicated reports endpoint.
      final response = await ApiClient.get('/reports');
      setState(() {
        _reportData = response['data'];
        _isLoading = false;
        _animationController.forward(from: 0.0);
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          // Error parsing: Stripping technical prefixes for a user-friendly diagnostic message.
          _error = e.toString().contains('Exception:')
              ? e.toString().substring(e.toString().indexOf('Exception:') + 10).trim()
              : 'Error connecting to server';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'Rs. ',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _error != null
                ? _buildErrorState()
                : _reportData == null
                    ? Center(child: Text('No data available'))
                    : RefreshIndicator(
                        onRefresh: _fetchReportData,
                        color: AppColors.primary,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: ScreenHeader(
                                title: 'Business Analytics',
                                subtitle: 'Financial & inventory insights',
                                showBackButton: true,
                                action: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const ModernPdfIcon(),
                                      onPressed: () {
                                        final auth = Provider.of<AuthProvider>(context, listen: false);
                                        ReportPdfUtils.generateAndDownloadReport(
                                          reportData: _reportData!,
                                          owner: auth.currentOwner,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                child: _buildSalesTrendSection(),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                                child: _buildSectionTitle('Financial Highlights'),
                              ),
                            ),
                            _buildFinancialGrid(currencyFormat),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                                child: _buildSectionTitle('Inventory Pulse'),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: _buildInventoryPulse(currencyFormat),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                                child: _buildSectionTitle('Performance Leaderboard'),
                              ),
                            ),
                             _buildTopProductsList(currencyFormat),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                                child: _buildSectionTitle('Top Suppliers (Last 30 Days)'),
                              ),
                            ),
                            _buildTopSuppliersList(currencyFormat),
                            const SliverToBoxAdapter(child: SizedBox(height: 40)),
                          ],
                        ),
                      ),
      ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1C1E),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildSalesTrendSection() {
    final List trend = _reportData!['trend'] ?? [];
    if (trend.isEmpty) return const SizedBox.shrink();

    // Statistical aggregation: Computing 30-day totals and identifying high-water marks for business performance.
    double totalRevenue = 0;
    double peakSale = 0;
    for (var day in trend) {
      double rev = (day['revenue'] as num).toDouble();
      totalRevenue += rev;
      if (rev > peakSale) peakSale = rev; // Peak detection: Finding the most profitable day in the trend.
    }
    double avgSale = trend.isNotEmpty ? totalRevenue / trend.length : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('30-Day Sales Trend'),
            Text(
              'Last update: ${DateFormat('hh:mm a').format(DateTime.now())}',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTrendSummaryItem('TOTAL REV', 'Rs. ${totalRevenue.toStringAsFixed(0)}'),
                  _buildTrendSummaryItem('AVG DAY', 'Rs. ${avgSale.toStringAsFixed(0)}'),
                  _buildTrendSummaryItem('PEAK SALE', 'Rs. ${peakSale.toStringAsFixed(0)}'),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppColors.divider.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() % 7 == 0 && value.toInt() < trend.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('MM/dd').format(DateTime.parse(trend[value.toInt()]['date'])),
                                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          getTitlesWidget: (value, meta) {
                            if (value == meta.min || value == meta.max) {
                              return const SizedBox.shrink();
                            }
                            String text;
                            if (value >= 1000) {
                              text = '${(value / 1000).toStringAsFixed(1)}k';
                            } else {
                              text = value.toStringAsFixed(0);
                            }
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                text,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppColors.textLight,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: trend.asMap().entries.map((e) {
                          // Coordinate mapping: Converting raw trend data into X/Y coordinates for the LineChart.
                          return FlSpot(e.key.toDouble(), (e.value['revenue'] as num).toDouble());
                        }).toList(),
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: AppColors.primary,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.15),
                              AppColors.primary.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (spot) => AppColors.textDark,
                        tooltipRoundedRadius: 8,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              'Rs. ${spot.y.toStringAsFixed(0)}',
                              GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.textLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialGrid(NumberFormat format) {
    final summary = _reportData!['summary'];
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          mainAxisExtent: 145,
        ),
        delegate: SliverChildListDelegate([
          _buildModernStatCard(
            'Total Revenue',
            format.format(summary['totalRevenue'] ?? 0),
            Icons.bar_chart_rounded,
            const Color(0xFF0EA5E9),
            const Color(0xFFE0F2FE),
          ),
          _buildModernStatCard(
            'Estimated Profit',
            format.format(summary['totalProfit'] ?? 0),
            Icons.trending_up_rounded,
            const Color(0xFF10B981),
            const Color(0xFFD1FAE5),
          ),
          _buildModernStatCard(
            'Today\'s Sales',
            format.format(summary['todaysSales'] ?? 0),
            Icons.payments_outlined,
            AppColors.primary,
            const Color(0xFFD1FAE5),
          ),
          _buildModernStatCard(
            'Avg Order',
            format.format(summary['averageOrderValue'] ?? 0),
            Icons.receipt_long_outlined,
            const Color(0xFF8B5CF6),
            const Color(0xFFEDE9FE),
          ),
          _buildModernStatCard(
            'Customer Credit',
            format.format(summary['totalCreditOutstanding'] ?? 0),
            Icons.account_balance_wallet_outlined,
            const Color(0xFFF59E0B),
            const Color(0xFFFEF3C7),
          ),
          _buildModernStatCard(
            'To Suppliers',
            format.format(summary['totalPayable'] ?? 0),
            Icons.local_shipping_outlined,
            const Color(0xFF3B82F6),
            const Color(0xFFDBEAFE),
          ),
        ]),
      ),
    );
  }

  Widget _buildModernStatCard(String label, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMedium.withValues(alpha: 0.8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryPulse(NumberFormat format) {
    final inventory = _reportData!['inventory'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  'Asset Value',
                  format.format(inventory['totalValue']),
                  Icons.account_balance_rounded,
                  const Color(0xFF64748B),
                  const Color(0xFFF1F5F9),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModernStatCard(
                  'In Stock',
                  '${inventory['itemCount']} units',
                  Icons.inventory_2_outlined,
                  const Color(0xFF64748B),
                  const Color(0xFFF1F5F9),
                ),
              ),
            ],
          ),
          if (inventory['lowStockCount'] > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEA580C)),
                  const SizedBox(width: 8),
                  Text(
                    '${inventory['lowStockCount']} items are below safety limit',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopProductsList(NumberFormat format) {
    final products = (_reportData!['topProducts'] as List);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = products[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'],
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          '${product['quantity']} ${product['unit'] ?? 'units'} moved',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        format.format(product['revenue']),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: index == 0 ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          index == 0 ? 'TOP' : 'STABLE',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: index == 0 ? AppColors.primary : AppColors.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          childCount: products.length,
        ),
      ),
    );
  }

  Widget _buildTopSuppliersList(NumberFormat format) {
    final suppliers = (_reportData!['topSuppliers'] as List? ?? []);
    if (suppliers.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Center(
            child: Text(
              'No procurement data for this period',
              style: GoogleFonts.inter(color: AppColors.textLight, fontSize: 14),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final supplier = suppliers[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(Icons.local_shipping_outlined, size: 20, color: const Color(0xFF3B82F6)),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier['name'],
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          '${supplier['purchaseCount']} orders processed',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        format.format(supplier['spending']),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: index == 0 ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          index == 0 ? 'PARTNER' : 'RELIABLE',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: index == 0 ? const Color(0xFF3B82F6) : AppColors.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          childCount: suppliers.length,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 80, color: AppColors.textLight),
            SizedBox(height: 24),
            Text(
              'Insight Engine Offline',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textLight),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _fetchReportData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Relaunch Engine', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

