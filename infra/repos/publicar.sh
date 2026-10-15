#!/usr/bin/env bash
# Publica cada microservicio en su propio repositorio (github.com/Kevinso4/logitrack-<servicio>),
# conservando la historia (y los autores) de sus archivos.
#
# tracklogi es el repositorio de integración: aquí se trabaja y se hacen los commits; este script
# vuelve a generar los repositorios por servicio. Requiere: gh (con sesión) y `pip install git-filter-repo`.
#
#   bash infra/repos/publicar.sh                 # todos
#   bash infra/repos/publicar.sh fleet shipment  # solo algunos
set -euo pipefail
cd "$(dirname "$0")/../.."
ORIGEN=$(pwd)
DUENO=Kevinso4
TMP=$(mktemp -d)
SERVICIOS=${*:-gateway fleet tracking shipment maintenance routing notification billing}

for s in $SERVICIOS; do
  echo "== $s"
  git clone -q --no-local "$ORIGEN" "$TMP/$s"
  cd "$TMP/$s"
  extra=()
  [ "$s" = tracking ] && extra=(--path services/simulator)  # Tracking puede embeber el simulador GPS
  # Solo los archivos del servicio y lo que necesita para construirse; services/ pasa a ser la raíz.
  python -m git_filter_repo --quiet --force \
    --path "services/$s" --path services/common --path services/Dockerfile --path services/.dockerignore \
    --path services/requirements.txt --path ".github/workflows/$s.yml" --path .gitignore "${extra[@]}" \
    --path-rename services/:

  # README en la raíz (GitHub lo muestra en la portada) y CI con las rutas del repositorio separado.
  sed -e "s#](db/#]($s/db/#g" -e "s#](.env.example)#]($s/.env.example)#g" \
      -e "s#^cd services/$s\$#cd $s#" -e "/^cd services\$/d" "$s/README.md" > README.md
  sed -i -e 's#"services/#"#g' -e 's#working-directory: services#working-directory: .#' \
      -e 's#cache-dependency-path: services/#cache-dependency-path: #' -e 's#context: services#context: .#' \
      ".github/workflows/$s.yml"
  git add -A
  git -c user.name="Kevin Ayazo" -c user.email=kevinayaso95@gmail.com commit -q \
    -m "docs: README en la raíz y CI con la estructura del repositorio propio [generado desde tracklogi]" || true

  gh repo view "$DUENO/logitrack-$s" >/dev/null 2>&1 || \
    gh repo create "$DUENO/logitrack-$s" --public \
      --description "LogiTrack · microservicio $s (FastAPI, PostgreSQL, RabbitMQ, Docker)" >/dev/null
  git push -q --force "https://github.com/$DUENO/logitrack-$s.git" HEAD:main
  echo "   https://github.com/$DUENO/logitrack-$s ($(git rev-list --count HEAD) commits)"
  cd "$ORIGEN"
done
rm -rf "$TMP"
