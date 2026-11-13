# OpenCode on Render — ready-to-deploy setup

Termux-il `opencode` odikkunna athupole **same OpenCode binary** thanne, pakshe
Render-il oru **headless agent server** aayi. Njan ivide local-aayi `opencode serve`
test cheythu verify cheythathaanu (v2.2.7): password auth, `/api/info`, web UI,
`/api/pair` login link — ellam work cheyyunnund.

---

## Files

| File | Enthennu |
|---|---|
| `Dockerfile` | Debian slim + OpenCode standalone binary + git/ripgrep/python/build tools |
| `entrypoint.sh` | HOME=/data, git setup, `REPO_URL` clone, `opencode serve` start |
| `render.yaml` | Render Blueprint (web service + 10GB disk + env vars) |
| `scripts/pair-link.sh` | Render Shell-il ninnu browser login link undakkan |
| `.dockerignore` | build context clean aakkan |

---

## 1. Deploy (2 reethi)

### A) Blueprint (easy)

1. Ee `opencode-render` folder ningalude GitHub repo-root aakkuka (allenkil
   ee files repo root-il copy cheyyuka).
2. Render Dashboard → **New → Blueprint** → repo select.
3. Render `render.yaml` vayichu service create cheyyum. `sync: false` enna
   vars-inu values chodikkum.
4. **Kandipa** `OPENCODE_PASSWORD` set cheyyuka (long random string):
   `openssl rand -base64 24`
5. Deploy kutheera kazhinj, service URL (e.g. `https://opencode-xxxx.onrender.com`)
   copy cheyyuka.

### B) Manual (Dashboard-il ninnu)

- **New → Web Service** → repo → Runtime: **Docker**
- Instance type: **Starter** or above (disk venam)
- Health check path: `/`
- **Disk**: name `opencode-data`, mount path `/data`, 10 GB
- Environment vars → thazhe kaanunnathu

---

## 2. Environment variables

| Key | Required | Enthennu |
|---|---|---|
| `OPENCODE_PASSWORD` | ✅ | Web UI / TUI login password. Ithu illathe server start aavilla |
| `REPO_URL` | optional | Agent work cheyyenda repo (`https://github.com/you/repo.git`) |
| `GITHUB_TOKEN` | optional | Private repo + commit push cheyyan (`repo` scope mathi) |
| `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL` | optional | Commit author |
| `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `OPENROUTER_API_KEY` / `GEMINI_API_KEY` | ee model use cheyyunnathenkil | Provider keys |
| `PORT` | Render thanne set cheyyum | Server port (default 10000) |
| `WORKSPACE` | optional | Repo clone cheyyunna stalam (default `/data/workspace`) |
| `RUN_PROMPT` | optional | Ithu set cheythal server illa — one-shot `opencode run` mode |

Provider key env vazhi kodukkathe, web UI-il `/connect` vazhi OAuth/API key
connect cheyyam — athu `/data` disk-il persist aakum.

---

## 3. First login (browser)

Server password-protected aanu. Render Shell (Dashboard → service → **Shell**)
open cheythu ithu adikkuka:

```bash
export OPENCODE_PASSWORD='ningalude password'
curl -s -u "opencode:$OPENCODE_PASSWORD" -X POST \
  "http://127.0.0.1:${PORT:-10000}/api/pair"
# -> {"code":"AbCdEf...","expires_in":300}
```

Pinne browser-il:

```
https://<YOUR-SERVICE>.onrender.com/auth/connect/AbCdEf...
```

Ithu 302 redirect + 30-divasam session cookie set cheyyum → web UI open aakum.
Link 5 minute mathrame valid; venda enkil `scripts/pair-link.sh` use cheyyuka.

---

## 4. Termux-il ninnu control cheyyan (TUI)

Render-il agent odum, ningal phone-il TUI:

```bash
OPENCODE_PASSWORD='ningalude password' \
  opencode --server https://<YOUR-SERVICE>.onrender.com
```

Phone-il heavy build illa — ellam Render-il nadakkum. (Phone-lum CPU save!)

---

## 5. One-shot / cron agent

`RUN_PROMPT` env set cheythal container server start cheyyilla, oru task
cheythu theerum:

```bash
RUN_PROMPT="Run the test suite, fix failures, then commit with a clear message"
```

Render **Cron Job** aakkam (same Dockerfile) — daily nightly agent tasks-inu.
`--auto` flag entrypoint-il already und, so permission prompts block cheyyilla.

---

## 6. Verdict / limits (vayikkuka)

- **Free tier-il ithu venda.** Free web services-inu persistent disk illa,
  15 min idle kazhinjal sleep aakum, RAM 512MB — coding agent-inu thikayilla.
  Disk-ode **Starter+** venam; builds/LSP-ക്ക് **Standard (2GB)** safe.
- **Ephemeral FS ozhivakkan** `HOME=/data` + disk thanne solution. Disk illenkil
  restart/redeploy-il sessions + credentials poyi pokum.
- **Security**: URL + password ullavarkku aa container-il **shell command**
  odikkaam (agent vazhi). Password strong aakkuka, share cheyyaruthu,
  `GITHUB_TOKEN` minimum scope kodukkuka.
- **Health check** `/` aanu (login page, 200 return cheyyum). `/api/info`-nu
  auth venam → 401 varum, athu health check aayi vekkaruthu.
- **Arch**: Render x64 default aanu; Dockerfile-il `TARGETARCH` handle cheythittund.

---

## 7. Local test (optional, Docker ullavar)

```bash
cd opencode-render
docker build -t opencode-render .
docker run --rm -p 4096:4096 \
  -e OPENCODE_PASSWORD=testpass \
  -e PORT=4096 \
  -v "$PWD/data:/data" \
  opencode-render
# browser: http://localhost:4096  (login link: /auth/connect/<code>)
```

---

## 8. Troubleshooting

| Prashnam | Solution |
|---|---|
| `OPENCODE_PASSWORD is not set` | Render → Environment-il add cheyyuka, redeploy |
| Login page 200, pakshe app load aavilla | Session cookie blocked aano? Direct Render URL use cheyyuka (custom domain illathe) |
| Redeploy kazhinj sessions poyi | Disk mount `/data` aano ennu check cheyyuka; `HOME` override cheyyaruthu |
| Commits push cheyyunnilla | `GITHUB_TOKEN` + `REPO_URL` https form-il venam; PAT-inu `repo` scope |
| Sleep aayi connection drop | Free plan; Starter+ aakuka |
| Build slow / OOM | Instance size koottuka; `.dockerignore` vazhi build context cheruthakkuka |
