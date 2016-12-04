class Nali < Formula
  desc "A tool to display geolocation info of an IP (in Chinese) which could be used in pipelines as well."
  homepage "https://github.com/soffchen/qqwry/tree/master/nali"
  url "https://github.com/soffchen/qqwry/archive/cf861215810b26c02ad340b98b55de8357f64ca8.zip"
  version "1.0.1"
  sha256 "512d555037055b302db18564c8d5c3b817681ad1bf94d8bb402a124658198442"

  option "without-dnsutils-scripts", "Compile without a bunch of scripts which help to pipe nali with dig, nslookup, ping, tracepath & traceroute."

  resource "qqwry_dat" do
    url "https://media.githubusercontent.com/media/QuChao/homebrew-wats/master/Resources/qqwry.dat"
    sha256 "6cd616f09acf62be57d373ac1a58a915a75377008fde058005bfcdaea793a696"
  end

  def install
    # Download a QQWry.Dat first
    resource("qqwry_dat").stage {
      (buildpath/"nali"/"share").install "qqwry.dat"
    }

    Dir.chdir "nali"

    # Fix location to the latest qqwry.dat
    inreplace "configure", "https://chenze.name/wenjian/QQWry.Dat", resource("qqwry_dat").url

    # Remove the scripts if needed
    if build.without? "dnsutils-scripts"
      inreplace "Makefile", /^\s+install bin\/nali-(?!update).*\n/, ""
    end

    system "./configure", "--prefix=#{prefix}"
    system "make"
    system "make", "install"
  end

  def caveats
    s = <<-EOS.undent
    To query geolocation info of a given IP, just run:
      nali 127.0.0.1
    EOS

    if build.with? "dnsutils-scripts"
      s += <<-EOS.undent
    Several handy scripts are created to help you use dnsutils with nali, they're:
      nali-traceroute, nali-tracepath, nali-dig, nali-nslookup & nali-ping
      EOS
    end

    s += <<-EOS.undent
    Or your could just pipe it:
      ping 127.0.0.1 | nali
    To update the geolocation data (qqwry.dat), just run (and you should):
      nali-update
    The geolocation data is from ipip.net and converted into qqwry.dat format with the tool below:
      https://www.shuax.com/archives/ipip_to_qqwry.html
    EOS

    s
  end

  test do
    system "#{bin}/nali", "127.0.0.1"
  end
end
