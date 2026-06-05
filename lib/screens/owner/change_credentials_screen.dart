import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../providers/session_provider.dart';
import '../../utils/theme.dart';
import '../splash_screen.dart';

class ChangeCredentialsScreen extends StatefulWidget {
  const ChangeCredentialsScreen({super.key});

  @override
  State<ChangeCredentialsScreen> createState() =>
      _ChangeCredentialsScreenState();
}

class _ChangeCredentialsScreenState extends State<ChangeCredentialsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Current credentials
  final _currentUsernameCtrl = TextEditingController();
  final _currentPasswordCtrl = TextEditingController();

  // New credentials
  final _newUsernameCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();

  bool _loading = false;
  bool _verified = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  Future<void> _verifyCurrent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final valid = await FirebaseService.instance.validateOwner(
        _currentUsernameCtrl.text.trim(),
        _currentPasswordCtrl.text,
      );
      if (!mounted) return;
      if (valid) {
        setState(() => _verified = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current credentials are incorrect'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveNew() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseService.instance.updateOwnerCredentials(
        username: _newUsernameCtrl.text.trim(),
        password: _newPasswordCtrl.text,
      );
      if (!mounted) return;
      await context.read<SessionProvider>().logout();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credentials updated! Please log in again.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
            (r) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _currentUsernameCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newUsernameCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Change Credentials')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Verify your current credentials first, then set new ones.',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── STEP 1: Verify current ──────────────────────────────────
              _StepHeader(number: '1', title: 'Verify Current Credentials', done: _verified),
              const SizedBox(height: 14),

              TextFormField(
                controller: _currentUsernameCtrl,
                enabled: !_verified,
                decoration: InputDecoration(
                  labelText: 'Current Username',
                  prefixIcon: const Icon(Icons.person_outline_rounded,
                      color: AppColors.textGrey),
                  suffixIcon: _verified
                      ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.success)
                      : null,
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currentPasswordCtrl,
                enabled: !_verified,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      color: AppColors.textGrey),
                  suffixIcon: _verified
                      ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.success)
                      : IconButton(
                    icon: Icon(
                      _obscureCurrent
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textGrey,
                    ),
                    onPressed: () => setState(
                            () => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                validator: (v) =>
                v == null || v.isEmpty ? 'Required' : null,
              ),

              if (!_verified) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _verifyCurrent,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                    ),
                    child: _loading
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    )
                        : Text('Verify',
                        style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],

              // ── STEP 2: Set new credentials ─────────────────────────────
              if (_verified) ...[
                const SizedBox(height: 28),
                _StepHeader(number: '2', title: 'Set New Credentials', done: false),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _newUsernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'New Username',
                    prefixIcon: Icon(Icons.person_rounded, color: AppColors.primary),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (v.trim().length < 4) return 'At least 4 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newPasswordCtrl,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_rounded,
                        color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textGrey,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '⚠️ You will be logged out after saving.',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.warning),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _saveNew,
                    icon: _loading
                        ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Save New Credentials'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step Header Widget ───────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final String number;
  final String title;
  final bool done;

  const _StepHeader({
    required this.number,
    required this.title,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: done ? AppColors.success : AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text(
              number,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}