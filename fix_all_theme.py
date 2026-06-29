import os
import re

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r') as f:
                content = f.read()
            
            # fix any broken theme imports to use the correct package path
            content = re.sub(r"import\s+['\"].*app_theme\.dart['\"];", "import 'package:purple_tomato/shared/theme/app_theme.dart';", content)
            
            with open(path, 'w') as f:
                f.write(content)
