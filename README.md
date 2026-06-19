# Docker n8n AI - PM Documentation DB Analyzer Bot

[![OpenSSF Scorecard]
(htt‌ps://api.securityscorecards.dev/projects/github.com/{owner}/{repo}/badge)]
(htt‌ps://securityscorecards.dev/viewer/?uri=github.com/{owner}/{repo})

Proyek ini menjalankan stack otomasi berbasis Docker untuk n8n, Qdrant, Cloudflare Tunnel, Telegram Bot, Google Drive, dan AI lokal via Ollama. Workflow utama digunakan untuk menerima perintah Telegram, membaca arsip Preventive Maintenance MariaDB/PerconaDB, menganalisis data dengan model AI lokal, membuat laporan Markdown/DOCX/HTML, serta membuat dokumen Google Docs.

Workflow n8n berada di:

```text
script-flow-n8n/PM-Documentation-DB-Analyzer-Bot-v8.json
```

## Arsitektur

Komponen utama:

| Komponen | Fungsi |
| --- | --- |
| n8n | Engine workflow Telegram, Google Drive, Google Docs, dan pemrosesan laporan PM |
| Qdrant | Vector database untuk fitur RAG/context retrieval |
| Cloudflare Tunnel | Akses HTTPS publik ke n8n tanpa membuka port langsung ke internet |
| Ollama | AI lokal untuk analisis PM dan database |
| Telegram Bot | Interface command untuk user |
| Google Drive | Penyimpanan dan pembuatan dokumen Google Docs |
| Docker Compose | Orkestrasi service di VM Ubuntu |

Port service dibind ke localhost VM:

```text
n8n    : 127.0.0.1:5678
Qdrant : 127.0.0.1:6333 dan 127.0.0.1:6334
```

Akses publik n8n diarahkan melalui Cloudflare Tunnel ke `http://n8n:5678` atau `http://localhost:5678` sesuai konfigurasi tunnel.

## Requirement

Server yang disarankan:

| Kebutuhan | Rekomendasi |
| --- | --- |
| OS | Ubuntu Server 24.04 LTS |
| CPU | Minimal 4 vCPU, disarankan 8 vCPU jika menjalankan AI lokal di host yang sama |
| RAM | Minimal 8 GB, disarankan 16 GB atau lebih |
| Storage | Minimal 50 GB, disarankan SSD |
| Docker | Docker Engine terbaru |
| Compose | Docker Compose plugin (`docker compose`) |
| Domain | Domain/subdomain yang dikelola di Cloudflare |
| AI Lokal | Ollama berjalan dan model tersedia, default workflow memakai `mistral:7b` |
| Akun eksternal | Telegram Bot Token dan Google Drive OAuth credential |

Package host yang umum dibutuhkan:

```bash
sudo apt update
sudo apt install -y ca-certificates curl git
```

## Struktur Folder VM

Folder host yang digunakan oleh container:

| Folder VM | Mount di container | Fungsi |
| --- | --- | --- |
| `/home/bajau/pm_source` | `/home/bajau/pm_source` | Sumber file arsip PM `.tar`, `.tar.gz`, `.tgz`, `.tar.bz2` |
| `/home/bajau/pm_output` | `/home/bajau/pm_output` | Output Markdown dan data antara dari proses `/pm` |
| `/home/bajau/pm_docx` | `/home/bajau/pm_docx` | Output DOCX |
| `/home/bajau/pm_docs` | `/home/bajau/pm_docs` | Output HTML/Markdown dari `/gendoc` dan `/listdoc` |
| `/home/bajau/pm_template` | `/home/bajau/pm_template` | Folder template dokumen tambahan jika dibutuhkan |
| `./n8n_data` | `/home/node/.n8n` | Data internal n8n |
| `/tmp/pm_work` | `/tmp/pm_work` | Working directory sementara |
| `/tmp/pm_extracted` | `/tmp/pm_extracted` | Extracted archive sementara |

Buat folder sebelum menjalankan container:

```bash
sudo mkdir -p /home/bajau/pm_source /home/bajau/pm_output /home/bajau/pm_docx /home/bajau/pm_docs /home/bajau/pm_template
sudo mkdir -p /tmp/pm_work /tmp/pm_extracted
sudo chown -R 1000:1000 /home/bajau/pm_source /home/bajau/pm_output /home/bajau/pm_docx /home/bajau/pm_docs /home/bajau/pm_template
```

## Instalasi

1. Clone repository ke VM.

```bash
git clone https://github.com/<username>/<nama-repo>.git
cd <nama-repo>
```

2. Buat file environment.

```bash
cp .env.example .env
nano .env
```

Isi nilai penting berikut:

| Variable | Keterangan |
| --- | --- |
| `N8N_HOST` | Domain n8n, contoh `n8n.example.com` |
| `N8N_PROTOCOL` | Gunakan `https` jika via Cloudflare |
| `WEBHOOK_URL` | URL publik n8n, contoh `https://n8n.example.com/` |
| `CLOUDFLARED_TUNNEL_TOKEN` | Token Cloudflare Tunnel |
| `TELEGRAM_BOT_TOKEN` | Token dari BotFather |
| `OLLAMA_BASE_URL` | URL Ollama, contoh `http://host.docker.internal:11434` |
| `MARIADB_HOST` | IP/host MariaDB target |
| `MARIADB_PORT` | Port MariaDB, default `3306` |
| `MARIADB_USER` | User MariaDB |
| `MARIADB_PASSWORD` | Password MariaDB |
| `SSH_HOST`, `SSH_USER`, `SSH_PORT` | Akses SSH server target jika workflow membutuhkannya |

3. Build dan jalankan stack.

```bash
docker compose up -d --build
```

4. Cek container.

```bash
docker compose ps
docker compose logs -f n8n
```

5. Buka n8n.

Jika dari VM lokal:

```text
http://127.0.0.1:5678
```

Jika Cloudflare Tunnel sudah aktif:

```text
https://domain-n8n-kamu
```

## Setup Cloudflare Tunnel

Di Cloudflare Zero Trust:

1. Buat tunnel baru.
2. Pilih Docker sebagai environment.
3. Copy tunnel token ke `.env` sebagai `CLOUDFLARED_TUNNEL_TOKEN`.
4. Buat Public Hostname, contoh:

```text
Subdomain : n8n
Domain    : example.com
Service   : http://n8n:5678
```

Jika tunnel service tidak bisa resolve nama container `n8n`, gunakan:

```text
http://localhost:5678
```

## Setup Ollama / AI Lokal

Jika Ollama berjalan di host VM:

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull mistral:7b
```

Pastikan Ollama menerima koneksi dari container. Contoh `.env`:

```text
OLLAMA_BASE_URL=http://host.docker.internal:11434
```

Tes dari container n8n:

```bash
docker exec -it n8n sh
wget -qO- http://host.docker.internal:11434/api/tags
```

## Setup n8n Workflow

1. Login ke n8n.
2. Pilih menu `Workflows`.
3. Import file:

```text
script-flow-n8n/PM-Documentation-DB-Analyzer-Bot-v8.json
```

4. Set credential pada node berikut:

| Credential | Digunakan oleh |
| --- | --- |
| Telegram account | Telegram Trigger dan node pengiriman pesan/file |
| Google Drive account | Pembuatan dan update file Google Docs |

5. Aktifkan workflow setelah credential valid.

## Command Telegram

Command utama yang tersedia di workflow:

| Command | Fungsi |
| --- | --- |
| `/help` | Menampilkan bantuan command |
| `/list` | Melihat daftar arsip PM di `/home/bajau/pm_source` |
| `/pm 1` | Memproses file PM berdasarkan nomor dari `/list` |
| `/pm namafile.tar.gz` | Memproses file PM berdasarkan nama file |
| `/gendoc` | Melihat daftar laporan Markdown yang bisa dibuat menjadi dokumen |
| `/gendoc 1` | Membuat output HTML dari laporan Markdown |
| `/gendoc 1 --md` | Mengirim ulang output Markdown |
| `/listdoc` | Melihat daftar output HTML/Markdown di `/home/bajau/pm_docs` |

Upload file PM ke server:

```bash
scp file_pm.tar.gz bajau@<ip-vm>:/home/bajau/pm_source/
```

Lalu jalankan dari Telegram:

```text
/list
/pm 1
```

## Operasional

Perintah harian:

```bash
docker compose ps
docker compose logs -f n8n
docker compose logs -f qdrant
docker compose restart n8n
docker compose down
docker compose up -d --build
```

Backup data n8n:

```bash
tar -czf n8n_data_backup_$(date +%F).tar.gz n8n_data
```

Backup folder PM:

```bash
sudo tar -czf pm_data_backup_$(date +%F).tar.gz \
  /home/bajau/pm_source \
  /home/bajau/pm_output \
  /home/bajau/pm_docx \
  /home/bajau/pm_docs \
  /home/bajau/pm_template
```

## Keamanan Sebelum Upload GitHub

Jangan commit file berikut:

```text
.env
n8n_data/
file arsip PM asli
output laporan client
token Cloudflare
credential Google/Telegram
```

Repository ini sudah menyediakan `.gitignore` untuk mencegah file runtime dan secret umum ikut terupload. Gunakan `.env.example` sebagai template konfigurasi publik.

## Troubleshooting

Jika n8n tidak bisa diakses:

```bash
docker compose logs -f cloudflared
docker compose logs -f n8n
```

Jika Telegram tidak merespons:

1. Pastikan workflow aktif.
2. Pastikan credential `Telegram account` sudah dipilih ulang di n8n.
3. Pastikan `WEBHOOK_URL` memakai domain HTTPS yang benar.
4. Cek log:

```bash
docker compose logs -f n8n
```

Jika output laporan tidak muncul di host:

1. Pastikan folder VM sudah dibuat.
2. Pastikan volume di `docker-compose.yaml` sesuai.
3. Tes permission:

```bash
docker exec -it n8n sh -lc 'touch /home/bajau/pm_output/test.txt && touch /home/bajau/pm_docx/test.txt && touch /home/bajau/pm_docs/test.txt'
```

Jika Ollama error:

```bash
docker exec -it n8n sh -lc 'wget -qO- $OLLAMA_BASE_URL/api/tags'
```

Jika Google Docs gagal dibuat:

1. Cek credential `Google Drive account`.
2. Pastikan OAuth scope Drive sudah cukup.
3. Pastikan folder Google Drive target di workflow masih valid.

## Struktur Repository

```text
.
├── Dockerfile
├── docker-compose.yaml
├── .env.example
├── .gitignore
├── README.md
└── script-flow-n8n/
    └── PM-Documentation-DB-Analyzer-Bot-v8.json
```
