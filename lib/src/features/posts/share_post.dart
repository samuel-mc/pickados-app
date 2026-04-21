import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_theme.dart';
import '../../config/app_config.dart';

Future<bool> sharePostLink({
  required BuildContext context,
  required int postId,
}) async {
  return await showModalBottomSheet<bool>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => FractionallySizedBox(
          heightFactor: 0.32,
          child: _PostShareSheet(postId: postId),
        ),
      ) ??
      false;
}

class _PostShareSheet extends StatelessWidget {
  const _PostShareSheet({required this.postId});

  final int postId;

  String get _shareText =>
      'Mira este post de Pickados: ${AppConfig.webBaseUrl}/posts/$postId';
  String get _shareLink => '${AppConfig.webBaseUrl}/posts/$postId';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<PickadosColors>()!;
    final width = MediaQuery.sizeOf(context).width;
    final tileWidth = ((width - 36 - 30) / 4).clamp(68.0, 88.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          18 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: colors.borderSoft,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compartir post',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Elige como quieres enviarlo',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: tileWidth,
                  child: _ShareActionTile(
                    label: 'Mensaje',
                    icon: const Icon(Icons.message_rounded),
                    onTap: () => _handleAction(
                      context,
                      () => _launchUri(
                        context,
                        Uri.parse(
                          'sms:?body=${Uri.encodeComponent(_shareText)}',
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _ShareActionTile(
                    label: 'WhatsApp',
                    icon: const _WhatsAppIcon(),
                    onTap: () =>
                        _handleAction(context, () => _launchWhatsApp(context)),
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _ShareActionTile(
                    label: 'Facebook',
                    icon: const Icon(Icons.facebook_rounded),
                    onTap: () => _handleAction(
                      context,
                      () => _launchUri(
                        context,
                        Uri.parse(
                          'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(_shareLink)}',
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _ShareActionTile(
                    label: 'Copy link',
                    icon: const Icon(Icons.link_rounded),
                    onTap: () =>
                        _handleAction(context, () => _copyLink(context)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    Future<bool> Function() action,
  ) async {
    final success = await action();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop(success);
  }

  Future<bool> _launchWhatsApp(BuildContext context) async {
    final whatsappUri = Uri.parse(
      'whatsapp://send?text=${Uri.encodeComponent(_shareText)}',
    );
    final canOpenWhatsApp = await canLaunchUrl(whatsappUri);
    if (!context.mounted) {
      return false;
    }

    if (canOpenWhatsApp) {
      return _launchUri(context, whatsappUri);
    }

    final webUri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(_shareText)}',
    );
    return _launchUri(context, webUri);
  }

  Future<bool> _launchUri(BuildContext context, Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir esta opcion de compartir.'),
          ),
        );
      }
      return opened;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir esta opcion de compartir.'),
          ),
        );
      }
      return false;
    }
  }

  Future<bool> _copyLink(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: _shareLink));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enlace copiado al portapapeles.')),
        );
      }
      return true;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo copiar el enlace.')),
        );
      }
      return false;
    }
  }
}

class _ShareActionTile extends StatelessWidget {
  const _ShareActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).extension<PickadosColors>()!.softSurface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: icon,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatsAppIcon extends StatelessWidget {
  const _WhatsAppIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        color: Color(0xFF25D366),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'WA',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
