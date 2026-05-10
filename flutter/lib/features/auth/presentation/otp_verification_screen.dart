import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/toast_helper.dart';
import '../data/auth_service.dart';

class OTPVerificationScreen extends ConsumerStatefulWidget {
  final String tempToken;
  final String email;

  const OTPVerificationScreen({
    super.key,
    required this.tempToken,
    required this.email,
  });

  @override
  ConsumerState<OTPVerificationScreen> createState() =>
      _OTPVerificationScreenState();
}

class _OTPVerificationScreenState
    extends ConsumerState<OTPVerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _secondsLeft = 60;
  Timer? _timer;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: -8.0),
        weight: 1,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -8.0, end: 8.0),
        weight: 2,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 8.0, end: 0.0),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _secondsLeft = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        setState(() {});
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  String _getOtp() => _controllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final otp = _getOtp();
    if (otp.length != 6) {
      _shakeController.forward(from: 0);
      ToastHelper.show('Please enter all 6 digits', context: context);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).verifyOtp(
        tempToken: widget.tempToken,
        otpCode: otp,
      );
      ToastHelper.show('Verified successfully', context: context);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        context.go('/home');
      }
    } catch (e) {
      _shakeController.forward(from: 0);
      ToastHelper.show(e.toString(), context: context, gravity: ToastGravity.TOP);
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_secondsLeft > 0) return;
    setState(() => _isResending = true);
    try {
      final response = await ref.read(authServiceProvider).dio.post(
        '${ref.read(authServiceProvider).authBaseUrl}/resend-otp',
        data: {'temp_token': widget.tempToken},
      );
      ToastHelper.show(response.data['message'] ?? 'OTP resent', context: context);
      _startTimer();
    } catch (e) {
      ToastHelper.show(e.toString(), context: context, gravity: ToastGravity.TOP);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Widget _buildOtpBox(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFilled = _controllers[index].text.isNotEmpty;
    final isFocused = _focusNodes[index].hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 58,
      decoration: BoxDecoration(
        color: isFilled
            ? AppColors.goldPrimary.withOpacity(0.08)
            : isDark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFocused
              ? AppColors.goldPrimary
              : isFilled
                  ? AppColors.goldPrimary.withOpacity(0.5)
                  : isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
          width: isFocused ? 2.0 : 1.5,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.goldPrimary.withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: isFilled ? AppColors.goldPrimary : null,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) {
          setState(() {});
          if (v.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (v.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (_getOtp().length == 6) _verifyOtp();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('OTP Verification'),
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        foregroundColor: AppColors.goldPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Email icon circle ──────────────────────────────────
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.goldPrimary.withOpacity(0.1),
                  border: Border.all(
                    color: AppColors.goldPrimary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  color: AppColors.goldPrimary,
                  size: 30,
                ),
              ).animate().scale(
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 20),

              // ── Title ──────────────────────────────────────────────
              Text(
                'Verify your login',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.goldPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1),
              const SizedBox(height: 8),

              // ── Subtitle with bold email ───────────────────────────
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to\n'),
                    TextSpan(
                      text: widget.email,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 36),

              // ── OTP Boxes ──────────────────────────────────────────
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (ctx, child) => Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: child,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, _buildOtpBox),
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
              const SizedBox(height: 32),

              // ── Verify Button ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.goldPrimary.withOpacity(0.5),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Verify OTP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
              const SizedBox(height: 20),

              // ── Resend Row ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: AppColors.goldPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _secondsLeft > 0
                            ? 'Resend in $_secondsLeft s'
                            : "Didn't receive the code?",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed:
                        _secondsLeft > 0 || _isResending ? null : _resendOtp,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.goldPrimary,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Resend OTP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _secondsLeft > 0
                                  ? AppColors.goldPrimary.withOpacity(0.4)
                                  : AppColors.goldPrimary,
                            ),
                          ),
                  ),
                ],
              ).animate().fadeIn(delay: 350.ms),
              const SizedBox(height: 32),

              // ── Secure Note ────────────────────────────────────────
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: AppColors.goldPrimary.withOpacity(0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Secured with end-to-end encryption',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary.withOpacity(0.6)
                            : AppColors.lightTextSecondary.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
