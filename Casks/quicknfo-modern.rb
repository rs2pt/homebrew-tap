cask "quicknfo-modern" do
  version "2.0"
  sha256 "b90bfb4e1128714ea5d6b0a34a81b8f596febdd23345bc8fc0a8f58f2b83149b"

  url "https://github.com/rs2pt/QuickNFO-Modern/releases/download/v#{version}/QuickNFO-Modern-#{version}.zip"
  name "QuickNFO Modern"
  desc "Quick Look preview and thumbnails for .nfo files"
  homepage "https://github.com/rs2pt/QuickNFO-Modern"

  depends_on macos: :ventura

  app "QuickNFO.app"

  # Not notarized (no paid Apple Developer account): drop the quarantine flag and register the extension(s).
  postflight_steps do
    run "/usr/bin/xattr",
        args: ["-dr", "com.apple.quarantine", "{{appdir}}/QuickNFO.app"],
        must_succeed: false
    run "/usr/bin/pluginkit",
        args: ["-a", "{{appdir}}/QuickNFO.app/Contents/PlugIns/PreviewExtension.appex"],
        must_succeed: false
    run "/usr/bin/pluginkit",
        args: ["-a", "{{appdir}}/QuickNFO.app/Contents/PlugIns/ThumbnailExtension.appex"],
        must_succeed: false
  end

  caveats <<~EOS
    QuickNFO Modern is not signed with an Apple Developer ID or notarized (the author has no
    paid Apple Developer account). The quarantine flag was removed for you, but if macOS still
    asks you to authorize the app, allow it under System Settings → Privacy & Security → "Open Anyway".

    If previews or thumbnails don't appear right away, run: qlmanage -r && qlmanage -r cache
  EOS
end
