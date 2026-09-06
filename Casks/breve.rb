cask "breve" do
  version "1.0.2"
  sha256 "aa540a6cb4fb07b4e1d81e3b49d51689ca41d34d9b54d0866001d9905a6c285e"

  url "https://github.com/xinnaider/breve/releases/download/v#{version}/Breve.zip"
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
