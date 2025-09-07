import 'dart:io';
import 'package:flutter/material.dart';
import 'package:storyapp/services/story_cach_manager.dart';

class OfflineCachedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final String? cacheKey;

  const OfflineCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.cacheKey,
  });

  @override
  State<OfflineCachedImage> createState() => _OfflineCachedImageState();
}

class _OfflineCachedImageState extends State<OfflineCachedImage> {
  File? _file;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant OfflineCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.cacheKey != widget.cacheKey) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final file = await StoryCacheManager().getFileFromUrl(
        widget.imageUrl,
        key: widget.cacheKey,
      );
      if (mounted) {
        setState(() {
          _file = file;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius;
    final content = _buildContent();
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: content,
      );
    }
    return content;
  }

  Widget _buildContent() {
    if (_loading) {
      return _sizedContainer(
        widget.placeholder ?? _defaultPlaceholder(),
      );
    }
    if (_error != null) {
      return _sizedContainer(
        widget.errorWidget ?? _defaultError(),
      );
    }
    if (_file != null) {
      return Image.file(
        _file!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }
    return _sizedContainer(
      widget.errorWidget ?? _defaultError(),
    );
  }

  Widget _sizedContainer(Widget child) {
    if (widget.width == null && widget.height == null) return child;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Center(child: child),
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      color: Colors.black12,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _defaultError() {
    return Container(
      color: Colors.black12,
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
