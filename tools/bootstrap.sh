#!/usr/bin/env bash
set -euo pipefail
# Install outside the project; do not change source, manifests or lockfiles.
for tool in git curl unzip make g++ python3; do command -v "$tool" >/dev/null || { echo "Missing prerequisite: $tool" >&2; exit 1; }; done
mkdir -p /workspace/tools/rojo /workspace/tools/luau
setup_tmp=$(mktemp -d /tmp/universe-setup.XXXXXX)
trap 'rm -rf "$setup_tmp"' EXIT
curl -fLsS https://github.com/rojo-rbx/rojo/releases/download/v7.5.1/rojo-7.5.1-linux-x86_64.zip -o "$setup_tmp/rojo.zip"
printf '%s  %s\n' '0d600df6c4c48a9d09c701d0c2a109c55c2db833cd9766fd7d1e6e2684843d53' "$setup_tmp/rojo.zip" | sha256sum -c -
unzip -oq "$setup_tmp/rojo.zip" -d /workspace/tools/rojo
git clone --quiet --depth 1 --branch 0.695 https://github.com/luau-lang/luau.git "$setup_tmp/luau"
test "$(git -C "$setup_tmp/luau" rev-parse HEAD)" = '1f6ff5d6f0072f2fab2adf35d1ffbaae7d848ad0'
make -s -C "$setup_tmp/luau" config=release luau luau-compile -j2 > "$setup_tmp/build.log" 2>&1 || { tail -40 "$setup_tmp/build.log"; exit 1; }
cp "$setup_tmp/luau/build/release/luau" "$setup_tmp/luau/build/release/luau-compile" /workspace/tools/luau/
/workspace/tools/rojo/rojo --version
/workspace/tools/luau/luau /workspace/roblox/tests/economy.spec.luau
