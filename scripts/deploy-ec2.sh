#!/usr/bin/env bash

set -Eeuo pipefail

APP_NAME="${APP_NAME:-flask-cicd-aws}"
APP_DIR="${APP_DIR:-/opt/flask-cicd-aws}"
PRODUCTION_PORT="${PRODUCTION_PORT:-80}"
CANDIDATE_PORT="${CANDIDATE_PORT:-5001}"
CONTAINER_PORT="5000"
IMAGE_REPOSITORY="hoangdonguit/flask-cicd-aws"

CURRENT_IMAGE_FILE="$APP_DIR/current-image"
PREVIOUS_IMAGE_FILE="$APP_DIR/previous-image"
DEPLOYMENT_HISTORY="$APP_DIR/deployment-history.log"
LOCK_DIR="$APP_DIR/.deployment-lock"

log() {
  printf '[%s] %s\n' \
    "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    "$*"
}

usage() {
  cat <<'USAGE'
Usage:
  deploy-ec2.sh deploy IMAGE
  deploy-ec2.sh rollback
  deploy-ec2.sh status

Examples:
  deploy-ec2.sh deploy hoangdonguit/flask-cicd-aws:sha-5edfc15
  deploy-ec2.sh rollback
USAGE
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    log "ERROR: required command not found: $1"
    exit 1
  }
}

validate_image() {
  local image="$1"

  if [[ ! "$image" =~ ^hoangdonguit/flask-cicd-aws:sha-[0-9a-f]{7}$ ]]; then
    log "ERROR: image must match:"
    log "       hoangdonguit/flask-cicd-aws:sha-<7 lowercase hex characters>"
    exit 1
  fi
}

container_exists() {
  docker container inspect "$1" >/dev/null 2>&1
}

remove_container() {
  local name="$1"

  if container_exists "$name"; then
    docker rm --force "$name" >/dev/null
  fi
}

image_tag_from_reference() {
  printf '%s\n' "${1##*:}"
}

start_container() {
  local name="$1"
  local image="$2"
  local host_binding="$3"
  local restart_policy="$4"

  local image_tag
  local deploy_time

  image_tag="$(image_tag_from_reference "$image")"
  deploy_time="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

  docker run \
    --detach \
    --name "$name" \
    --restart "$restart_policy" \
    --publish "${host_binding}:${CONTAINER_PORT}" \
    --env "APP_VERSION=$image_tag" \
    --env "IMAGE_TAG=$image_tag" \
    --env "DEPLOY_ENV=production" \
    --env "DEPLOY_TIME=$deploy_time" \
    --security-opt no-new-privileges:true \
    --cap-drop ALL \
    --read-only \
    --tmpfs /tmp:rw,noexec,nosuid,size=64m \
    --pids-limit 128 \
    --memory 256m \
    --cpus 0.75 \
    --label "com.example.application=$APP_NAME" \
    --label "com.example.image-tag=$image_tag" \
    "$image"
}

wait_for_application() {
  local base_url="$1"
  local expected_tag="$2"
  local attempts="${3:-30}"

  local health_file
  local version_file

  health_file="$(mktemp)"
  version_file="$(mktemp)"

  for attempt in $(seq 1 "$attempts"); do
    if curl -fsS \
        --connect-timeout 2 \
        --max-time 4 \
        "$base_url/health" \
        >"$health_file" 2>/dev/null \
      && curl -fsS \
        --connect-timeout 2 \
        --max-time 4 \
        "$base_url/version" \
        >"$version_file" 2>/dev/null \
      && jq -e \
        --arg expected "$expected_tag" \
        '.status == "ok" and .version == $expected' \
        "$health_file" >/dev/null \
      && jq -e \
        --arg expected "$expected_tag" \
        '.version == $expected and .image_tag == $expected' \
        "$version_file" >/dev/null
    then
      log "Application healthy on attempt $attempt"
      cat "$health_file"
      echo
      cat "$version_file"
      echo

      rm -f "$health_file" "$version_file"
      return 0
    fi

    sleep 2
  done

  log "ERROR: application did not become healthy at $base_url"
  rm -f "$health_file" "$version_file"
  return 1
}

start_production() {
  local image="$1"
  local expected_tag

  expected_tag="$(image_tag_from_reference "$image")"

  remove_container "$APP_NAME"

  start_container \
    "$APP_NAME" \
    "$image" \
    "0.0.0.0:${PRODUCTION_PORT}" \
    "unless-stopped" \
    >/dev/null

  wait_for_application \
    "http://127.0.0.1:${PRODUCTION_PORT}" \
    "$expected_tag" \
    30
}

