import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:clean_connect/services/auth_service.dart';
import 'package:clean_connect/services/user_service.dart';
import 'package:clean_connect/models/app_user_model.dart';
import '../../app/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService authService = AuthService();
  final UserService userService = UserService();

  bool isLoading = false;
  bool isPasswordVisible = false;

  final Color backgroundColor = const Color(0xFF252633);
  final Color inputColor = const Color(0xFFD9D9D9);
  final Color buttonColor = const Color(0xFF7CCFA3);
  final Color iconColor = const Color(0xFFAFF4D0);

  // The Login user fr fr
  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Pangauthenticate ng user
      UserCredential credential = await authService.loginUser(
        emailController.text.trim(),
        passwordController.text,

        
      );
      if(!mounted) return;

      // pangretrieve ng profile ni user sa Firestore
      AppUserModel? user = await userService.getUser(
        credential.user!.uid,
      );

      if(!mounted) return;

      if (user == null) {
        await authService.logoutUser();
        throw Exception('User profile not found.');
      }

      if (!mounted) return;

      if (user.status != 'active') {
        await authService.logoutUser();
        throw Exception('Your account is inactive.');
      }

      if (!mounted) return;

      // navigate kung ano role ni user
      switch (user.role.toLowerCase()) {
        case 'student':
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.studentDashboard,
          );
          break;

        case 'staff':
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.staffDashboard,
          );
          break;

        case 'admin':
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.adminDashboard,
          );
          break;

        default:
          await authService.logoutUser();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid account role.'),
            ),
          );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        default:
          message = e.message ?? 'Login failed.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );

    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // INPUT FIELD DESIGN
  Widget buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 13,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.black,
          size: 21,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: inputColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 17,
          horizontal: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: buttonColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 25,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [

                    // broom icon
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: iconColor,
                      child: const Icon(
                        Icons.cleaning_services,
                        color: Colors.black,
                        size: 48,
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Log-in',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 26),

                    const Text(
                      'Welcome to Clean Connect',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'A simple way to keep the campus space clean.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 45),

                    // email input
                    buildInputField(
                      controller: emailController,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email.';
                        }

                        if (!RegExp(
                          r'^[^@]+@[^@]+\.[^@]+$',
                        ).hasMatch(value.trim())) {
                          return 'Please enter a valid email.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    // password input
                    buildInputField(
                      controller: passwordController,
                      hint: 'Password',
                      icon: Icons.key_outlined,
                      obscureText: !isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.black,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    // button ng login
                    SizedBox(
                      width: double.infinity,
                      height: 43,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Log-In',
                                style: TextStyle(fontSize: 12),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // forgot password
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.forgotPassword,
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Divider(
                      color: Colors.white70,
                      thickness: 0.5,
                    ),

                    const SizedBox(height: 15),

                    // signup
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.register,
                            );
                          },
                          child: const Text(
                            'Sign-up',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
