cask "quickmsg" do
  version "1.0"
  sha256 "86e8dd4e927c7dc527ed9777a26461cea5543b0c3975e77d4b50092cf6a19de9"

  url "https://github.com/rs2pt/QuickMSG/releases/download/v#{version}/QuickMSG-#{version}.zip"
  name "QuickMSG"
  desc "Quick Look preview for Outlook .msg files"
  homepage "https://github.com/rs2pt/QuickMSG"

  depends_on macos: :ventura

  app "QuickMSG.app"

  # Not notarized (no paid Apple Developer account): drop the quarantine flag.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/QuickMSG.app"], must_succeed: false
  end

  caveats <<~EOS
    QuickMSG is not signed with an Apple Developer ID or notarized (the author has no paid
    Apple Developer account). The quarantine flag was removed for you, but if macOS still asks
    you to authorize the app, allow it under System Settings → Privacy & Security → "Open Anyway".

    Open the app once so macOS registers the extension. If previews don't appear
    right away, run: qlmanage -r
  EOS
end
