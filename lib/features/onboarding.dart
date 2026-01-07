import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Onboarding overlay widget with gentle instruction pages
class OnboardingOverlay extends StatelessWidget {
  final int currentPage;
  final VoidCallback onTap;

  const OnboardingOverlay({
    super.key,
    required this.currentPage,
    required this.onTap,
  });

  static const List<Map<String, String>> pages = [
    {
      'title': 'welcome',
      'body': 'a quiet space for\ncontemplation',
    },
    {
      'title': 'navigate',
      'body': 'tap anywhere for\nthe next verse\n\ntap ■ source to see\nwhere it\'s from',
    },
    {
      'title': 'breathe',
      'body': 'let each verse\nsettle before\nmoving on',
    },
  ];

  static int get pageCount => pages.length;

  @override
  Widget build(BuildContext context) {
    final page = pages[currentPage];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: const Color(0xFFFAF8F3).withOpacity(0.95),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    page['title']!,
                    style: GoogleFonts.jost(
                      fontSize: 14,
                      color: const Color(0xFFAAAAAA),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    page['body']!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jost(
                      fontSize: 20,
                      height: 1.6,
                      color: const Color(0xFF2C2C2C),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    currentPage < pageCount - 1 ? 'tap to continue' : 'tap to begin',
                    style: GoogleFonts.jost(
                      fontSize: 12,
                      color: const Color(0xFFAAAAAA),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
