import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AiMascotStyle {
  classic, // 3D Aero Bot (Classic)
  cat,     // 3D Cyber Neko (Cat Bot)
  dog,     // 3D Cyber Pup (Dog Bot)
  astral,  // 3D Astral Bot (Space Chibi)
}

extension AiMascotStyleExt on AiMascotStyle {
  String get assetPath => switch (this) {
        AiMascotStyle.classic => 'assets/images/ai_mascot_classic.jpg',
        AiMascotStyle.cat => 'assets/images/ai_mascot_cat.jpg',
        AiMascotStyle.dog => 'assets/images/ai_mascot_dog.jpg',
        AiMascotStyle.astral => 'assets/images/ai_mascot_astral.jpg',
      };

  String get displayName => switch (this) {
        AiMascotStyle.classic => 'Aero Bot (Classic)',
        AiMascotStyle.cat => 'Cyber Neko (Cat Bot)',
        AiMascotStyle.dog => 'Cyber Pup (Dog Bot)',
        AiMascotStyle.astral => 'Astral Bot (Space Chibi)',
      };

  String get tagline => switch (this) {
        AiMascotStyle.classic => 'Sleek 3D Aerodynamic AI Companion',
        AiMascotStyle.cat => 'Adorable 3D Robotic Cat with Holographic Ears',
        AiMascotStyle.dog => 'Playful 3D Cyber Puppy with Golden Shield',
        AiMascotStyle.astral => 'Cosmic 3D Space Chibi with Celestial Halo',
      };

  Color get glowColor => switch (this) {
        AiMascotStyle.classic => const Color(0xFF06B6D4), // Cyan
        AiMascotStyle.cat => const Color(0xFFEC4899),     // Neon Pink
        AiMascotStyle.dog => const Color(0xFFF59E0B),     // Amber Gold
        AiMascotStyle.astral => const Color(0xFF8B5CF6),  // Cosmic Violet
      };

  List<String> get greetings => switch (this) {
        AiMascotStyle.classic => [
            'Hi! Aero AI here ⚡',
            'Ready to assist your pet! 🤖',
            'Symptom scan ready! 🩺',
            'Ask me anything! 💡',
          ],
        AiMascotStyle.cat => [
            'Nya~ Hi friend! 🐾',
            'Waving paws to you! 🐱',
            'Purr-fect day ahead! 💖',
            'Meow! Need health tips? ✨',
          ],
        AiMascotStyle.dog => [
            'Woof! Hi there! 🐶',
            'Ready for an AI checkup! 🦴',
            'Always happy to help! 🐾',
            'Good dog vibes today! 🌟',
          ],
        AiMascotStyle.astral => [
            'Greetings Explorer! ✨',
            'Cosmic sensors active! 🔮',
            'Scanning pet vitals! 🚀',
            'Starry health alert! 🌌',
          ],
      };

  IconData get emoteIcon => switch (this) {
        AiMascotStyle.classic => Icons.waving_hand_rounded,
        AiMascotStyle.cat => Icons.pets_rounded,
        AiMascotStyle.dog => Icons.celebration_rounded,
        AiMascotStyle.astral => Icons.auto_awesome_rounded,
      };
}

