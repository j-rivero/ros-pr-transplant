#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

ALL_BRANCHES="indigo-devel jade-devel kinetic-devel"

#set -e

if [[ $# -lt 1 ]]; then
    echo "Usage: transplant <pr_url> [<destination_branch>]"
    exit 1
fi

PR=${1}

REPO=${PR/\/pull*} && REPO=${REPO#*github.com\/}
PR_NUMBER=${PR##*/}
GITHUB_API_PR="https://api.github.com/repos/${REPO}/pulls/${PR_NUMBER}"
PR_ORIG_BRANCH=$(curl -s ${GITHUB_API_PR} | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["base"]["ref"]')
PR_TITLE=$(curl -s ${GITHUB_API_PR} | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["title"]')
PR_BODY=$(curl -s ${GITHUB_API_PR} | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["body"]')

if [[ $# == 2 ]]; then  
  DEST_BRANCHES=${2}
else
  DEST_BRANCHES=${ALL_BRANCHES/$PR_ORIG_BRANCH}
fi

FORK_DIR=$(mktemp -d)
git clone git@github.com:${REPO} ${FORK_DIR}
pushd ${FORK_DIR} > /dev/null

for branch in $DEST_BRANCHES; do
    echo "-------------------------------------------------"
    echo "Transplanting pull-request ${PR_NUMBER}          "
    echo " - Title  : $PR_TITLE                            "
    echo " - Branch : ${PR_ORIG_BRANCH} -> ${branch}       "
    echo "-------------------------------------------------"
    _transplant_branch="${branch}-transplant-${PR_NUMBER}"
    git checkout ${branch}
    git checkout -b ${_transplant_branch}
    # keep tabs
    cat > commit.md <<- DELIM
	${PR_TITLE} (${branch})

	{ port of pull request #${PR_NUMBER} }
	${PR_BODY}

	DELIM
    # --reject will help when patch don't apply cleanly. It will force to try with the
    # usual offset and leave the repo at least partially patched. Be sure of use am --continue
    # when finish
    ret=$(hub am --3way ${PR}) || true
    if [[ $ret != 0  ]]; then
	cat <<- EOF

	    -- The merge needs manual attention --"
	
	    After fixing it you can run:
	     1. git push origin ${_transplant_branch}
	     2. hub pull-request --browse -F commit.md -b ${branch} -h ${_transplant_branch}

	EOF
	popd > /dev/null
	cd ${FORK_DIR}
    else
      # If the merge is succesful go ahead with the branch and PR
      git push origin ${_transplant_branch}
      hub pull-request --browse -F commit.md -b ${branch} -h ${_transplant_branch}
    fi
done
