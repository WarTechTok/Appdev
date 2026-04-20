// lib/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../widgets/common_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  DashboardStats? _stats;
  List<Map<String, dynamic>> _dailyData = [];
  List<Map<String, dynamic>> _monthlyData = [];
  SensorReading? _sensorReading;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    try {
      debugPrint('Fetching dashboard stats...');
      final statsResult = await ApiService.get('/api/admin/dashboard/stats', auth: true);
      debugPrint('Stats result: $statsResult');
      
      final dailyResult = await ApiService.get('/api/admin/dashboard/daily-chart', auth: true);
      debugPrint('Daily chart result type: ${dailyResult.runtimeType}');
      
      final monthlyResult = await ApiService.get('/api/admin/dashboard/monthly-chart', auth: true);
      debugPrint('Monthly chart result type: ${monthlyResult.runtimeType}');

      setState(() {
        // Parse stats - handle both direct object and wrapped response
        if (statsResult is Map) {
          if (statsResult['data'] is Map) {
            _stats = DashboardStats.fromJson(statsResult['data'] as Map<String, dynamic>);
          } else if (statsResult['stats'] is Map) {
            _stats = DashboardStats.fromJson(statsResult['stats'] as Map<String, dynamic>);
          } else {
            _stats = DashboardStats.fromJson(statsResult as Map<String, dynamic>);
          }
        }
        
        // Parse daily chart data
        _dailyData = [];
        if (dailyResult is Map && dailyResult['data'] is List) {
          _dailyData = (dailyResult['data'] as List).cast<Map<String, dynamic>>();
        } else if (dailyResult is List) {
          _dailyData = dailyResult.cast<Map<String, dynamic>>();
        }
        
        // Parse monthly chart data
        _monthlyData = [];
        if (monthlyResult is Map && monthlyResult['data'] is List) {
          _monthlyData = (monthlyResult['data'] as List).cast<Map<String, dynamic>>();
        } else if (monthlyResult is List) {
          _monthlyData = monthlyResult.cast<Map<String, dynamic>>();
        }
        
        _loading = false;
        debugPrint('Dashboard loaded: ${_stats?.toString()}');
      });
    } catch (e, stack) {
      debugPrint('Error fetching dashboard data: $e');
      debugPrint('Stack: $stack');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dashboard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAll),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _loading
          ? const LoadingWidget(message: 'Loading dashboard...')
          : RefreshIndicator(
              onRefresh: _fetchAll,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Welcome
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pool, color: Colors.white, size: 32),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome back, Admin!',
                                style: GoogleFonts.poppins(
                                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                            Text(user?.email ?? '',
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pool Monitoring
                  if (_sensorReading != null) ...[
                    Text('Pool Monitoring',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _SensorCard(
                          label: 'Temperature',
                          value: _sensorReading!.temperature != null
                              ? '${_sensorReading!.temperature!.toStringAsFixed(1)}°C'
                              : '--',
                          icon: Icons.thermostat,
                          color: AppColors.warning,
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _SensorCard(
                          label: 'Turbidity',
                          value: _sensorReading!.turbidity != null
                              ? '${_sensorReading!.turbidity!.toStringAsFixed(1)} NTU'
                              : '--',
                          icon: Icons.water,
                          color: AppColors.info,
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _SensorCard(
                          label: 'pH Level',
                          value: _sensorReading!.ph != null
                              ? _sensorReading!.ph!.toStringAsFixed(1)
                              : '--',
                          icon: Icons.science,
                          color: AppColors.success,
                        )),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Stats Overview
                  Text('Overview',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (_stats != null) ...[
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.6,
                      children: [
                        StatCard(
                          title: 'Total Reservations',
                          value: '${_stats!.totalReservations}',
                          icon: Icons.book_online,
                          color: AppColors.primary,
                          onTap: () => Navigator.pushNamed(context, '/admin/bookings'),
                        ),
                        StatCard(
                          title: 'Available Rooms',
                          value: '${_stats!.availableRooms}',
                          icon: Icons.hotel,
                          color: AppColors.success,
                          onTap: () => Navigator.pushNamed(context, '/admin/rooms'),
                        ),
                        StatCard(
                          title: 'Maintenance Rooms',
                          value: '${_stats!.maintainanceRooms}',
                          icon: Icons.build_outlined,
                          color: AppColors.warning,
                          onTap: () => Navigator.pushNamed(context, '/admin/rooms'),
                        ),
                        StatCard(
                          title: 'Active Staff',
                          value: '${_stats!.activeStaff}',
                          icon: Icons.people,
                          color: AppColors.info,
                          onTap: () => Navigator.pushNamed(context, '/admin/staff'),
                        ),
                        StatCard(
                          title: 'Monthly Revenue',
                          value: formatPeso(_stats!.monthlyRevenue),
                          icon: Icons.attach_money,
                          color: AppColors.accentGold,
                          onTap: () => Navigator.pushNamed(context, '/admin/sales'),
                        ),
                        StatCard(
                          title: 'Low Stock Items',
                          value: '${_stats!.lowStockItems}',
                          icon: Icons.warning_amber,
                          color: AppColors.error,
                          onTap: () => Navigator.pushNamed(context, '/admin/inventory'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Sales Charts
                  Text('Sales Analytics',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),

                  if (_dailyData.isNotEmpty)
                    _ChartCard(
                      title: 'Daily Sales (Last 7 Days)',
                      child: BarChart(
                        BarChartData(
                          barGroups: _dailyData.asMap().entries.map((e) {
                            final val = (e.value['total'] ?? 0).toDouble();
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: val,
                                  color: AppColors.primary,
                                  width: 16,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }).toList(),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  final idx = v.toInt();
                                  if (idx < _dailyData.length) {
                                    return Text(
                                      '${_dailyData[idx]['_id'] ?? ''}',
                                      style: GoogleFonts.poppins(fontSize: 10),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  if (_monthlyData.isNotEmpty)
                    _ChartCard(
                      title: 'Monthly Sales',
                      child: LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: _monthlyData.asMap().entries.map((e) {
                                final val = (e.value['total'] ?? 0).toDouble();
                                return FlSpot(e.key.toDouble(), val);
                              }).toList(),
                              isCurved: true,
                              color: AppColors.primaryLight,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primaryLight.withOpacity(0.15),
                              ),
                            ),
                          ],
                          titlesData: const FlTitlesData(
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Quick Navigation
                  Text('Quick Actions',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _QuickNav(Icons.hotel, 'Rooms', AppColors.primary,
                          () => Navigator.pushNamed(context, '/admin/rooms')),
                      _QuickNav(Icons.people, 'Staff', AppColors.info,
                          () => Navigator.pushNamed(context, '/admin/staff')),
                      _QuickNav(Icons.inventory_2, 'Inventory', AppColors.success,
                          () => Navigator.pushNamed(context, '/admin/inventory')),
                      _QuickNav(Icons.book_online, 'Bookings', AppColors.warning,
                          () => Navigator.pushNamed(context, '/admin/bookings')),
                      _QuickNav(Icons.point_of_sale, 'Sales', AppColors.accentGold,
                          () => Navigator.pushNamed(context, '/admin/sales')),
                      _QuickNav(Icons.assessment, 'Reports', AppColors.error,
                          () => Navigator.pushNamed(context, '/admin/reports')),
                      _QuickNav(Icons.sensors, 'Pool Monitor', AppColors.primary,
                          () => Navigator.pushNamed(context, '/admin/pool-monitoring')),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SensorCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          SizedBox(height: 160, child: child),
        ],
      ),
    );
  }
}

class _QuickNav extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickNav(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