/// A floating, animated 3D AI Mascot with live active hand-waving physics,
/// dynamic digital emotes, ambient halo glow, and 4-character switcher.
class OwnerAiFab extends StatefulWidget {
  const OwnerAiFab({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  State<OwnerAiFab> createState() => _OwnerAiFabState();
}

class _OwnerAiFabState extends State<OwnerAiFab> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _waveController;
  late AnimationController _bubbleController;
  late AnimationController _pulseController;

  late Animation<double> _floatAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _waveRotation;
  late Animation<double> _waveScale;
  late Animation<double> _bubbleFade;
  late Animation<Offset> _bubbleSlide;
  late Animation<double> _pulseScale;

  AiMascotStyle _selectedMascot = AiMascotStyle.classic;
  bool _pressed = false;
  String _currentGreeting = 'Hi! Aero AI here ⚡';
  Timer? _greetingTimer;
  int _greetingIndex = 0;
  int _emoteCycleIndex = 0;

  static const List<String> _digitalEmotes = [
    '( ^ _ ^ )',
    '( ^ _ ~ )',
    '( ♥ _ ♥ )',
    '( ★ _ ★ )',
    '( * _ * )',
  ];

  @override
  void initState() {
    super.initState();
    _loadMascotPreference();

    // 1. Dual-Harmonic Floating Physics (Smooth hover bobbing loop)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _glowAnim = Tween<double>(begin: 0.45, end: 0.95).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutCubic),
    );

    // 2. Active Articulated Robotic Arm Waving Animation (Continuous Gentle Wave + Tap Wave)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _waveRotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -0.15, end: 0.45), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.45, end: -0.25), weight: 35),
      TweenSequenceItem(tween: Tween(begin: -0.25, end: -0.15), weight: 25),
    ]).animate(CurvedAnimation(parent: _waveController, curve: Curves.easeInOutSine));

    _waveScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _waveController, curve: Curves.easeInOut));

    // 3. Pulse Aura Controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 4. Speech Bubble Intro/Outro Animation
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _bubbleFade = CurvedAnimation(parent: _bubbleController, curve: Curves.easeOut);
    _bubbleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _bubbleController, curve: Curves.easeOutBack));

    // Initial greeting after 1.5s & recurring wave greeting every 8s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _triggerEmoteWave();
    });

    _greetingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) _triggerEmoteWave();
    });
  }

  void _triggerEmoteWave() {
    final greetings = _selectedMascot.greetings;
    _greetingIndex = (_greetingIndex + 1) % greetings.length;
    _emoteCycleIndex = (_emoteCycleIndex + 1) % _digitalEmotes.length;

    setState(() {
      _currentGreeting = greetings[_greetingIndex];
    });

    _waveController.forward(from: 0.0);
    _bubbleController.forward(from: 0.0);

    // Auto-dismiss bubble after 3.2 seconds
    Future.delayed(const Duration(milliseconds: 3200), () {
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
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose 3D AI Mascot Companion',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Select your animated companion with live emotes & wave physics',
                              style: TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.88,
                      physics: const NeverScrollableScrollPhysics(),
                      children: AiMascotStyle.values.map((style) {
                        final isSelected = _selectedMascot == style;
                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            _setMascot(style);
                            setModalState(() {});
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? style.glowColor.withValues(alpha: 0.18)
                                  : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? style.glowColor
                                    : Colors.white.withValues(alpha: 0.1),
                                width: isSelected ? 2.2 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: style.glowColor.withValues(alpha: 0.35),
                                        blurRadius: 14,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: style.glowColor,
                                      width: 2.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: style.glowColor.withValues(alpha: 0.45),
                                        blurRadius: 12,
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
                                const SizedBox(height: 10),
                                Text(
                                  style.displayName,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  style.tagline,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
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
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = _selectedMascot.glowColor;
    final currentEmote = _digitalEmotes[_emoteCycleIndex];

    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          // ── Floating Animated Speech Bubble Greeting ─────────────
          Positioned(
            bottom: 86,
            right: 0,
            child: IgnorePointer(
              ignoring: true,
              child: SlideTransition(
                position: _bubbleSlide,
                child: FadeTransition(
                  opacity: _bubbleFade,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: glowColor.withValues(alpha: 0.8), width: 1.8),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                        const BoxShadow(
                          color: Colors.black54,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_selectedMascot.emoteIcon, size: 16, color: glowColor),
                        const SizedBox(width: 8),
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

          // ── Main Freestanding 3D Mascot Character with Live Wave & Emotes ──
          AnimatedBuilder(
            animation: Listenable.merge([
              _floatController,
              _waveController,
              _pulseController,
            ]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: GestureDetector(
                  onLongPress: _openMascotSwitcher,
                  onDoubleTap: _openMascotSwitcher,
                  onTapDown: (_) => setState(() => _pressed = true),
                  onTapUp: (_) => setState(() => _pressed = false),
                  onTapCancel: () => setState(() => _pressed = false),
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    _triggerEmoteWave();
                    widget.onPressed();
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // ── 1. Soft Ambient Ground Breathing Glow Shadow ─────────
                      Positioned(
                        bottom: -10,
                        child: Container(
                          width: 52,
                          height: 14,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: glowColor.withValues(alpha: _glowAnim.value * 0.5),
                                blurRadius: 18,
                                spreadRadius: 3,
                              ),
                              const BoxShadow(
                                color: Colors.black54,
                                blurRadius: 12,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── 2. Pulsing Energy Ring ──────────────────────────────
                      Transform.scale(
                        scale: _pulseScale.value,
                        child: Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: glowColor.withValues(alpha: _glowAnim.value * 0.7),
                              width: 2.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: glowColor.withValues(alpha: _glowAnim.value * 0.45),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── 3. 3D Mascot Character Render Chassis (Hero Flight to AI Chat) ────
                      Hero(
                        tag: 'ai-mascot-avatar-hero',
                        flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
                          final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubicEmphasized);
                          return ScaleTransition(
                            scale: Tween<double>(begin: 1.0, end: 0.85).animate(curved),
                            child: fromHeroContext.widget,
                          );
                        },
                        child: Transform.rotate(
                          angle: _waveRotation.value * 0.25,
                          child: Transform.scale(
                            scale: _pressed ? 0.90 : _waveScale.value,
                            child: Container(
                              width: 70,
                              height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white,
                                  glowColor.withValues(alpha: 0.2),
                                ],
                              ),
                              border: Border.all(
                                color: glowColor,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: glowColor.withValues(alpha: 0.6),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                                const BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // High-Definition 3D Mascot Character Model Image
                                Positioned.fill(
                                  child: ClipOval(
                                    child: Image.asset(
                                      _selectedMascot.assetPath,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),

                                // Curved Gloss Visor Specular Reflection
                                Positioned(
                                  top: 3,
                                  left: 10,
                                  right: 10,
                                  height: 14,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white.withValues(alpha: 0.45),
                                          Colors.transparent,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),

                                // Digital Visor Emote Overlay at Bottom
                                Positioned(
                                  bottom: 4,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: glowColor.withValues(alpha: 0.6),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        currentEmote,
                                        style: TextStyle(
                                          color: glowColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            Shadow(
                                              color: glowColor,
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                      // ── 4. ARTICULATED ANIMATED WAVING HAND & ARM (Active Real-Time Wave Arc) ──
                      Positioned(
                        top: 2,
                        right: -10,
                        child: Transform.rotate(
                          angle: _waveRotation.value * 2.6,
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Waving Hand / Cyber Paw / Emote Glove
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white,
                                      glowColor.withValues(alpha: 0.3),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: glowColor, width: 2.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: glowColor.withValues(alpha: 0.95),
                                      blurRadius: 12,
                                      spreadRadius: 2,
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
                                height: 12,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: glowColor.withValues(alpha: 0.8),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── 5. Live Online Beacon ────────────────────────────────
                      Positioned(
                        bottom: 0,
                        right: 2,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.0),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.9),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
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
