#!/usr/bin/env bash
# Publish a new version of a cask in this tap: build, zip, GitHub release, update the cask.
#
#   scripts/release.sh <cask> <version> [--dry-run] [--notes "text"]
#
# The project's project.yml must already have MARKETING_VERSION == <version> on a clean `main`
# that matches origin/main (bump it through the normal branch/PR flow first).
# --dry-run builds and zips but publishes nothing. See RELEASING.md for the manual steps.
set -euo pipefail

usage() { sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-1}"; }
[ $# -ge 2 ] || usage

token=$1; version=$2; shift 2
dry=0; notes=""
while [ $# -gt 0 ]; do
  case $1 in
    --dry-run) dry=1 ;;
    --notes) notes=${2:?--notes needs a value}; shift ;;
    -h|--help) usage 0 ;;
    *) echo "unknown option: $1" >&2; usage ;;
  esac
  shift
done

# --- projects in this tap -----------------------------------------------------------------
# dir: folder next to this repo; xcodeproj/scheme/app: build names; zip: release asset prefix
case $token in
  quickmsg)        repo=rs2pt/QuickMSG;       dir=QuickMSG;       xcproj=QuickMSG; app=QuickMSG; zip=QuickMSG ;;
  quicknfo-modern) repo=rs2pt/QuickNFO-Modern; dir=QuickNFOModern; xcproj=QuickNFO; app=QuickNFO; zip=QuickNFO-Modern ;;
  *) echo "unknown cask '$token' (add it to scripts/release.sh)" >&2; exit 1 ;;
esac

tap_repo=rs2pt/homebrew-tap
root=$(cd "$(dirname "$0")/../.." && pwd)
proj=$root/$dir
asset="$zip-$version.zip"
tag="v$version"
auth_note="**You may need to authorize the app the first time.** It is not signed with an Apple Developer ID or notarized, because the author doesn't have a paid Apple Developer account. If macOS blocks the first launch, allow it under System Settings → Privacy & Security → \"Open Anyway\", or run \`xattr -dr com.apple.quarantine /Applications/$app.app\`. Installing with \`brew install --cask rs2pt/tap/$token\` does this for you."

# --- checks -------------------------------------------------------------------------------
[ -d "$proj/.git" ] || { echo "project not found: $proj" >&2; exit 1; }
[ -z "$(git -C "$proj" status --porcelain)" ] || { echo "$dir has uncommitted changes" >&2; exit 1; }
[ "$(git -C "$proj" branch --show-current)" = main ] || { echo "$dir is not on main" >&2; exit 1; }
git -C "$proj" fetch -q --tags origin
[ "$(git -C "$proj" rev-parse HEAD)" = "$(git -C "$proj" rev-parse origin/main)" ] \
  || { echo "$dir main differs from origin/main (push or pull first)" >&2; exit 1; }
grep -Eq "MARKETING_VERSION: \"?$version\"?\$" "$proj/project.yml" \
  || { echo "project.yml MARKETING_VERSION is not $version" >&2; exit 1; }
if gh release view "$tag" --repo "$repo" >/dev/null 2>&1; then
  [ $dry -eq 1 ] && echo "note: release $tag already exists (ignored in --dry-run)" \
    || { echo "release $tag already exists on $repo" >&2; exit 1; }
fi

# --- build (universal) --------------------------------------------------------------------
echo "==> Building $app $version"
( cd "$proj"
  xcodegen generate -q
  xcodebuild -project "$xcproj.xcodeproj" -scheme "$xcproj" -configuration Release -derivedDataPath build \
    ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO CODE_SIGN_IDENTITY="-" clean build 2>&1 \
    | grep -E ": error:|BUILD (SUCCEEDED|FAILED)" || true )
built=$proj/build/Build/Products/Release/$app.app
[ -d "$built" ] || { echo "build failed: $built missing" >&2; exit 1; }
archs=$(lipo -archs "$built/Contents/MacOS/$app")
case $archs in *arm64*x86_64*|*x86_64*arm64*) ;; *) echo "not universal: $archs" >&2; exit 1 ;; esac

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
ditto -c -k --sequesterRsrc --keepParent "$built" "$work/$asset"
sha=$(shasum -a 256 "$work/$asset" | cut -d' ' -f1)

# --- notes --------------------------------------------------------------------------------
if [ -z "$notes" ]; then
  prev=$(git -C "$proj" describe --tags --abbrev=0 2>/dev/null || true)
  if [ -n "$prev" ]; then changes=$(git -C "$proj" log --pretty='- %s' "$prev"..HEAD); else changes="Initial release."; fi
  notes="$changes"
fi
notes="$notes

Universal binary (Apple silicon and Intel), macOS 13+.

$auth_note"

echo "==> $asset  sha256 $sha  ($archs)"
if [ $dry -eq 1 ]; then
  echo "==> --dry-run: nothing published. Release notes would be:"; echo "$notes"; exit 0
fi

# --- publish ------------------------------------------------------------------------------
echo "==> Creating release $tag on $repo"
gh release create "$tag" "$work/$asset" --repo "$repo" --target main --title "$app $version" --notes "$notes"

echo "==> Updating cask in $tap_repo"
gh repo clone "$tap_repo" "$work/tap" -- -q
cask="$work/tap/Casks/$token.rb"
sed -i.bak -E "s/^(  version )\"[^\"]*\"/\1\"$version\"/; s/^(  sha256 )\"[^\"]*\"/\1\"$sha\"/" "$cask"
rm -f "$cask.bak"
git -C "$work/tap" diff --stat
git -C "$work/tap" commit -qam "$token $version"
git -C "$work/tap" push -q origin main

echo "==> Verifying"
brew update >/dev/null 2>&1 || true
brew fetch --cask "rs2pt/tap/$token" 2>&1 | tail -2
echo "Done. Users update with: brew update && brew upgrade --cask $token"
