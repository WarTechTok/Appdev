// lib/screens/admin/sales_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Map<String, dynamic>> _sales = [];
  double _totalSales = 0;
  bool _loading = true;
  String _period = 'daily';

  @override
  void initState() {
    super.initState();
    _fetchSales();
  }

  Future<void> _fetchSales() async {
    setState(() => _loading = true);
    try {
      debugPrint('Fetching sales for period: $_period');
      final result = await ApiService.get('/api/admin/sales/${_period}', auth: true);
      debugPrint('Sales result type: ${result.runtimeType}');
      debugPrint('Sales result: $result');
      
      final sales = result is Map
          ? (result['sales'] as List? ?? result['data'] as List? ?? []).cast<Map<String, dynamic>>()
          : result is List
              ? result.cast<Map<String, dynamic>>()
              : <Map<String, dynamic>>[];
      
      double total = result is Map
          ? (result['total'] ?? result['totalSales'] ?? result['sum'] ?? 0).toDouble()
          : sales.fold(0.0, (sum, s) => sum + ((s['amount'] ?? s['total'] ?? 0) as num).toDouble());
      
      setState(() {
        _sales = sales;
        _totalSales = total;
        _loading = false;
        debugPrint('Loaded ${_sales.length} sales records, total: $_totalSales');
      });
    } catch (e, stack) {
      debugPrint('Error fetching sales: $e');
      debugPrint('Stack: $stack');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load sales: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final avgSale = _sales.isNotEmpty ? _totalSales / _sales.length : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sales Tracking', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchSales)],
      ),
      body: Column(
        children: [
          // Period selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text('Period: ', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(width: 8),
                ...['daily', 'weekly', 'monthly'].map((p) {
                  final sel = p == _period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _period = p);
                        _fetchSales();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                        ),
                        child: Text(
                          p[0].toUpperCase() + p.substring(1),
                          style: GoogleFonts.poppins(
                              color: sel ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const LoadingWidget()
                : RefreshIndicator(
                    onRefresh: _fetchSales,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Summary cards
                        Row(
                          children: [
                            Expanded(child: _SummaryCard(
                              title: 'Total Sales',
                              value: formatPeso(_totalSales),
                              icon: Icons.attach_money,
                              color: AppColors.primary,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _SummaryCard(
                              title: 'Transactions',
                              value: '${_sales.length}',
                              icon: Icons.receipt_long,
                              color: AppColors.info,
                            )),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _SummaryCard(
                          title: 'Average Sale',
                          value: formatPeso(avgSale),
                          icon: Icons.trending_up,
                          color: AppColors.success,
                          wide: true,
                        ),
                        const SizedBox(height: 20),

                        // Chart
                        if (_sales.isNotEmpty) ...[
                          Text('Sales Chart', style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: SizedBox(
                              height: 160,
                              child: BarChart(BarChartData(
                                barGroups: _sales.take(10).toList().asMap().entries.map((e) {
                                  return BarChartGroupData(
                                    x: e.key,
                                    barRods: [BarChartRodData(
                                      toY: (e.value['amount'] ?? 0).toDouble(),
                                      color: AppColors.primary,
                                      width: 18,
                                      borderRadius: BorderRadius.circular(4),
                                    )],
                                  );
                                }).toList(),
                                titlesData: const FlTitlesData(
                                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: const FlGridData(show: false),
                              )),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Sales table
                        Text('Sales Details', style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        if (_sales.isEmpty)
                          EmptyState(
                            message: 'No sales data for this period',
                            icon: Icons.point_of_sale_outlined,
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: Column(
                              children: [
                                // Header
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.06),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                  ),
                                  child: Row(children: [
                                    Expanded(child: Text('ID / Guest', style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700, fontSize: 12))),
                                    SizedBox(width: 80, child: Text('Amount', style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.right)),
                                    SizedBox(width: 80, child: Text('Date', style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.right)),
                                  ]),
                                ),
                                ..._sales.map((sale) {
                                  final guestName = sale['reservation']?['guestName'] ??
                                      sale['customerName'] ?? 'N/A';
                                  final amount = (sale['amount'] ?? 0).toDouble();
                                  final dateStr = sale['date'] ?? sale['createdAt'];
                                  final date = dateStr != null ? DateTime.tryParse(dateStr.toString()) : null;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.5))),
                                    ),
                                    child: Row(children: [
                                      Expanded(child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(guestName, style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600, fontSize: 13)),
                                          Text(
                                            '${sale['_id']?.toString().substring(0, 8) ?? ''}...',
                                            style: GoogleFonts.poppins(
                                                fontSize: 10, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      )),
                                      SizedBox(width: 80, child: Text(formatPeso(amount),
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700,
                                              fontSize: 13, color: AppColors.primary),
                                          textAlign: TextAlign.right)),
                                      SizedBox(width: 80, child: Text(
                                        date != null ? DateFormat('MM/dd').format(date) : '--',
                                        style: GoogleFonts.poppins(
                                            fontSize: 11, color: AppColors.textSecondary),
                                        textAlign: TextAlign.right,
                                      )),
                                    ]),
                                  );
                                }),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  final bool wide;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: wide
          ? Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary)),
                Text(value, style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800, fontSize: 20, color: color)),
              ]),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(title, style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary)),
              Text(value, style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800, fontSize: 18, color: color)),
            ]),
    );
  }
}

