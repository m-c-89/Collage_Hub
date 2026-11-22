import 'package:flutter/material.dart';
import 'package:college_canteen/core/theme/app_theme.dart';

class SphericalModuleCard extends StatefulWidget {
  final double diameter;
  final String hook;
  final String label;
  final Widget icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const SphericalModuleCard({
    super.key,
    required this.diameter,
    required this.hook,
    required this.label,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  factory SphericalModuleCard.food({
    Key? key,
    required double diameter,
    required String hook,
    required VoidCallback onTap,
  }) =>
      SphericalModuleCard(
        key: key,
        diameter: diameter,
        hook: hook,
        label: 'Foods',
        icon: _ModuleIcons.food(diameter * 0.40),
        gradientColors: const [
          Color(0xFFFFB74D),
          AppTheme.primaryColor,
          Color(0xFF8C2D00),
        ],
        onTap: onTap,
      );

  factory SphericalModuleCard.bus({
    Key? key,
    required double diameter,
    required String hook,
    required VoidCallback onTap,
  }) =>
      SphericalModuleCard(
        key: key,
        diameter: diameter,
        hook: hook,
        label: 'Bus',
        icon: _ModuleIcons.bus(diameter * 0.40),
        gradientColors: const [
          Color(0xFF64B5F6),
          Color(0xFF1976D2),
          Color(0xFF0D47A1),
        ],
        onTap: onTap,
      );

  factory SphericalModuleCard.stationary({
    Key? key,
    required double diameter,
    required String hook,
    required VoidCallback onTap,
  }) =>
      SphericalModuleCard(
        key: key,
        diameter: diameter,
        hook: hook,
        label: 'Stationary',
        icon: _ModuleIcons.stationary(diameter * 0.40),
        gradientColors: const [
          Color(0xFFBA68C8),
          Color(0xFF7B1FA2),
          Color(0xFF4A148C),
        ],
        onTap: onTap,
      );

  @override
  State<SphericalModuleCard> createState() => _SphericalModuleCardState();
}

class _SphericalModuleCardState extends State<SphericalModuleCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) => setState(() => _isPressed = true);
  void _handleTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _handleTapCancel() => setState(() => _isPressed = false);

  @override
  Widget build(BuildContext context) {
    final d = widget.diameter;
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedScale(
          scale: _isPressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                radius: 0.85,
                colors: widget.gradientColors,
                stops: const [0.0, 0.55, 1.0],
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18, offset: const Offset(0, 8)),
                BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 6, offset: const Offset(0, 3)),
                BoxShadow(color: widget.gradientColors[1].withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 4)),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: d * 0.05,
                  left: d * 0.12,
                  child: IgnorePointer(
                    child: Container(
                      width: d * 0.52,
                      height: d * 0.28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.elliptical(d * 0.26, d * 0.14)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white.withOpacity(0.55), Colors.white.withOpacity(0.0)],
                        ),
                      ),
                    ),
                  ),
                ),
                ClipOval(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: d * 0.16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: d * 0.08),
                          child: SizedBox(
                            height: d * 0.18,
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  widget.hook,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  style: TextStyle(
                                    fontSize: d * 0.075,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.95),
                                    letterSpacing: -0.2,
                                    shadows: const [Shadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1))],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: SizedBox(
                              width: d * 0.36,
                              height: d * 0.36,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: widget.icon,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: d * 0.08),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: d * 0.11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.2,
                                shadows: const [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1.5))],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuleIcons {
  _ModuleIcons._();

  static Widget _buildShaderIcon(IconData icon, double size) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0xFFF0F0F0)],
      ).createShader(bounds),
      child: Icon(
        icon,
        size: size,
        color: Colors.white,
        shadows: const [Shadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2))],
      ),
    );
  }

  static Widget food(double size) => _buildShaderIcon(Icons.lunch_dining_rounded, size);

  static Widget bus(double size) => _buildShaderIcon(Icons.directions_bus_rounded, size);

  static Widget stationary(double size) => Stack(
        alignment: Alignment.center,
        children: [
          _buildShaderIcon(Icons.print_rounded, size),
          Positioned(
            right: size * 0.08,
            bottom: size * 0.08,
            child: Container(
              padding: EdgeInsets.all(size * 0.04),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.description_rounded, size: size * 0.32, color: const Color(0xFF7B1FA2)),
            ),
          ),
        ],
      );
}
