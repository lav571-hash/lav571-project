# lav571-project

Placeholder repository. There is no application source, dependency manifests, or documented run/lint/test commands yet.

## Cursor Cloud specific instructions

### Repository state

- **Contents:** `README.md` only (no `package.json`, `pyproject.toml`, Docker Compose, CI config, or source directories).
- **Services:** None to start. No dev server, database, or background workers are defined in this repo.
- **Update script:** No-op (`true`) — there are no project dependencies to refresh on VM startup.

### When application code is added

Match the stack’s usual workflow once manifests exist (for example `npm install` / `pnpm install`, `pip install -r requirements.txt`, `uv sync`, or `docker compose up` for local infra). Document non-obvious startup steps here instead of expanding the update script with service startup or migrations.

### VM toolchain (available without repo-specific install)

These runtimes are preinstalled on the Cloud Agent VM and do not require repo setup:

| Tool | Version (approx.) |
|------|-------------------|
| Node.js | v22.x |
| npm | 10.x |
| pnpm | 10.x |
| Python | 3.12 |
| Go | 1.22 |
| Rust | 1.83 |

Docker is not assumed to be available unless you install it during a session.

### Lint / test / build / run

Not applicable until the project adds source and scripts. Check `README.md` and package manifests after the first real commit.
