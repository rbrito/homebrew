require 'formula'

class GstPluginsBase < Formula
  homepage 'http://gstreamer.freedesktop.org/'
  url 'http://gstreamer.freedesktop.org/src/gst-plugins-base/gst-plugins-base-0.10.35.tar.bz2'
  md5 '1d300983525f4f09030eb3ba47cb04b0'

  depends_on 'pkg-config' => :build
  depends_on 'gettext'
  depends_on 'gstreamer'

  # The set of optional dependencies is based on the intersection of
  # gst-plugins-base-0.10.35/REQUIREMENTS and Homebrew formulas
  depends_on 'orc' => :optional
  depends_on 'gtk+' => :optional
  depends_on 'libogg' => :optional
  depends_on 'pango' => :optional
  depends_on 'theora' => :optional
  depends_on 'libvorbis' => :optional

  def install
    # gnome-vfs turned off due to lack of formula for it. MacPorts has it.
    system "./configure", "--prefix=#{prefix}", "--disable-debug",
      "--disable-dependency-tracking", "--enable-experimental",
      "--disable-libvisual", "--disable-gst_v4l", "--disable-alsa",
      "--disable-cdparanoia", "--without-x", "--disable-x", "--disable-xvideo",
      "--disable-xshm", "--disable-gnome_vfs"
    system "make"
    system "make install"
  end
end
