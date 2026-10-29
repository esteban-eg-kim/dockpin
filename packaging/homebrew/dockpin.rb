# Homebrew cask. Put this in the tap repository esteban-eg-kim/homebrew-tap
# (Casks/dockpin.rb), then:  brew install --cask esteban-eg-kim/tap/dockpin
# scripts/release.sh prints the version and sha256 to paste here.
cask "dockpin" do
  version "0.1.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/esteban-eg-kim/dockpin/releases/download/v#{version}/dockpin-#{version}.zip"
  name "dockpin"
  desc "Keep the Dock on one display"
  homepage "https://github.com/esteban-eg-kim/dockpin"

  depends_on macos: ">= :ventura"

  app "dockpin.app"

  # Not notarized (no Apple Developer ID): drop the quarantine flag so Gatekeeper lets it open.
  postflight do
    system_command "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "#{appdir}/dockpin.app"]
  end

  uninstall quit: "io.github.esteban-eg-kim.dockpin",
            login_item: "dockpin"

  zap trash: "~/Library/Preferences/io.github.esteban-eg-kim.dockpin.plist"

  caveats <<~EOS
    dockpin needs Accessibility access:
      System Settings › Privacy & Security › Accessibility › dockpin
      (macOS 27: Privacy & Security › Device Control and Data Access)
    Open dockpin once and it walks you through it. Upgrades keep the permission.
  EOS
end
