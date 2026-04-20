// lib/screens/auth/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true, _obscure2 = true;
  bool _loading = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final result = await ApiService.post(
        '/api/auth/reset-password/${widget.token}',
        {'password': _passwordCtrl.text},
        auth: false,
      );
      if (!mounted) return;
      if (result['message']?.toString().toLowerCase().contains('success') == true ||
          result['token'] != null) {
        setState(() { _success = true; _loading = false; });
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() {
          _error = result['message'] ?? 'Reset failed. Link may have expired.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() { _error = 'Network error. Please try again.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_reset, color: Colors.white, size: 48),
                        ),
                        const SizedBox(height: 16),
                        Text('Create New Password',
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text('Enter your new password below',
                            style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.8))),
                        const SizedBox(height: 32),

                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 20, offset: const Offset(0, 8))],
                          ),
                          child: _success
                              ? Column(
                                  children: [
                                    const Icon(Icons.check_circle, color: AppColors.success, size: 60),
                                    const SizedBox(height: 14),
                                    Text('Password Reset Successful!',
                                        style: GoogleFonts.poppins(
                                            fontSize: 18, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 8),
                                    Text('Redirecting to login...',
                                        style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                                    const SizedBox(height: 16),
                                    const CircularProgressIndicator(color: AppColors.primary),
                                  ],
                                )
                              : Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (_error != null)
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 16),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(_error!,
                                              style: GoogleFonts.poppins(
                                                  color: AppColors.error, fontSize: 13)),
                                        ),
                                      TextFormField(
                                        controller: _passwordCtrl,
                                        obscureText: _obscure1,
                                        decoration: InputDecoration(
                                          labelText: 'New Password',
                                          prefixIcon: const Icon(Icons.lock_outlined),
                                          suffixIcon: IconButton(
                                            icon: Icon(_obscure1
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined),
                                            onPressed: () => setState(() => _obscure1 = !_obscure1),
                                          ),
                                        ),
                                        validator: (v) {
                                          if (v == null || v.isEmpty) return 'Required';
                                          if (v.length < 6) return 'Minimum 6 characters';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _confirmCtrl,
                                        obscureText: _obscure2,
                                        decoration: InputDecoration(
                                          labelText: 'Confirm New Password',
                                          prefixIcon: const Icon(Icons.lock_outlined),
                                          suffixIcon: IconButton(
                                            icon: Icon(_obscure2
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined),
                                            onPressed: () => setState(() => _obscure2 = !_obscure2),
                                          ),
                                        ),
                                        validator: (v) {
                                          if (v != _passwordCtrl.text) return 'Passwords do not match';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: _loading ? null : _submit,
                                          child: _loading
                                              ? const SizedBox(
                                                  height: 20, width: 20,
                                                  child: CircularProgressIndicator(
                                                      color: Colors.white, strokeWidth: 2))
                                              : Text('Reset Password',
                                                  style: GoogleFonts.poppins(
                                                      fontWeight: FontWeight.w700, fontSize: 16)),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Center(
                                        child: TextButton(
                                          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                                          child: Text('Back to Login',
                                              style: GoogleFonts.poppins(
                                                  color: AppColors.primary, fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
