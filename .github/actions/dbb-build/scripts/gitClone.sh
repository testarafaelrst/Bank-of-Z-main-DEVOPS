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
# Usar /tmp para o ZIP temporario — filesystem separado do home do usuario,
# evita falha por falta de espaco em /u/<user> durante o download
ZIPFILE="/tmp/repo_$$.zip"

mkdir -p "$WORKSPACE"

# Verificar espaco disponivel antes de tentar o download
AVAIL_TMP=$(df -k /tmp 2>/dev/null | awk 'NR==2{print $4}')
AVAIL_WS=$(df -k "$WORKSPACE" 2>/dev/null | awk 'NR==2{print $4}')
echo "[INFO] Espaco disponivel: /tmp=${AVAIL_TMP}KB  workspace=${AVAIL_WS}KB"
if [ -n "$AVAIL_TMP" ] && [ "$AVAIL_TMP" -lt 102400 ]; then
  echo "[ERR] Espaco insuficiente em /tmp (${AVAIL_TMP}KB < 100MB). Libere disco antes de continuar."
  exit 1
fi

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

# Tagear arquivos extraidos do ZIP do GitHub (todos chegam em ASCII/ISO8859-1).
#
# Estrategia de tagging em DUAS camadas:
#
#   1. EBCDIC (IBM-1047): arquivos copiados para datasets z/OS pelo DBB
#      e scripts Groovy lidos pela JVM:
#      - *.groovy, *.cbl, *.cpy, *.pli, *.inc
#      - *.jcl, *.proc, *.cntl, *.rexx, *.asm, *.bms
#      Convertidos via iconv ISO8859-1->IBM-1047.
#      O DBB copia com copyMode:BINARY — bytes EBCDIC vao direto para datasets.
#
#   2. ISO8859-1 (ASCII): arquivos lidos pelo bash/Python/JVM via AUTOCVT=ON:
#      - *.yaml, *.json, *.sh, *.py, *.j2, *.html, *.js, etc.
#
# MOTIVO: com _BPXK_AUTOCVT=ON + arquivo ISO8859-1 + copyMode:TEXT, o DBB
# faz DUPLA conversao ao gravar em datasets (EDC5003I Truncation confirmado
# nos runs 42, 44, 49). Com copyMode:BINARY + arquivo IBM-1047, nao ha
# conversao — bytes EBCDIC vao direto para o dataset.
#
# ZCodeScan: chamado com _BPXK_AUTOCVT=OFF em task-zcodescan-static-scan.sh
# para receber bytes EBCDIC brutos dos arquivos IBM-1047 tagados.
# zcodescan -e IBM-1047 decodifica corretamente.

echo "[INFO] Taggeando arquivos nao-mainframe como ISO8859-1..."
find "$TARGET_DIR" -type f \
  ! -name "*.class" ! -name "*.jar" ! -name "*.war" \
  ! -name "*.zip"   ! -name "*.tar" ! -name "*.gz"  \
  ! -name "*.png"   ! -name "*.jpg" ! -name "*.gif"  \
  ! -name "*.ico"   ! -name "*.pdf" ! -name "*.bin"  \
  ! -name "*.cbl"   ! -name "*.cpy" ! -name "*.pli"  ! -name "*.inc" \
  ! -name "*.jcl"   ! -name "*.proc" ! -name "*.cntl" \
  ! -name "*.rexx"  ! -name "*.asm" ! -name "*.bms"  \
  ! -name "*.groovy" \
  -exec chtag -tc ISO8859-1 {} \; 2>/dev/null

echo "[INFO] Convertendo fontes mainframe e Groovy para EBCDIC (IBM-1047)..."
# IMPORTANTE: chmod u+w ANTES do iconv — os ZIPs do GitHub extraem arquivos
# somente-leitura (a+r sem w). O iconv grava em "$f.ebcdic" e o mv substitui
# "$f", mas mv falha silenciosamente se "$f" for read-only, deixando o arquivo
# em ASCII tagado como IBM-1047 (causa do erro [ERROR - lexing] Line 1 no ZCodeScan).
find "$TARGET_DIR" \( \
  -name "*.cbl"  -o -name "*.cpy"  -o -name "*.pli"  -o -name "*.inc"  \
  -o -name "*.jcl"  -o -name "*.proc" -o -name "*.cntl" \
  -o -name "*.rexx" -o -name "*.asm"  -o -name "*.bms"  \
  -o -name "*.groovy" \
\) -type f -exec chmod u+w {} \; 2>/dev/null

CONVERT_OK=0
CONVERT_FAIL=0
find "$TARGET_DIR" \( \
  -name "*.cbl"  -o -name "*.cpy"  -o -name "*.pli"  -o -name "*.inc"  \
  -o -name "*.jcl"  -o -name "*.proc" -o -name "*.cntl" \
  -o -name "*.rexx" -o -name "*.asm"  -o -name "*.bms"  \
  -o -name "*.groovy" \
\) -type f | while read f; do
  if iconv -f ISO8859-1 -t IBM-1047 "$f" > "$f.ebcdic" 2>/dev/null \
      && mv "$f.ebcdic" "$f" 2>/dev/null \
      && chtag -tc IBM-1047 "$f" 2>/dev/null; then
    CONVERT_OK=$((CONVERT_OK+1))
  else
    rm -f "$f.ebcdic" 2>/dev/null
    echo "[WARN] iconv/mv falhou para: $f"
    CONVERT_FAIL=$((CONVERT_FAIL+1))
  fi
done
echo "[INFO] Conversao EBCDIC concluida"

# Garantir permissoes corretas apos extracao do ZIP:
#   - Todos os arquivos: leitura para todos (a+r)
#   - Scripts shell: execucao para todos (a+x)
#   - Diretorios: leitura e navegacao (a+rx)
echo "[INFO] Definindo permissoes..."
chmod -R a+r "$TARGET_DIR" 2>/dev/null
find "$TARGET_DIR" -name "*.sh" -type f -exec chmod a+x {} \; 2>/dev/null
find "$TARGET_DIR" -type d -exec chmod a+rx {} \; 2>/dev/null
echo "[INFO] Permissoes definidas"

echo "[OK] Clone concluido em $WORKSPACE/$REPO_NAME"