restore_previous_image() {
  local previous_image="$1"

  if [ -z "$previous_image" ]; then
    log "No previous image is available for automatic restoration"
    return 1
  fi

  log "Attempting restoration of previous image: $previous_image"

  if start_production "$previous_image"; then
    log "Previous image restored successfully"
    return 0
  fi

  log "ERROR: previous image restoration failed"
  return 1
}

deploy_image() {
  local target_image="$1"
  local target_tag
  local current_image=""

  validate_image "$target_image"
  target_tag="$(image_tag_from_reference "$target_image")"

  if container_exists "$APP_NAME"; then
    current_image="$(
      docker inspect \
        --format '{{.Config.Image}}' \
        "$APP_NAME"
    )"
  elif [ -f "$CURRENT_IMAGE_FILE" ]; then
    current_image="$(cat "$CURRENT_IMAGE_FILE")"
  fi

  log "Target image: $target_image"
  log "Current image: ${current_image:-none}"

  docker pull "$target_image"

  remove_container "${APP_NAME}-candidate"

  log "Starting candidate container on loopback port $CANDIDATE_PORT"

  start_container \
    "${APP_NAME}-candidate" \
    "$target_image" \
    "127.0.0.1:${CANDIDATE_PORT}" \
    "no" \
    >/dev/null

  if ! wait_for_application \
    "http://127.0.0.1:${CANDIDATE_PORT}" \
    "$target_tag" \
    30
  then
    docker logs "${APP_NAME}-candidate" || true
    remove_container "${APP_NAME}-candidate"
    exit 1
  fi

  remove_container "${APP_NAME}-candidate"

  log "Candidate passed. Promoting image to production"

  if ! start_production "$target_image"; then
    log "ERROR: production health verification failed"
    docker logs "$APP_NAME" || true
    remove_container "$APP_NAME"

    restore_previous_image "$current_image" || true
    exit 1
  fi

  if [ -n "$current_image" ] && [ "$current_image" != "$target_image" ]; then
    printf '%s\n' "$current_image" >"$PREVIOUS_IMAGE_FILE"
  fi

  printf '%s\n' "$target_image" >"$CURRENT_IMAGE_FILE"

  printf '%s action=deploy image=%s previous=%s\n' \
    "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    "$target_image" \
    "${current_image:-none}" \
    >>"$DEPLOYMENT_HISTORY"

  log "Deployment completed successfully"
}

rollback_image() {
  local previous_image

  if [ ! -s "$PREVIOUS_IMAGE_FILE" ]; then
    log "ERROR: no previous image is recorded"
    exit 1
  fi

  previous_image="$(cat "$PREVIOUS_IMAGE_FILE")"

  log "Rollback target: $previous_image"
  deploy_image "$previous_image"

  printf '%s action=rollback image=%s\n' \
    "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    "$previous_image" \
    >>"$DEPLOYMENT_HISTORY"
}

show_status() {
  echo "=== Container ==="
  docker ps \
    --filter "name=^/${APP_NAME}$" \
    --format 'name={{.Names}} image={{.Image}} status={{.Status}} ports={{.Ports}}'

  echo
  echo "=== Current image ==="
  if [ -f "$CURRENT_IMAGE_FILE" ]; then
    cat "$CURRENT_IMAGE_FILE"
  else
    echo "not recorded"
  fi

  echo
  echo "=== Previous image ==="
  if [ -f "$PREVIOUS_IMAGE_FILE" ]; then
    cat "$PREVIOUS_IMAGE_FILE"
  else
    echo "not recorded"
  fi

  echo
  echo "=== Recent deployment history ==="
  tail -20 "$DEPLOYMENT_HISTORY" 2>/dev/null || true
}

main() {
  require_command docker
  require_command curl
  require_command jq

  mkdir -p "$APP_DIR"

  if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    log "ERROR: another deployment appears to be running"
    exit 1
  fi

  trap 'rm -rf "$LOCK_DIR"; remove_container "${APP_NAME}-candidate"' EXIT

  case "${1:-}" in
    deploy)
      [ "$#" -eq 2 ] || {
        usage
        exit 1
      }

      deploy_image "$2"
      ;;

    rollback)
      [ "$#" -eq 1 ] || {
        usage
        exit 1
      }

      rollback_image
      ;;

    status)
      show_status
      ;;

    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
