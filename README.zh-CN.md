# CPA + NewAPI 一键部署

[English](README.md) | [GitHub 仓库](https://github.com/haamill/API-Gen)

这是一个纯脚本部署项目，用于在全新的 Ubuntu/Debian 服务器上同时运行 [CLIProxyAPI](https://hub.docker.com/r/eceasy/cli-proxy-api)、内置的 CPAMC 管理页面，以及 [NewAPI](https://hub.docker.com/r/calciumion/new-api)。

部署栈包含：

- [CLIProxyAPI 镜像](https://hub.docker.com/r/eceasy/cli-proxy-api)：`eceasy/cli-proxy-api:latest`
- CPAMC 管理页面：CLIProxyAPI 内置页面 `/management.html`
- [NewAPI 镜像](https://hub.docker.com/r/calciumion/new-api)：`calciumion/new-api:latest`
- NewAPI 依赖：[Redis](https://redis.io/) 和 [Postgres](https://www.postgresql.org/)
- 运行环境：[Docker Engine](https://docs.docker.com/engine/) 与 [Docker Compose v2](https://docs.docker.com/compose/)

## 快速开始

在全新的 Ubuntu/Debian 服务器上，以 `root` 或 `sudo` 运行：

```bash
git clone https://github.com/haamill/API-Gen.git
cd API-Gen
sudo ./install.sh
sudo ./deploy.sh --host YOUR_SERVER_IP
```

相关脚本：

- [install.sh](install.sh)：安装 Docker Engine 和 Docker Compose v2。
- [deploy.sh](deploy.sh)：渲染配置、生成密钥并启动服务。
- [docker-compose.yml 模板](templates/docker-compose.yml.tpl)：容器编排模板。
- [CPA 配置模板](templates/cpa-config.yaml.tpl)：CLIProxyAPI 配置模板。

如果不传 `--host`，部署脚本会尝试自动检测公网 IP；检测失败时会回退到本机第一个局域网 IP。

## 部署后会生成什么

默认安装目录是 `/opt/cpa-newapi`：

```text
/opt/cpa-newapi
├── docker-compose.yml
├── DEPLOYMENT_INFO.md
├── cpa/
│   ├── config.yaml
│   ├── auths/
│   └── logs/
└── new-api/
    ├── data/
    └── logs/
```

默认访问地址：

- CPA/CPAMC 管理页面：`http://YOUR_SERVER_IP:8317/management.html`
- CPA API 地址：`http://YOUR_SERVER_IP:8317`
- NewAPI 面板：`http://YOUR_SERVER_IP:3000`

每次执行 [deploy.sh](deploy.sh) 都会生成新的密钥，并写入：

```bash
/opt/cpa-newapi/DEPLOYMENT_INFO.md
```

这个文件包含 CPA 管理密钥、CPA API Key、NewAPI 会话密钥、Postgres 密码和 Redis 密码，请不要公开。

## NewAPI 渠道配置

容器启动后：

1. 打开 CPA/CPAMC：`http://YOUR_SERVER_IP:8317/management.html`
2. 使用 `DEPLOYMENT_INFO.md` 中的 CPA management key 登录。
3. 在 CPA 中添加或登录你的上游服务账号。
4. 打开 NewAPI：`http://YOUR_SERVER_IP:3000`
5. 完成 NewAPI 首次管理员初始化。
6. 在 NewAPI 中添加 OpenAI 兼容渠道：
   - API 地址：`http://YOUR_SERVER_IP:8317`
   - 密钥：`DEPLOYMENT_INFO.md` 中的 CPA API key
   - 模型：使用 CPA 登录/OAuth 完成后显示的模型名称
7. 在 NewAPI 中设置模型倍率、价格，并创建给客户端使用的 NewAPI Token。

## 部署参数

完整示例：

```bash
sudo ./deploy.sh \
  --install-dir /opt/cpa-newapi \
  --host YOUR_SERVER_IP \
  --timezone Asia/Shanghai \
  --cpa-port 8317 \
  --newapi-port 3000
```

常用参数：

- [`--install-dir PATH`](deploy.sh)：安装和渲染目录，默认 `/opt/cpa-newapi`。
- [`--host HOST`](deploy.sh)：写入部署信息中的公网域名或 IP。
- [`--timezone TZ`](deploy.sh)：容器时区，默认 `Asia/Shanghai`。
- [`--cpa-port PORT`](deploy.sh)：CPA/CPAMC 对外端口，默认 `8317`。
- [`--newapi-port PORT`](deploy.sh)：NewAPI 对外端口，默认 `3000`。
- [`--cpa-image IMAGE`](deploy.sh)：覆盖 CLIProxyAPI 镜像。
- [`--newapi-image IMAGE`](deploy.sh)：覆盖 NewAPI 镜像。
- [`--render-only`](deploy.sh)：只渲染配置文件，不启动容器。
- [`--force`](deploy.sh)：覆盖已经渲染过的文件。

## 常用运维命令

查看容器状态：

```bash
sudo docker compose -f /opt/cpa-newapi/docker-compose.yml ps
```

查看日志：

```bash
sudo docker compose -f /opt/cpa-newapi/docker-compose.yml logs -f
```

拉取新镜像并重启：

```bash
sudo docker compose -f /opt/cpa-newapi/docker-compose.yml pull
sudo docker compose -f /opt/cpa-newapi/docker-compose.yml up -d
```

停止服务：

```bash
sudo docker compose -f /opt/cpa-newapi/docker-compose.yml down
```

## 本地测试

渲染测试不需要 Docker：

```bash
bash tests/test_render.sh
```

脚本语法检查：

```bash
bash -n install.sh
bash -n deploy.sh
```

测试文件：[tests/test_render.sh](tests/test_render.sh)

## 安全提醒

- 不要提交 `DEPLOYMENT_INFO.md`、渲染后的 `config.yaml` 或生成的数据目录。
- 如果服务暴露到公网，建议在前面加防火墙或反向代理。
- 这个部署默认开启 CLIProxyAPI 远程管理，因为需要通过浏览器访问 CPAMC；请保护好生成的管理密钥。
- 生产环境建议使用 [Caddy](https://caddyserver.com/)、[Nginx](https://nginx.org/) 或云负载均衡终止 HTTPS。
