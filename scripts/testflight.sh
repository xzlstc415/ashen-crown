#!/usr/bin/env bash
# Release the iOS app: raise the version, archive, upload to TestFlight, commit and tag.
#
#   scripts/testflight.sh            next patch version (2.0.1 -> 2.0.2)
#   scripts/testflight.sh 2.1.0      a chosen version
#
# The tree must be clean: commit the change first, then release. The version is
# MARKETING_VERSION in ios/project.yml; this script raises it, builds with that
# number, and only after the upload succeeds commits "Release x.y.z" (project.yml
# and the regenerated project), tags vx.y.z and pushes. A failed build or upload
# puts both files back. The build number is the time, so every upload is higher
# than the last.
#
# Signing is manual (Release config of the app target in ios/project.yml): the "Apple Distribution: Zhiliang Xing" identity in the login
# keychain and the "Ruinaccord App Store" profile (created through the App Store
# Connect API on 2026-10-15, expires 2027-10-07). The upload authenticates with the
# team API key in ~/.appstoreconnect/private_keys.
set -euo pipefail
cd "$(dirname "$0")/.."

KEY_ID=265ZV23WG2
ISSUER=d0852cf7-20ea-44e5-80b8-ddf09df4f765
KEY=~/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8
BUNDLE=com.hermes-eris.ruinaccord
PROFILE="Ruinaccord App Store"
BUILD=$(date +%Y%m%d%H%M)
OUT=ios/.build/release

if [ -n "$(git status --porcelain)" ]; then echo "working tree is not clean; commit first, then release" >&2; exit 1; fi
[ -f ios/Ruinaccord/Resources/GoogleService-Info.plist ] || { echo "ios/Ruinaccord/Resources/GoogleService-Info.plist is missing; the build would run offline" >&2; exit 1; }

current=$(sed -nE 's/^ *MARKETING_VERSION: "([0-9.]+)"/\1/p' ios/project.yml)
[ -n "$current" ] || { echo "no MARKETING_VERSION in ios/project.yml" >&2; exit 1; }
if [ $# -ge 1 ]; then
  VERSION=$1
  [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "version must be x.y.z, got '$VERSION'" >&2; exit 1; }
else
  VERSION=$(echo "$current" | awk -F. '{printf "%d.%d.%d", $1, $2, $3 + 1}')
fi
if git rev-parse -q --verify "refs/tags/v$VERSION" >/dev/null; then echo "v$VERSION is already tagged" >&2; exit 1; fi

echo "== release $VERSION ($BUILD), was $current"
sed -i '' -E "s/^( *MARKETING_VERSION: )\"[0-9.]+\"/\1\"$VERSION\"/" ios/project.yml
# Until the upload succeeds, a failure puts the version back in both files.
trap 'git checkout -q -- ios/project.yml ios/Ruinaccord.xcodeproj/project.pbxproj' EXIT

(cd ios && xcodegen generate -q)
rm -rf "$OUT"; mkdir -p "$OUT"
xcodebuild -project ios/Ruinaccord.xcodeproj -scheme Ruinaccord -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$OUT/Ruinaccord.xcarchive" \
  -clonedSourcePackagesDirPath ios/.spm -derivedDataPath ios/.build/DerivedData-release archive \
  MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$BUILD" | grep -E "error:|ARCHIVE (SUCCEEDED|FAILED)"
[ -d "$OUT/Ruinaccord.xcarchive" ] || { echo "archive failed" >&2; exit 1; }

cat > "$OUT/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>teamID</key><string>7Z6WNXV55C</string>
  <key>signingStyle</key><string>manual</string>
  <key>signingCertificate</key><string>Apple Distribution</string>
  <key>provisioningProfiles</key><dict><key>$BUNDLE</key><string>$PROFILE</string></dict>
  <key>uploadSymbols</key><true/>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict></plist>
PLIST

xcodebuild -exportArchive -archivePath "$OUT/Ruinaccord.xcarchive" -exportPath "$OUT/export" \
  -exportOptionsPlist "$OUT/ExportOptions.plist" \
  -authenticationKeyPath "$KEY" -authenticationKeyID "$KEY_ID" -authenticationKeyIssuerID "$ISSUER" \
  | grep -E "error|Upload succeeded|EXPORT (SUCCEEDED|FAILED)"

trap - EXIT
git commit -q -m "Release $VERSION" -- ios/project.yml ios/Ruinaccord.xcodeproj/project.pbxproj
git tag "v$VERSION"
git push -q origin HEAD "v$VERSION"
echo "uploaded $VERSION ($BUILD), tagged v$VERSION; it reaches TestFlight once Apple has processed it"
