import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/providers/auth_provider.dart';

/// Screen for entering OTP
class OtpScreen extends ConsumerStatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    await ref.read(authStateProvider.notifier).verifyOtp(
      email: widget.email,
      otp: otp,
    );
    
    // Auth provider will update state and trigger navigation listener in app.dart
    // But we check for error manually here just in case
    if (mounted) {
       final authState = ref.read(authStateProvider);
       if (authState.hasError) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(authState.error.toString()), backgroundColor: Colors.red),
         );
         setState(() => _isLoading = false);
       } else if (authState.hasValue && authState.value != null) {
          // Success handled by global listener usually, but explicit push helps
          if (authState.value!.isPendingExpert) {
             _showPendingDialog();
          } else if (authState.value!.isExpert) {
             Navigator.pushNamedAndRemoveUntil(context, AppRoutes.expertDashboard, (route) => false);
          } else {
             Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
          }
       }
    }
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Application Pending'),
        content: const Text('Your expert application is pending approval.'),
        actions: [
          ElevatedButton(
            onPressed: () {
               Navigator.pushNamedAndRemoveUntil(context, AppRoutes.expertDashboard, (route) => false);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 80, color: AppTheme.primaryGreen),
            const SizedBox(height: 24),
            Text(
              'Verification Code Sent',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a 6-digit code to\n${widget.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Text(
                'Development Mode: Check your backend console/terminal for the code.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '000000',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white)) 
                    : const Text('Verify'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
