# Simple Transmission torrent client container
# Web UI available on port 9091

FROM linuxserver/transmission:latest

# Optional: set your timezone
ENV TZ=Europe/Oslo

# Transmission settings
ENV PUID=1000
ENV PGID=1000

# Optional authentication
# IMPORTANT: Example login credentials. Change USER and PASS before using this image.
ENV USER=admin
ENV PASS=change_this_password

# Optional peer port
ENV PEERPORT=51413

# Expose web UI + torrent ports
EXPOSE 9091
EXPOSE 51413
EXPOSE 51413/udp

# Volumes
# /config     -> Transmission config
# /downloads  -> Downloaded torrents
# /watch      -> Auto-load .torrent files
VOLUME ["/config", "/downloads", "/watch"]