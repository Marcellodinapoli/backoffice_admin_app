$ErrorActionPreference = "Stop"

$required = @(
  "OUTFIT_FIREBASE_API_KEY",
  "OUTFIT_FIREBASE_APP_ID",
  "OUTFIT_FIREBASE_MESSAGING_SENDER_ID"
)

foreach ($name in $required) {
  $value = [Environment]::GetEnvironmentVariable($name)
  if ([string]::IsNullOrWhiteSpace($value)) {
    throw "Variabile ambiente mancante: $name"
  }
}

flutter build apk --release --target-platform android-arm64 `
  "--dart-define=OUTFIT_FIREBASE_API_KEY=$env:OUTFIT_FIREBASE_API_KEY" `
  "--dart-define=OUTFIT_FIREBASE_APP_ID=$env:OUTFIT_FIREBASE_APP_ID" `
  "--dart-define=OUTFIT_FIREBASE_MESSAGING_SENDER_ID=$env:OUTFIT_FIREBASE_MESSAGING_SENDER_ID"
