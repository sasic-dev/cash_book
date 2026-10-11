import 'package:flutter/material.dart';

/// Reusable Cash Book brand logo widget with flat UI styling.
class AppLogo extends StatelessWidget {
  final double size;
  final double borderRadius;

  const AppLogo({
    super.key,
    this.size = 28,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          'assets/icons/app_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: size,
            height: size,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: size * 0.65,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable AppBar title component featuring the Cash Book logo next to the screen title.
class AppBrandTitle extends StatelessWidget {
  final String title;
  final double logoSize;
  final TextStyle? textStyle;

  const AppBrandTitle({
    super.key,
    required this.title,
    this.logoSize = 28,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: logoSize),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: textStyle ??
                theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: -0.3,
                  color: theme.colorScheme.onSurface,
                ),
          ),
        ),
      ],
    );
  }
}
