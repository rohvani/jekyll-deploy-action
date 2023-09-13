#!/bin/bash
set -e

# Check if deploy to same branch
if [[ "${REPOSITORY}" = "${GITHUB_REPOSITORY}" ]]; then
  if [[ "${GITHUB_REF}" = "refs/heads/${BRANCH}" ]]; then
    echo "It's conflicted to deploy on same branch ${BRANCH}"
    exit 1
  fi
fi

# Tell GitHub Pages not to run Jekyll
touch .nojekyll
[[ -n "$INPUT_CNAME" ]] && echo "$INPUT_CNAME" > CNAME

# Prefer to use SSH approach when SSH private key is provided
if [[ -n "${SSH_PRIVATE_KEY}" ]]; then
  export GIT_SSH_COMMAND="ssh -i ${SSH_PRIVATE_KEY_PATH} \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null"
  REMOTE_REPO="git@github.com:${REPOSITORY}.git"
else
  REMOTE_REPO="https://${ACTOR}:${TOKEN}@github.com/${REPOSITORY}.git"
fi

echo "Deploying to ${REPOSITORY} on branch ${BRANCH}"
echo "Deploying to ${REMOTE_REPO}"

JEKYLL_BUILD_OUTPUT_PATH=${PWD}
cd $GITHUB_WORKSPACE && \
  mv $JEKYLL_BUILD_OUTPUT_PATH jek_build_output && \
  cd $JEKYLL_SRC && \
  git config user.name "${ACTOR}" && \
  git config user.email "${ACTOR}@users.noreply.github.com" && \
  git reset --hard && git clean  -d  -f . && \
  git fetch $REMOTE_REPO $BRANCH && \
  git checkout $BRANCH && \
  git reset --hard && git clean  -d  -f . && \
  cp -Rf $GITHUB_WORKSPACE/jek_build_output/* ./ && \
  # remove artifacts
  rm -rf jekyll_site/.bundle/ jekyll_site/.jekyll-cache/ jekyll_site/Gemfile.lock jekyll_site/package.json
  # push it all to the repo
  git add -A && git commit -m "update site deployment" && \
  git push --force $REMOTE_REPO $BRANCH:$BRANCH

PROVIDER_EXIT_CODE=$?
