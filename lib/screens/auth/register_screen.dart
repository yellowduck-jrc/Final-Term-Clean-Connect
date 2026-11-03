
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/app_user_model.dart';
import '../../app/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final AuthService authService = AuthService();
  final UserService userService = UserService();

  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  final Color backgroundColor = const Color(0xFF252633);
  final Color inputColor = const Color(0xFFD9D9D9);
  final Color buttonColor = const Color(0xFF7CCFA3);
  final Color iconColor = const Color(0xFFAFF4D0);

  //The register account fr fr

Future<void> register() async {
  debugPrint('1. Registration started');

  if (!formKey.currentState!.validate()) {
    debugPrint('2. Form validation failed');
    return;
  }

  debugPrint('2. Form validation successful');

  setState(() {
    isLoading = true;
  });

  try {
    debugPrint('3. Before Firebase Authentication');

    UserCredential credential = await authService.registerUser(
      emailController.text.trim(),
      passwordController.text,
    );

    debugPrint('4. Firebase Authentication successful');

    AppUserModel newUser = AppUserModel(
      uid: credential.user!.uid,
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      role: 'student',
      status: 'active',
    );

    debugPrint('5. Before saving user to Firestore');

    await userService.createUser(newUser);

    debugPrint('6. Firestore profile created');

    await authService.logoutUser();

    debugPrint('7. Firebase logout successful');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account created successfully! Please log in.'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.login,
    );

  } on FirebaseAuthException catch (e) {
    debugPrint('FIREBASE AUTH ERROR: ${e.code} - ${e.message}');

    if (!mounted) return;

    String message;

    switch (e.code) {
      case 'email-already-in-use':
        message = 'this email is already registered';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email address.';
        break;
      case 'weak-password':
        message = 'Password must be at least 6 characters.';
        break;
      default:
        message = e.message ?? 'Registration failed.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

  } catch (e) {
    debugPrint('REGISTRATION ERROR: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Something went wrong: $e'),
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
  void dispose(){
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  //The design of Register screen


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
        errorStyle: const TextStyle(
          color: Colors.redAccent,
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
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // Icon ng broom
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

                    // yung title in between
                    const Text(
                      'Sign-in',
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

                    // kung saan sila magtytype
                    buildInputField(
                      controller: nameController,
                      hint: 'Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name.';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

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
                          return 'Please enter a password.';
                        }

                        if (value.length < 6) {
                          return 'Password must be at least 6 characters.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    buildInputField(
                      controller: confirmPasswordController,
                      hint: 'Confirm Password',
                      icon: Icons.check,
                      obscureText: !isConfirmPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.black,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            isConfirmPasswordVisible =
                                !isConfirmPasswordVisible;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password.';
                        }

                        if (value != passwordController.text) {
                          return 'Passwords do not match.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    // SIGN UP BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 43,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                debugPrint('SIGN-IN BUTTON PRESSED');
                                register();
                              },
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
                                'Sign-In',
                                style: TextStyle(fontSize: 12),
                              ),
                      ),
                    ),

                    const SizedBox(height: 35),

                    // LOGIN NAVIGATION
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(
                              context,
                              AppRoutes.login,
                            );
                          },
                          child: const Text(
                            'Log-in',
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
