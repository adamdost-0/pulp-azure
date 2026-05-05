## Learnings
- **May 5, 2026:** Validated local deployment of the Pulp container. Encountered a port conflict on 8080 with qBittorrent WebUI. Resolved by setting `PULP_HTTPS_PORT=8081` in `.env` and restarting the docker-compose stack.
## Learnings
- **May 5, 2026:** Moved Pulp port from 8080 to 8081 to avoid conflict with qBittorrent.
