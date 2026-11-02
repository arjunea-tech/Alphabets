import 'package:flutter/material.dart';
import '../../models/avatar_model.dart';
import '../../services/auth_service.dart';
import '../../services/progress_service.dart';
import '../../services/tamil_transliteration_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/mascot_widget.dart';
import '../auth/login_screen.dart';
import '../language/language_selection_screen.dart';
import '../profile/profile_screen.dart';
import '../writing/writing_history_screen.dart';
import '../../services/language_service.dart';

class SettingsScreen extends StatefulWidget {
  final ProgressService progressService;

  const SettingsScreen({super.key, required this.progressService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  final AuthService _authService = AuthService();
  String _liveTamilPreview = '';

  @override
  void initState() {
    super.initState();
    _authService.loadSession();
    _nameController = TextEditingController(text: widget.progressService.childName);
    _liveTamilPreview = TamilTransliterationService.toTamil(widget.progressService.childName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveName() {
    final text = _nameController.text.trim();
    if (text.isNotEmpty) {
      widget.progressService.updateProfile(
        name: text,
        avatarIndex: widget.progressService.avatarIndex,
      );
      final converted = TamilTransliterationService.toTamil(text);
      setState(() {
        _liveTamilPreview = converted;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: AppColors.mintGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progressService;

    return Scaffold(
      appBar: KidAppBar(
        title: 'Settings',
        starCount: progress.stars,
      ),
      body: KidScaffoldBackground(
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Profile Section with Character Avatars
                    _buildSectionHeader('My Profile', Icons.person_rounded),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar Selection Header
                          Text(
                            'Choose Avatar',
                            style: AppTextStyles.cardSubtitle.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Character Avatar Horizontal List
                          SizedBox(
                            height: 94,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: AppAvatar.list.length,
                              separatorBuilder: (ctx, idx) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final avatar = AppAvatar.list[index];
                                final isSelected = progress.avatarIndex == index;

                                return GestureDetector(
                                  onTap: () {
                                    progress.updateProfile(
                                      name: progress.childName,
                                      avatarIndex: index,
                                    );
                                  },
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected ? AppColors.primary : Colors.transparent,
                                            width: 3.5,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors.primary.withValues(alpha: 0.35),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: CircleAvatar(
                                          radius: 28,
                                          backgroundColor: const Color(0xFFFFF3CD),
                                          backgroundImage: AssetImage(avatar.assetPath),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        avatar.label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                          color: isSelected ? AppColors.primaryDark : AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Name TextField (with live Tamil transliteration)
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  style: AppTextStyles.bodyTextBold.copyWith(fontSize: 18),
                                  onChanged: (val) {
                                    setState(() {
                                      _liveTamilPreview = TamilTransliterationService.toTamil(val);
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Child Name (e.g. Alex)',
                                    labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                    filled: true,
                                    fillColor: AppColors.background,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: BorderSide.none,
                                    ),
                                    prefixIcon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              BouncyButton(
                                onPressed: _saveName,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: AppColors.orangeGradient),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Save',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Live Tamil name preview tag
                          if (_liveTamilPreview.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4E5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Preview: ', style: TextStyle(fontSize: 12, color: Color(0xFF78350F))),
                                  Text(
                                    _liveTamilPreview,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Action buttons: View Profile & Writing Records
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF6B6B),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    elevation: 2,
                                  ),
                                  icon: const Icon(Icons.person_rounded, size: 18),
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'View Profile',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProfileScreen(progressService: progress),
                                      ),
                                    ).then((_) {
                                      if (mounted) {
                                        setState(() {
                                          _nameController.text = progress.childName;
                                          _liveTamilPreview = progress.childName;
                                        });
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3A86FF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    elevation: 2,
                                  ),
                                  icon: const Icon(Icons.history_edu_rounded, size: 18),
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Practice Records',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const WritingHistoryScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. Sound Settings
                    _buildSectionHeader('Audio & Sounds', Icons.volume_up_rounded),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          title: Text(
                            'Sound Effects & Music',
                            style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
                          ),
                          subtitle: const Text('Letter pronunciation and sound effects'),
                          value: progress.soundEnabled,
                          activeThumbColor: AppColors.secondary,
                          onChanged: (val) {
                            progress.toggleSound(val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2.5 Language Selection
                    _buildSectionHeader('Language', Icons.translate_rounded),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              LanguageService.instance.currentLanguage.flagEmoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                          title: Text(
                            '${LanguageService.instance.currentLanguage.nativeName} (${LanguageService.instance.currentLanguage.name})',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          subtitle: const Text(
                            'Selected Language: English',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LanguageSelectionScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. About AGARAM
                    _buildSectionHeader('About App', Icons.info_outline_rounded),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const MascotWidget(
                                pose: MascotPose.welcome,
                                size: MascotSize.small,
                                customHeight: 80,
                                animate: false,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ALPHABETS', style: AppTextStyles.cardTitle.copyWith(fontSize: 18)),
                                    const SizedBox(height: 2),
                                    Text('“Learn English Alphabets from A to Z!”', style: AppTextStyles.tagLine),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'ALPHABETS is an engaging early learning app designed for kids to master the 26 English alphabets, phonics, writing, and vocabulary.',
                            style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. Reset Progress
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              title: const Text('Reset Progress?'),
                              content: const Text('Stars and lesson progress will be reset to start.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.playfulPink),
                                  onPressed: () {
                                    progress.resetProgress();
                                    setState(() {
                                      _nameController.text = 'Kid';
                                      _liveTamilPreview = 'Kid';
                                    });
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Yes, Reset'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.playfulPink),
                        label: const Text(
                          'Reset Progress',
                          style: TextStyle(color: AppColors.playfulPink, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 5. Account & Logout Section (If authenticated)
                    if (_authService.currentUser != null) ...[
                      _buildSectionHeader('Account', Icons.lock_outline_rounded),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.account_circle_rounded, color: AppColors.primaryDark, size: 28),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _authService.currentUser!.name,
                                        style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
                                      ),
                                      if (_authService.currentUser!.email.isNotEmpty)
                                        Text(
                                          _authService.currentUser!.email,
                                          style: AppTextStyles.cardSubtitle.copyWith(fontSize: 13),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const Divider(height: 1),
                            const SizedBox(height: 18),

                            // Logout Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFEBEB),
                                  foregroundColor: const Color(0xFFE53E3E),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    side: const BorderSide(color: Color(0xFFFFC5C5)),
                                  ),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                      title: const Text('Sign Out?'),
                                      content: const Text('You will need to sign in again to access your account.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.playfulPink),
                                          onPressed: () async {
                                            Navigator.pop(ctx);
                                            await _authService.logout();
                                            if (context.mounted) {
                                              Navigator.of(context).pushAndRemoveUntil(
                                                MaterialPageRoute(
                                                  builder: (_) => LoginScreen(
                                                    authService: _authService,
                                                    progressService: widget.progressService,
                                                  ),
                                                ),
                                                (route) => false,
                                              );
                                            }
                                          },
                                          child: const Text('Sign Out'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.logout_rounded, size: 20),
                                label: const Text(
                                  'Sign Out (Logout)',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 18,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
