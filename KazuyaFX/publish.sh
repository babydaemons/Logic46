#!/bin/bash
rm -rf KazuyaFX_Setup/KazuyaFX
mkdir -p KazuyaFX_Setup/KazuyaFX/installer

printf "\n\n##### インストーラーをビルド...\n"
(pushd KazuyaFX_Installer; powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1; cp -p KazuyaFX_Installer.exe ../KazuyaFX_Setup/KazuyaFX/installer; popd)

printf "\n##### .NETアプリをビルド...\n"
(pushd KazuyaFX; dotnet publish KazuyaFX.csproj -c Release -o ../KazuyaFX_Setup/KazuyaFX; cd ../KazuyaFX_Setup/KazuyaFX; rm -rf app *.pdb; popd)
