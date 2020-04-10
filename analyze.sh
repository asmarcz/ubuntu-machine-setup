#!/bin/dash
DIR=/tmp/scan-build

OUTPUT=$(scan-build -o "$DIR" clang -c "$1" 2>/dev/null |
tail -n 1)
if [ "$OUTPUT" = "scan-build: No bugs found." ]; then
	echo "$OUTPUT"
else
	ls "$DIR" |
	tail -n 1 |
	xargs -I '{}' /opt/firefox-dev/firefox "$DIR/{}/index.html"
fi
