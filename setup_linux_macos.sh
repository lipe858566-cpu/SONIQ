#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ ! -f android/settings.gradle && ! -f android/settings.gradle.kts ]]; then
  flutter create --platforms=android --org com.soniq --project-name soniq .
fi
flutter pub get
python3 - <<'PY'
from pathlib import Path
import re
p=Path('android/app/src/main/AndroidManifest.xml')
if p.exists():
    p.write_text(re.sub(r'android:label="[^"]*"', 'android:label="SONIQ"', p.read_text()))
PY
flutter pub run flutter_launcher_icons
echo 'SONIQ preparado. Execute flutter run.'
