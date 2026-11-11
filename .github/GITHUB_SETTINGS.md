# Configuração do Repositório — GitHub Actions

Guia para configurar Secrets e Variables necessárias para o pipeline do Bank of Z
no repositório **https://github.ibm.com/rafael-testa/Bank-of-Z**.

---

## 🔐 Secrets

> Settings → Secrets and variables → Actions → **New repository secret**
> URL: https://github.ibm.com/rafael-testa/Bank-of-Z/settings/secrets/actions

| Secret | Valor | Observação |
|--------|-------|------------|
| `ZOS_SSH_KEY` | Conteúdo PEM da chave privada SSH (`~/.ssh/id_ed25519`) | Incluir linhas `-----BEGIN` e `-----END` |
| `GH_ACTIONS_PAT` | Token PAT do GitHub público | Criar em https://github.com/settings/tokens com escopo `repo` |

---

## ⚙️ Variables

> Settings → Secrets and variables → Actions → **New repository variable**
> URL: https://github.ibm.com/rafael-testa/Bank-of-Z/settings/variables/actions

| Variable | Valor de exemplo | Descrição |
|----------|-----------------|-----------|
| `ZOS_HOST` | `ESYSMVS.wsclab.washington.ibm.com` | Hostname do z/OS |
| `ZOS_SSH_USER` | `rafaelt` | Usuário SSH no z/OS |
| `ZOS_SSH_PORT` | `22` | Porta SSH |
| `ZOS_SANDBOX_DIR` | `/u/rafaelt/projects` | Diretório base do workspace no z/OS USS |
| `BOZ_BUILD_HLQ` | `BANKZ` | HLQ destino dos artefatos compilados |
| `BOZ_FRONTEND_URL` | `http://ESYSMVS.wsclab.washington.ibm.com:9081` | URL do frontend Bank of Z |

---

## ✅ Checklist

- [ ] Secret `ZOS_SSH_KEY` adicionado
- [ ] Secret `GH_ACTIONS_PAT` adicionado
- [ ] Variable `ZOS_HOST` configurada
- [ ] Variable `ZOS_SSH_USER` configurada
- [ ] Variable `ZOS_SSH_PORT` configurada
- [ ] Variable `ZOS_SANDBOX_DIR` configurada
- [ ] Variable `BOZ_BUILD_HLQ` configurada
- [ ] Variable `BOZ_FRONTEND_URL` configurada
- [ ] Pipeline testado manualmente via **Actions → Run workflow**
