import 'package:flutter/material.dart';

class LoadingPlaceholder extends StatelessWidget {
  const LoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _SkeletonBox(height: 28, width: 220),
        SizedBox(height: 16),
        _SkeletonBox(height: 140),
        SizedBox(height: 16),
        _SkeletonBox(height: 32, width: 100),
        SizedBox(height: 12),
        _SkeletonBox(height: 32, width: 120),
        SizedBox(height: 24),
        _SkeletonBox(height: 56),
        SizedBox(height: 12),
        _SkeletonBox(height: 56),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.height = 16, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