// ============================================
// REPORTS SCREEN
// ============================================
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _reportType = 'reservation';
  DateTime? _startDate;
  DateTime? _endDate;
  dynamic _reportData;
  bool _loading = false;

  final _reportTypes = {
    'reservation': 'Reservation Report',
    'sales': 'Sales Report',
    'inventory': 'Inventory Usage Report',
    'staff': 'Staff Activity Report',
  };

  Future<void> _generateReport() async {
    setState(() { _loading = true; _reportData = null; });
    try {
      String path;
      final params = <String>[];
      if (_startDate != null) params.add('startDate=${_startDate!.toIso8601String().split('T')[0]}');
      if (_endDate != null) params.add('endDate=${_endDate!.toIso8601String().split('T')[0]}');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';

      switch (_reportType) {
        case 'reservation':
          path = '/api/admin/reports/reservation$query';
          break;
        case 'sales':
          path = '/api/admin/reports/sales$query';
          break;
        case 'inventory':
          path = '/api/admin/reports/inventory-usage$query';
          break;
        case 'staff':
          path = '/api/admin/reports/staff-activity';
          break;
        default:
          path = '/api/admin/reports/reservation$query';
      }

      debugPrint('Generating report from: $path');
      final result = await ApiService.get(path, auth: true);
      debugPrint('Report result type: ${result.runtimeType}');
      debugPrint('Report result: $result');
      
      setState(() { 
        _reportData = result; 
        _loading = false;
        debugPrint('Report loaded successfully');
      });
      
      if (mounted && _reportData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data available for this report')),
        );
      }
    } catch (e, stack) {
      debugPrint('Error generating report: $e');
      debugPrint('Stack: $stack');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate report: $e')),
        );
      }
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  List<dynamic> get _tableRows {
    if (_reportData == null) return [];
    if (_reportData is List) return _reportData;
    if (_reportData is Map) {
      if (_reportData['reservations'] is List) return _reportData['reservations'];
      if (_reportData['sales'] is List) return _reportData['sales'];
      if (_reportData['items'] is List) return _reportData['items'];
      if (_reportData['staff'] is List) return _reportData['staff'];
    }
    return [];
  }

  double get _totalSales {
    if (_reportData is Map) {
      return (_reportData['totalSales'] ?? _reportData['total'] ?? 0).toDouble();
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Controls
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Report Type', style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _reportTypes.entries.map((e) {
                      final sel = e.key == _reportType;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _reportType = e.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                            ),
                            child: Text(e.value, style: GoogleFonts.poppins(
                                color: sel ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (_reportType != 'staff') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: GestureDetector(
                        onTap: () => _pickDate(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              _startDate != null
                                  ? DateFormat('MMM d, yyyy').format(_startDate!)
                                  : 'Start Date',
                              style: GoogleFonts.poppins(fontSize: 12,
                                  color: _startDate != null ? AppColors.textPrimary : AppColors.textSecondary),
                            ),
                          ]),
                        ),
                      )),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('to', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      Expanded(child: GestureDetector(
                        onTap: () => _pickDate(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              _endDate != null
                                  ? DateFormat('MMM d, yyyy').format(_endDate!)
                                  : 'End Date',
                              style: GoogleFonts.poppins(fontSize: 12,
                                  color: _endDate != null ? AppColors.textPrimary : AppColors.textSecondary),
                            ),
                          ]),
                        ),
                      )),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity, height: 44,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.bar_chart, size: 18),
                    label: Text('Generate Report',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    onPressed: _loading ? null : _generateReport,
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _loading
                ? const LoadingWidget(message: 'Generating report...')
                : _reportData == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.assessment_outlined,
                                size: 64, color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            Text('Select a report type and tap Generate',
                                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(14),
                        children: [
                          // Summary for sales
                          if (_reportType == 'sales' && _totalSales > 0) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [AppColors.primary, AppColors.primaryLight]),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Revenue', style: GoogleFonts.poppins(
                                      color: Colors.white70, fontSize: 13)),
                                  Text(formatPeso(_totalSales), style: GoogleFonts.poppins(
                                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28)),
                                  Text('${_tableRows.length} transactions',
                                      style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          Text('${_reportTypes[_reportType]} Results',
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),

                          if (_tableRows.isEmpty)
                            const EmptyState(message: 'No data for selected period',
                                icon: Icons.inbox_outlined)
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white, borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                                    blurRadius: 6, offset: const Offset(0, 2))],
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(
                                      AppColors.primary.withOpacity(0.06)),
                                  columns: _buildColumns(),
                                  rows: _buildRows(),
                                ),
                              ),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    switch (_reportType) {
      case 'reservation':
        return ['Guest', 'Email', 'Oasis', 'Package', 'Date', 'Status'].map((c) =>
            DataColumn(label: Text(c, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)))).toList();
      case 'sales':
        return ['Guest', 'Amount', 'Method', 'Date'].map((c) =>
            DataColumn(label: Text(c, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)))).toList();
      case 'inventory':
        return ['Item', 'Total Used', 'Current Stock', 'Unit'].map((c) =>
            DataColumn(label: Text(c, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)))).toList();
      case 'staff':
        return ['Name', 'Role', 'Position', 'Status', 'Activity'].map((c) =>
            DataColumn(label: Text(c, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)))).toList();
      default:
        return [DataColumn(label: Text('Data', style: GoogleFonts.poppins()))];
    }
  }

  List<DataRow> _buildRows() {
    return _tableRows.map<DataRow>((row) {
      List<DataCell> cells;
      switch (_reportType) {
        case 'reservation':
          cells = [
            DataCell(Text(row['customerName'] ?? row['guestName'] ?? '--',
                style: GoogleFonts.poppins(fontSize: 13))),
            DataCell(Text(row['customerEmail'] ?? row['guestEmail'] ?? '--',
                style: GoogleFonts.poppins(fontSize: 12))),
            DataCell(Text(row['oasis'] ?? '--', style: GoogleFonts.poppins(fontSize: 13))),
            DataCell(Text(row['package'] ?? '--', style: GoogleFonts.poppins(fontSize: 13))),
            DataCell(Text(row['bookingDate'] != null
                ? DateFormat('MM/dd/yy').format(DateTime.parse(row['bookingDate']))
                : '--', style: GoogleFonts.poppins(fontSize: 12))),
            DataCell(Text(row['status'] ?? '--', style: GoogleFonts.poppins(fontSize: 12))),
          ];
          break;
        case 'sales':
          final amount = (row['amount'] ?? 0).toDouble();
          final date = row['date'] != null ? DateTime.tryParse(row['date']) : null;
          cells = [
            DataCell(Text(row['reservation']?['guestName'] ?? row['customerName'] ?? 'N/A',
                style: GoogleFonts.poppins(fontSize: 13))),
            DataCell(Text(formatPeso(amount),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.primary))),
            DataCell(Text(row['paymentMethod'] ?? '--', style: GoogleFonts.poppins(fontSize: 12))),
            DataCell(Text(date != null ? DateFormat('MM/dd/yy').format(date) : '--',
                style: GoogleFonts.poppins(fontSize: 12))),
          ];
          break;
        case 'inventory':
          cells = [
            DataCell(Text(row['item'] ?? '--', style: GoogleFonts.poppins(fontSize: 13))),
            DataCell(Text('${row['totalUsed'] ?? 0}', style: GoogleFonts.poppins(fontSize: 13))),
            DataCell(Text('${row['currentStock'] ?? row['quantity'] ?? 0}',
                style: GoogleFonts.poppins(fontSize: 13))),
            DataCell(Text(row['unit'] ?? '--', style: GoogleFonts.poppins(fontSize: 12))),
          ];
          break;
        case 'staff':
          cells = [
            DataCell(Text(row['name'] ?? '--', style: GoogleFonts.poppins(fontSize: 13))),
            DataCell(Text(row['role'] ?? '--', style: GoogleFonts.poppins(fontSize: 12))),
            DataCell(Text(row['position'] ?? '--', style: GoogleFonts.poppins(fontSize: 12))),
            DataCell(Text(row['status'] ?? '--', style: GoogleFonts.poppins(fontSize: 12))),
            DataCell(Text('${row['activityCount'] ?? 0}', style: GoogleFonts.poppins(fontSize: 13))),
          ];
          break;
        default:
          cells = [DataCell(Text('$row'))];
      }
      return DataRow(cells: cells);
    }).toList();
  }
}
