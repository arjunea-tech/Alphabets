import 'package:flutter/material.dart';
import '../../models/avatar_model.dart';
import '../../services/auth_service.dart';
import '../../services/progress_service.dart';
import '../../services/writing_practice_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/mascot_widget.dart';
import '../auth/login_screen.dart';
import '../language/language_selection_screen.dart';
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
  final WritingPracticeRepository _writingRepo = LocalWritingPracticeRepository();
  int _practicedLetters = 0;
  int _totalPractices = 0;

  @override
  void initState() {
    super.initState();
    _authService.loadSession();
    _nameController = TextEditingController(text: widget.progressService.childName);
    _loadWritingStats();
  }

  Future<void> _loadWritingStats() async {
    final practiced = await _writingRepo.getPracticedLettersCount();
    final total = await _writingRepo.getTotalPracticesCount();
    if (mounted) {
      setState(() {
        _practicedLetters = practiced;
        _totalPractices = total;
      });
    }
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
      FocusScope.of(context).unfocus();
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

    // Rebuild when stars / avatar / age change so the profile card stays current
    return ListenableBuilder(
      listenable: progress,
      builder: (context, _) => Scaffold(
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
                    // 2. Edit Profile: avatar, name, age
                    _buildSectionHeader('Edit Profile', Icons.person_rounded),
                    _buildCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Choose Avatar'),
                          const SizedBox(height: 12),
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
                          const SizedBox(height: 20),

                          _buildFieldLabel('Child Name'),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 54,
                                  child: TextField(
                                    controller: _nameController,
                                    style: AppTextStyles.bodyTextBold.copyWith(fontSize: 18),
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _saveName(),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. Alex',
                                      filled: true,
                                      fillColor: AppColors.background,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: BorderSide.none,
                                      ),
                                      prefixIcon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              BouncyButton(
                                onPressed: _saveName,
                                child: Container(
                                  height: 54,
                                  padding: const EdgeInsets.symmetric(horizontal: 22),
                                  alignment: Alignment.center,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. Learning Progress
                    _buildSectionHeader('Learning Progress', Icons.insights_rounded),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.stars_rounded,
                            iconColor: const Color(0xFFFFB703),
                            title: 'Total Stars',
                            value: '${progress.stars}',
                            bgColor: const Color(0xFFFFFBEB),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.menu_book_rounded,
                            iconColor: const Color(0xFF3A86FF),
                            title: 'Letters Learned',
                            value: '${progress.completedLettersCount}',
                            bgColor: const Color(0xFFEFF6FF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.edit_note_rounded,
                            iconColor: const Color(0xFF06D6A0),
                            title: 'Writing Practiced',
                            value: '$_practicedLetters Letters',
                            bgColor: const Color(0xFFECFDF5),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.history_rounded,
                            iconColor: const Color(0xFFFF6B6B),
                            title: 'Total Practices',
                            value: '$_totalPractices Times',
                            bgColor: const Color(0xFFFFF1F2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildWritingRecordsTile(),
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
                                      _nameController.text = progress.childName;
                                    });
                                    _loadWritingStats();
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
      ),
    );
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding,
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
      child: child,
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.cardSubtitle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color bgColor,
  }) {
    return Container(
      height: 128,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: iconColor.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWritingRecordsTile() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF3A86FF), Color(0xFF4895EF)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3A86FF).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WritingHistoryScreen()),
            ).then((_) => _loadWritingStats());
          },
          child: const Padding(
            padding: EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.history_edu_rounded, color: Color(0xFF3A86FF), size: 28),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Writing Practice Records',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Handwriting practice history for parents',
                        style: TextStyle(fontSize: 13, color: Color(0xFFDBEAFE)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
              ],
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
