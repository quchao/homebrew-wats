# Modified from https://github.com/Homebrew/homebrew-core/blob/master/Formula/dnsmasq.rb
class DnsmasqFastLookup < Formula
  desc "A fork of the original lightweight DNS forwarder and DHCP server, featuring fast ipset/server/address lookups."
  homepage "https://github.com/infinet/dnsmasq"
  url "https://github.com/infinet/dnsmasq/archive/137dcbc95d9240e492c913f2217795b028be805e.zip"
  version "r20170221"
  sha256 "d8d181672458626764ec78076928143d7033d2c28986db110c18e174a93c4752"

  conflicts_with "dnsmasq", :because => "dnsmasq-fast-lookup symlink with the name for compatibility with dnsmasq"

  option "with-libidn", "Compile with IDN support"
  option "with-dnssec", "Compile with DNSSEC support"

  depends_on "pkg-config" => :build
  depends_on "libidn" if build.with? "libidn"
  depends_on "nettle" if build.with? "dnssec"

  def install
    ENV.deparallelize

    # Fix etc location
    inreplace "src/config.h", "/etc/dnsmasq.conf", "#{etc}/dnsmasq.conf"

    # Optional IDN support
    if build.with? "libidn"
      inreplace "src/config.h", "/* #define HAVE_IDN */", "#define HAVE_IDN"
    end

    # Optional DNSSEC support
    if build.with? "dnssec"
      inreplace "src/config.h", "/* #define HAVE_DNSSEC */", "#define HAVE_DNSSEC"
    end

    # Fix compilation on Lion
    ENV.append_to_cflags "-D__APPLE_USE_RFC_3542" if MacOS.version >= :lion
    inreplace "Makefile" do |s|
      s.change_make_var! "CFLAGS", ENV.cflags
    end

    system "make", "install", "PREFIX=#{prefix}"

    prefix.install "dnsmasq.conf.example"
    if build.with? "dnssec"
      prefix.install "trust-anchors.conf"
    end
  end

  def caveats
    s = <<-EOS.undent
    To configure dnsmasq, copy the example configuration to #{etc}/dnsmasq.conf
    and edit to taste:
      cp #{opt_prefix}/dnsmasq.conf.example #{etc}/dnsmasq.conf
    If you would like to change the startup options,
      you will have to edit the plist file located at
      #{plist_path}
    EOS

    if build.with? "dnssec"
      s += <<-EOS.undent
        If you want to enable the DNSSEC feature,
          you may need this config:
          #{opt_prefix}/trust-anchors.conf
      EOS
    end

    s
  end

  plist_options :manual => "dnsmasq --keep-in-foreground --conf-file={CFG_FILE}"

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <false/>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_sbin}/dnsmasq</string>
          <string>--keep-in-foreground</string>
          <string>--local-service</string>
          <string>--conf-file=#{etc}/dnsmasq.conf</string>
        </array>
        <key>UserName</key>
        <string>nobody</string>
        <key>WorkingDirectory</key>
        <string>#{var}</string>
        <key>StandardErrorPath</key>
        <string>/dev/null</string>
        <key>StandardOutPath</key>
        <string>/dev/null</string>
      </dict>
    </plist>
  EOS
  end

  test do
    system "#{sbin}/dnsmasq", "--test"
  end
end
