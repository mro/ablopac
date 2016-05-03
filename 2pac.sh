#!/bin/sh
#
# This is free and unencumbered software released into the public domain.
# 
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
# 
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
# 
# For more information, please refer to <http://unlicense.org/>
#
#
# Take the blacklists *.txt and turn them into a filtering PAC file.
#
# Works without any proxy.
# Uses 8.8.8.8:53 (Google) as a black-hole.
#
# Inspired by
#    http://www.schooner.com/~loverso/no-ads/
#    http://www.antd.org/files/os/iphone/proxy.pac
#
cd "$(dirname "$0")"

cat <<InputComesFromHERE
//
// Filtering PAC file generated by https://github.com/mro/ablopac/blob/master/2pac.sh on $(date +%FT%T)
//
// inspired by
// - inspired by http://www.schooner.com./~loverso/no-ads/
// - https://de.wikipedia.org/wiki/Proxy_Auto-Config#Die_PAC-Datei
// - https://web.archive.org/web/20140213182543/http://www.proxypacfiles.com/proxypac/index.php?option=com_content&view=article&id=58&Itemid=87
//
// auto config:
// 1. ensure there's a host 'wpad' in the current network, see
//   - https://en.wikipedia.org/wiki/Web_Proxy_Autodiscovery_Protocol#Context
//   - http://fritz.box/net/network_user_devices.lua
// 2. have a http webserver running on that host
// 3. ensure http://wpad/wpad.dat or http://wpad.fritz.box/wpad.dat contains this PAC file

var bypass = "DIRECT";
var blackhole = "PROXY 0.0.0.0:65535";  // Safari on iOS let's through
// blackhole = "SOCKS !";               // Safari on iOS let's through
// blackhole = "PROXY 127.0.0.1:1234";  // Safari on iOS let's through. http://www.antd.org/files/os/iphone/proxy.pac
blackhole = "PROXY 8.8.8.8:53";         // Google (sigh). http://shion.ca/ios/adblockpub.js via http://forums.macrumors.com/showpost.php?p=20626459&postcount=6

var isActive = 1;

function addHost(arr, host) {
  arr.unshift( host.replace(/(\.)/g,'\\\\\$1').replace(/\?/,'.').replace(/\*/,'.*') );
}

var blackPat = function() {
  var a = new Array();
InputComesFromHERE

for black in *.txt
do
  [ "robots.txt" = "${black}" ] && continue
  echo "  // $(ls -l "$black")"
  tr -d '\r' < "$black" | sed -n -E -e "/^#/s:#:  //:p" -e '/  \/\//!s/([a-zA-Z0-9.\?*-]+)/  addHost(a, "&");/p'
done

cat <<InputComesFromHERE
  // console.log('black: ^(.+\.)?((' + a.join(')|(') + '))$' );
  return new RegExp( '^(.+\.)?((' + a.join(')|(') + '))$', 'i' );
}();

function FindProxyForURL(url, host) {
  // Excellent kludge from Sean M. Burke:
  // block or display ads for the current browser session.
  //
  // To block ads, visit this URL:      http://ads/off
  // To display ads, visit this URL:    http://ads/on
  //
  // (this will not work with Mozilla or Opera if the alert()s are present)
  //
  if( "ads" == host || "ablopac" == host ) {
    if( shExpMatch(url, "*://" + host + "/off") ) {
      isActive = 1;
      // LOG alert("ads will be blocked.\n" + url);
    } else if( shExpMatch(url, "*://" + host + "/on") ) {
      isActive = 0;
      // LOG alert("ads will be displayed.\n" + url);
    } else if( shExpMatch(url, "*://" + host + "/") ) {
      alert("ads are " + (isActive ? "blocked" : "displayed") + ".\n" + url);
    } else {
      alert("ads unknown option.\n" + url);
    }
    return blackhole;
  }

  if( ! isActive )
    return bypass;

  if( null != host.match(blackPat) )
    return blackhole;

  return bypass;
}
InputComesFromHERE