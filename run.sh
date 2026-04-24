#!/usr/bin/env bash
# Run Circle Hub with local secrets injected.
# Usage:
#   ./run.sh                        → debug on connected device
#   ./run.sh -d emulator-5554       → specific device
#   ./run.sh --release              → release build
set -e
flutter run --dart-define-from-file=local.env "$@"
