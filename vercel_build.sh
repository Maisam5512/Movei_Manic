# #!/usr/bin/env bash
# set -euo pipefail

# echo ">>> Writing env.json from build environment variables..."
# cat > env.json <<EOF
# {
#   "IMDB_API_KEY": "${IMDB_API_KEY:-}",
#   "FIREBASE_WEB_API_KEY": "${FIREBASE_WEB_API_KEY:-}",
#   "FIREBASE_WEB_APP_ID": "${FIREBASE_WEB_APP_ID:-}",
#   "FIREBASE_WEB_MESSAGING_SENDER_ID": "${FIREBASE_WEB_MESSAGING_SENDER_ID:-}",
#   "FIREBASE_WEB_PROJECT_ID": "${FIREBASE_WEB_PROJECT_ID:-}",
#   "FIREBASE_WEB_AUTH_DOMAIN": "${FIREBASE_WEB_AUTH_DOMAIN:-}",
#   "FIREBASE_WEB_STORAGE_BUCKET": "${FIREBASE_WEB_STORAGE_BUCKET:-}"
# }
# EOF

# # (Optional) Show file for debugging — comment out in production logs
# # echo "env.json contents:"
# # cat env.json

# # Clone Flutter SDK if not present (keeps the build self-contained)
# if [ ! -d flutter ]; then
#   echo ">>> Cloning Flutter SDK..."
#   git clone https://github.com/flutter/flutter.git --depth 1
# else
#   echo ">>> Flutter SDK already exists; updating..."
#   (cd flutter && git pull --ff-only)
# fi

# # Ensure flutter is on PATH for this script
# export PATH="$PWD/flutter/bin:$PATH"

# echo ">>> Enabling web support and fetching packages..."
# flutter config --enable-web
# flutter pub get

# echo ">>> Building Flutter web with --dart-define-from-file=env.json..."
# flutter build web --release --dart-define-from-file=env.json

# echo ">>> Build finished. Output at build/web"









#!/usr/bin/env bash
set -euxo pipefail

echo ">>> Writing env.json from build environment variables..."
cat > env.json <<EOF
{
  "IMDB_API_KEY": "${IMDB_API_KEY:-}",
  "FIREBASE_WEB_API_KEY": "${FIREBASE_WEB_API_KEY:-}",
  "FIREBASE_WEB_APP_ID": "${FIREBASE_WEB_APP_ID:-}",
  "FIREBASE_WEB_MESSAGING_SENDER_ID": "${FIREBASE_WEB_MESSAGING_SENDER_ID:-}",
  "FIREBASE_WEB_PROJECT_ID": "${FIREBASE_WEB_PROJECT_ID:-}",
  "FIREBASE_WEB_AUTH_DOMAIN": "${FIREBASE_WEB_AUTH_DOMAIN:-}",
  "FIREBASE_WEB_STORAGE_BUCKET": "${FIREBASE_WEB_STORAGE_BUCKET:-}"
}
EOF

echo ">>> env.json created:"
cat env.json

# Clone Flutter SDK if not present
if [ ! -d flutter ]; then
  echo ">>> Cloning Flutter SDK (stable branch)..."
  git clone https://github.com/flutter/flutter.git --branch stable --depth 1
else
  echo ">>> Flutter SDK already exists; updating..."
  (cd flutter && git pull --ff-only)
fi

# Add Flutter to PATH
export PATH="$PWD/flutter/bin:$PATH"

echo ">>> Flutter version:"
flutter --version

echo ">>> Enabling web support & fetching packages..."
flutter config --enable-web
flutter pub get

echo ">>> Attempting to build with --dart-define-from-file..."
if flutter build web --release --dart-define-from-file=env.json; then
  echo ">>> Build succeeded with --dart-define-from-file."
else
  echo ">>> Fallback: building with explicit --dart-define values..."
  flutter build web --release \
    --dart-define=IMDB_API_KEY=$IMDB_API_KEY \
    --dart-define=FIREBASE_WEB_API_KEY=$FIREBASE_WEB_API_KEY \
    --dart-define=FIREBASE_WEB_APP_ID=$FIREBASE_WEB_APP_ID \
    --dart-define=FIREBASE_WEB_MESSAGING_SENDER_ID=$FIREBASE_WEB_MESSAGING_SENDER_ID \
    --dart-define=FIREBASE_WEB_PROJECT_ID=$FIREBASE_WEB_PROJECT_ID \
    --dart-define=FIREBASE_WEB_AUTH_DOMAIN=$FIREBASE_WEB_AUTH_DOMAIN \
    --dart-define=FIREBASE_WEB_STORAGE_BUCKET=$FIREBASE_WEB_STORAGE_BUCKET
fi

echo ">>> Build finished. Output at build/web"

