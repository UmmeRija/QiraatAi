import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_helper.dart';
import '../data/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '1086004720596-fqp1bocbuvm5p9o77lu9buih6jjmectr.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ToastHelper.show("Please enter email and password", context: context);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final loginResponse = await ref
          .read(authServiceProvider)
          .login(email: email, password: password);

      if (loginResponse['requires_2fa'] == true &&
          loginResponse['temp_token'] != null) {
        if (mounted) {
          context.push(
            '/otp-verification',
            extra: {'temp_token': loginResponse['temp_token'], 'email': email},
          );
        }
        return;
      }

      await ref.read(authServiceProvider).loadSession();
      final session = await ref.read(authServiceProvider).loadSession();
      ref.read(authStateProvider.notifier).setSession(session);

      if (mounted) context.go('/home');
    } catch (e) {
      ToastHelper.show(e.toString(), context: context, gravity: ToastGravity.TOP);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Exception('Failed to obtain Google ID token');
      }

      await ref
          .read(authServiceProvider)
          .signInWithGoogle(googleIdToken: idToken);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      ToastHelper.show(e.toString(), context: context, gravity: ToastGravity.TOP);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    if (mounted) {
      context.push('/forgot-password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
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
                        const SizedBox(height: 80),
                        Text(
                              "Welcome Back",
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(
                                    color: AppColors.goldPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 40,
                                  ),
                            )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .moveY(begin: -20, end: 0),
                        const SizedBox(height: 10),
                        Text(
                          "Sign in to continue your journey",
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                        const SizedBox(height: 40),

                        // Floating Card
                        Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.lightSurface,
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
                                  _buildTextField(
                                    "Email Address",
                                    Icons.email_outlined,
                                    _emailController,
                                    isDark,
                                  ).animate().fadeIn(
                                    delay: 400.ms,
                                    duration: 400.ms,
                                  ),
                                  const SizedBox(height: 24),
                                  _buildTextField(
                                    "Password",
                                    Icons.lock_outline,
                                    _passController,
                                    isDark,
                                    isPassword: true,
                                  ).animate().fadeIn(
                                    delay: 550.ms,
                                    duration: 400.ms,
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _handleForgotPassword,
                                      child: Text(
                                        "Forgot Password?",
                                        style: TextStyle(
                                          color: AppColors.goldPrimary
                                              .withOpacity(0.8),
                                        ),
                                      ),
                                    ),
                                  ).animate().fadeIn(delay: 700.ms),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.goldPrimary,
                                          foregroundColor: isDark
                                              ? AppColors.darkBg
                                              : Colors.white,
                                          minimumSize: const Size(
                                            double.infinity,
                                            56,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: _isLoading
                                            ? const CircularProgressIndicator(
                                                color: Colors.white,
                                              )
                                            : const Text(
                                                "Sign In",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      )
                                      .animate()
                                      .fadeIn(delay: 850.ms)
                                      .scale(begin: const Offset(0.9, 0.9)),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: isDark
                                              ? AppColors.darkBorder
                                              : AppColors.lightBorder,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          "OR",
                                          style: TextStyle(
                                            color: isDark
                                                ? AppColors.darkTextHint
                                                : AppColors.lightTextHint,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: isDark
                                              ? AppColors.darkBorder
                                              : AppColors.lightBorder,
                                        ),
                                      ),
                                    ],
                                  ).animate().fadeIn(delay: 1000.ms),
                                  const SizedBox(height: 24),
                                  _socialButton(
                                    "Continue with Google",
                                    Icons.g_mobiledata_rounded,
                                    isDark,
                                    onTap: _handleGoogleSignIn,
                                  ).animate().fadeIn(delay: 1150.ms),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .slideY(
                              begin: 0.1,
                              end: 0,
                              curve: Curves.easeOutCubic,
                            ),

                        const Spacer(),
                        const SizedBox(height: 40),
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.push('/register'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    color: AppColors.goldPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 1300.ms),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller,
    bool isDark, {
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
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
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
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

  Widget _socialButton(
    String label,
    IconData icon,
    bool isDark, {
    VoidCallback? onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 28, color: AppColors.goldPrimary),
      label: Text(label, style: const TextStyle(color: AppColors.goldPrimary)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: AppColors.goldPrimary.withOpacity(0.5)),
      ),
    );
  }
}
