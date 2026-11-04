#!/usr/bin/env bash
# Génère les dossiers android/ et ios/ de WAMI Pro puis y déclare SES permissions
# (règle 4 : jamais dans le socle, jamais dans WAMI Business).
#
# Usage : ./tool/setup_pro_platform.sh        (depuis la racine, Flutter ≥ 3.27 requis)
# Idempotent : relançable sans doubler les lignes.
set -euo pipefail

APP="apps/wami_pro"
cd "$(dirname "$0")/.."

command -v flutter >/dev/null || { echo "Flutter est introuvable dans le PATH." >&2; exit 1; }

# L'identifiant bj.wami devient l'ID de store : à valider avant la première publication.
( cd "$APP" && flutter create --org bj.wami --project-name wami_pro --platforms android,ios . )

python3 - "$APP" <<'PY'
import re, sys, pathlib

app = pathlib.Path(sys.argv[1])

# ── Android : permissions ─────────────────────────────────────────────────────
manifest = app / "android/app/src/main/AndroidManifest.xml"
text = manifest.read_text()
perms = [
    "android.permission.INTERNET",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_BACKGROUND_LOCATION",   # suivi écran éteint (justification Play Console)
    "android.permission.FOREGROUND_SERVICE",
    "android.permission.FOREGROUND_SERVICE_LOCATION",  # Android 14+
    "android.permission.CAMERA",                       # pièces, photos de colis
    "android.permission.POST_NOTIFICATIONS",           # offres, rappels
]
lines = "".join(
    f'    <uses-permission android:name="{p}"/>\n'
    for p in perms if p not in text
)
# Permissions que des plugins pourraient ajouter sans que Pro en ait besoin.
removed = ["android.permission.RECORD_AUDIO", "android.permission.READ_CONTACTS"]
lines += "".join(
    f'    <uses-permission android:name="{p}" tools:node="remove"/>\n'
    for p in removed if f'{p}" tools:node="remove"' not in text
)
if lines:
    text = text.replace("<application", lines + "    <application", 1)
if "xmlns:tools" not in text:
    text = text.replace("<manifest ", '<manifest xmlns:tools="http://schemas.android.com/tools" ', 1)
manifest.write_text(text)

# flutter_secure_storage exige minSdk 23.
for name in ("build.gradle", "build.gradle.kts"):
    g = app / "android/app" / name
    if g.exists():
        s = g.read_text()
        s = re.sub(r"minSdk(Version)?\s*=?\s*flutter\.minSdkVersion", "minSdk = 23", s)
        g.write_text(s)

# ── iOS : textes d'usage et mode arrière-plan ────────────────────────────────
plist = app / "ios/Runner/Info.plist"
p = plist.read_text()
entries = {
    "NSLocationWhenInUseUsageDescription":
        "WAMI Pro utilise votre position pour vous proposer des missions proches et suivre vos courses.",
    "NSLocationAlwaysAndWhenInUseUsageDescription":
        "WAMI Pro utilise votre position même app fermée pour suivre vos courses et vous proposer des missions proches.",
    "NSCameraUsageDescription":
        "L’appareil photo sert à photographier vos documents et les colis que vous livrez.",
    "NSPhotoLibraryUsageDescription":
        "Vous pouvez choisir une photo existante pour vos documents.",
}
add = "".join(f"\t<key>{k}</key>\n\t<string>{v}</string>\n" for k, v in entries.items() if k not in p)
if "UIBackgroundModes" not in p:
    add += "\t<key>UIBackgroundModes</key>\n\t<array>\n\t\t<string>location</string>\n\t</array>\n"
if "LSApplicationQueriesSchemes" not in p:
    add += "\t<key>LSApplicationQueriesSchemes</key>\n\t<array>\n\t\t<string>tel</string>\n\t\t<string>sms</string>\n\t</array>\n"
if add:
    p = p.replace("</dict>\n</plist>", add + "</dict>\n</plist>", 1)
plist.write_text(p)
print("Permissions de WAMI Pro déclarées. Relisez le manifeste fusionné avant publication (README).")
PY
