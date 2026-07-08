#!/usr/bin/env bash
# Write keystore.properties and upload-keystore.jks from GitHub Actions secrets.
set -euo pipefail

if [[ -z "${KEYSTORE_B64:-}" || -z "${STORE_PASSWORD:-}" || -z "${KEY_ALIAS:-}" || -z "${KEY_PASSWORD:-}" ]]; then
  echo '::error::Set repository secrets: RELEASE_KEYSTORE_BASE64, RELEASE_STORE_PASSWORD, RELEASE_KEY_ALIAS, RELEASE_KEY_PASSWORD'
  echo 'See README: "Release signing".'
  exit 1
fi

echo "$KEYSTORE_B64" | base64 -d > "${GITHUB_WORKSPACE}/upload-keystore.jks"

python3 <<'PY'
import os
from pathlib import Path


def escape_java_properties_value(s: str) -> str:
    out = []
    for c in s:
        if c == "\\":
            out.append("\\\\")
        elif c == "\n":
            out.append("\\n")
        elif c == "\r":
            out.append("\\r")
        elif c == "\t":
            out.append("\\t")
        elif c == ":":
            out.append("\\:")
        elif c == "=":
            out.append("\\=")
        else:
            out.append(c)
    return "".join(out)


root = Path(os.environ["GITHUB_WORKSPACE"])
lines = [
    "storeFile=upload-keystore.jks",
    "storePassword=" + escape_java_properties_value(os.environ["STORE_PASSWORD"]),
    "keyAlias=" + escape_java_properties_value(os.environ["KEY_ALIAS"]),
    "keyPassword=" + escape_java_properties_value(os.environ["KEY_PASSWORD"]),
]
(root / "keystore.properties").write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
