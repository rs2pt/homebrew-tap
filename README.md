# homebrew-tap

[Homebrew](https://brew.sh) tap for my macOS Quick Look extensions.

```sh
brew tap rs2pt/tap
```

| Cask | Install | What it does |
| --- | --- | --- |
| [`quickmsg`](https://github.com/rs2pt/QuickMSG) | `brew install --cask rs2pt/tap/quickmsg` | Preview Outlook `.msg` files in Finder (press space) |
| [`quicknfo-modern`](https://github.com/rs2pt/QuickNFO-Modern) | `brew install --cask rs2pt/tap/quicknfo-modern` | Preview and thumbnails for `.nfo` files, rebuilt for current macOS on Apple silicon |

You can install without tapping first by using the full name, as above.

## About authorization

These apps are not signed with an Apple Developer ID or notarized, because I don't have a paid Apple
Developer account. The casks remove the quarantine flag after installing, so macOS usually opens them
without complaint. If it still asks you to authorize an app, allow it under System Settings →
Privacy & Security → "Open Anyway".

If previews don't appear right away, run `qlmanage -r`.

## Updating

```sh
brew update && brew upgrade --cask quickmsg quicknfo-modern
```
