#!/bin/sh
#
# https://github.com/mro/ablopac/
#
# based on
#
# John's No-ADS proxy script
#      http://www.schooner.com/~loverso/no-ads/
#      loverso@schooner.com
#
# Copyright 2015-2016, Marcus Rohrmoser. http://mro.name/me All Rights Reserved.
# Copyright 1996-2003, John LoVerso.  All Rights Reserved.
#
#      Permission is given to distribute this file, as long as this
#      copyright message and author notice are not removed, and no
#      monies are exchanged.
#
#      No responsibility is taken for any errors on inaccuracies inherent
#      either to the comments or the code of this program, but if reported
#      to me, then an attempt will be made to fix them.
#

#
# This fakes an HTTP transaction by it just returning a canned response.
#
# Normally, this is run from inetd with this line in inetd.conf
# (remember to "kill -HUP" the inetd process after changing that file)
#
# # no-ads proxy
# 3421 stream tcp nowait nobody /usr/local/lib/www/noproxy noproxy
#
# 3421 is either an arbitrary TCP port number or TCP service name;
# just make sure you use the same value in "no-ads.pac".
#
###############################################################################

SERVER="http://purl.mro.name/wpad"

# Pick one of the noproxy schemes and use it at the end

###############################################################################
#
# Just deny the connection
#
deny() {
  result="501 No Ads Accepted"
  printf '%s\r\n' \
    "HTTP/1.0 ${result}" \
    "Date: Mon, 12 Nov 2001 12:25:47 GMT" \
    "Server: ${SERVER}" \
    ""
}

###############################################################################
#
# Return redirection to "no-ads" image,
# so you can tell when an ad is suppressed.
#
redir() {
  printf '%s\r\n' \
    "HTTP/1.0 301 No Ads Accepted" \
    "Date: Mon, 20 Oct 1997 12:25:47 GMT" \
    "Server: ${SERVER}" \
    "Content-Length: 3" \
    "Location: http://wpad.mro.name/img/ads-off.svg" \
    "" \
    "nil"
}

###############################################################################
#
# Return an image.  Returns either noproxy.clear.gif or noproxy.noads.gif.
#
# Netscape 4.0 bug with <script SRC="http://adforce.imgis.com/...">
# causes crash when returning an image.  This may have been fixed since.
#
# Netscape bug with <layer> causes such references to use the embedded
# link as a title.  alta vista uses <layer> for ads.  damn.
#
image() {
  result="200 No Ads Accepted"
  image_file="${0}.ads-off.svg" size=1938
  printf '%s\r\n' \
    "HTTP/1.0 ${result}" \
    "Date: Mon, 12 Nov 2001 12:25:47 GMT" \
    "Server: ${SERVER}" \
    "Last-Modified: Mon, 20 Oct 1997 12:25:47 GMT" \
    "Expires: Mon, 20 Oct 2040 20:20:20 GMT" \
    "Content-Length: ${size}" \
    "Content-Type: image/svg" \
    "" \
  | cat - "${image_file}"
}

###############################################################################
#
empty() {
#  result="418 No Ads Accepted"
#  result="404 No Ads Accepted"
  result="200 No Ads Accepted"
  r=${1-' '}
  size=${1:+${#r}}
  size=${size:-"1"}
  printf '%s\r\n' \
    "HTTP/1.0 ${result}" \
    "Date: Mon, 12 Nov 2001 12:25:47 GMT" \
    "Server: ${SERVER}" \
    "Last-Modified: Mon, 20 Oct 1997 12:25:47 GMT" \
    "Expires: Mon, 20 Oct 2040 20:20:20 GMT" \
    "Content-Length: ${size}" \
    "Content-Type: text/plain" \
    "" \
    "${r}"
}

###############################################################################
#
fourohfour() {
  result="404 No Ads Accepted"
  printf '%s\r\n' \
    "HTTP/1.0 ${result}" \
    "Date: Mon, 12 Nov 2001 12:25:47 GMT" \
    "Server: ${SERVER}" \
    ""
}


###############################################################################
#
# If we got this, no-ads sent it to the blackhole
control() {
  result="200 OK"
  ads_state="$(echo "${url}" | cut -d / -f 4)"
  buf="$(cat <<SET_VAR
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Toggle Ads</title>
  <meta name="viewport" content="width=device-width" />
  <link rel="icon" href="http://wpad.mro.name/img/ads-${ads_state}-256x256.png?v=2" type="image/png" />
  <style type="text/css">
/*<![CDATA[*/
  html {
    background-color: #DDD;
  }
  .ads-on { color:  #008754; }
  .ads-off { color: #E30613; }
  .on span.ads-off, .off span.ads-on  {
    display: none;
  }
  .on span.ads-on, .off span.ads-off {
    display: inline;
    font-size: 18pt;
    font-family: sans-serif;
    font-weight: bold;
    vertical-align: middle;
  }
  svg { width: 32px; height: 32px; vertical-align: middle; }
  /*]]>*/
  </style>
</head>

<body class="${ads_state}">
  <p>Ads are currently $(cat "${0}.ads-${ads_state}.svg") <span class="ads-on">on</span><span class="ads-off">off</span></p>

  <p>I am file://$(hostname)$0<br/>
     from <a href="${SERVER}">${SERVER}</a><br/>
     running as uid $(id -un)<br/>
  </p>

  <p><a href="#" onclick="history.go(-2)">Go Back</a></p>
</body>
</html>
SET_VAR
)"

  printf '%s\r\n' \
    "HTTP/1.0 ${result}" \
    "Server: ${SERVER}" \
    "Content-Type: text/html" \
    "Content-Length: $(echo "$buf" | wc -c)" \
    "" \
    "${buf}" \
    ""
}

###############################################################################

# quaff HTTP request + 1st line of headers
read meth url http
read h f

# Gack!  This is needed on Linux, as Linux TCP does not handle half
# open TCP connections (WHY!?) and will reset a connection with unread data
cat <&0 > /dev/null &
catpid=$!
# close stdin
exec <&-

case "${url}" in
http://ads/*)
  control
  ;;
*.js)
  # echo "blocked $url" | logger --tag blackholeproxy.sh
  deny
  ;;
*:443)
  # echo "blocked $url" | logger --tag blackholeproxy.sh
  deny
  ;;
*)
  # echo "blocked $url" | logger --tag blackholeproxy.sh
  redir
  ;;
esac

# close (for broken Linux)
exec >&- 2>&-
kill ${catpid}

exit 0
