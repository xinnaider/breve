cask "breve" do
  version "1.0.0"
  sha256 "2be7c123317c6dca7206c13c6bcc6c3528acb44f9d0e88f480899fa04af3c3f9"

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
