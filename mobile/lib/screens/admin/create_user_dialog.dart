import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../providers/users_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';

class CreateUserDialog extends ConsumerStatefulWidget {
  const CreateUserDialog({super.key});

  @override
  ConsumerState<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  UserRole _role = UserRole.teacher;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final user = await ref.read(usersServiceProvider).createUser(
        email: _emailCtrl.text.trim(),
        fullName: _nameCtrl.text.trim(),
        password: _passwordCtrl.text,
        role: _role,
        phone: _phoneCtrl.text.trim(),
      );
      // ignore: unused_result
      ref.refresh(allUsersProvider);
      if (mounted) Navigator.of(context).pop(user);
    } catch (e) {
      setState(() {
        _error = e.toString().contains('занят') || e.toString().contains('уже')
            ? 'Этот email уже занят'
            : 'Ошибка создания пользователя';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Новый пользователь',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF888888)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Role selector
              const Text('Роль', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _RoleChip(
                    label: 'Преподаватель',
                    icon: Icons.school_outlined,
                    selected: _role == UserRole.teacher,
                    onTap: () => setState(() => _role = UserRole.teacher),
                  ),
                  const SizedBox(width: 10),
                  _RoleChip(
                    label: 'Администратор',
                    icon: Icons.admin_panel_settings_outlined,
                    selected: _role == UserRole.admin,
                    onTap: () => setState(() => _role = UserRole.admin),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13)),
                ),
                const SizedBox(height: 12),
              ],

              AppTextField(
                controller: _nameCtrl,
                label: 'Полное имя',
                prefixIcon: Icons.person_outlined,
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'Введите имя' : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _emailCtrl,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Неверный email' : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _phoneCtrl,
                label: 'Телефон (необязательно)',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _passwordCtrl,
                label: 'Пароль',
                obscureText: _obscure,
                prefixIcon: Icons.lock_outlined,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFF888888),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                validator: (v) => (v == null || v.length < 8)
                    ? 'Минимум 8 символов'
                    : null,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black)),
                      )
                    : const Text('Создать'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.gold.withAlpha(20) : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.gold : const Color(0xFF2A2A2A),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? AppTheme.gold : const Color(0xFF888888)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? AppTheme.gold : const Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
