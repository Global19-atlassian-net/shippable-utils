#!/bin/bash -e
# Author: Bassam Tabbara <Bassam.Tabbara@Quantum.com>
# Licence: MIT
# Copyright (c) 2015, Quantum Corp.

usage() 
{
cat <<EOF 
Usage: 
  github-release <repo_name> <branch> <asset_path>

Description:
  Checks the branch name and if it is a semantic version,
  create a new github draft release in the specified repo and uploads
  assets from the specified path.

Arguments:
  repo_name - the name of the repo in the form user/repo. e.g. trovalds/linux
  branch - the name of the branch. e.g. master or 1.0.3-alpha.4+build.6
  asset_path - a path to the binary assets to be uploaded

Environment:
  GITHUB_TOKEN - github oauth token

Dependencies:
  github-release from github.com/carlsverre/github-release
    e.g. go get github.com/carlsverre/github-release

Examples:
  github-release trovalds/linux 4.90.23 ./builds
EOF
}

while getopts ":h" opt
do
  case "${opt}" in
    h )  usage; exit 0 ;;
    \?)  echo "unrecognized option: $OPTARG" 1>&2
         exit 1
         ;;
  esac
done
shift $((OPTIND-1))

REPO_NAME="$1"
BRANCH="$2"
ASSET_PATH="$3"

[[ ${REPO_NAME} != "" ]] || { echo "repository name is required." 1>&2; usage; exit 1; }
[[ ${BRANCH} != "" ]] || { echo "branch is required." 1>&2; usage; exit 1; }
[[ ${ASSET_PATH} != "" ]] || { echo "path to assets is required." 1>&2; usage; exit 1; }

# check if we are building from a tag that is a semver. If so add the assets to the build.
if echo ${BRANCH} | grep -q -E '^([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+)(-([A-Za-z0-9\-\.]+))?(\+([A-Za-z0-9\-\.]+))?$'; then

  echo "Creating github draft release ${BRANCH} and uploading assets."

  # create the draft releast if not already created.
  if ! github-release info --user ${REPO_NAME%%/*} --repo ${REPO_NAME#*/} --tag ${BRANCH} > /dev/null 2>&1; then
    github-release release --user ${REPO_NAME%%/*} --repo ${REPO_NAME#*/} --tag ${BRANCH} --name "${BRANCH}" --description "Release Draft" --draft
  fi

  find ${ASSET_PATH} -type f | while read f 
  do
    echo "Uploading $f"
    github-release upload --user ${REPO_NAME%%/*} --repo ${REPO_NAME#*/} --tag ${BRANCH} --name $(basename $f) --file $f
  done
else
  echo "Skipping github release from branch ${BRANCH}."
fi
