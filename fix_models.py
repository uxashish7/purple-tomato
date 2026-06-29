import os
import re

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r') as f:
                content = f.read()
            
            # fix broken relative imports to models
            content = re.sub(r"import\s+'(?:\.\./)+models/([^']+)\.dart';", r"import 'package:purple_tomato/domain/models/\1.dart';", content)
            
            with open(path, 'w') as f:
                f.write(content)
