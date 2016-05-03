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
# Update blacklists and finally wpad.dat.
#
# Typically run weekly via cron, like
# 
#
cd "$(dirname "${0}")"

date +%FT%T

curl --version >/dev/null || { echo "install curl." && exit 1; }

{
  url="http://pgl.yoyo.org/adservers/serverlist.php?hostformat=nohtml"
  file="adservers"
  echo "${file}.txt from ${url} …"
  curl --silent --show-error --output "${file}.txt.tmp" --remote-time --time-cond "${file}.txt" "${url}" \
    && mv "${file}.txt.tmp" "${file}.txt"
}

for file in analytics evil
do
  url="https://raw.githubusercontent.com/sononum/abloprox/master/${file}.txt"
  echo "${file}.txt from ${url} …"
  curl --silent --show-error  --output "${file}.txt~" --remote-time --time-cond "${file}.txt" "${url}" \
    && mv "${file}.txt~" "${file}.txt"
done

sh 2pac.sh > wpad.dat
ls -Al adservers.txt* analytics.txt* evil.txt* user.txt* wpad.dat

echo "${HOME}/log/wpad.log" | logger --tag "USER=$(whoami)"
