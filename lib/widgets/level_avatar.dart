import 'package:flutter/material.dart';
import 'dart:math' as math;

class LevelAvatar extends StatefulWidget {
  final String? avatarUrl;
  final String name;
  final int level;
  final double radius;

  const LevelAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.level = 1,
    this.radius = 24.0,
  });

  @override
  State<LevelAvatar> createState() => _LevelAvatarState();
}

class _LevelAvatarState extends State<LevelAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Animate if level >= 10
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.level >= 40 ? 2 : 4),
    );
    if (widget.level >= 10) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant LevelAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.level >= 10) {
      _controller.duration = Duration(seconds: widget.level >= 40 ? 2 : 4);
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      if (_controller.isAnimating) _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBaseColor(int level) {
    if (level < 3) return const Color(0xFFCD7F32); // Bronze
    if (level < 10) return const Color(0xFFC0C0C0); // Silver
    if (level < 21) return const Color(0xFFFFD700); // Gold
    if (level < 40) return const Color(0xFF00FFFF); // Cyan/Diamond
    return const Color(0xFFD500F9); // Legend Purple
  }

  List<Color> _getGradientColors(int level) {
    if (level < 3) return [const Color(0xFF8D5524), const Color(0xFFE6A15C)]; // Bronze
    if (level < 10) return [const Color(0xFFE0E0E0), const Color(0xFF9E9E9E)]; // Silver
    if (level < 21) return [
      const Color(0xFFFFD700),
      const Color(0xFFFFA000), 
      const Color(0xFFFFE082),
      const Color(0xFFFFD700)
    ]; // Shiny Gold
    if (level < 40) return [
      const Color(0xFF00E5FF),
      const Color(0xFF2979FF),
      const Color(0xFF76FF03),
      const Color(0xFF00E5FF)
    ]; // Aurora Diamond
    return [
      const Color(0xFFFF007F), // Neon Pink
      const Color(0xFF7D00FF), // Neon Purple
      const Color(0xFF00E5FF), // Neon Cyan
      const Color(0xFFFFD700), // Solid Gold
      const Color(0xFFFF007F)
    ]; // Cosmic Legend
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _getBaseColor(widget.level);
    final isGlowing = widget.level >= 10;
    final isAnimated = widget.level >= 10;
    
    // Border thickness mapping
    double borderThickness = 2.0;
    if (widget.level >= 10) borderThickness = 3.0;
    if (widget.level >= 40) borderThickness = 4.0;

    // Dark separator to make the ring pop
    Widget avatarCore = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2.0),
      ),
      child: CircleAvatar(
        radius: widget.radius - borderThickness - 2.0,
        backgroundColor: Colors.grey.shade800,
        backgroundImage: widget.avatarUrl != null
            ? NetworkImage(widget.avatarUrl!)
            : null,
        child: widget.avatarUrl == null
            ? Text(
                widget.name.isNotEmpty
                    ? widget.name.substring(0, 1).toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: (widget.radius - borderThickness) * 0.8,
                  fontWeight: FontWeight.bold,
                  color: baseColor,
                ),
              )
            : null,
      ),
    );

    if (isAnimated) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: widget.radius * 2,
            height: widget.radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: baseColor.withOpacity(widget.level >= 40 ? 0.8 : 0.5),
                  blurRadius: widget.level >= 40 ? 12 : 8,
                  spreadRadius: 2,
                ),
                if (widget.level >= 40)
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: -2,
                  ),
              ],
              gradient: SweepGradient(
                colors: _getGradientColors(widget.level),
                transform: GradientRotation(_controller.value * 2 * math.pi),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(borderThickness),
              child: child,
            ),
          );
        },
        child: avatarCore,
      );
    } else {
      return Container(
        width: widget.radius * 2,
        height: widget.radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: widget.level >= 3
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getGradientColors(widget.level),
                )
              : null,
          color: widget.level < 3 ? baseColor : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(borderThickness),
          child: avatarCore,
        ),
      );
    }
  }
}
