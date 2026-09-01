import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AiMascotStyle {
  classic, // 5th reference match: Classic Aero Bot
  cat,     // Cyber Neko Bot
  dog,     // Cyber Pup Bot
  astral,  // Chibi Astral Bot
}

extension AiMascotStyleExt on AiMascotStyle {
  String get assetPath => switch (this) {
        AiMascotStyle.classic => 'assets/images/ai_mascot_classic.jpg',
        AiMascotStyle.cat => 'assets/images/ai_mascot_cat.jpg',
        AiMascotStyle.dog => 'assets/images/ai_mascot_dog.jpg',
        AiMascotStyle.astral => 'assets/images/ai_mascot_astral.jpg',
      };

  String get displayName => switch (this) {
        AiMascotStyle.classic => 'Classic Aero Bot',
        AiMascotStyle.cat => 'Cyber Neko (Cat Bot)',
        AiMascotStyle.dog => 'Cyber Pup (Dog Bot)',
        AiMascotStyle.astral => 'Chibi Astral Bot',
      };

  String get description => switch (this) {
        AiMascotStyle.classic => 'Sleek white floating AI assistant with cyan visor smile',
        AiMascotStyle.cat => 'Cute 3D white & mint robot with waving cat paws & ears',
        AiMascotStyle.dog => 'Friendly 3D robot with puppy-ear headset & shield',
        AiMascotStyle.astral => 'Spherical chibi space explorer with bubble dome helmet',
      };

  Color get glowColor => switch (this) {
        AiMascotStyle.classic => const Color(0xFF06B6D4), // Cyan
        AiMascotStyle.cat => const Color(0xFF10B981),     // Emerald Mint
        AiMascotStyle.dog => const Color(0xFFF59E0B),     // Golden Amber
        AiMascotStyle.astral => const Color(0xFF8B5CF6),  // Cosmic Violet
      };

  List<String> get greetings => switch (this) {
        AiMascotStyle.classic => [
            'Hi! Aero AI here ⚡',
            'Ready to assist your pet! 🤖',
            'How can I help today? 💡',
          ],
        AiMascotStyle.cat => [
            'Nya~ Hi friend! 🐾',
            'Waving paws to you! 🐱',
            'Purr-fect day ahead! 💖',
          ],
        AiMascotStyle.dog => [
            'Woof! Hi there! 🐶',
            'Ready for an AI checkup! 🦴',
            'Always happy to help! 🐾',
          ],
        AiMascotStyle.astral => [
            'Greetings Explorer! ✨',
            'Cosmic sensors active! 🔮',
            'Scanning pet vitals! 🚀',
          ],
      };

  IconData get emoteIcon => switch (this) {
        AiMascotStyle.classic => Icons.waving_hand_rounded,
        AiMascotStyle.cat => Icons.pets_rounded,
        AiMascotStyle.dog => Icons.celebration_rounded,
        AiMascotStyle.astral => Icons.auto_awesome_rounded,
      };
}

