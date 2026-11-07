import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage = AuthService.authErrorMessage(
            error,
            creatingAccount: false,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<String>? autofillHints,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      style: const TextStyle(color: Color(0xFF1D2732), fontSize: 17),
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF5D6975), fontSize: 17),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 10),
          child: Icon(icon, color: const Color(0xFF5D6975), size: 26),
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
          borderSide: const BorderSide(color: Color(0xFF4DB979), width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 12,
        ),
      ),
    );
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    const Center(child: BroomIcon()),
                    const SizedBox(height: 18),
                    const Text(
                      'CleanConnect',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4ED782),
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'A simple way to keep the campus clean.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        color: Color(0xFFE7EAEE),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildInputField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: AuthService.validateEmail,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      validator: (value) =>
                          (value ?? '').isEmpty ? 'Enter your password.' : null,
                      onFieldSubmitted: (_) => _signIn(),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _signIn,
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
                                'Log-in',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Forgot Password or Username?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFEDEFF2),
                              fontSize: 17,
                              decoration: TextDecoration.underline,
                              decorationThickness: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: Color(0xFF7D8694), thickness: 1.1),
                    const SizedBox(height: 18),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                        child: const Text(
                          "Don't have an account? Sign-up",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFF3F4F5),
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
