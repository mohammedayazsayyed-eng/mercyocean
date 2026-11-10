import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mercyocean/config/app_theme.dart';
import 'package:mercyocean/models/tasbih_save_model.dart';
import 'package:mercyocean/service/tasbih_service.dart';
import 'package:mercyocean/service/tasbih_stats_service.dart';
import 'package:mercyocean/widgets/tasbih_beads_icon.dart';

// ═══════════════════════════════════════════════════════════════════
//
//   T A S B I H   —   E D I T   T H E S E   N U M B E R S
//
//   Change a number  →  save the file  →  press "r" to hot reload.
//
//   Every number is in pixels, like "320".
//   To move something LEFT or UP, use a minus number, like "-15".
//   Leave a number at 0 to keep it where it is.
//
//   You do not need to touch anything below the "STOP" line.
//
// ═══════════════════════════════════════════════════════════════════

//  ─── THE BEADS PICTURE ───

/// Which picture file to show.
const String kBeadsImage = 'assets/images/icons/tasbih2.png';

/// How big the beads are. Bigger number = bigger beads.
const double kBeadsSize = 320;

/// Move the beads picture sideways.  (minus number = move left)
const double kBeadsMoveRight = 20;

/// Move the beads picture up or down.  (minus number = move up)
const double kBeadsMoveDown = 0;

//  ─── THE CIRCLE WITH THE NUMBER IN IT ───

/// How big the circle is. Bigger number = bigger circle.
const double kCircleSize = 185;

/// Move the circle sideways.  (minus number = move left)
const double kCircleMoveRight = 25;

/// Move the circle up or down.  (minus number = move up)
const double kCircleMoveDown = 0;

/// How big the counting number is.
const double kNumberSize = 40;

//  ─── ONE ROUND ───

/// How many counts make one complete round.
/// The small "0 / 100" line inside the circle counts up to this, then
/// starts again from 1 for the next round.
const int kRoundTarget = 70;

/// How big that small "0 / 100" line is.
const double kRoundTextSize = 15;

// ═══════════════════════════════════════════════════════════════════
//   S T O P  —  nothing below here needs editing.
//
//   (The two numbers just below say where the empty gap inside the
//   beads loop is, as a fraction of the picture. They were measured
//   from the picture's pixels. Only change them if you swap in a
//   different beads picture and the circle no longer sits in the gap.)
// ═══════════════════════════════════════════════════════════════════

const double _gapCentreAcross = 0.376; // 0 = far left, 1 = far right
const double _gapCentreDown = 0.44; // 0 = very top,  1 = very bottom

// Where the circle lands: start from the gap, then apply the moves above.
const double _circleX =
    (_gapCentreAcross - 0.5) * kBeadsSize + kCircleMoveRight;
const double _circleY = (_gapCentreDown - 0.5) * kBeadsSize + kCircleMoveDown;

// Small decorative glyph above the number.
const double _glyphSize = kNumberSize * 0.4;

