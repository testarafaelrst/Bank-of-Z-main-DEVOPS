#!/bin/sh
# gitClone.sh — baixa repositório via GitHub API (sem git nativo no z/OS)
# Uso: gitClone.sh -w <workspace> -r <https://token@github.com/org/repo.git> -b <branch>

while getopts "w:r:b:" opt; do
  case $opt in
    w) WORKSPACE="$OPTARG" ;;
    r) REPO_URL="$OPTARG"  ;;
    b) BRANCH="$OPTARG"    ;;
  esac
done

export JAVA_HOME=/usr/lpp/java/J21.0_64
export DBB_HOME=/shared/IBM/dbb
export PYTHON_HOME=/shared/IBM/cyp/v3r14/pyz
export PATH=$JAVA_HOME/bin:$DBB_HOME/bin:$PYTHON_HOME/bin:$PATH

# Extrair token e repo da URL https://TOKEN@github.com/org/repo.git
TOKEN=$(echo "$REPO_URL" | sed 's|https://||' | cut -d@ -f1)
REPO_PATH=$(echo "$REPO_URL" | sed 's|https://[^@]*@github.com/||' | sed 's|\.git$||')
REPO_NAME=$(basename "$REPO_PATH")
ZIP_URL="https://api.github.com/repos/${REPO_PATH}/zipball/${BRANCH}"
ZIPFILE="$WORKSPACE/repo_$$.zip"

mkdir -p "$WORKSPACE"

echo "[INFO] Baixando ${REPO_PATH}@${BRANCH} via GitHub API..."
python3 - "$ZIP_URL" "$TOKEN" "$ZIPFILE" << 'PYEOF'
import sys, urllib.request
url, token, dest = sys.argv[1], sys.argv[2], sys.argv[3]
req = urllib.request.Request(url, headers={
    'Authorization': 'token ' + token,
    'User-Agent': 'gitClone-zos'
})
with urllib.request.urlopen(req) as r, open(dest, 'wb') as f:
    f.write(r.read())
print('[OK] Download concluido')
PYEOF

RC=$?
if [ $RC -ne 0 ]; then
  echo "[ERR] Download falhou RC=$RC"
  rm -f "$ZIPFILE"
  exit 1
fi

echo "[INFO] Extraindo em $WORKSPACE..."
python3 - "$ZIPFILE" "$WORKSPACE" "$REPO_NAME" << 'PYEOF'
import sys, zipfile, os, shutil
zipf, dest, name = sys.argv[1], sys.argv[2], sys.argv[3]
with zipfile.ZipFile(zipf) as z:
    top = z.namelist()[0].split('/')[0]
    z.extractall(dest)
    tgt = os.path.join(dest, name)
    if os.path.exists(tgt):
        shutil.rmtree(tgt)
    os.rename(os.path.join(dest, top), tgt)
os.remove(zipf)
print('[OK] Extraido em ' + tgt)
PYEOF

RC=$?
if [ $RC -ne 0 ]; then
  echo "[ERR] Extracao falhou RC=$RC"
  rm -f "$ZIPFILE"
  exit 1
fi

echo "[OK] Clone concluido em $WORKSPACE/$REPO_NAME"
