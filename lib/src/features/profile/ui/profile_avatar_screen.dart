import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/app_theme.dart';
import '../../../core/models/profile_models.dart';
import '../../../services/api_client.dart';

class ProfileAvatarScreen extends StatefulWidget {
  const ProfileAvatarScreen({
    super.key,
    required this.apiClient,
    required this.profile,
  });

  final ApiClient apiClient;
  final MeProfile profile;

  @override
  State<ProfileAvatarScreen> createState() => _ProfileAvatarScreenState();
}

class _ProfileAvatarScreenState extends State<ProfileAvatarScreen> {
  static const _allowedMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
  };
  static const _maxImageBytes = 5 * 1024 * 1024;

  final _imagePicker = ImagePicker();

  bool _uploading = false;
  String? _error;
  XFile? _selected;
  Uint8List? _previewBytes;

  Future<void> _pick() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (picked == null || !mounted) {
        return;
      }

      final size = await picked.length();
      final mimeType = picked.mimeType ?? _guessMimeType(picked.name);

      if (!_allowedMimeTypes.contains(mimeType)) {
        setState(() {
          _error = 'Usa una imagen JPG, PNG o WebP.';
        });
        return;
      }

      if (size > _maxImageBytes) {
        setState(() {
          _error = 'La imagen no debe pesar mas de 5 MB.';
        });
        return;
      }

      final bytes = await picked.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _selected = picked;
        _previewBytes = bytes;
        _error = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'No se pudo seleccionar la imagen.';
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _selected = null;
      _previewBytes = null;
      _error = null;
    });
  }

  Future<void> _upload() async {
    final selected = _selected;
    final bytes = _previewBytes;
    if (selected == null || bytes == null) {
      return;
    }

    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      final mimeType = selected.mimeType ?? _guessMimeType(selected.name);
      final updated = await widget.apiClient.uploadProfileAvatar(
        bytes: bytes,
        contentType: mimeType,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop<MeProfile>(updated);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'No se pudo actualizar la foto de perfil.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  String _guessMimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<PickadosColors>()!;

    final fullName = widget.profile.fullName.isNotEmpty
        ? widget.profile.fullName
        : widget.profile.username;
    final initials = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();

    final currentAvatarUrl = widget.profile.avatarUrl;
    final hasPreview = _previewBytes != null;

    return Scaffold(
      backgroundColor: colors.pageGradientBottom,
      appBar: AppBar(title: const Text('Cambiar foto')),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.pageGradientTop, colors.pageGradientBottom],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Foto visible',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acepta JPG, PNG o WebP hasta 5 MB. Mostramos una vista previa antes de subir.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _AvatarPreview(
                          avatarUrl: currentAvatarUrl,
                          previewBytes: _previewBytes,
                          initials: initials.isEmpty ? 'P' : initials,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                hasPreview
                                    ? 'Vista previa lista'
                                    : 'Sin vista previa',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.textMuted,
                                ),
                              ),
                              if (_selected != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Archivo: ${_selected!.name}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.softSurface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: colors.borderSoft,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _uploading
                                    ? Icons.cloud_upload_rounded
                                    : Icons.image_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _uploading
                                      ? 'Subiendo tu nueva foto...'
                                      : 'Seleccionar una nueva imagen',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: _uploading ? null : _pick,
                                icon: const Icon(Icons.photo_library_rounded),
                                label: const Text('Elegir'),
                              ),
                              if (_selected != null)
                                TextButton(
                                  onPressed: _uploading ? null : _clearSelection,
                                  child: const Text('Quitar'),
                                ),
                            ],
                          ),
                          if (_uploading) ...[
                            const SizedBox(height: 12),
                            const LinearProgressIndicator(),
                          ],
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: colors.danger.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: colors.danger,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _uploading || _selected == null ? null : _upload,
                      icon: _uploading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.camera_alt_rounded),
                      label: Text(_uploading ? 'Procesando' : 'Actualizar foto'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.avatarUrl,
    required this.previewBytes,
    required this.initials,
  });

  final String? avatarUrl;
  final Uint8List? previewBytes;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<PickadosColors>()!;

    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: (avatarUrl == null && previewBytes == null)
            ? LinearGradient(colors: [theme.colorScheme.primary, colors.danger])
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: previewBytes != null
          ? Image.memory(
              previewBytes!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            )
          : avatarUrl != null
              ? Image.network(
                  avatarUrl!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                      ),
                    );
                  },
                )
              : Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                ),
    );
  }
}

