import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_helper.dart';
import '../data/auth_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ToastHelper.show("Tamam fields pur karein", context: context);
      return;
    }

    if (password != confirmPass) {
      ToastHelper.show("Passwords match nahi kar rahay", context: context);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signUp(
            fullName: name,
            email: email,
            password: password,
          );
      
      // Update local state
      final session = await ref.read(authServiceProvider).loadSession();
      ref.read(authStateProvider.notifier).setSession(session);
      
      ToastHelper.show("Account created successfully! Welcome.", context: context);
      if (mounted) context.go('/home');
    } catch (e) {
      ToastHelper.show(e.toString(), context: context, gravity: ToastGravity.TOP);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.goldPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        "Create Account",
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: AppColors.goldPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 36,
                            ),
                      ).animate().fadeIn(duration: 600.ms).moveY(begin: -20, end: 0),
                      const SizedBox(height: 10),
                      Text(
                        "Start your recitation journey today",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                      ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                      const SizedBox(height: 40),

                      // Floating Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildTextField("Full Name", Icons.person_outline, _nameController, isDark)
                                .animate()
                                .fadeIn(delay: 400.ms, duration: 400.ms)
                                .slideX(begin: 0.1, end: 0),
                            const SizedBox(height: 20),
                            _buildTextField("Email Address", Icons.email_outlined, _emailController, isDark)
                                .animate()
                                .fadeIn(delay: 600.ms, duration: 400.ms)
                                .slideX(begin: 0.1, end: 0),
                            const SizedBox(height: 20),
                            _buildTextField("Password", Icons.lock_outline, _passController, isDark, isPassword: true)
                                .animate()
                                .fadeIn(delay: 800.ms, duration: 400.ms)
                                .slideX(begin: 0.1, end: 0),
                            const SizedBox(height: 20),
                            _buildTextField("Confirm Password", Icons.lock_clock_outlined, _confirmPassController,
                                    isDark, isPassword: true)
                                .animate()
                                .fadeIn(delay: 1000.ms, duration: 400.ms)
                                .slideX(begin: 0.1, end: 0),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.goldPrimary,
                                foregroundColor: isDark ? AppColors.darkBg : Colors.white,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      "Create Account",
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                            ).animate().fadeIn(delay: 1200.ms).scale(begin: const Offset(0.9, 0.9)),
                          ],
                        ),
                      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),

                      const Spacer(),
                      const SizedBox(height: 40),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                            TextButton(
                              onPressed: () => context.pop(),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              child: const Text("Sign In",
                                  style: TextStyle(color: AppColors.goldPrimary, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 1400.ms),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, bool isDark,
      {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.goldPrimary, size: 20),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey[100],
            border: const UnderlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.goldPrimary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}
