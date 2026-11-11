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
import sys, urllib.request, ssl
url, token, dest = sys.argv[1], sys.argv[2], sys.argv[3]
# Desabilita verificacao de certificado SSL para compatibilidade com z/OS
# onde os certificados CA do GitHub podem nao estar no truststore do sistema.
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE
req = urllib.request.Request(url, headers={
    'Authorization': 'token ' + token,
    'User-Agent': 'gitClone-zos'
})
with urllib.request.urlopen(req, context=ctx) as r, open(dest, 'wb') as f:
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
# Desativa conversao automatica durante extracao para preservar conteudo ASCII do ZIP
_BPXK_AUTOCVT=OFF python3 - "$ZIPFILE" "$WORKSPACE" "$REPO_NAME" << 'PYEOF'
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

TARGET_DIR="$WORKSPACE/$REPO_NAME"

# Tagger todos os arquivos texto como ISO8859-1 (ASCII-compativel).
# O DBB 3.x le YAML, shell scripts e arquivos fonte em ISO8859-1.
# Arquivos binarios (*.class, *.jar, *.war, *.zip) sao excluidos.
echo "[INFO] Taggeando arquivos texto como ISO8859-1..."
find "$TARGET_DIR" -type f \
  ! -name "*.class" ! -name "*.jar" ! -name "*.war" \
  ! -name "*.zip"   ! -name "*.tar" ! -name "*.gz"  \
  ! -name "*.png"   ! -name "*.jpg" ! -name "*.gif"  \
  ! -name "*.ico"   ! -name "*.pdf" ! -name "*.bin"  \
  ! -name "*.groovy" \
  -exec chtag -tc ISO8859-1 {} \; 2>/dev/null

# Arquivos Groovy precisam ser convertidos para EBCDIC (IBM-1047) porque
# o DBB 3.x carrega scripts Groovy como EBCDIC internamente via JVM z/OS.
echo "[INFO] Convertendo arquivos Groovy para EBCDIC IBM-1047..."
find "$TARGET_DIR" -name "*.groovy" -type f | while read gf; do
  iconv -f ISO8859-1 -t IBM-1047 "$gf" > "$gf.ebcdic"
  mv "$gf.ebcdic" "$gf"
  chtag -tc IBM-1047 "$gf"
done
echo "[INFO] Taggeamento e conversao concluidos"

# Garantir permissoes de execucao para scripts shell e Python
echo "[INFO] Definindo permissoes de execucao..."
find "$TARGET_DIR" -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null
find "$TARGET_DIR" -name "*.py" -type f -exec chmod +r {} \; 2>/dev/null
# Garantir que diretorios sao legíveis e navegaveis
find "$TARGET_DIR" -type d -exec chmod +rx {} \; 2>/dev/null
echo "[INFO] Permissoes definidas"

echo "[OK] Clone concluido em $WORKSPACE/$REPO_NAME"
