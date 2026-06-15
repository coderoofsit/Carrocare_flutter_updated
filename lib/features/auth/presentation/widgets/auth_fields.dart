import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.assetIcon,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.borderColor,
    this.borderRadius = 0,
    this.maxLength,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final String? assetIcon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final Color? borderColor;
  final double borderRadius;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      padding: const EdgeInsets.all(7),
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(10),
            child: assetIcon != null
                ? Image.asset(
                    assetIcon!,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  )
                : Icon(icon, size: 22, color: Colors.black87),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscure,
              maxLength: maxLength,
              inputFormatters: inputFormatters,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                suffixIcon: suffix,
                counterText: maxLength == null ? null : '',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
