#!/usr/bin/env bash

set -e

source pipelines/shared/utils.sh
source /etc/profile.d/chruby.sh
chruby 2.1.7

# inputs
input_dir=$(realpath director-state/)
bosh_cli=$(realpath bosh-cli/bosh-cli-*)
chmod +x $bosh_cli

if [ ! -e "${input_dir}/director-state.json" ]; then
  echo "director-state.json does not exist, skipping..."
  exit 0
fi

if [ -d "${input_dir}/.bosh" ]; then
  # reuse compiled packages
  cp -r ${input_dir}/.bosh $HOME/
fi

pushd ${input_dir} > /dev/null
  # configuration
  source director.env
  : ${BOSH_DIRECTOR_IP:?}
  : ${BOSH_USER:?}
  : ${BOSH_PASSWORD:?}

  # Don't exit on failure to target the BOSH director
  set +e
    # teardown deployments against BOSH Director
    time $bosh_cli -n env ${BOSH_DIRECTOR_IP//./-}.sslip.io

    if [ -n "${DEPLOYMENT_NAME}" ]; then
      time $bosh_cli -n delete-deployment -d ${DEPLOYMENT_NAME} --force
    fi
    time $bosh_cli -n clean-up --all
  set -e

  echo "deleting existing BOSH Director VM..."
  $bosh_cli -n delete-env director.yml
popd
