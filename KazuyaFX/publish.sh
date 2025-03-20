#!/bin/bash
WORK="_work_KazuyaFX_InstallerBuild"
rm -rf ${WORK} KazuyaFX/KazuyaFX.zip
mkdir ${WORK}

printf "##### .NETアプリ1をビルド...\n"
(pushd KazuyaFX_Service; dotnet publish KazuyaFX_Service.csproj -c Release -o ../${WORK}; cd ../${WORK}; rm -rf app; popd)
printf "\n\n##### .NETアプリ2をビルド...\n"
(pushd KazuyaFX_Server; dotnet publish KazuyaFX_Server.csproj -c Release -o ../${WORK}/kestrel; cd ../${WORK}/kestrel; rm -rf app; popd)
printf "\n\n##### インストーラーをビルド...\n"
(pushd KazuyaFX_Installer; powershell -File build.ps1; cp -p KazuyaFX_Installer.exe ../${WORK}; popd)

printf "\n\n##### 7zでzipアーカイブ作成...\n"
(pushd ${WORK}; find * -name \*.pdb -delete -print; 7z.exe a ../KazuyaFX/KazuyaFX.zip .; popd)
rm -rf ${WORK}

printf "\n\n##### PuInstallerでインストーラー作成...\n"
cd KazuyaFX
if [ ! -f venv/Scripts/activate ]
then
    python -m venv venv
    source venv/Scripts/activate
    pip install PyInstaller
else
    source venv/Scripts/activate
fi
pyinstaller KazuyaFX.spec
cp -p dist/KazuyaFX.exe ..
rm -rf build dist
