import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/colors.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 96, this.reversed});

  final double size;

  /// The light-on-dark variant, for navy or dark backgrounds. Follows the
  /// theme brightness when null.
  final bool? reversed;

  @override
  Widget build(BuildContext context) {
    final reversed =
        this.reversed ?? Theme.of(context).brightness == Brightness.dark;
    return SvgPicture.asset(
      reversed
          ? 'branding/svg/logo-mark-reversed.svg'
          : 'branding/svg/logo-mark.svg',
      width: size,
      height: size,
      semanticsLabel: 'Logo Sabu Saku',
    );
  }
}

/// Full-screen welcome that mirrors branding/svg/splash.svg. Shown while the
/// session is being resolved, so the name is visible on Android 12+ too.
class BrandSplash extends StatelessWidget {
  const BrandSplash({super.key});

  @override
  Widget build(BuildContext context) {
    // Navy in both themes, like the native splash before it.
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1D457A), AppColors.navy, AppColors.navyDeep],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandLogo(size: 168, reversed: true),
                SizedBox(height: 8),
                Text(
                  'SABU SAKU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Satu Bulan Satu Buku',
                  style: TextStyle(
                    color: Color(0xFFA9C6FF),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
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
