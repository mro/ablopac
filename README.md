# <img src="https://cdn.rawgit.com/mro/ablopac/master/img/ads-off.svg" height="32px"/> Ad BLOcking [Proxy-Auto-Configuration](https://en.wikipedia.org/wiki/Proxy_auto-config)

plus a black-hole proxy if you prefer to not use Google's.

## Installation (PAC)

1. `ssh` into your webspace where your PAC should reside,
2. `$ git clone https://github.com/mro/ablopac.git`
3. `$ sh ablopac/update.sh`
4. set `http://myserver.example/wpad.dat` as your proxy configuration.

## Data Sources

- blacklist from <http://pgl.yoyo.org/adservers/serverlist.php?hostformat=nohtml>
- blacklists from <https://github.com/sononum/abloprox/>
