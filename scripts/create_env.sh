#!/usr/bin/env bash
ENV_FILE="$PWD/.env"
EXAMPLE_ENV_FILE="${ENV_FILE}.example"

env_file_exists() {
  test -f "$ENV_FILE"
}

create_env_file_from_example() {
  grep -Ev '^#' "$EXAMPLE_ENV_FILE" > $ENV_FILE
}

if ! env_file_exists
then
  create_env_file_from_example
fi
