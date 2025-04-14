#!/bin/bash

printf "\n\n##### インストーラーをビルド...\n"
powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1
