# Pubblicare BackOffice Admin App su Netlify

Repository GitHub: `Marcellodinapoli/backoffice_admin_app` (branch `main`).

## Opzione A — Netlify collegato a GitHub (consigliata)

1. [Netlify](https://app.netlify.com) → **Add new site** → **Import an existing project** → **GitHub**.
2. Scegli il repo **`backoffice_admin_app`**.
3. In **Site configuration** → **Build & deploy**:

| Impostazione | Valore |
|--------------|--------|
| Branch | `main` |
| Base directory | *(vuoto)* |
| Build command | *(vuoto — legge `netlify.toml`)* |
| Publish directory | `build/web` |

4. **Deploy site** (o push su `main` per deploy automatici).

## Opzione B — GitHub Actions

Se Netlify non builda da solo, usa il workflow `.github/workflows/netlify-deploy.yml`:

1. Netlify → **User settings** → **Applications** → **Personal access token**.
2. Netlify → sito → **Site details** → copia **Site ID** (API ID).
3. GitHub → repo `backoffice_admin_app` → **Settings** → **Secrets and variables** → **Actions**:
   - `NETLIFY_AUTH_TOKEN`
   - `NETLIFY_SITE_ID`
4. Push su `main` → tab **Actions** per vedere il deploy.

## Aggiornare Git + Netlify (ogni modifica)

```powershell
cd "percorso\backoffice_admin_app"
git add -A
git status
git commit -m "descrizione modifiche"
git push origin main
```

Dopo il push, Netlify (opzione A) o GitHub Actions (opzione B) pubblica la versione web.

## Nota

- **App Android/iOS**: si installa con `flutter build apk` / store, non passa da Netlify.
- **Versione web** su Netlify: stesso codice Flutter, utile per accesso da browser (login admin + biometria dipende dal browser).