/// A floating 3D AI Mascot character with individual avatar-specific emotes,
/// hand-waving shake animations, dynamic speech bubbles, and avatar switcher.
class OwnerAiFab extends StatefulWidget {
  const OwnerAiFab({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  State<OwnerAiFab> createState() => _OwnerAiFabState();
}

class _OwnerAiFabState extends State<OwnerAiFab>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _waveController;
  late AnimationController _bubbleController;

  late Animation<double> _floatAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _waveRotation;
  late Animation<double> _waveScale;
  late Animation<double> _bubbleFade;
  late Animation<Offset> _bubbleSlide;

  AiMascotStyle _selectedMascot = AiMascotStyle.classic;
  bool _pressed = false;
  String _currentGreeting = 'Hi! Aero AI here ⚡';
  Timer? _greetingTimer;
  int _greetingIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMascotPreference();

    // 1. Continuous Floating Hover Loop
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutCubic),
    );

    _glowAnim = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    // 2. Avatar-specific Hand-Wave & Emote Gesture Animation (Continuous Gentle Wave + Tap Emotes)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _waveRotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.28), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.28, end: -0.15), weight: 35),
      TweenSequenceItem(tween: Tween(begin: -0.15, end: -0.05), weight: 30),
    ]).animate(CurvedAnimation(parent: _waveController, curve: Curves.easeInOutSine));

    _waveScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _waveController, curve: Curves.easeInOut));

    // 3. Speech Bubble Intro/Outro Animation
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _bubbleFade = CurvedAnimation(parent: _bubbleController, curve: Curves.easeOut);
    _bubbleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _bubbleController, curve: Curves.easeOutBack));

    // Initial welcome greeting after 1.5s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _triggerEmoteWave();
      }
    });
  }

  void _triggerEmoteWave() {
    final greetings = _selectedMascot.greetings;
    _greetingIndex = (_greetingIndex + 1) % greetings.length;
    setState(() {
      _currentGreeting = greetings[_greetingIndex];
    });

    _waveController.forward(from: 0.0);
    _bubbleController.forward(from: 0.0);

    // Auto-dismiss bubble after 3.0 seconds
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        _bubbleController.reverse();
      }
    });
  }

  Future<void> _loadMascotPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('selected_ai_mascot_style') ?? 0;
    if (savedIndex >= 0 && savedIndex < AiMascotStyle.values.length) {
      if (mounted) {
        setState(() {
          _selectedMascot = AiMascotStyle.values[savedIndex];
          _currentGreeting = _selectedMascot.greetings.first;
        });
      }
    }
  }

  Future<void> _setMascot(AiMascotStyle style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_ai_mascot_style', style.index);
    if (mounted) {
      setState(() {
        _selectedMascot = style;
        _currentGreeting = style.greetings.first;
      });
      _triggerEmoteWave();
    }
  }

  void _openMascotSwitcher() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Your AI Mascot Avatar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Each 3D mascot has unique gestures, emotes, and voice lines.',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.15,
                    physics: const NeverScrollableScrollPhysics(),
                    children: AiMascotStyle.values.map((style) {
                      final isSelected = _selectedMascot == style;
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          _setMascot(style);
                          setModalState(() {});
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? style.glowColor.withValues(alpha: 0.15)
                                : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? style.glowColor
                                  : Colors.white.withValues(alpha: 0.1),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: style.glowColor.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    style.assetPath,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                style.displayName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    _floatController.dispose();
    _waveController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = _selectedMascot.glowColor;

    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          // ── Floating Animated Speech Bubble Greeting ─────────────
          Positioned(
            bottom: 78,
            right: 0,
            child: IgnorePointer(
              ignoring: true, // Prevents any touch interception or overlay glitch
              child: SlideTransition(
                position: _bubbleSlide,
                child: FadeTransition(
                  opacity: _bubbleFade,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 190),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: glowColor.withValues(alpha: 0.6), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_selectedMascot.emoteIcon, size: 16, color: glowColor),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _currentGreeting,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Main Freestanding 3D Mascot Character ─────────────────
          AnimatedBuilder(
            animation: Listenable.merge([_floatController, _waveController]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: GestureDetector(
                  onLongPress: _openMascotSwitcher,
                  onTapDown: (_) => setState(() => _pressed = true),
                  onTapUp: (_) => setState(() => _pressed = false),
                  onTapCancel: () => setState(() => _pressed = false),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _triggerEmoteWave();
                    widget.onPressed();
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // ── Soft Ambient Ground Breathing Shadow ─────────────
                      Positioned(
                        bottom: -8,
                        child: Container(
                          width: 48,
                          height: 12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: glowColor.withValues(alpha: _glowAnim.value * 0.4),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Freestanding 3D Mascot Character Body (Pure Character Body, Zero Button Box) ────
                      Transform.rotate(
                        angle: _waveRotation.value * 0.35,
                        child: Transform.scale(
                          scale: _pressed ? 0.92 : _waveScale.value,
                          child: SizedBox(
                            width: 76,
                            height: 82,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                // 1. Top Antenna / Ears / Astral Rings based on Mascot Style
                                if (_selectedMascot == AiMascotStyle.classic) ...[
                                  Positioned(
                                    top: 0,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: glowColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: glowColor.withValues(alpha: 0.9),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 2.5,
                                          height: 7,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (_selectedMascot == AiMascotStyle.cat) ...[
                                  // Left Cat Ear
                                  Positioned(
                                    top: 2,
                                    left: 12,
                                    child: Transform.rotate(
                                      angle: -0.3,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFFFFF),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            topRight: Radius.circular(2),
                                            bottomLeft: Radius.circular(2),
                                          ),
                                          border: Border.all(color: glowColor, width: 1.5),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: glowColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Right Cat Ear
                                  Positioned(
                                    top: 2,
                                    right: 12,
                                    child: Transform.rotate(
                                      angle: 0.3,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFFFFF),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(2),
                                            topRight: Radius.circular(8),
                                            bottomRight: Radius.circular(2),
                                          ),
                                          border: Border.all(color: glowColor, width: 1.5),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: glowColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ] else if (_selectedMascot == AiMascotStyle.dog) ...[
                                  // Left Dog Ear
                                  Positioned(
                                    top: 8,
                                    left: 4,
                                    child: Transform.rotate(
                                      angle: -0.4,
                                      child: Container(
                                        width: 12,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: glowColor, width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: glowColor.withValues(alpha: 0.3),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Right Dog Ear
                                  Positioned(
                                    top: 8,
                                    right: 4,
                                    child: Transform.rotate(
                                      angle: 0.4,
                                      child: Container(
                                        width: 12,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: glowColor, width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: glowColor.withValues(alpha: 0.3),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ] else if (_selectedMascot == AiMascotStyle.astral) ...[
                                  // Orbiting Cosmic Star Ring
                                  Positioned(
                                    top: 4,
                                    child: Container(
                                      width: 64,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: glowColor.withValues(alpha: 0.7),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: glowColor.withValues(alpha: 0.5),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],

                                // 2. Main Robot Head with Specular 3D Gradient
                                Positioned(
                                  top: 10,
                                  child: Container(
                                    width: 58,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFFFFFFFF),
                                          const Color(0xFFF1F5F9),
                                          const Color(0xFFE2E8F0),
                                          glowColor.withValues(alpha: 0.35),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: glowColor.withValues(alpha: _glowAnim.value * 0.5),
                                          blurRadius: 18,
                                          spreadRadius: 1,
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.35),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: glowColor.withValues(alpha: 0.8),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      // Glowing Digital Visor Eyes
                                      child: Container(
                                        width: 44,
                                        height: 25,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A),
                                          borderRadius: BorderRadius.circular(13),
                                          border: Border.all(
                                            color: glowColor.withValues(alpha: 0.6),
                                            width: 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: glowColor.withValues(alpha: 0.35),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            // Expressive Digital Left Eye
                                            Text(
                                              _selectedMascot == AiMascotStyle.cat
                                                  ? '^'
                                                  : (_selectedMascot == AiMascotStyle.dog
                                                      ? '●'
                                                      : (_selectedMascot == AiMascotStyle.astral ? '★' : '^')),
                                              style: TextStyle(
                                                color: glowColor,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                                shadows: [
                                                  Shadow(color: glowColor, blurRadius: 8),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '‿',
                                              style: TextStyle(
                                                color: glowColor.withValues(alpha: 0.8),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            // Expressive Digital Right Eye
                                            Text(
                                              _selectedMascot == AiMascotStyle.cat
                                                  ? '^'
                                                  : (_selectedMascot == AiMascotStyle.dog
                                                      ? '●'
                                                      : (_selectedMascot == AiMascotStyle.astral ? '★' : '^')),
                                              style: TextStyle(
                                                color: glowColor,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                                shadows: [
                                                  Shadow(color: glowColor, blurRadius: 8),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // 3. Floating Mini Torso with Core Arc Reactor
                                Positioned(
                                  top: 57,
                                  child: Container(
                                    width: 36,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          const Color(0xFFFFFFFF),
                                          const Color(0xFFCBD5E1),
                                          glowColor.withValues(alpha: 0.3),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(11),
                                      border: Border.all(
                                        color: glowColor.withValues(alpha: 0.6),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: glowColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: glowColor,
                                              blurRadius: 8,
                                              spreadRadius: 1.5,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // 4. Left Arm
                                Positioned(
                                  top: 38,
                                  left: 2,
                                  child: Transform.rotate(
                                    angle: -0.25,
                                    child: Container(
                                      width: 10,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: glowColor.withValues(alpha: 0.5),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // 5. ARTICULATED ANIMATED WAVING HAND & ARM (Right Shoulder Pivot)
                                Positioned(
                                  top: 14,
                                  right: -6,
                                  child: Transform.rotate(
                                    angle: _waveRotation.value * 2.8,
                                    alignment: Alignment.bottomLeft,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Waving Hand / Paw / Emote Glove
                                        Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFFFFFFFF),
                                                glowColor.withValues(alpha: 0.2),
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: glowColor, width: 2.0),
                                            boxShadow: [
                                              BoxShadow(
                                                color: glowColor.withValues(alpha: 0.85),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            _selectedMascot.emoteIcon,
                                            size: 16,
                                            color: glowColor,
                                          ),
                                        ),
                                        // Arm Link
                                        Container(
                                          width: 5,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(3),
                                            border: Border.all(
                                              color: glowColor.withValues(alpha: 0.6),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // 6. Mini Online Pulse Indicator
                                Positioned(
                                  bottom: 4,
                                  right: 14,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.8),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
