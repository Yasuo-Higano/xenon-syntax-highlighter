#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

git remote add origin git@github-Yasuo-Higano:Yasuo-Higano/xenon-syntax-highlighter.git
git branch -M main
git push -u origin main
