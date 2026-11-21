import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:college_canteen/core/constants/daily_messages.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/bus/screens/bus_tracking_screen.dart';
import 'package:college_canteen/features/food/screens/menu_screen.dart';
import 'package:college_canteen/features/home/widgets/spherical_module_card.dart';
import 'package:college_canteen/features/profile/profile_provider.dart';
import 'package:college_canteen/features/profile/profile_screen.dart';
import 'package:college_canteen/features/stationary/screens/stationary_print_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final rawName = profileProvider.profile?.fullName.trim() ?? '';
    final String greetingTitle;

    if (rawName.isEmpty) {
      greetingTitle = 'Welcome, Campus Explorer!';
    } else {
      final firstName = rawName.split(RegExp(r'\s+')).first;
      greetingTitle = 'Welcome back, $firstName!';
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.maxContentWidth,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Row: Greeting & Profile Action Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greetingTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DailyMessages.welcome,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: 'Profile',
                        icon: const Icon(
                          Icons.account_circle_outlined,
                          size: 32,
                          color: AppTheme.primaryColor,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Spherical Module Hub Layout (2 on top row, 1 centered below)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final rawDiameter = min(constraints.maxWidth * 0.44, 190.0);
                      final diameter = rawDiameter.clamp(120.0, 190.0);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top Row: Foods and Bus
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SphericalModuleCard.food(
                                diameter: diameter,
                                hook: DailyMessages.foodHook,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MenuScreen(),
                                    ),
                                  );
                                },
                              ),
                              SphericalModuleCard.bus(
                                diameter: diameter,
                                hook: DailyMessages.busHook,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const BusTrackingScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Bottom Row: Stationary (Centered)
                          Center(
                            child: SphericalModuleCard.stationary(
                              diameter: diameter,
                              hook: DailyMessages.stationaryHook,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const StationaryPrintScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
