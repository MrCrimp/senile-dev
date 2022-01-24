#!/bin/bash
# Exit if any subcommand fails
set -e
set -o pipefail
export FORCE_COLOR=true

# Run from the directory of the script, not where called from. redirect stderr to stdout
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )" 
cd $DIR

until curl -s http://localhost:8080/healthz > /dev/null; do
  printf "Service not ready - checking again in 5s...\n" 
  sleep 5
done

printf "✔ FOO services is ready\n"

# Do other stuff
cd ./services/service/app
npm start

