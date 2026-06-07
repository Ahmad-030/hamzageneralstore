import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../providers/session_provider.dart';
import '../../utils/theme.dart';
import 'owner_dashboard.dart';

class OwnerLoginScreen extends StatefulWidget {
  const OwnerLoginScreen({super.key});

  @override
  State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;
  int _failedAttempts = 0;
  bool _locked = false;

  Future<void> _login() async {
    if (_locked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Too many failed attempts. Wait a moment.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final valid = await FirebaseService.instance.validateOwner(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (!mounted) return;
      if (valid) {
        _failedAttempts = 0;
        await context.read<SessionProvider>().loginOwner();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OwnerDashboardScreen()),
        );
      } else {
        _failedAttempts++;
        // Lock after 5 wrong attempts for 10 seconds
        if (_failedAttempts >= 5) {
          setState(() => _locked = true);
          Future.delayed(const Duration(seconds: 10), () {
            if (mounted) setState(() { _locked = false; _failedAttempts = 0; });
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('5 failed attempts. Locked for 10 seconds.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 10),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Invalid credentials. ${5 - _failedAttempts} attempts remaining.'),
            backgroundColor: AppColors.error,
          ));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Owner Login'),
        backgroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Lock icon
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.store_rounded,
                    color: AppColors.primaryDark, size: 42),
              ),
              const SizedBox(height: 20),
              Text('Owner Access',
                  style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Enter your credentials to continue',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textGrey)),

              const SizedBox(height: 36),

              // Username
              TextFormField(
                controller: _usernameCtrl,
                enabled: !_locked,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline_rounded,
                      color: AppColors.textGrey),
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter username' : null,
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                enabled: !_locked,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      color: AppColors.textGrey),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textGrey,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) =>
                v == null || v.isEmpty ? 'Enter password' : null,
              ),

              const SizedBox(height: 28),

              // Locked warning
              if (_locked)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_rounded,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Text('Account temporarily locked.',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.error,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_loading || _locked) ? null : _login,
                  child: _loading
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Text('Login'),
                ),
              ),

              const SizedBox(height: 24),

            ],
          ),
        ),
      ),
    );
  }
}