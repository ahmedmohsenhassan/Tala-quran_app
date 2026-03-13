import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    // Register global error handler
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (!_hasError) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _error = details.exception;
              _stackTrace = details.stack;
            });
          }
        });
      }
      return const SizedBox.shrink(); // Hide the red screen
    };
  }

  void _handleReset() {
    setState(() {
      _hasError = false;
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _PremiumErrorScreen(
        error: _error,
        stackTrace: _stackTrace,
        onReset: _handleReset,
      );
    }

    return widget.child;
  }
}

class _PremiumErrorScreen extends StatelessWidget {
  final Object? error;
  final StackTrace? stackTrace;
  final VoidCallback onReset;

  const _PremiumErrorScreen({
    this.error,
    this.stackTrace,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF021612), // Deep green background
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.5,
              colors: [
                Color(0xFF0A2E26),
                Color(0xFF021612),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error Icon with Glow
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'عذراً، حدث خطأ غير متوقع',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'نعتذر عن هذا الخلل البرمجي. نحن نسعى دائماً لتقديم أفضل تجربة لتلاوة القرآن الكريم.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),
                // Buttons
                ElevatedButton(
                  onPressed: onReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB8860B), // Gold
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    'حاول مرة أخرى',
                    style: GoogleFonts.amiri(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // In a real app, you might mail this to yourself
                    debugPrint('Error: $error');
                    debugPrint('Stack: $stackTrace');
                  },
                  child: Text(
                    'عرض تفاصيل الخطأ (للمطورين)',
                    style: GoogleFonts.amiri(
                      color: Colors.white38,
                      fontSize: 14,
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
