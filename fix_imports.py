import os
import re

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r') as f:
                content = f.read()
            
            # replace various relative imports with package imports
            content = re.sub(r"import\s+'(?:\.\./)+shared/theme/app_theme\.dart';", "import 'package:purple_tomato/shared/theme/app_theme.dart';", content)
            content = re.sub(r"import\s+'(?:\.\./)+core/theme/app_theme\.dart';", "import 'package:purple_tomato/shared/theme/app_theme.dart';", content)
            content = re.sub(r"import\s+'package:purple_tomato/core/theme/app_theme\.dart';", "import 'package:purple_tomato/shared/theme/app_theme.dart';", content)
            
            # fix others
            content = re.sub(r"import\s+'(?:\.\./)+domain/models/([^']+)\.dart';", r"import 'package:purple_tomato/domain/models/\1.dart';", content)
            content = re.sub(r"import\s+'(?:\.\./)+core/providers/([^']+)\.dart';", r"import 'package:purple_tomato/core/providers/\1.dart';", content)
            content = re.sub(r"import\s+'(?:\.\./)+core/services/([^']+)\.dart';", r"import 'package:purple_tomato/core/services/\1.dart';", content)
            content = re.sub(r"import\s+'(?:\.\./)+core/constants/([^']+)\.dart';", r"import 'package:purple_tomato/core/constants/\1.dart';", content)
            content = re.sub(r"import\s+'(?:\.\./)+shared/widgets/([^']+)\.dart';", r"import 'package:purple_tomato/shared/widgets/\1.dart';", content)
            
            # fix cross-feature imports
            content = re.sub(r"import\s+'(?:\.\./)+features/([^']+)\.dart';", r"import 'package:purple_tomato/features/\1.dart';", content)

            with open(path, 'w') as f:
                f.write(content)
