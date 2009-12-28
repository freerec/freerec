# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="1"

inherit eutils

DESCRIPTION="Audio recorder (MP3/Speex) and song player"
HOMEPAGE="https://launchpad.net/freerec"
SRC_URI="http://launchpad.net/freerec/trunk/${PV}/+download/${P}.tar.gz"

LICENSE="ISC"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="dev-lang/ruby:1.8
	>=dev-ruby/ruby-gtk2-0.19.0
	>=dev-ruby/ruby-gstreamer-0.19.0
	dev-ruby/ruby-gettext
	media-libs/gst-plugins-good
	media-plugins/gst-plugins-ogg
	media-plugins/gst-plugins-speex
	media-plugins/gst-plugins-lame
	media-plugins/gst-plugins-mad
	media-plugins/gst-plugins-x
	media-plugins/gst-plugins-libvisual"
DEPEND="dev-ruby/rake
	dev-util/intltool"

src_compile() {
	ebegin "Patching for system-wide installation"
	sed -i -r \
		-e '1s|^#!.*|#!/usr/bin/ruby18|' \
		-e 's|^(LIB_DIR\s*=).*|\1 "/usr/share/freerec/lib"|' \
		-e 's|^(SONGS_DIR\s*=).*|\1 "/usr/share/freerec/songs"|' \
		freerec
	eend
	rake
}

src_install() {
	dobin freerec
	dodir /usr/share/freerec/songs
	insinto /usr/share/freerec
	doins -r lib ui
	insinto /usr/share
	doins -r locale
	insinto /usr/share/applications
	doins freerec.desktop
	dodoc README TODO
}

pkg_postinst() {
	elog ""
	elog "Please copy the songs to /usr/share/freerec/songs/"
	elog ""
	elog "If you are not using Gnome Desktop Environment, make sure"
	elog "that a proper Gtk icon theme is set, please see README for"
	elog "further instructions."
}