class TasbihPage extends StatefulWidget {
  const TasbihPage({super.key});

  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage> {
  int _count = 0;
  TasbihSave? _activeSave;
  List<TasbihSave> _saves = [];
  bool _loading = true;

  int _todayCount = 0;
  int _bestStreak = 0;
  int get _rounds => _todayCount ~/ kRoundTarget;

  /// Progress through the current round, 0…kRoundTarget.
  ///
  /// Lands on the full target when a round is completed (100/100) rather
  /// than wrapping straight to 0 — the next tap starts the new round at 1.
  int get _roundProgress => _count == 0 ? 0 : ((_count - 1) % kRoundTarget) + 1;

  @override
  void initState() {
    super.initState();
    _loadSaves();
    _loadStats();
  }

  Future<void> _loadSaves() async {
    final saves = await TasbihService.getSaves();
    if (!mounted) return;
    setState(() {
      _saves = saves;
      _loading = false;
    });
  }

  Future<void> _loadStats() async {
    final stats = await TasbihStatsService.getStats();
    if (!mounted) return;
    setState(() {
      _todayCount = stats.today;
      _bestStreak = stats.bestStreak;
    });
  }

  void _increment() {
    final completesRound = (_count + 1) % kRoundTarget == 0;
    // Stronger buzz on the tap that completes a round, so it's felt
    // without having to look at the number.
    completesRound
        ? HapticFeedback.mediumImpact()
        : HapticFeedback.lightImpact();
    setState(() {
      _count++;
      _todayCount++;
    });
    // Persisted in the background — daily activity tracking doesn't need
    // to block the tap feedback.
    TasbihStatsService.recordTap().then((stats) {
      if (!mounted) return;
      setState(() => _bestStreak = stats.bestStreak);
    });
  }

  Future<void> _reset() async {
    if (_count == 0) return;
    final confirmed = await _confirm(
      title: 'Start over?',
      message: _activeSave != null
          ? 'This clears the counter back to 0 and detaches it from "${_activeSave!.name}". The saved count itself won\'t be touched unless you save again.'
          : 'This clears the counter back to 0.',
      confirmLabel: 'Reset',
    );
    if (confirmed != true) return;
    setState(() {
      _count = 0;
      _activeSave = null;
    });
  }

  void _resume(TasbihSave save) {
    HapticFeedback.selectionClick();
    setState(() {
      _count = save.count;
      _activeSave = save;
    });
    _showSnack('Continuing "${save.name}" from ${save.count}');
  }

  Future<void> _save() async {
    if (_count == 0) {
      _showSnack('Count is at 0 — nothing to save yet.');
      return;
    }

    // Already tracking a named save — just sync its count.
    if (_activeSave != null) {
      await TasbihService.updateCount(_activeSave!.id, _count);
      final updated = _activeSave!.copyWith(count: _count);
      setState(() => _activeSave = updated);
      await _loadSaves();
      if (!mounted) return;
      _showSnack('Updated "${updated.name}" to $_count');
      return;
    }

    final name = await _promptForName();
    if (name == null || name.trim().isEmpty) return;

    final save = await TasbihService.addSave(name: name, count: _count);
    setState(() => _activeSave = save);
    await _loadSaves();
    if (!mounted) return;
    _showSnack('Saved "${save.name}"');
  }

  Future<void> _rename(TasbihSave save, {VoidCallback? onChanged}) async {
    final name = await _promptForName(initialValue: save.name, isRename: true);
    if (name == null || name.trim().isEmpty) return;

    await TasbihService.rename(save.id, name);
    if (_activeSave?.id == save.id) {
      setState(() => _activeSave = _activeSave!.copyWith(name: name.trim()));
    }
    await _loadSaves();
    onChanged?.call();
  }

  Future<void> _delete(TasbihSave save, {VoidCallback? onChanged}) async {
    final confirmed = await _confirm(
      title: 'Delete "${save.name}"?',
      message: 'This can\'t be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) return;

    await TasbihService.delete(save.id);
    if (_activeSave?.id == save.id) {
      setState(() => _activeSave = null);
    }
    await _loadSaves();
    onChanged?.call();
  }

  Future<String?> _promptForName({
    String? initialValue,
    bool isRename = false,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRename ? 'Rename' : 'Save your count'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 60,
          decoration: InputDecoration(
            hintText: 'e.g. "I read 100 times Allah"',
            counterText: '',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(isRename ? 'Rename' : 'Save'),
          ),
        ],
        backgroundColor: isDark
            ? const Color.fromARGB(255, 30, 32, 15)
            : AppColors.lightSurface,
      ),
    );
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'Nunito',
            color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: destructive
                ? ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB00020),
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Nunito')),
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSavesSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.62,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                return Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color.fromARGB(255, 129, 122, 52)
                              : const Color.fromARGB(255, 214, 186, 131),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSavesHeader(isDark),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _saves.isEmpty
                            ? ListView(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  24,
                                ),
                                children: [_buildEmptySaves(isDark)],
                              )
                            : ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  24,
                                ),
                                itemCount: _saves.length,
                                itemBuilder: (context, i) => _buildSaveTile(
                                  _saves[i],
                                  isDark,
                                  onResume: () {
                                    _resume(_saves[i]);
                                    Navigator.pop(sheetContext);
                                  },
                                  onChanged: () => setSheetState(() {}),
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppGradients.darkBackground
              : AppGradients.lightBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(isDark),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      )
                    : _buildBody(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNavBar : AppColors.lightNavBar,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: isDark
            ? AppShadows.navBarShadowDark
            : AppShadows.navBarShadowLight,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isDark
                    ? AppShadows.cardShadowDark
                    : AppShadows.cardShadowLight,
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),
          const Spacer(),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppGradients.goldShimmer.createShader(bounds),
            child: const Text(
              'Tasbeeh',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showSavesSheet,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isDark
                        ? AppShadows.cardShadowDark
                        : AppShadows.cardShadowLight,
                  ),
                  child: const Icon(
                    Icons.bookmark_rounded,
                    size: 18,
                    color: AppColors.gold,
                  ),
                ),
                if (_saves.isNotEmpty)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      height: 16,
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkNavBar
                              : AppColors.lightNavBar,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${_saves.length}',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    // Saved counts live behind the bookmark icon in the app bar now, so the
    // body is just the hero counter, vertically centered in the viewport.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: _buildCounterCard(isDark)),
          ),
        );
      },
    );
  }

  Widget _buildCounterCard(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuote(isDark),
        const SizedBox(height: 22),
        if (_activeSave != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: isDark ? 0.16 : 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bookmark_rounded,
                  size: 14,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Continuing "${_activeSave!.name}"',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        GestureDetector(
          onTap: _increment,
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              SizedBox(
                width: kBeadsSize,
                height: kBeadsSize,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // The beads picture.
                    Transform.translate(
                      offset: const Offset(kBeadsMoveRight, kBeadsMoveDown),
                      child: Image.asset(
                        kBeadsImage,
                        width: kBeadsSize,
                        height: kBeadsSize,
                      ),
                    ),

                    // The circle with the number, sitting in the loop's gap.
                    Transform.translate(
                      offset: const Offset(_circleX, _circleY),
                      child: Container(
                        width: kCircleSize,
                        height: kCircleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.5 : 0.18,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TasbihBeadsIcon(
                              size: _glyphSize,
                              color: AppColors.gold.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 2),
                            // Running total — never resets on its own.
                            Text(
                              '$_count',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: kNumberSize,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkText
                                    : AppColors.lightText,
                              ),
                            ),
                            const SizedBox(height: 1),
                            // Progress through the current round of
                            // kRoundTarget, restarting each time one is done.
                            Text(
                              '$_roundProgress / $kRoundTarget',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: kRoundTextSize,
                                fontWeight: FontWeight.w600,
                                color: _roundProgress == kRoundTarget
                                    ? AppColors.gold
                                    : (isDark
                                          ? AppColors.darkSubText
                                          : AppColors.lightSubText),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'TAP THE BEADS TO COUNT',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: isDark
                      ? AppColors.darkSubText
                      : AppColors.lightSubText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildStatsRow(isDark),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPillButton(
              label: 'Reset',
              icon: Icons.restart_alt_rounded,
              isDark: isDark,
              filled: false,
              onTap: _reset,
            ),
            const SizedBox(width: 14),
            _buildPillButton(
              label: _activeSave != null ? 'Update' : 'Save',
              icon: Icons.bookmark_add_rounded,
              isDark: isDark,
              filled: true,
              onTap: _save,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: isDark
            ? AppShadows.cardShadowDark
            : AppShadows.cardShadowLight,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatTile(
              icon: Icons.autorenew_rounded,
              label: 'Rounds',
              value: '$_rounds',
              isDark: isDark,
            ),
          ),
          _buildStatDivider(isDark),
          Expanded(
            child: _buildStatTile(
              icon: Icons.star_rounded,
              label: 'Today',
              value: '$_todayCount',
              isDark: isDark,
            ),
          ),
          _buildStatDivider(isDark),
          Expanded(
            child: _buildStatTile(
              icon: Icons.local_fire_department_rounded,
              label: 'Best Streak',
              value: '$_bestStreak',
              suffix: _bestStreak == 1 ? 'day' : 'days',
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      width: 1,
      height: 36,
      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    String? suffix,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: AppColors.gold),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 3),
              Text(
                suffix,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkSubText
                      : AppColors.lightSubText,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildQuote(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
        boxShadow: isDark
            ? AppShadows.cardShadowDark
            : AppShadows.cardShadowLight,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: AppColors.gold.withValues(alpha: 0.55),
            size: 22,
          ),
          const SizedBox(height: 8),
          Text(
            '"So remember Me, and I will remember you."',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              height: 1.5,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'SURAH AL-BAQARAH · 2:152',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required IconData icon,
    required bool isDark,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        decoration: BoxDecoration(
          gradient: filled ? AppGradients.goldShimmer : null,
          color: filled
              ? null
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
          border: filled
              ? null
              : Border.all(
                  color: isDark
                      ? AppColors.darkDivider
                      : AppColors.lightDivider,
                ),
          boxShadow: isDark
              ? AppShadows.cardShadowDark
              : AppShadows.cardShadowLight,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: filled
                  ? Colors.white
                  : (isDark ? AppColors.darkText : AppColors.lightText),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: filled
                    ? Colors.white
                    : (isDark ? AppColors.darkText : AppColors.lightText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavesHeader(bool isDark) {
    return Row(
      children: [
        Text(
          'Saved Tasbih',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        const SizedBox(width: 8),
        if (_saves.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: isDark ? 0.18 : 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_saves.length}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptySaves(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: isDark
            ? AppShadows.cardShadowDark
            : AppShadows.cardShadowLight,
      ),
      child: Column(
        children: [
          TasbihBeadsIcon(
            size: 40,
            color: (isDark ? AppColors.darkSubText : AppColors.lightSubText)
                .withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'No saved counts yet',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Count your dhikr, then tap Save to keep track of it.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveTile(
    TasbihSave save,
    bool isDark, {
    required VoidCallback onResume,
    required VoidCallback onChanged,
  }) {
    final isActive = _activeSave?.id == save.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: isActive ? Border.all(color: AppColors.gold, width: 1.5) : null,
        boxShadow: isDark
            ? AppShadows.cardShadowDark
            : AppShadows.cardShadowLight,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onTap: onResume,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: isDark ? 0.16 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${save.count}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        save.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Updated ${_formatDate(save.savedAt)} · tap to continue',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkSubText
                              : AppColors.lightSubText,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: isDark
                        ? AppColors.darkSubText
                        : AppColors.lightSubText,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  onSelected: (value) {
                    if (value == 'rename') {
                      _rename(save, onChanged: onChanged);
                    }
                    if (value == 'delete') {
                      _delete(save, onChanged: onChanged);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.lightText,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Rename',
                            style: TextStyle(fontFamily: 'Nunito'),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Color(0xFFB00020),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Delete',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: Color(0xFFB00020),
                            ),
                          ),
                        ],
                      ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
