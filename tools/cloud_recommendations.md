```md
# Cloud & Storage Recommendations — least-confusing and least-sketchy stacks for free / generous tiers

Goal: choose low-friction, reasonably-trustworthy providers for:
- cheap/free compute (runners / test VMs)
- object storage / backups
- model hosting and fast ephemeral runners for CI/experiments

Summary recommendation (practical stack)
1. Code + CI: GitHub (repo + Actions) — free public repos, decent free minutes for small personal projects.
2. Persistent free-ish compute: Oracle Cloud Always Free (ARM/AMD VMs + 2 OCPU/1GB each in ARM Ampere; includes 2 VMs + 200 GB block + 10 GB object storage) — best raw always-free VM for long-lived tests.
3. Object storage for backups: Backblaze B2 (cheap, reliable) or Google Drive (convenient, limited free 15GB). Use rclone for multi-target sync.
4. Model hosting / free inference: Hugging Face Inference (free tiers/spaces), Ollama local (host models locally), or self-host on Oracle VM.
5. Edge / quick deploy runners: Fly.io (free credits), Render (free plan for web services), Vercel (frontend).
6. Large free credits for experiments: Google Cloud and Azure often give $300 credits for new signups — great for short-term heavy jobs.
7. Avoid: dubious darknet hosting providers (darknetarmy.*) — they’re high risk and often illegal; use Tor only for privacy, not as hosting provider.

Why this stack
- Oracle Always Free wins for always-on small VMs on ARM/amd64 — you can SSH and run UBULITE components directly.
- Backblaze B2 is S3-compatible and inexpensive; rclone supports it out-of-the-box and you can script encrypted uploads.
- GitHub Actions + self-hosted runner: use your device/VM as a self-hosted runner to run heavy parallel jobs without burning cloud minutes.
- Hugging Face Spaces/Inference: free-tier for light inference and easy model sharing.

Concrete provider notes
- Oracle Cloud Always Free (https://cloud.oracle.com/): always free ARM/AMD instances, block volumes, object storage. Good for persistent dev VMs.
- Backblaze B2 (https://www.backblaze.com/b2/): cheap storage; rclone-compatible; pay-as-you-go.
- Google Cloud / AWS / Azure: generous promo credits for new accounts; longer-term free tiers are limited. Good for burst jobs.
- Hugging Face: free Spaces & inference for open models, easy for model demos.
- Fly.io / Render / Vercel: free-tier web services for frontends / small HTTP backends.

Privacy / Tor / “darknet” guidance
- Tor network: use Tor for client-side privacy or as a proxy. Hosting Tor-hidden services is possible, but using Tor as your host runner/backups is rarely appropriate for reliable, performant backups.
- Don’t rely on obscure "darknet host" services (darknetarmy.* or similar). They’re high-risk, often unregulated, and may break or be seized.
- If you need privacy-preserving hosting, prefer reputable providers + disk-level encryption and minimal metadata leakage. Consider renting a VM on a trusted provider and running Tor hidden service inside the VM.
- If you must use Tor for administration, use ephemeral keys, strict logging, and a hardened access flow (jump host -> ephemeral VM -> local service).

Operational templates (quick)
- rclone encrypt + copy to Backblaze B2 (outline):
  - rclone config create b2 b2 account ENV:B2_ACCOUNT key ENV:B2_KEY
  - rclone config create enccrypt crypt remote:b2:bucket/enc crypt-password-file ~/.config/rclone/enc_pass
  - rclone copy /path/to/backup enccrypt: --progress
- Self-hosted CI runner:
  - Use a cheap Oracle Always Free instance as a self-hosted GitHub Actions runner for long CI jobs and to keep API tokens off mobile.

Security basics
- Never store provider tokens in plain files. Use:
  - GitHub Actions secrets / repo secrets for CI.
  - Android Keystore for on-device secrets.
  - GPG to encrypt backups before upload (see find_and_backup.sh).
- Use OIDC / Workload Identity where possible to avoid long-lived keys.

Final quick choices
- If you want always-free persistent VMs: Oracle Cloud Always Free (best).
- If you want cheap object storage: Backblaze B2.
- If you want free inference & model demos: Hugging Face Spaces.
- For quick ephemeral frontends: Fly.io or Render.
```