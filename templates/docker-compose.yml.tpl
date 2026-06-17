services:
  cli-proxy-api:
    image: __CPA_IMAGE__
    container_name: cpa-cli-proxy-api
    restart: unless-stopped
    environment:
      DEPLOY: ""
    ports:
      - "__CPA_PORT__:8317"
      - "__CPA_REDIS_PORT__:8085"
      - "__CPA_ANTHROPIC_PORT__:1455"
      - "__CPA_CODEX_WS_PORT__:54545"
      - "__CPA_CODEX_PORT__:51121"
      - "__CPA_GEMINI_PORT__:11451"
    volumes:
      - ./cpa/config.yaml:/CLIProxyAPI/config.yaml
      - ./cpa/auths:/root/.cli-proxy-api
      - ./cpa/logs:/CLIProxyAPI/logs
    networks:
      - cpa-newapi

  new-api:
    image: __NEWAPI_IMAGE__
    container_name: new-api-app
    restart: unless-stopped
    command: --log-dir /app/logs
    ports:
      - "__NEWAPI_PORT__:3000"
    volumes:
      - ./new-api/data:/data
      - ./new-api/logs:/app/logs
    environment:
      SQL_DSN: "postgresql://__POSTGRES_USER__:__POSTGRES_PASSWORD__@postgres:5432/__POSTGRES_DB__"
      REDIS_CONN_STRING: "redis://:__REDIS_PASSWORD__@redis:6379"
      TZ: "__TIMEZONE__"
      ERROR_LOG_ENABLED: "true"
      BATCH_UPDATE_ENABLED: "true"
      NODE_NAME: "new-api-node-1"
      SESSION_SECRET: "__NEWAPI_SESSION_SECRET__"
    depends_on:
      redis:
        condition: service_started
      postgres:
        condition: service_healthy
    networks:
      - cpa-newapi
    healthcheck:
      test: ["CMD-SHELL", "wget -q -O - http://localhost:3000/api/status | grep -o '\"success\":\\s*true' || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3

  redis:
    image: redis:latest
    container_name: new-api-redis
    restart: unless-stopped
    command: ["redis-server", "--requirepass", "__REDIS_PASSWORD__"]
    networks:
      - cpa-newapi

  postgres:
    image: postgres:15
    container_name: new-api-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: "__POSTGRES_USER__"
      POSTGRES_PASSWORD: "__POSTGRES_PASSWORD__"
      POSTGRES_DB: "__POSTGRES_DB__"
    volumes:
      - pg_data:/var/lib/postgresql/data
    networks:
      - cpa-newapi
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U __POSTGRES_USER__ -d __POSTGRES_DB__"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  pg_data:

networks:
  cpa-newapi:
    driver: bridge
