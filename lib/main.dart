// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'services/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/customer/home_screen.dart';
import 'screens/customer/booking_screen.dart';
import 'screens/customer/booking_receipt_screen.dart';
import 'screens/customer/my_bookings_screen.dart';
import 'screens/customer/info_screens.dart';
import 'screens/customer/pool_monitoring_screen.dart';
import 'screens/customer/package_details_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/room_management_screen.dart';
import 'screens/admin/staff_management_screen.dart';
import 'screens/admin/inventory_management_screen.dart';
import 'screens/admin/booking_management_screen.dart';
import 'screens/admin/sales_screen.dart';
import 'screens/staff/staff_screens.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const BlueSenseApp(),
    ),
  );
}

class BlueSenseApp extends StatelessWidget {
  const BlueSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Catherine's Oasis - BlueSense",
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Handle dynamic route: /reset-password/:token
        if (settings.name?.startsWith('/reset-password/') == true) {
          final token = settings.name!.replaceFirst('/reset-password/', '');
          return MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(token: token),
          );
        }
        // Handle dynamic route: /package/:packageName
        if (settings.name?.startsWith('/package/') == true) {
          final packageName = settings.name!.replaceFirst('/package/', '');
          return MaterialPageRoute(
            builder: (_) => PackageDetailsScreen(packageName: packageName),
          );
        }
        // Handle booking receipt with arguments
        if (settings.name == '/booking-receipt') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (_) => BookingReceiptScreen(bookingData: args),
            );
          }
        }
        return null;
      },
      routes: {
        '/': (ctx) => const _SplashRouter(),
        '/login': (ctx) => const LoginScreen(),
        '/register': (ctx) => const RegisterScreen(),
        '/forgot-password': (ctx) => const ForgotPasswordScreen(),

        // Customer routes
        '/home': (ctx) => const HomeScreen(),
        '/booking': (ctx) => const BookingScreen(),
        '/my-bookings': (ctx) => const MyBookingsScreen(),
        '/about-us': (ctx) => const AboutUsScreen(),
        '/oasis-1': (ctx) => const Oasis1Screen(),
        '/oasis-2': (ctx) => const Oasis2Screen(),
        '/gallery': (ctx) => const GalleryScreen(),
        '/contact-us': (ctx) => const ContactUsScreen(),
        '/pool-monitoring': (ctx) => const PoolMonitoringScreen(),

        // Admin routes (role-guarded)
        '/admin/dashboard': (ctx) => const _AdminRoute(child: AdminDashboardScreen()),
        '/admin/rooms': (ctx) => const _AdminRoute(child: RoomManagementScreen()),
        '/admin/staff': (ctx) => const _AdminRoute(child: StaffManagementScreen()),
        '/admin/inventory': (ctx) => const _AdminRoute(child: InventoryManagementScreen()),
        '/admin/bookings': (ctx) => const _AdminRoute(child: BookingManagementScreen()),
        '/admin/sales': (ctx) => const _AdminRoute(child: SalesScreen()),
        '/admin/reports': (ctx) => const _AdminRoute(child: ReportsScreen()),
        '/admin/pool-monitoring': (ctx) => const _AdminRoute(child: PoolMonitoringScreen()),

        // Staff routes (role-guarded)
        '/staff/dashboard': (ctx) => const _StaffRoute(child: StaffDashboardScreen()),
        '/staff/tasks': (ctx) => const _StaffRoute(child: StaffTasksScreen()),
        '/staff/inspections': (ctx) => const _StaffRoute(child: StaffInspectionsScreen()),
        '/staff/notifications': (ctx) => const _StaffRoute(child: StaffNotificationsScreen()),
      },
    );
  }
}

// ============================================
// SPLASH / ROUTER
// ============================================
class _SplashRouter extends StatefulWidget {
  const _SplashRouter();
  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigate());
  }

  void _navigate() {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    switch (auth.user?.role) {
      case 'admin':
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
        break;
      case 'staff':
        Navigator.pushReplacementNamed(context, '/staff/dashboard');
        break;
      default:
        Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.pool, color: Colors.white, size: 56),
              ),
              const SizedBox(height: 20),
              const Text("Catherine's Oasis", style: TextStyle(
                  color: Colors.white, fontSize: 28,
                  fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 4),
              const Text('BlueSense Resort Management',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// ROUTE GUARDS
// ============================================
class _AdminRoute extends StatelessWidget {
  final Widget child;
  const _AdminRoute({required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => Navigator.pushReplacementNamed(context, '/login'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.user?.role != 'admin') {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: AppColors.error),
              const SizedBox(height: 12),
              const Text('Access Denied',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Admin access required.',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      );
    }
    return child;
  }
}

class _StaffRoute extends StatelessWidget {
  final Widget child;
  const _StaffRoute({required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => Navigator.pushReplacementNamed(context, '/login'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.user?.role != 'staff' && auth.user?.role != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => Navigator.pushReplacementNamed(context, '/login'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return child;
  }
}
