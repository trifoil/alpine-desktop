#!/bin/bash

apk update && apk add texmf-dist texlive-full

apk update && apk add texstudio

read -n 1 -s -r -p "Done. Press any key to continue..."

