set -eu
TITLE="Pico Pico"
WINDOW_XID=$(xwininfo -tree -root -all | egrep "$TITLE" | sed -e 's/^ *//' | cut -d\  -f1)
echo $WINDOW_XID
gst-launch-1.0 -e ximagesrc xid=$WINDOW_XID ! video/x-raw,framerate=30/1 ! videoconvert ! queue ! x264enc ! mp4mux ! filesink location=video.mp4
