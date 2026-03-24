#!/usr/bin/env bash
# Post-create setup: downloads SpongyCastle JARs and writes local.properties
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "==> Downloading SpongyCastle JARs for TLS 1.2 support..."
BASE="https://repo1.maven.org/maven2/com/madgag/spongycastle"
curl -fL "${BASE}/core/1.58.0.0/core-1.58.0.0.jar"            -o "${PROJECT_DIR}/libs/spongycastle-core-1.58.0.0.jar"
curl -fL "${BASE}/prov/1.58.0.0/prov-1.58.0.0.jar"            -o "${PROJECT_DIR}/libs/spongycastle-prov-1.58.0.0.jar"
curl -fL "${BASE}/bctls-jdk15on/1.58.0.0/bctls-jdk15on-1.58.0.0.jar" \
                                                                -o "${PROJECT_DIR}/libs/spongycastle-bctls-jdk15on-1.58.0.0.jar"
echo "    SpongyCastle JARs downloaded."

echo "==> Writing local.properties (sdk.dir -> ANDROID_HOME)..."
echo "sdk.dir=${ANDROID_HOME}" > "${PROJECT_DIR}/local.properties"
echo "    local.properties written."

echo "==> Setup complete. Run: tools/nook-adb.sh build"
