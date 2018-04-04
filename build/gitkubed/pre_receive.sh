#!/bin/bash

# Repo Name:
DEPLOY_REPO_NAME=$(basename "$PWD")

export REPO_LOC='{{REPO_LOC}}'
export REPO_OPTS='{{REPO_OPTS}}'
export REGISTRY_PREFIX='{{REGISTRY_PREFIX}}'
export REMOTE_HOOKS_DIR='{{REMOTE_HOOKS_DIR}}'

# This is the root deploy dir.
BUILD_ROOT="${HOME}/build/${DEPLOY_REPO_NAME}"

###########################################################################################

# export GIT_DIR="$(cd $(dirname $(dirname $0));pwd)"
# export GIT_WORK_TREE="${BUILD_ROOT}"

echo "Initialising gitkube pre-receive"
echo

# Loop, because it is possible to push more than one branch at a time. (git push --all)
while read oldrev newrev refname
do

    # export DEPLOY_BRANCH=$(git rev-parse --symbolic --abbrev-ref $refname)
    DEPLOY_BRANCH=$(expr "$refname" : "refs/heads/\(.*\)")
    DEPLOY_OLDREV="$oldrev"
    DEPLOY_NEWREV="$newrev"
    DEPLOY_REFNAME="$refname"

    echo "adfadfa" $DEPLOY_BRANCH $DEPLOY_OLDREV $DEPLOY_NEWREV $DEPLOY_REFNAME

    if [ "$DEPLOY_BRANCH" == "master" ]; then
        echo "Checking out master branch"
        mkdir -p "${BUILD_ROOT}"
        git archive $DEPLOY_NEWREV | tar -x -C $BUILD_ROOT
        echo "Copying hooks..."
        for hook in $BUILD_ROOT/$REMOTE_HOOKS_DIR/*
        do
            mo $hook | tee $hook.tmp > /dev/null
            cat $hook.tmp | tee $hook > /dev/null
        done
        chmod -R a+x $BUILD_ROOT/$REMOTE_HOOKS_DIR
        cp $BUILD_ROOT/$REMOTE_HOOKS_DIR/* $REPO_LOC/hooks/
        rm -rf $BUILD_ROOT
    fi

    if [ -f $REPO_LOC/hooks/pre-receive ]; then
        echo $oldrev $newrev $refname | $REPO_LOC/hooks/pre-receive
        echo "return value: $?"
    fi
done
exit 0

