// lib/screens/customer/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../services/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  final List<Widget> _tabs = const [
    _HomeTab(),
    _BookingTabPlaceholder(),
    _MyBookingsTabPlaceholder(),
    _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_selectedTab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (i) {
          if (i == 1) {
            Navigator.pushNamed(context, '/booking');
            return;
          }
          if (i == 2) {
            Navigator.pushNamed(context, '/my-bookings');
            return;
          }
          setState(() => _selectedTab = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Book'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'My Bookings'),
          NavigationDestination(icon: Icon(Icons.person_outlined), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text('BlueSense Resort',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/hero/welcome.jpg',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  cacheHeight: 275,
                  cacheWidth: 600,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Error loading hero image: $error');
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Welcome
              if (auth.user != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text(
                          auth.user!.name.isNotEmpty ? auth.user!.name[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back!',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: AppColors.textSecondary)),
                          Text(auth.user!.name,
                              style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Quick actions
              Text('Quick Actions',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.calendar_month,
                      label: 'Book Now',
                      color: AppColors.primary,
                      onTap: () => Navigator.pushNamed(context, '/booking'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.receipt_long,
                      label: 'My Bookings',
                      color: AppColors.primary,
                      onTap: () => Navigator.pushNamed(context, '/my-bookings'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.sensors,
                      label: 'Pool Status',
                      color: AppColors.primary,
                      onTap: () => Navigator.pushNamed(context, '/pool-monitoring'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Our Pools
              Text('Our Pools',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _PoolCard(
                name: 'Oasis 1',
                imagePath: 'assets/images/hero/oasis1.jpg',
                description:
                    'A tropical paradise with swimming pool, jacuzzi, and private cottages. Perfect for groups and family getaways.',
                icon: Icons.waves,
                color: AppColors.primary,
                onTap: () => Navigator.pushNamed(context, '/oasis-1'),
              ),
              const SizedBox(height: 12),
              _PoolCard(
                name: 'Oasis 2',
                imagePath: 'assets/images/hero/oasis2.jpg',
                description:
                    'Exclusive private pool experience with covered function hall. Ideal for special events and large groups.',
                icon: Icons.pool,
                color: AppColors.primary,
                onTap: () => Navigator.pushNamed(context, '/oasis-2'),
              ),
              const SizedBox(height: 20),

              // Special Packages Section
              Text('Special Packages',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Exclusive offers for your perfect getaway',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              
              // Package Cards
              _PackageCard(
                name: 'Standard Package',
                price: '₱1,500',
                duration: 'Day Tour',
                features: const ['Pool Access', '2 Meals', '1 Cottage'],
                imagePath: 'assets/images/package/package-1.jpg',
                color: AppColors.primary,
                onTap: () => Navigator.pushNamed(context, '/package/standard'),
              ),
              const SizedBox(height: 12),
              
              _PackageCard(
                name: 'Premium Package',
                price: '₱2,500',
                duration: 'Day Tour',
                features: const ['Pool Access', '3 Meals', '1 Private Cottage', 'Welcome Drink'],
                imagePath: 'assets/images/package/package-2.jpg',
                color: AppColors.primary,
                onTap: () => Navigator.pushNamed(context, '/package/premium'),
              ),
              const SizedBox(height: 12),
              
              _PackageCard(
                name: 'Executive Package',
                price: '₱3,500',
                duration: 'Day Tour',
                features: const ['Pool Access', 'Buffet Lunch', 'Private Kubo', 'Free Towels', 'Fruit Platter'],
                imagePath: 'assets/images/package/package-3.jpg',
                color: AppColors.primary,
                onTap: () => Navigator.pushNamed(context, '/package/executive'),
              ),
              const SizedBox(height: 12),
              
              _PackageCard(
                name: 'Overnight Package',
                price: '₱5,000',
                duration: 'Overnight',
                features: const ['Pool Access', 'Dinner & Breakfast', 'Aircon Room', 'Free Breakfast'],
                imagePath: 'assets/images/package/package-4.jpg',
                color: AppColors.primary,
                onTap: () => Navigator.pushNamed(context, '/package/overnight'),
              ),
              const SizedBox(height: 12),
              
              _PackageCard(
                name: 'Family Package',
                price: '₱7,500',
                duration: '2 Days / 1 Night',
                features: const ['Pool Access', '3 Meals', 'Family Room', 'Free Kids Swim', 'Game Room Access'],
                imagePath: 'assets/images/package/package-5.jpg',
                color: AppColors.primary,
                onTap: () => Navigator.pushNamed(context, '/package/family'),
              ),
              const SizedBox(height: 12),
              
              _PackageCard(
                name: 'Deluxe Plus Package',
                price: '₱10,000',
                duration: '2 Days / 1 Night',
                features: const ['All Premium Features', 'VIP Lounge', 'Spa Treatment', 'Private Jacuzzi', 'Champagne'],
                imagePath: 'assets/images/package/package-5plus.jpg',
                color: AppColors.primary,
                isFeatured: true,
                onTap: () => Navigator.pushNamed(context, '/package/deluxe-plus'),
              ),
              const SizedBox(height: 20),

              // Amenities
              Text('Amenities',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _AmenityChip(label: 'Swimming Pool', icon: Icons.pool),
                  _AmenityChip(label: 'Jacuzzi', icon: Icons.spa),
                  _AmenityChip(label: 'Free WiFi', icon: Icons.wifi),
                  _AmenityChip(label: 'BBQ Grill', icon: Icons.outdoor_grill),
                  _AmenityChip(label: 'Karaoke', icon: Icons.mic),
                  _AmenityChip(label: 'AC Rooms', icon: Icons.ac_unit),
                  _AmenityChip(label: 'Smart TV', icon: Icons.tv),
                  _AmenityChip(label: 'Parking', icon: Icons.local_parking),
                ],
              ),
              const SizedBox(height: 20),

              // Contact
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/contact-us'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Need help?',
                                style: GoogleFonts.poppins(
                                    color: Colors.white, fontWeight: FontWeight.w700)),
                            Text('Contact us for inquiries about reservations.',
                                style: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // More links
              Row(
                children: [
                  Expanded(child: OutlinedButton.icon(
                    icon: const Icon(Icons.info_outlined, size: 16),
                    label: const Text('About Us'),
                    onPressed: () => Navigator.pushNamed(context, '/about-us'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: const Text('Gallery'),
                    onPressed: () => Navigator.pushNamed(context, '/gallery'),
                  )),
                ],
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }
}

class _PackageCard extends StatelessWidget {
  final String name;
  final String price;
  final String duration;
  final List<String> features;
  final String? imagePath;
  final Color color;
  final VoidCallback onTap;
  final bool isFeatured;

  const _PackageCard({
    required this.name,
    required this.price,
    required this.duration,
    required this.features,
    this.imagePath,
    required this.color,
    required this.onTap,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                  child: Image.asset(
                    imagePath ?? 'assets/images/package/package-1.jpg',
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    cacheHeight: 200,
                    cacheWidth: 600,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Image load error for $imagePath: $error');
                      return Container(
                        height: 160,
                        color: color.withOpacity(0.15),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported_outlined, color: color, size: 48),
                              const SizedBox(height: 8),
                              Text('Image Not Found',
                                  style: TextStyle(color: color, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (isFeatured)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text('BEST SELLER',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(duration,
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(name,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.textPrimary)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(price,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: features.map((feature) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 10, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(feature,
                                style: GoogleFonts.poppins(
                                    fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onTap,
                      child: const Text('View Details'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.poppins(
                    color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _PoolCard extends StatelessWidget {
  final String name;
  final String? imagePath;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PoolCard({
    required this.name,
    this.imagePath,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            if (imagePath != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                child: Image.asset(
                  imagePath!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  cacheHeight: 225,
                  cacheWidth: 600,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Error loading pool image $imagePath: $error');
                    return Container(
                      height: 180,
                      color: color.withOpacity(0.1),
                      child: Center(
                        child: Icon(icon, color: color, size: 56),
                      ),
                    );
                  },
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: imagePath != null
                    ? const BorderRadius.only(
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      )
                    : BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: AppColors.textSecondary, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _AmenityChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _BookingTabPlaceholder extends StatelessWidget {
  const _BookingTabPlaceholder();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _MyBookingsTabPlaceholder extends StatelessWidget {
  const _MyBookingsTabPlaceholder();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?.name ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                Text(user?.email ?? '',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _ProfileItem(icon: Icons.person_outlined, label: 'Full Name', value: user?.name ?? ''),
          _ProfileItem(icon: Icons.email_outlined, label: 'Email', value: user?.email ?? ''),
          _ProfileItem(icon: Icons.phone_outlined, label: 'Phone', value: user?.phone ?? 'Not set'),
          _ProfileItem(icon: Icons.badge_outlined, label: 'Role', value: user?.role ?? ''),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}