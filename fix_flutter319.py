import os
import re

# 1. Fix app_theme.dart
theme_path = 'lib/shared/theme/app_theme.dart'
if os.path.exists(theme_path):
    with open(theme_path, 'r') as f:
        content = f.read()
    content = content.replace('CardThemeData(', 'CardTheme(')
    content = content.replace('DialogThemeData(', 'DialogTheme(')
    content = content.replace('WidgetState.', 'MaterialState.')
    content = content.replace('WidgetStateProperty.', 'MaterialStateProperty.')
    with open(theme_path, 'w') as f:
        f.write(content)

# 2. Fix app_logger.dart
logger_path = 'lib/core/utils/app_logger.dart'
if os.path.exists(logger_path):
    with open(logger_path, 'r') as f:
        content = f.read()
    content = content.replace('static void warn(String message, {String? tag}) {', 
                              'static void warn(String message, {String? tag, dynamic error}) {')
    with open(logger_path, 'w') as f:
        f.write(content)

# 3. Fix recent_transactions_section.dart
recent_tx_path = 'lib/features/market/widgets/recent_transactions_section.dart'
if os.path.exists(recent_tx_path):
    with open(recent_tx_path, 'r') as f:
        content = f.read()
    if 'hive_service.dart' not in content:
        content = "import 'package:purple_tomato/core/services/hive_service.dart';\n" + content
        with open(recent_tx_path, 'w') as f:
            f.write(content)
