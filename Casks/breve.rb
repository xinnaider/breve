cask "breve" do
  version "1.0.1"
  sha256 "7fc618fae16d098b5d1679bc939983cbf8f679eb99a17d1bd83f5a8c5190a3f9"

  url "https://github.com/xinnaider/breve/releases/download/v#{version}/Breve.zip",
      verified: "github.com/xinnaider/breve/"
  name "Breve"
  desc "Parceiro de estudo no canto da tela"
  homepage "https://breve.jfernando.dev/"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: :sonoma
  depends_on arch: :arm64

  app "Breve.app"

  zap trash: "~/Library/Preferences/dev.fordevs.breve.plist"
end
