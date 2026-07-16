# BackOffice Admin App

Pannello Flutter per CreditCore e per il progetto Firebase secondario Outfit.

## Configurazione Firebase Outfit

Nessuna credenziale Outfit è salvata nel repository. Web e Android richiedono:

- `OUTFIT_FIREBASE_API_KEY`
- `OUTFIT_FIREBASE_APP_ID`
- `OUTFIT_FIREBASE_MESSAGING_SENDER_ID`

Impostarle come secret GitHub Actions e come variabili d'ambiente Netlify. Per
una build locale Android, impostarle nell'ambiente e usare:

```powershell
.\scripts\build_android.ps1
```

Per altre build passare gli stessi valori tramite:

```text
--dart-define=OUTFIT_FIREBASE_API_KEY=...
--dart-define=OUTFIT_FIREBASE_APP_ID=...
--dart-define=OUTFIT_FIREBASE_MESSAGING_SENDER_ID=...
```

Usare esclusivamente le opzioni pubbliche della Web App Firebase del progetto
`outfit-ai-d0363`; non inserire file `.env` o valori reali nel repository.
