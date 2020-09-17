#!/usr/bin/env bash

# Defaults variables
export RELEASE_NAME=blog
export CLEAN=false
export HELM_STABLE_REPO="https://kubernetes-charts.storage.googleapis.com"

# shellcheck disable=SC2086
cwd="$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)"

display_help() {
  echo "Usage: ./deploy.sh [arguments]..."
  echo
  echo "  -r, --release-name      helm release name (default: ${RELEASE_NAME})"
  echo "  -c, --clean             clean install will purge all existing resource (default: false)"
  echo "  -h, --help              display this help message"
  echo
}

exit_help() {
  display_help
  echo "Error: $1"
  exit 1
}

confirm_prompt() {
  read -r -p "[?] Are you sure? [Y/n] " input

  case $input in
    [yY][eE][sS] | [yY])
      return 0
      ;;
    [nN][oO] | [nN])
      exit 1
      ;;
    *)
      echo "Invalid input."
      exit 1
      ;;
  esac
}

# process arguments
while [[ $# -gt 0 ]]; do
  arg=$1
  case $arg in
    -h | --help)
      display_help
      exit 0
      ;;
    -c | --clean)
      CLEAN="true"
      ;;
    -r | --release-name)
      RELEASE_NAME=${2}
      shift
      ;;
    *)
      exit_help "Unknown argument: $arg"
      ;;
  esac
  shift
done

install_kubectl() {
  case "$(uname -s)" in
    Darwin)
      brew install kubectl
      ;;
    Linux)
      stable=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
      curl -LO "https://storage.googleapis.com/kubernetes-release/release/${stable}/bin/linux/amd64/kubectl"
      chmod +x ./kubectl
      sudo mv ./kubectl /usr/local/bin/kubectl
      ;;
    *)
      echo 'Unsupported OS.'
      exit 1
      ;;
  esac
}

install_helm() {
  curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
}

# Dependency checks
dep_check() {
  deps="kubectl helm"

  for dep in $deps; do
    echo "[+] Checking for installed dependency: $dep"
    if ! which "${dep//_/-}" &> /dev/null; then
      echo "[-] Missing dependency: $dep"
      echo "[+] Attempting to install:"
      install_"${dep}"
    fi
  done

  echo "[+] All done! Creating hidden file .dep_check so we don't have preform check again."
  touch .dep_check
}

# Run dependency check once (see above for dep check)
if [ ! -f ".dep_check" ]; then
  dep_check
else
  echo   "[+] Dependency check previously conducted. To rerun remove file .dep_check."
fi

helm repo add stable "${HELM_STABLE_REPO}" > /dev/null

if [ -f "${cwd}/requirements.yaml" ]; then
  if [ ! -f "${cwd}/requirements.lock" ]; then
    helm dependency update > /dev/null
  fi
fi

if [ "${CLEAN}" == "true" ]; then
  echo "[-] Deleting all resources in namespace -> ${RELEASE_NAME}."
  confirm_prompt
  kubectl get ns "${RELEASE_NAME}" > /dev/null 2>&1 && kubectl delete ns "${RELEASE_NAME}"
fi

# Create namespace where helm will deploy resources
# https://github.com/helm/helm/issues/6794

echo "[+] Attempting to create ${RELEASE_NAME} namespace"
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ${RELEASE_NAME}
EOF

HELM_CMD=()
HELM_CMD+=("-n" "${RELEASE_NAME}")

if [ -f "${cwd}/secrets.yaml" ]; then
  HELM_CMD+=("-f" "secrets.yaml")
fi

helm install "${RELEASE_NAME}" . "${HELM_CMD[@]}"

watch -n1 "kubectl get all -n ${RELEASE_NAME}"
