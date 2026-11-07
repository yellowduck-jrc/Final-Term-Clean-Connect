import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isSubmitting = false;
  String? _message;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() {
        _errorMessage = 'Enter a valid email address.';
        _message = null;
      });
      return;
    }
    setState(() {
      _isSubmitting = true;
      _message = null;
      _errorMessage = null;
    });
    try {
      await _authService.sendPasswordReset(email);
      if (mounted) {
        setState(() {
          _message =
              'If an account exists for this address, a reset email '
              'has been sent.';
        });
      }
    } catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF242735),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const Center(child: BroomIcon()),
                  const SizedBox(height: 18),
                  const Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 33,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                      ),
                      children: [
                        TextSpan(
                          text: 'Welcome to ',
                          style: TextStyle(color: Color(0xFFF3F4F5)),
                        ),
                        TextSpan(
                          text: 'Clean Connect',
                          style: TextStyle(color: Color(0xFF4ED782)),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A simple way to keep the campus space clean.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFFE7EAEE),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A394C),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Forgot Password',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF3F4F5),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            color: Color(0xFF1D2732),
                            fontSize: 17,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: const TextStyle(
                              color: Color(0xFF5D6975),
                              fontSize: 17,
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 16, right: 10),
                              child: Icon(
                                Icons.email_outlined,
                                color: Color(0xFF5D6975),
                                size: 26,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF0F0F0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF4DB979),
                                width: 1.4,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _sendResetEmail,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4ED782),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Send Code',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Already have an account? Log-in',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFF3F4F5),
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFE7EAEE),
                        fontSize: 14,
                      ),
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BroomIcon extends StatelessWidget {
  const BroomIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 136,
      child: Image.asset('assets/auth/broom.png'),
    );
  }
}

class BroomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = const Color(0xFFE5E4E1);
    final handlePaint = Paint()
      ..color = const Color(0xFF343A42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final bristlePaint = Paint()..color = const Color(0xFFD7D5D2);
    final sparklePaint = Paint()..color = const Color(0xFFD6D0C8);

    canvas.drawCircle(
      Offset(size.width * 0.44, size.height * 0.46),
      size.width * 0.25,
      backgroundPaint,
    );

    canvas.save();
    canvas.translate(size.width * 0.46, size.height * 0.18);
    canvas.rotate(-0.55);
    canvas.drawLine(Offset.zero, Offset(0, size.height * 0.68), handlePaint);
    canvas.restore();

    final bristles = Path()
      ..moveTo(size.width * 0.32, size.height * 0.64)
      ..lineTo(size.width * 0.58, size.height * 0.64)
      ..lineTo(size.width * 0.65, size.height * 0.82)
      ..lineTo(size.width * 0.25, size.height * 0.82)
      ..close();
    canvas.drawPath(bristles, bristlePaint);

    final broomBottom = Path()
      ..moveTo(size.width * 0.25, size.height * 0.82)
      ..lineTo(size.width * 0.65, size.height * 0.82)
      ..lineTo(size.width * 0.62, size.height * 0.88)
      ..lineTo(size.width * 0.28, size.height * 0.88)
      ..close();
    canvas.drawPath(broomBottom, Paint()..color = const Color(0xFFC7C5C1));

    final starOffsets = [
      Offset(size.width * 0.76, size.height * 0.08),
      Offset(size.width * 0.9, size.height * 0.18),
      Offset(size.width * 0.83, size.height * 0.35),
    ];

    for (final offset in starOffsets) {
      final path = Path();
      const starPoints = 5;
      final innerRadius = 5.0;
      final outerRadius = 9.0;
      for (var i = 0; i <= starPoints * 2; i++) {
        final angle = (i * pi / starPoints) - pi / 2;
        final radius = i.isEven ? outerRadius : innerRadius;
        final x = offset.dx + cos(angle) * radius;
        final y = offset.dy + sin(angle) * radius;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
