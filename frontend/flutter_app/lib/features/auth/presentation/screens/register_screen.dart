import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes.dart';
import '../../../../core/providers/auth_provider.dart';

/// Registration screen with farmer/expert selection
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _expertiseController = TextEditingController();
  final _qualificationController = TextEditingController();
  
  String _selectedRole = 'FARMER';
  bool _obscurePassword = true;
  bool _isLoading = false;
  int? _experienceYears;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _expertiseController.dispose();
    _qualificationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final success = await ref.read(authStateProvider.notifier).register(
      email: email,
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      role: _selectedRole,
      expertiseDomain: _selectedRole == 'EXPERT' ? _expertiseController.text.trim() : null,
      qualification: _selectedRole == 'EXPERT' ? _qualificationController.text.trim() : null,
      experienceYears: _selectedRole == 'EXPERT' ? _experienceYears : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        // Navigate to OTP screen
        Navigator.pushNamed(
          context, 
          AppRoutes.otp,
          arguments: email,
        );
      } else {
        // Error handling is done by the provider triggering state change, 
        // but we can also use ref.listen in build, or just rely on the return value for now.
        // Since we updated provider to return bool, we rely on that.
        // We can show error from provider state if needed.
        final authState = ref.read(authStateProvider);
        if (authState.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authState.error.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.orange),
            SizedBox(width: 8),
            Text('Application Submitted'),
          ],
        ),
        content: const Text(
          'Your expert application has been submitted and is pending approval. '
          'You will be able to access expert features once an admin approves your application.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, AppRoutes.expertDashboard);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Role selection
                Text(
                  'I am a...',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        title: 'Farmer',
                        icon: Icons.agriculture,
                        isSelected: _selectedRole == 'FARMER',
                        onTap: () => setState(() => _selectedRole = 'FARMER'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _RoleCard(
                        title: 'Expert',
                        icon: Icons.school,
                        isSelected: _selectedRole == 'EXPERT',
                        onTap: () => setState(() => _selectedRole = 'EXPERT'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Full name
                TextFormField(
                  controller: _fullNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Phone (Optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Confirm password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                
                // Expert-specific fields
                if (_selectedRole == 'EXPERT') ...[
                  const SizedBox(height: 24),
                  Text(
                    'Expert Information',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  
                  TextFormField(
                    controller: _expertiseController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Area of Expertise',
                      prefixIcon: Icon(Icons.category_outlined),
                      hintText: 'e.g., Plant Pathology, Crop Science',
                    ),
                    validator: (value) {
                      if (_selectedRole == 'EXPERT' && (value == null || value.isEmpty)) {
                        return 'Please enter your expertise area';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _qualificationController,
                    maxLines: 2,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Qualifications',
                      prefixIcon: Icon(Icons.school_outlined),
                      hintText: 'Your degree and certifications',
                    ),
                    validator: (value) {
                      if (_selectedRole == 'EXPERT' && (value == null || value.isEmpty)) {
                        return 'Please enter your qualifications';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<int>(
                    value: _experienceYears,
                    decoration: const InputDecoration(
                      labelText: 'Years of Experience',
                      prefixIcon: Icon(Icons.work_history_outlined),
                    ),
                    items: List.generate(30, (i) => i + 1)
                        .map((year) => DropdownMenuItem(
                              value: year,
                              child: Text('$year ${year == 1 ? 'year' : 'years'}'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _experienceYears = value);
                    },
                    validator: (value) {
                      if (_selectedRole == 'EXPERT' && value == null) {
                        return 'Please select years of experience';
                      }
                      return null;
                    },
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Expert notice
                if (_selectedRole == 'EXPERT')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Expert accounts require admin approval before you can answer questions.',
                            style: TextStyle(color: Colors.orange.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_selectedRole == 'EXPERT') const SizedBox(height: 16),
                
                // Register button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_selectedRole == 'EXPERT' 
                            ? 'Submit Application' 
                            : 'Create Account'),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary 
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
