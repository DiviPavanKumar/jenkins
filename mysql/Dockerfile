# ✅ Use official MySQL base image
FROM mysql:8.0

# ✅ Copy initialization SQL files (executed automatically on first container start)
COPY db/* /docker-entrypoint-initdb.d/

# ✅ Copy custom entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# ✅ Ensure script has execute permissions
RUN chmod +x /usr/local/bin/entrypoint.sh

# ✅ Use custom entrypoint (script will call MySQL default entrypoint internally)
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]