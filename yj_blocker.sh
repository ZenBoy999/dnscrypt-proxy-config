#!/bin/sh
verify_wall () {
	/usr/local/bin/proxychains4 -q curl -m 15 -kIsS https://www.google.com/ >/dev/null 
	[ "$?" = "0" ] && WALL="OK" || WALL="BAD"
	echo "Wall $WALL"
}

[ "$1" = "-c" ] && verify_wall && exit 0
# 
verify_wall
[ "${WALL}" != "OK" ] && echo "Not able to cross GFW, may not download the BL domains" && exit 1

D="/etc/dnscrypt-proxy/dnscrypt-proxy-config"
W="/usr/local/bin/proxychains4 -q wget  -T 15 -q "
BL=$D/"yj-blacklist-domains.txt"
RAW="https://raw.githubusercontent.com"
[ -f ${BL} ] && mv $BL $BL.$(date "+%Y%m%d%H%M%S")

# CNMAN # jfoboss # mybase #WindowsSpy
# "${RAW}/crazy-max/WindowsSpyBlocker/master/dnscrypt/extra.txt" 
# "${RAW}/crazy-max/WindowsSpyBlocker/master/dnscrypt/spy.txt" 
for URL in "${RAW}/CNMan/dnscrypt-proxy-config/master/dnscrypt-blacklist-domains.txt" "${RAW}/jfoboss/dnscrypt-domain-blacklists/master/blacklist.txt" "https://download.dnscrypt.info/blacklists/domains/mybase.txt" 
do
	FILE=$D/$(basename $URL)
	echo "Grabbing ${URL} ..."
	$W -O $FILE $URL
	[ "$?" = "0" ] && cat $FILE >> $BL
	rm $FILE
done
#
# DNSMASQ Format
URL="https://raw.githubusercontent.com/notracking/hosts-blocklists/master/domains.txt"
FILE=$D/$(basename $URL)
echo "Grabbing ${URL} ..."
$W -O $FILE $URL
if [ "$?" = "0" ] ;then
	awk -F'/' '{print $2}' $FILE|sort|uniq >> $BL
fi
rm $FILE

# Hostname Format
URL="https://raw.githubusercontent.com/notracking/hosts-blocklists/master/hostnames.txt"
FILE=$D/$(basename $URL)
echo "Grabbing ${URL} ..."
$W -O $FILE $URL
if [ "$?" = "0" ] ;then
	awk '{print $2}' $FILE|sort|uniq >> $BL
fi
rm $FILE

# Sort
grep -v ^# $BL|sort|uniq >${BL}.tmp && mv ${BL}.tmp $BL
echo "Reloading DNSCrypt-Proxy Service ..."
systemctl restart dnscrypt-proxy
sleep 2
systemctl status dnscrypt-proxy
