# Manim Studio render server

Renders [Manim Studio](https://github.com/lukaznj/manim-studio)'s exports on another machine, such as a home server, so the computer you make videos on stays free. You keep working on the next video; the export arrives in its usual folder when it's done.

It's the same renderer as the app's, built from the matching Manim Studio release: the video comes out exactly as a local export would. It splits each export into parts rendered at once, so a machine with many cores does it faster.

## Run it

You need an x86-64 (Intel or AMD) machine with Docker and about 4 GB of disk. ARM machines, such as a Raspberry Pi, aren't supported yet: Manim Studio's locked Python environment has no Linux ARM build.

```bash
git clone https://github.com/lukaznj/manim-studio-renderer
cd manim-studio-renderer
# edit compose.yaml: STUDIO_WORKER_URL (how your computer reaches this machine) and the port binding
docker compose up -d
docker compose logs renderer
```

The log ends with a **pairing code** (`msw1.…`). In Manim Studio, open **Settings → General → Render servers**, paste it and click **Pair**. Then choose **Render on** in the export dialog, or in quick and series mode.

To print the code again: `docker compose exec renderer pixi run python -m studio_worker code`.

## Match the app's version

The image tag is the Manim Studio version it renders like (`0.4.0`). When you update the app, update the image too: change the tag in `compose.yaml` and run `docker compose pull && docker compose up -d`. Settings → General shows each server's version.

To build instead of pulling, use the `build:` line in `compose.yaml`; `STUDIO_REF` is the release to build.

## Reach it

The app connects to the address in the pairing code, so that address must work from your computer:

- **Tailscale (recommended).** Put the server on your tailnet, bind the port to its Tailscale address (`"100.x.y.z:7400:7400"`) and set `STUDIO_WORKER_URL` to its MagicDNS name, e.g. `http://my-server.tail1234.ts.net:7400`. To let a friend use it, [share the machine](https://tailscale.com/kb/1084/sharing) with them; nothing is open to the internet.
- **Your home network.** Use the machine's LAN address.
- **A tunnel** (Cloudflare Tunnel and similar), when someone has to reach it from outside. Add the tunnel's own access control as well.

## Security

The pairing code holds a token, and every request needs it. Whoever has it can make this server run a video scene, which is Python code, inside the container. So:

- Share the code only with people you trust.
- Keep the port on a private network or behind a tunnel with its own login; don't publish it to the internet as is.
- The data volume holds the token (`/data/token`). Delete that file and restart to get a new token; every paired app then needs the new code.

The server never makes narration and holds no API keys: the app makes the narration with your own keys and uploads it with the project. Uploaded projects are deleted after rendering, and finished files once the app has downloaded them, or after a day.

## Settings

| Variable | Default | What |
|---|---|---|
| `STUDIO_WORKER_URL` | `http://<hostname>:7400` | The address in the pairing code |
| `STUDIO_WORKER_PORT` | `7400` | The port inside the container |
| `STUDIO_WORKER_SLICES` | one per two cores, at most 6 | Parts of an export rendered at once |
| `STUDIO_WORKER_DATA` | `/data` | Token, caches and jobs |

## How it works

The worker is `python/studio_worker` in the Manim Studio repository, a small HTTP server: `POST /jobs` takes a project (tar.gz) and its export choices, `GET /jobs/<id>` reports progress, `GET /jobs/<id>/files/<name>` returns the results. The decision record is [ADR 0021](https://github.com/lukaznj/manim-studio/blob/main/docs/04-decisions/0021-render-servers.md).

MIT licensed, like Manim Studio.
