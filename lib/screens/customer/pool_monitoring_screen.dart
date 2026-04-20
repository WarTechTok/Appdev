// lib/screens/customer/pool_monitoring_screen.dart
// Also used by admin dashboard for embedded pool monitoring
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/common_widgets.dart';

class PoolMonitoringScreen extends StatefulWidget {
  const PoolMonitoringScreen({super.key});
  @override
  State<PoolMonitoringScreen> createState() => _PoolMonitoringScreenState();
}

class _PoolMonitoringScreenState extends State<PoolMonitoringScreen> {
  Map<String, dynamic>? _latest;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  String _historyFilter = 'today';
  String _selectedChart = 'ph';
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchAll();
    // Poll every 30 seconds like the web app
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchAll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    try {
      final results = await Future.wait([
        ApiService.get('/api/readings/latest', auth: false),
        ApiService.get('/api/readings/history', auth: false),
      ]);
      if (!mounted) return;
      setState(() {
        _latest = results[0] is Map ? (results[0] as Map).cast<String, dynamic>() : null;
        _history = results[1] is List
            ? (results[1] as List).cast<Map<String, dynamic>>()
            : [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredHistory {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final weekStart = todayStart.subtract(const Duration(days: 7));

    return _history.where((r) {
      if (r['timestamp'] == null) return false;
      final d = DateTime.tryParse(r['timestamp'].toString());
      if (d == null) return false;
      switch (_historyFilter) {
        case 'today':
          return d.isAfter(todayStart);
        case 'yesterday':
          return d.isAfter(yesterdayStart) && d.isBefore(todayStart);
        case 'week':
          return d.isAfter(weekStart);
        default:
          return true;
      }
    }).toList()
      ..sort((a, b) {
        final da = DateTime.tryParse(a['timestamp'].toString()) ?? DateTime(0);
        final db = DateTime.tryParse(b['timestamp'].toString()) ?? DateTime(0);
        return da.compareTo(db);
      });
  }

  Color get _statusColor {
    if (_latest == null) return AppColors.textSecondary;
    final ph = (_latest!['ph'] as num?)?.toDouble() ?? 7.0;
    final turb = _latest!['turbidity']?.toString() ?? '';
    if (ph < 6.5 || ph > 8.5 || turb == 'Dirty') return AppColors.error;
    if (turb == 'Cloudy') return AppColors.warning;
    return AppColors.success;
  }

  String get _statusText {
    if (_latest == null) return 'No Data';
    final ph = (_latest!['ph'] as num?)?.toDouble() ?? 7.0;
    final turb = _latest!['turbidity']?.toString() ?? '';
    if (ph < 6.5 || ph > 8.5 || turb == 'Dirty') return 'Needs Attention';
    if (turb == 'Cloudy') return 'Monitor';
    return 'Good Condition';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pool Monitoring', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [
          // Live indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.success.withOpacity(0.6), blurRadius: 6)]),
                ),
                const SizedBox(width: 4),
                Text('LIVE', style: GoogleFonts.poppins(
                    color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAll),
        ],
      ),
      body: _loading
          ? const LoadingWidget(message: 'Fetching sensor data...')
          : RefreshIndicator(
              onRefresh: _fetchAll,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Status overview card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _statusColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _statusColor == AppColors.success
                              ? Icons.check_circle
                              : _statusColor == AppColors.warning
                                  ? Icons.warning_amber
                                  : Icons.error_outline,
                          color: _statusColor, size: 36,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pool Status', style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                              Text(_statusText, style: GoogleFonts.poppins(
                                  color: _statusColor, fontWeight: FontWeight.w600, fontSize: 14)),
                              if (_latest?['timestamp'] != null)
                                Text(
                                  'Last updated: ${_formatTime(_latest!['timestamp'].toString())}',
                                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sensor readings
                  Text('Latest Readings', style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _SensorTile(
                        label: 'pH Level',
                        value: _latest?['ph'] != null
                            ? (_latest!['ph'] as num).toStringAsFixed(1)
                            : '--',
                        unit: 'pH',
                        icon: Icons.science_outlined,
                        color: _phColor(_latest?['ph']),
                        normalRange: '6.5 – 8.5',
                        onTap: () => setState(() => _selectedChart = 'ph'),
                        isSelected: _selectedChart == 'ph',
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _SensorTile(
                        label: 'Temperature',
                        value: _latest?['temperature'] != null
                            ? (_latest!['temperature'] as num).toStringAsFixed(1)
                            : '--',
                        unit: '°C',
                        icon: Icons.thermostat_outlined,
                        color: AppColors.warning,
                        normalRange: '25 – 32°C',
                        onTap: () => setState(() => _selectedChart = 'temperature'),
                        isSelected: _selectedChart == 'temperature',
                      )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _SensorTile(
                    label: 'Turbidity',
                    value: _latest?['turbidity']?.toString() ?? '--',
                    unit: '',
                    icon: Icons.water_drop_outlined,
                    color: _turbColor(_latest?['turbidity']),
                    normalRange: 'Clear',
                    onTap: () => setState(() => _selectedChart = 'turbidity'),
                    isSelected: _selectedChart == 'turbidity',
                    wide: true,
                  ),
                  const SizedBox(height: 20),

                  // Chart
                  if (_filteredHistory.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('History Chart', style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                        // Filter pills
                        Row(
                          children: {'today': 'Today', 'yesterday': 'Yesterday', 'week': 'Week'}
                              .entries.map((e) {
                            final sel = e.key == _historyFilter;
                            return GestureDetector(
                              onTap: () => setState(() => _historyFilter = e.key),
                              child: Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sel ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                                ),
                                child: Text(e.value, style: GoogleFonts.poppins(
                                    fontSize: 11, fontWeight: FontWeight.w600,
                                    color: sel ? Colors.white : AppColors.textSecondary)),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Chart type selector
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _ChartPill('ph', 'pH', _selectedChart, (v) => setState(() => _selectedChart = v)),
                          _ChartPill('temperature', 'Temperature', _selectedChart, (v) => setState(() => _selectedChart = v)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                            blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: SizedBox(
                        height: 200,
                        child: LineChart(_buildChart()),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // History table
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Reading History', style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('${_filteredHistory.length} records',
                          style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_filteredHistory.isEmpty)
                    const EmptyState(message: 'No readings for this period', icon: Icons.sensors_off)
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(12),
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
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text('Time', style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700, fontSize: 12))),
                                SizedBox(width: 60, child: Text('pH', style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.center)),
                                SizedBox(width: 60, child: Text('Temp', style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.center)),
                                SizedBox(width: 70, child: Text('Turbidity', style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.center)),
                              ],
                            ),
                          ),
                          // Rows — show last 20 reversed (newest first)
                          ...(_filteredHistory.reversed.take(20).map((r) {
                            final ph = r['ph'] as num?;
                            final temp = r['temperature'] as num?;
                            final turb = r['turbidity']?.toString() ?? '--';
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.5))),
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: Text(
                                    r['timestamp'] != null ? _formatTime(r['timestamp'].toString()) : '--',
                                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                                  )),
                                  SizedBox(width: 60, child: Text(
                                    ph != null ? ph.toStringAsFixed(1) : '--',
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600,
                                        color: _phColor(ph)),
                                    textAlign: TextAlign.center,
                                  )),
                                  SizedBox(width: 60, child: Text(
                                    temp != null ? '${temp.toStringAsFixed(1)}°' : '--',
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  )),
                                  SizedBox(width: 70, child: Text(
                                    turb,
                                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600,
                                        color: _turbColor(turb)),
                                    textAlign: TextAlign.center,
                                  )),
                                ],
                              ),
                            );
                          })),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  LineChartData _buildChart() {
    final data = _filteredHistory;
    if (data.isEmpty) return LineChartData();

    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      double? val;
      if (_selectedChart == 'ph') {
        val = (data[i]['ph'] as num?)?.toDouble();
      } else if (_selectedChart == 'temperature') {
        val = (data[i]['temperature'] as num?)?.toDouble();
      }
      if (val != null) spots.add(FlSpot(i.toDouble(), val));
    }

    final color = _selectedChart == 'ph' ? AppColors.primary : AppColors.warning;

    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 2.5,
          dotData: FlDotData(show: spots.length <= 20),
          belowBarData: BarAreaData(show: true, color: color.withOpacity(0.12)),
        ),
      ],
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (data.length / 5).ceilToDouble(),
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= data.length) return const Text('');
              final ts = data[i]['timestamp']?.toString();
              if (ts == null) return const Text('');
              final d = DateTime.tryParse(ts);
              if (d == null) return const Text('');
              return Text(DateFormat('HH:mm').format(d),
                  style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textSecondary));
            },
          ),
        ),
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1),
              style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textSecondary)),
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border.withOpacity(0.5), strokeWidth: 1),
        drawVerticalLine: false,
      ),
      borderData: FlBorderData(show: false),
    );
  }

  Color _phColor(dynamic ph) {
    if (ph == null) return AppColors.textSecondary;
    final v = (ph as num).toDouble();
    if (v < 6.5 || v > 8.5) return AppColors.error;
    if (v < 7.0 || v > 8.0) return AppColors.warning;
    return AppColors.success;
  }

  Color _turbColor(dynamic turb) {
    if (turb == null) return AppColors.textSecondary;
    switch (turb.toString()) {
      case 'Clear': return AppColors.success;
      case 'Cloudy': return AppColors.warning;
      case 'Dirty': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  String _formatTime(String ts) {
    final d = DateTime.tryParse(ts);
    if (d == null) return ts;
    return DateFormat('MMM d, hh:mm a').format(d.toLocal());
  }
}

class _SensorTile extends StatelessWidget {
  final String label, value, unit, normalRange;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isSelected;
  final bool wide;

  const _SensorTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.normalRange,
    required this.onTap,
    required this.isSelected,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: wide
            ? Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary)),
                      Row(
                        children: [
                          Text(value, style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800, fontSize: 22, color: color)),
                          const SizedBox(width: 4),
                          Text(unit, style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  )),
                  Text('Normal: $normalRange',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 6),
                    Text(label, style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(value, style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800, fontSize: 26, color: color)),
                      const SizedBox(width: 3),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(unit, style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                  Text('Normal: $normalRange', style: GoogleFonts.poppins(
                      fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
      ),
    );
  }
}

class _ChartPill extends StatelessWidget {
  final String value, label, selected;
  final ValueChanged<String> onTap;
  const _ChartPill(this.value, this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    final sel = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sel ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: GoogleFonts.poppins(
            color: sel ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600, fontSize: 12)),
      ),
    );
  }
}
