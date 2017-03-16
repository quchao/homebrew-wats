# Modified from https://github.com/Homebrew/homebrew-core/blob/master/Formula/haproxy.rb
class HaproxyLibressl < Formula
  desc "Reliable, high performance TCP/HTTP load balancer w/ LibreSSL"
  homepage "http://www.haproxy.org/"
  url "http://www.haproxy.org/download/1.7/src/haproxy-1.7.3.tar.gz"
  version "1.7.3"
  sha256 "ebb31550a5261091034f1b6ac7f4a8b9d79a8ce2a3ddcd7be5b5eb355c35ba65"

  conflicts_with "haproxy", :because => "haproxy-libressl symlink with the name for compatibility with haproxy"

  depends_on "pcre"
  depends_on "libressl" => :recommended
  depends_on "openssl" => :optional

  def install
    # USE_POLL, USE_TPROXY are implicit
    args = %w[
      TARGET=generic
      ARCH=x86_64
      CPU=native
      USE_KQUEUE=1
      USE_TFO=1
      USE_ZLIB=1
    ]

    pcre = Formula["pcre"]
    args << "USE_REGPARM=1 USE_PCRE=1 USE_PCRE_JIT=1 USE_STATIC_PCRE=1 PCRE_LIB=#{pcre.lib} PCRE_INC=#{pcre.include}"

    if build.with? "libressl"
      libressl = Formula["libressl"]
      cc_opt = "#{libressl.include}"
      ld_opt = "#{libressl.lib}"
    else
      openssl = Formula["openssl"]
      cc_opt = "#{openssl.include}"
      ld_opt = "#{openssl.lib}"
    end
    args << "USE_OPENSSL=1 SSL_INC=#{cc_opt} SSL_LIB=#{ld_opt}"

    # Since the Makefile.osx doesn't work due to the implicit option USE_LIBCRYPT,
    # so we just build generic.
    system "make", "CC=#{ENV.cc}", "CFLAGS=#{ENV.cflags}", "LDFLAGS=#{ENV.ldflags}", *args
    system "make", "install", "PREFIX=#{prefix}", "DOCDIR=#{prefix}/share/doc/haproxy"
  end

  def caveats; <<-EOS.undent
    **IMPORTANT**: NO DEFAULT CONFIG FILE WILL BE CREATED WITH THE INSTALLTION,
      please create your own at #{etc}/haproxy/haproxy.cfg.
    If you would like to change the path to the config,
      you will have to edit the plist file located at
      #{plist_path}
  EOS
  end

  plist_options :manual => "haproxy -f {CFG_FILE}"

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-/Apple/DTD PLIST 1.0/EN" "http:/www.apple.com/DTDs/PropertyList-1.0.dtd">
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
          <string>#{opt_sbin}/haproxy</string>
          <string>-f</string>
          <string>#{etc}/haproxy/haproxy.cfg</string>
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
    system "#{sbin}/haproxy", "-v"
  end
end
