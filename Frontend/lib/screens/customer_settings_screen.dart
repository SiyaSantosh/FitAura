import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../styles/profile_styles.dart';

class CustomerSettingsScreen extends StatefulWidget {
  final int userId;

  const CustomerSettingsScreen({super.key, required this.userId});

  @override
  State<CustomerSettingsScreen> createState() => _CustomerSettingsScreenState();
}

class _CustomerSettingsScreenState extends State<CustomerSettingsScreen> {
  String _language = 'English';
  String _themeMode = 'Light';
  final List<String> _languages = ['English'];
  final List<String> _themeModes = ['Light'];
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileStyles.whiteColor,
      appBar: AppBar(
        backgroundColor: ProfileStyles.whiteColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ProfileStyles.darkTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ProfileStyles.darkTextColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Preferences',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ProfileStyles.darkTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: ProfileStyles.beigeBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ProfileStyles.borderColor),
              ),
              child: Column(
                children: [
                  _buildDropdownRow(
                    label: 'Language',
                    value: _language,
                    items: _languages,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _language = value);
                      }
                    },
                  ),
                  _buildDivider(),
                  _buildDropdownRow(
                    label: 'Theme',
                    value: _themeMode,
                    items: _themeModes,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _themeMode = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ProfileStyles.darkTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: ProfileStyles.beigeBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ProfileStyles.borderColor),
              ),
              child: ListTile(
                leading: const Icon(Icons.lock_outline, color: ProfileStyles.primaryColor),
                title: const Text('Change password'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showChangePasswordDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ProfileStyles.darkTextColor,
              ),
            ),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.keyboard_arrow_down, color: ProfileStyles.darkTextColor),
            items: items
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(color: ProfileStyles.darkTextColor),
                    ),
                  ),
                )
                .toList(),
            onChanged: items.length > 1 ? onChanged : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Colors.transparent, height: 0);
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? errorText,
    bool obscureText = false,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: ProfileStyles.darkTextColor.withOpacity(0.7)),
            prefixIcon: Icon(icon, color: ProfileStyles.primaryColor, size: 20),
            filled: true,
            fillColor: ProfileStyles.beigeBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: errorText != null ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: errorText != null ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: errorText != null ? const BorderSide(color: Colors.red, width: 2.0) : const BorderSide(color: ProfileStyles.primaryColor, width: 2.0),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }

  void _showChangePasswordDialog() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _currentPasswordError = null;
    _newPasswordError = null;
    _confirmPasswordError = null;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: ProfileStyles.whiteColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Center(
              child: Text(
                'Change Password',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPasswordField(
                    _currentPasswordController,
                    'Current Password',
                    Icons.lock_outline,
                    errorText: _currentPasswordError,
                    obscureText: true,
                    onChanged: (_) {
                      setDialogState(() => _currentPasswordError = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    _newPasswordController,
                    'New Password',
                    Icons.lock_reset_outlined,
                    errorText: _newPasswordError,
                    obscureText: true,
                    onChanged: (_) {
                      setDialogState(() => _newPasswordError = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    _confirmPasswordController,
                    'Confirm New Password',
                    Icons.lock_clock_outlined,
                    errorText: _confirmPasswordError,
                    obscureText: true,
                    onChanged: (_) {
                      setDialogState(() => _confirmPasswordError = null);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: ProfileStyles.lightGrayColor)),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final currentPassword = _currentPasswordController.text.trim();
                        final newPassword = _newPasswordController.text.trim();
                        final confirmPassword = _confirmPasswordController.text.trim();

                        bool isValid = true;
                        if (currentPassword.isEmpty) {
                          setDialogState(() => _currentPasswordError = 'Current password is required');
                          isValid = false;
                        }
                        if (newPassword.isEmpty) {
                          setDialogState(() => _newPasswordError = 'New password is required');
                          isValid = false;
                        } else if (newPassword.length < 8) {
                          setDialogState(() => _newPasswordError = 'Min 8 characters');
                          isValid = false;
                        } else if (!RegExp(r'[a-zA-Z]').hasMatch(newPassword) || !RegExp(r'[0-9]').hasMatch(newPassword)) {
                          setDialogState(() => _newPasswordError = 'Must contain 1 alphabet and 1 number');
                          isValid = false;
                        }
                        if (confirmPassword != newPassword) {
                          setDialogState(() => _confirmPasswordError = 'Passwords do not match');
                          isValid = false;
                        }

                        if (!isValid) return;

                        setDialogState(() => isLoading = true);
                        final result = await ApiService.changePassword(
                          userId: widget.userId,
                          currentPassword: currentPassword,
                          newPassword: newPassword,
                        );
                        setDialogState(() => isLoading = false);

                        if (result['success']) {
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        } else {
                          final message = result['message'] ?? 'Failed to change password';
                          if (message.toLowerCase().contains('current') || message.toLowerCase().contains('incorrect')) {
                            setDialogState(() => _currentPasswordError = message);
                          } else {
                            setDialogState(() => _newPasswordError = message);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProfileStyles.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Password', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}
