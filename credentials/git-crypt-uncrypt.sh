#!/bin/bash

if [ -n "$GIT_CRYPT_KEY" ]; then
    echo "GIT_CRYPT_KEY env variable is not defined"
    exit 1
else

echo $GIT_CRYPT_KEY | base64 -d > .git-crypt.key
git-crypt unlock .git-crypt.key
