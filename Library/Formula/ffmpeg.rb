require 'formula'

def ffplay?
  ARGV.include? '--with-ffplay'
end

class Ffmpeg < Formula
  url 'http://ffmpeg.org/releases/ffmpeg-0.10.tar.bz2'
  homepage 'http://ffmpeg.org/'
  sha1 'a3a7fe25db760a99d51266b33386da9c8552feef'

  head 'git://git.videolan.org/ffmpeg.git'

  fails_with_llvm 'Undefined symbols when linking libavfilter'

  def options
    [
      ["--with-tools", "Install additional FFmpeg tools."],
      ["--with-ffplay", "Build ffplay."]
    ]
  end

  depends_on 'yasm' => :build
  depends_on 'x264' => :optional
  depends_on 'faac' => :optional
  depends_on 'lame' => :optional
  depends_on 'rtmpdump' => :optional
  depends_on 'theora' => :optional
  depends_on 'libvorbis' => :optional
  depends_on 'libogg' => :optional
  depends_on 'libvpx' => :optional
  depends_on 'xvid' => :optional
  depends_on 'opencore-amr' => :optional

  depends_on 'sdl' if ffplay?

  def install
    ENV.x11
    args = ["--prefix=#{prefix}",
            "--enable-shared",
            "--enable-gpl",
            "--enable-version3",
            "--enable-nonfree",
            "--enable-hardcoded-tables",
            "--enable-libfreetype",
            "--cc=#{ENV.cc}"]

    args << "--enable-libx264" if Formula.factory('x264').installed?
    args << "--enable-libfaac" if Formula.factory('faac').installed?
    args << "--enable-libmp3lame" if Formula.factory('lame').installed?
    args << "--enable-librtmp" if Formula.factory('rtmpdump').installed?
    args << "--enable-libtheora" if Formula.factory('theora').installed?
    args << "--enable-libvorbis" if Formula.factory('libvorbis').installed?
    args << "--enable-libvpx" if Formula.factory('libvpx').installed?
    args << "--enable-libxvid" if Formula.factory('xvid').installed?
    args << "--enable-libopencore-amrnb" if Formula.factory('opencore-amr').installed?
    args << "--enable-libopencore-amrwb" if Formula.factory('opencore-amr').installed?
    args << "--disable-ffplay" unless ffplay?

    # For 32-bit compilation under gcc 4.2, see:
    # http://trac.macports.org/ticket/20938#comment:22
    if MacOS.leopard? or Hardware.is_32_bit?
      ENV.append_to_cflags "-mdynamic-no-pic"
    end

    system "./configure", *args

    if MacOS.prefer_64_bit?
      inreplace 'config.mak' do |s|
        shflags = s.get_make_var 'SHFLAGS'
        if shflags.gsub!(' -Wl,-read_only_relocs,suppress', '')
          s.change_make_var! 'SHFLAGS', shflags
        end
      end
    end

    write_version_file if ARGV.build_head?

    system "make install"

    if ARGV.include? "--with-tools"
      system "make alltools"
      bin.install Dir['tools/*'].select {|f| File.executable? f}
    end
  end

  # Makefile expects to run in git repo and generate a version number
  # with 'git describe' command (see version.sh) but Homebrew build
  # runs in temp copy created via git checkout-index, so 'git describe'
  # does not work. Work around by writing VERSION file in build directory
  # to be picked up by version.sh.  Note that VERSION file will already
  # exist in release versions, so this only applies to git HEAD builds.
  def write_version_file
    return if File.exists?("VERSION")
    git_tag = "UNKNOWN"
    Dir.chdir(cached_download) do
      ver = `./version.sh`.chomp
      if not $?.success? or ver == "UNKNOWN"
        # fall back to git
        ver = `git describe --tags --match N --always`.chomp
        if not $?.success?
          opoo "Could not determine build version from git repository - set to #{git_tag}"
        else
          git_tag = "git-#{ver}"
        end
      else
        git_tag = ver
      end
    end
    File.open("VERSION","w") {|f| f.puts git_tag}
  end

end
