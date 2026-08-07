import 'package:flutter/material.dart';
import 'package:purple_tomato/shared/theme/app_theme.dart';

class AiInsightCard extends StatelessWidget {
  final String content;
  final bool isUser;
  final String? attachmentName;

  const AiInsightCard({
    super.key,
    required this.content,
    required this.isUser,
    this.attachmentName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology,
                color: AppTheme.accentPurple,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.accentPurple : AppTheme.cardDark,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: !isUser
                    ? Border.all(color: AppTheme.cardElevated.withOpacity(0.5))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (attachmentName != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_file, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            attachmentName!,
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SelectableText(
                    content,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppTheme.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  if (!isUser && content.contains('educational')) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'For educational simulation only. Not SEBI registered financial advice.',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }
}
