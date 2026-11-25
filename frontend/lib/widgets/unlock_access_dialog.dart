import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/access_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bouncy_button.dart';

/// Popup shown to a user who has not unlocked the content yet.
/// Two options: enter the scratch code from the book, or pay in the app.
/// It cannot be dismissed until one of them succeeds.
class UnlockAccessDialog extends StatefulWidget {
  const UnlockAccessDialog({super.key});

  /// Shows the popup; resolves to true once access is granted.
  static Future<bool> show(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const UnlockAccessDialog(),
    );
    return ok ?? false;
  }

  @override
  State<UnlockAccessDialog> createState() => _UnlockAccessDialogState();
}

class _UnlockAccessDialogState extends State<UnlockAccessDialog> {
  final _codeController = TextEditingController();
  bool _payMode = false; // false = scratch code tab, true = payment tab
  bool _busy = false;
  String? _error;
  int? _priceInr; // null while loading

  @override
  void initState() {
    super.initState();
    AccessService.instance.fetchPriceInr().then((price) {
      if (mounted) setState(() => _priceInr = price);
    });
  }

  String get _priceLabel => _priceInr == null ? '₹ …' : '₹$_priceInr';

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<AccessResult> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message,
              style: GoogleFonts.catamaran(fontSize: 16, fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.lock_open_rounded, size: 34, color: AppColors.primaryDark),
                ),
                const SizedBox(height: 12),
                Text(
                  'Unlock All Lessons',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.catamaran(
                      fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Have the book? Enter the scratch code inside it.\nNo book? Buy the content here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.catamaran(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                ),
                if (kAccessSampleMode) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4D6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Sample mode: any code works, payment is not charged.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.catamaran(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildTabs(),
                const SizedBox(height: 16),
                if (_payMode) _buildPayment() else _buildScratchCode(),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.catamaran(
                        fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFC53030)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    Widget tab(String label, IconData icon, bool selected, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: _busy ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: selected
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? AppColors.primaryDark : AppColors.textMuted),
                const SizedBox(width: 6),
                Text(label,
                    style: GoogleFonts.catamaran(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: selected ? AppColors.textDark : AppColors.textMuted)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          tab('Scratch Code', Icons.confirmation_number_rounded, !_payMode,
              () => setState(() { _payMode = false; _error = null; })),
          tab('Buy Online', Icons.payments_rounded, _payMode,
              () => setState(() { _payMode = true; _error = null; })),
        ],
      ),
    );
  }

  Widget _buildScratchCode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _codeController,
          enabled: !_busy,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          style: GoogleFonts.catamaran(
              fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 3, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: 'XXXX-XXXX-XXXX',
            hintStyle: GoogleFonts.catamaran(
                fontSize: 18, letterSpacing: 3, color: const Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onSubmitted: (_) => _run(() => AccessService.instance.redeemScratchCode(_codeController.text)),
        ),
        const SizedBox(height: 14),
        _actionButton(
          label: 'Unlock with Code',
          colors: AppColors.orangeGradient,
          onPressed: () => _run(() => AccessService.instance.redeemScratchCode(_codeController.text)),
        ),
      ],
    );
  }

  Widget _buildPayment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondaryLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Text('Full Course – Lifetime Access',
                  style: GoogleFonts.catamaran(
                      fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 4),
              Text(_priceLabel,
                  style: GoogleFonts.catamaran(
                      fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.secondaryDark)),
              Text('All letters, games, videos and quizzes',
                  style: GoogleFonts.catamaran(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _actionButton(
          label: 'Pay $_priceLabel',
          colors: AppColors.tealGradient,
          onPressed: _priceInr == null ? () {} : () => _run(AccessService.instance.purchase),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required List<Color> colors,
    required VoidCallback onPressed,
  }) {
    return BouncyButton(
      onPressed: _busy ? () {} : onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.6),
                )
              : Text(label,
                  style: GoogleFonts.catamaran(
                      fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ),
    );
  }
}
