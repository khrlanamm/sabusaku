#!/usr/bin/env bash
# Deploys the Cloud Functions to production a few at a time.
#
#   tool/deploy-functions.sh                 every function in functions/src/index.ts
#   tool/deploy-functions.sh addTeacher …    only these
#
# Cloud Run's CPU quota in asia-southeast2 is 20 vCPU for all running
# instances together. A deploy starts one instance per function for its health
# check, and those instances stay up for a while, so deploying everything at
# once can fail with "Quota exceeded for total allowable CPU per project per
# region". Small batches, retried after a pause, stay inside the quota. A
# function whose revision fails keeps serving its previous revision.
set -euo pipefail
cd "$(dirname "$0")/.."

PROJECT=sabusaku
BATCH="${BATCH:-4}"
RETRIES="${RETRIES:-5}"
PAUSE="${PAUSE:-120}"

if [ $# -gt 0 ]; then
  names=("$@")
else
  names=()
  while IFS= read -r name; do names+=("$name"); done < <(
    sed -nE 's/^export \{([A-Za-z]+)\} from .*/\1/p' functions/src/index.ts
  )
fi

log="$(mktemp)"
trap 'rm -f "$log"' EXIT

for ((i = 0; i < ${#names[@]}; i += BATCH)); do
  batch=("${names[@]:i:BATCH}")
  only="$(printf 'functions:%s,' "${batch[@]}")"
  only="${only%,}"
  for ((try = 1; ; try++)); do
    echo "== ${batch[*]} (percobaan $try)"
    if firebase deploy --only "$only" --project "$PROJECT" >"$log" 2>&1; then
      grep -E '✔  functions\[' "$log" || true
      break
    fi
    grep -E '✔  functions\[|Error|Quota' "$log" || true
    if grep -q 'Changing from an HTTPS function to a background triggered function' "$log"; then
      # A trigger whose first deploy failed is left behind as an HTTPS
      # function. It never ran, but deleting it is left to a person.
      echo "Hapus dulu trigger setengah jadi itu, lalu jalankan lagi:" >&2
      echo "  firebase functions:delete <nama> --region asia-southeast2 --project $PROJECT" >&2
      exit 1
    fi
    if ! grep -q 'Quota exceeded' "$log" || [ "$try" -ge "$RETRIES" ]; then
      echo "Gagal. Log lengkap: firebase deploy --only $only --project $PROJECT" >&2
      exit 1
    fi
    echo "Kuota CPU penuh; tunggu ${PAUSE} detik sampai instance idle mati."
    sleep "$PAUSE"
  done
done
echo "Selesai: ${#names[@]} function."
