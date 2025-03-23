#!/bin/bash
WORK="__WORK__"
rm -rf ${WORK} KazuyaFX_Setup/KazuyaFX_Setup.zip
mkdir ${WORK}

printf "\n##### .NETアプリをビルド...\n"
(pushd KazuyaFX_Server; dotnet publish KazuyaFX_Server.csproj -c Release -o ../${WORK}/server; cd ../${WORK}/server; rm -rf app; popd)
printf "\n\n##### インストーラーをビルド...\n"
(pushd KazuyaFX_Installer; powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1; cp -p KazuyaFX_Installer.exe ../${WORK}; popd)

printf "\n\n##### 7zでzipアーカイブ作成...\n"
export PATH="/c/Program Files/7-Zip:${PATH}"
(pushd ${WORK}; find * -name \*.pdb -delete -print; 7z.exe a ../KazuyaFX_Setup/KazuyaFX_Setup.zip .; popd)
rm -rf ${WORK}

printf "\n\n##### PyInstallerでインストーラー作成...\n"
cd KazuyaFX_Setup
if [ ! -f venv/Scripts/activate ]
then
    python -m venv venv
    source venv/Scripts/activate
    pip install PyInstaller
else
    source venv/Scripts/activate
fi
pyinstaller KazuyaFX_Setup.spec
cp -p dist/KazuyaFX_Setup.exe ..
rm -rf build dist
