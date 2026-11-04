#!/usr/bin/env bash
# Garde-fou de la règle 4 : le socle wami_core n'embarque aucun plugin natif.
#
# Tout ce qui est déclaré dans packages/wami_core/pubspec.yaml part dans LES DEUX apps.
# Un plugin natif (caméra, scan, cartes, localisation…) y ajouterait du code Android/iOS
# et des permissions inutiles à l'une des deux apps — source de refus sur les stores.
#
# Usage : ./tool/check_core_deps.sh     (depuis la racine du dépôt)
# Pour autoriser un nouveau paquet en pur Dart : l'ajouter à ALLOWED ci-dessous,
# après avoir vérifié sur pub.dev qu'il n'a pas de dossier android/ ni ios/.

set -euo pipefail

PUBSPEC="packages/wami_core/pubspec.yaml"

# Paquets en pur Dart / Flutter autorisés dans le socle.
ALLOWED=(
  flutter
  equatable
  get_it
  go_router
  dio
  flutter_svg
)

# Noms déclarés à 2 espaces d'indentation dans le bloc « dependencies: ».
deps=$(awk '
  /^dependencies:/ { inblock = 1; next }
  /^[^ #]/         { inblock = 0 }
  inblock && /^  [a-z0-9_]+:/ { sub(/^  /, ""); sub(/:.*/, ""); print }
' "$PUBSPEC")

status=0
for dep in $deps; do
  ok=0
  for allowed in "${ALLOWED[@]}"; do
    [[ "$dep" == "$allowed" ]] && ok=1 && break
  done
  if [[ $ok -eq 0 ]]; then
    echo "REFUSÉ : « $dep » n'est pas autorisé dans wami_core."
    echo "  → S'il ne sert qu'à une app, déclarez-le dans apps/<app>/pubspec.yaml."
    echo "  → S'il sert aux deux apps et n'a pas de code natif, ajoutez-le à ALLOWED dans $0."
    echo "  → S'il a du code natif, créez un paquet dédié (ex. packages/wami_maps)."
    status=1
  fi
done

[[ $status -eq 0 ]] && echo "OK : wami_core ne contient que des paquets autorisés."
exit $status
