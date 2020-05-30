class Powerline < Formula
  homepage "https://github.com/powerline/fontpatcher"
  url "https://github.com/powerline/fontpatcher/archive/c3488091611757cb02014ed7ed2f11be0208da83.zip"
  sha256 "bf736ea3d18395ba197a492fc8b0ddb47b44142e101b6c780b2a8380503d5a36"
  version "20160320"
  def initialize(name = "powerline", path = Pathname(__FILE__), spec = "stable")
    super
  end
  patch :DATA
end

class Ricty < Formula
  desc "Font for programming"
  homepage "https://rictyfonts.github.io/"
  url "https://raw.githubusercontent.com/rictyfonts/rictyfonts.github.io/master/files/ricty_generator-4.1.1.sh"
  sha256 "86bf0fed84ef806690b213798419405d7ca2a1a4bed4f6a28b87c2e2d07ad60d"

  option "with-powerline", "Patch for Powerline"
  option "without-fullwidth", "Disable fullwidth ambiguous characters"
  option "without-visible-space", "Disable visible zenkaku space"
  option "with-patch-in-place", "Patch Powerline glyphs directly into Ricty fonts without creating new 'for Powerline' fonts"

  depends_on "fontforge" => :build

  resource "inconsolataregular" do
    url "https://github.com/google/fonts/raw/0f203e3740b5eb77e0b179dff1e5869482676782/ofl/inconsolata/static/Inconsolata-Regular.ttf" 
    sha256 "0f11ac40d1618e1aa1adb7322a14980a0b0c943421124022073f83236d15f0d5"
    version "0f203e3"
  end

  resource "inconsolatabold" do
    url "https://github.com/google/fonts/raw/0f203e3740b5eb77e0b179dff1e5869482676782/ofl/inconsolata/static/Inconsolata-Bold.ttf"
    sha256 "69deb4d3626bcdce00331458e62de49e0ae58236626841014939dd8c5119abb4"
    version "0f203e3"
  end

  resource "migu1mfonts" do
    url "https://osdn.net/frs/redir.php?m=gigenet&f=mix-mplus-ipa%2F72511%2Fmigu-1m-20200307.zip"
    sha256 "a4770fca22410668d2747d7898ed4d7ef5d92330162ee428a6efd5cf247d9504"
  end

  def install
    resource("migu1mfonts").stage { buildpath.install Dir["*"] }
    resource("inconsolataregular").stage { buildpath.install Dir["*"] }
    resource("inconsolatabold").stage { buildpath.install Dir["*"] }

    if build.with? "powerline"
      powerline = Powerline.new
      powerline.brew { buildpath.install Dir["*"] }
      powerline.patch
      rename_from = "(Ricty|Discord|Bold(?=Oblique))-?"
      rename_to = "\\1 "
    end

    ricty_args = ["Inconsolata-Regular.ttf", "Inconsolata-Bold.ttf", "migu-1m-regular.ttf", "migu-1m-bold.ttf"]
    ricty_args.unshift("-z") if build.without? "visible-space"
    ricty_args.unshift("-a") if build.without? "fullwidth"

    system "sh", "./ricty_generator-#{version}.sh", *ricty_args

    if build.with? "powerline"
      powerline_args = []
      powerline_args.unshift("--no-rename") if build.with? "patch-in-place"
      Dir["Ricty*.ttf"].each do |ttf|
        system "fontforge", "-lang=py", "-script", buildpath/"scripts/powerline-fontpatcher", *powerline_args, ttf
        mv ttf.gsub(/#{rename_from}/, rename_to), ttf if build.with? "patch-in-place"
      end
    end

    (share/"fonts").install Dir["Ricty*.ttf"]
  end

  def caveats; <<~EOS
    ***************************************************
    Generated files:
      #{Dir[share + "fonts/Ricty*.ttf"].join("\n      ")}
    ***************************************************
    To install Ricty:
      $ cp -f #{share}/fonts/Ricty*.ttf ~/Library/Fonts/
      $ fc-cache -vf
    ***************************************************
    EOS
  end
end

__END__
--- a/scripts/powerline-fontpatcher
+++ b/scripts/powerline-fontpatcher
@@ -79,6 +79,13 @@
 		if bbox[3] > target_bb[3]:
 			target_bb[3] = bbox[3]
 
+		# Ignore the above calculation and
+		# manually set the best values for Ricty
+		target_bb[0]=0
+		target_bb[1]=-525
+		target_bb[2]=1025
+		target_bb[3]=1650
+
 	# Find source and target size difference for scaling
 	x_ratio = (target_bb[2] - target_bb[0]) / (source_bb[2] - source_bb[0])
 	y_ratio = (target_bb[3] - target_bb[1]) / (source_bb[3] - source_bb[1])
