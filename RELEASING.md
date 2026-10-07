# Releasing

How a new version of a cask in this tap gets published, and how to add a new one. Casks download a zip
from a GitHub release, so a release needs a zip, a tag, and a cask pointing at both.

Users get the update with `brew update && brew upgrade --cask <name>`; nothing else is needed on their side.

## Publish a new version

Example for `quickmsg` (`QuickMSG`, scheme `QuickMSG`, zip `QuickMSG-<version>.zip`, tag `v<version>`).

1. In the project repo, bump `MARKETING_VERSION` in `project.yml`, commit and push to `main`.
2. Build a universal Release (always pass the architectures; a plain build can come out arm64-only):

   ```sh
   xcodegen generate
   xcodebuild -project QuickMSG.xcodeproj -scheme QuickMSG -configuration Release \
     -derivedDataPath build ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO CODE_SIGN_IDENTITY="-" clean build
   lipo -archs build/Build/Products/Release/QuickMSG.app/Contents/MacOS/QuickMSG   # x86_64 arm64
   ```

3. Zip with `ditto` (keeps the bundle intact) and take the checksum:

   ```sh
   ditto -c -k --sequesterRsrc --keepParent build/Build/Products/Release/QuickMSG.app QuickMSG-1.1.zip
   shasum -a 256 QuickMSG-1.1.zip
   ```

4. Create the release with the zip attached. Keep the "you may need to authorize the app" note in the notes:

   ```sh
   gh release create v1.1 QuickMSG-1.1.zip --repo rs2pt/QuickMSG --title "QuickMSG 1.1" --notes "..."
   ```

5. In this repo, edit `Casks/quickmsg.rb`: set `version` and the new `sha256`. Run `brew style --cask Casks/quickmsg.rb`,
   commit and push to `main`.
6. Check it from the user's side: `brew update && brew info --cask rs2pt/tap/quickmsg` shows the new version.
   To try an install without touching `/Applications`:
   `brew install --cask --appdir=/tmp/apps rs2pt/tap/quickmsg`, then `brew uninstall --cask quickmsg`.

The `sha256` must match the uploaded zip exactly. If you re-upload or rebuild a zip, recompute it.

## Add a new project

1. Give the project a release as above (zip + tag).
2. Copy an existing file in `Casks/` to `Casks/<token>.rb` (token is lowercase, dashes) and change `version`, `sha256`, `url`,
   `name`, `desc` (one English line), `homepage` and the `app` name. Keep the `postflight_steps` and `caveats` about authorization.
3. Add a row to the table in `README.md`.
4. `brew style --cask Casks/<token>.rb`, then commit and push.

## Why the authorization notes

The apps are ad-hoc signed and not notarized because there is no paid Apple Developer account. The cask removes the quarantine
flag, but macOS may still ask the user to allow the app. If that account ever exists, sign with a Developer ID, notarize, and the
`postflight_steps` and most of the caveats can go.
