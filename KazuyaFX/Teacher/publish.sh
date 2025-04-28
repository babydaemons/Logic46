#!/bin/bash

taskkill.exe -im EXPLZH.EXE -f 1>/dev/null 2>&1

#rm -rf KazuyaFX_Setup/KazuyaFX
#mkdir -p KazuyaFX_Setup/KazuyaFX/installer

cp -pr ../Experts/KazuyaFX_*EA KazuyaFX_Setup/Users/Administrator/AppData/Roaming/MetaQuotes/Terminal/F1DD1D6E7C4A311D1B1CA0D34E33291D/MQL4/Experts

printf "\n\n##### インストーラーをビルド...\n"
(pushd KazuyaFX_Installer; powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1; cp -p KazuyaFX_Installer.exe ../KazuyaFX_Setup/KazuyaFX/installer; popd)

printf "\n##### .NETアプリをビルド...\n"
(pushd KazuyaFX; dotnet publish KazuyaFX.csproj -c Release -o ../KazuyaFX_Setup/KazuyaFX; cd ../KazuyaFX_Setup/KazuyaFX; rm -rf app *.pdb; popd)

cp -p KazuyaFX.ico ./KazuyaFX_Setup/KazuyaFX/

"/c/Program Files/Explzh/EXPLZH.EXE" &
