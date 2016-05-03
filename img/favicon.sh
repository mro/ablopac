#!/bin/sh
cd "$(dirname "$0")"

# 
# http://stackoverflow.com/a/15072127
# 

inkscape=/Applications/Inkscape.app/Contents/Resources/bin/inkscape

$inkscape --help >/dev/null 2>&1  || { echo "Inkscape is not installed." && exit 1; }
# optipng -help >/dev/null 2>&1     || { echo "optipng is not installed." && exit 1; }
sips --help >/dev/null 2>&1       || { echo "sips is not installed. https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/sips.1.html" && exit 1; }

dst_dir="$(pwd)/../img"

OPTS="--without-gui --export-area-page"

mkdir -p "${dst_dir}"
for src_ in on off
do
	src="$(pwd)/../img/ads-${src_}.svg"
	dst="${dst_dir}/ads-${src_}-256x256.png"

	$inkscape --export-width=256 --export-height=256 --export-png="${dst}" ${OPTS} --file="${src}"

	sips --setProperty description "ads-${src_} favicon" \
  	--setProperty artist "https://github.com/mro/ablopac" \
  	--setProperty copyright "http://unlicense.org/" \
  	"${dst}"
	
	[ -x "$(which optipng)" ] && optipng -o 7 "${dst}" &
done

wait
