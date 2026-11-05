# Especificação Técnica — Menu e Telas 3270 (alterações para segurança RACF)

**Versão:** 0.1  
**Data:** 2026-11-05  
**Autor:** Gerado via IBM Bob Z Architect  
**Status:** Rascunho para validação  
**Origem:** [`RACF-security-functional-spec.md`](RACF-security-functional-spec.md) (RF-12, RF-15) · **Índice:** [`RACF-security-technical-index.md`](RACF-security-technical-index.md) §5

---

## 1. Escopo

| Programa | Transação | Papel nesta mudança |
|----------|-----------|---------------------|
| [`BNKMENU`](../../src/base/cics/cobol/BNKMENU.cbl) | `OMEN` | Mostrar/permitir apenas as opções do papel (conveniência, RF-12) |
| [`BNK1CAC`](../../src/base/cics/cobol/BNK1CAC.cbl) | `OCAC` | Tratar fail codes `S`/`X` de `CREACC` |
| [`BNK1CCS`](../../src/base/cics/cobol/BNK1CCS.cbl) | `OCCS` | Tratar fail codes `S`/`X` de `CRECUST` |
| [`BNK1CRA`](../../src/base/cics/cobol/BNK1CRA.cbl) | `OCRA` | Tratar fail codes `S`/`X` de `DBCRFUN` |
| [`BNK1DAC`](../../src/base/cics/cobol/BNK1DAC.cbl) | `ODAC` | Tratar fail codes `S`/`X` de `DELACC` |
| [`BNK1DCS`](../../src/base/cics/cobol/BNK1DCS.cbl) | `ODCS` | Tratar fail codes `S`/`X` de `DELCUS` e `UPDCUST` |
| [`BNK1TFN`](../../src/base/cics/cobol/BNK1TFN.cbl) | `OTFN` | Tratar fail codes `S`/`X` de `XFRFUN` |
| [`BNK1UAC`](../../src/base/cics/cobol/BNK1UAC.cbl) | `OUAC` | Tratar fail codes `S`/`X` de `UPDACC` **e ajustar o layout da COMMAREA** |
| [`BNK1CCA`](../../src/base/cics/cobol/BNK1CCA.cbl) | `OCCA` | Sem alteração (somente consulta via `INQACCCU`) |

**Princípio:** as telas **não** decidem autorização. A fonte da verdade é o `BNKSECCK` chamado pelo subprograma (RF-09, RF-11) e, antes dele, o RACF na transação (L4). A tela apenas apresenta bem o resultado.

## 2. Camadas que protegem uma tela

1. **L4 (`TCICSTRN`/`GCICSTRN`):** o RACF nega a **transação** (ex.: `OUAC`) para quem não é gerente; o CICS devolve a mensagem padrão de segurança e o programa da tela nem executa.
2. **L5 (`BNKSECCK`):** protege o subprograma, inclusive quando chamado pela API.
3. **Tela:** mensagem amigável, ver abaixo.

## 3. BNKMENU

### 3.1 Estado atual (verificado)

- Cabeçalho `PROCESS CICS,NODYNAM,NSYMBOL(NATIONAL),TRUNC(STD)` e `CBL CICS('SP,EDF')` (linhas 1–2).
- `EDIT-MENU-DATA` (355–374) aceita `'1'`–`'7'` e `'A'`; mensagem de erro: `You must enter a valid value (1-7 or A).`
- `INVOKE-OTHER-TXNS` (377+) faz `EXEC CICS RETURN TRANSID(...) IMMEDIATE` por opção: `1`→`ODCS`, `2`→`ODAC`, `3`→`OCCS`, `4`→`OCAC`, `5`→`OUAC`, `6`→`OCRA`, `7`→`OTFN`, `A`→`OCCA`.
- Em falha do `RETURN`, abenda via `ABNDPROC` (`HBNK`).

### 3.2 Comportamento atual sob RACF L4

O `RETURN TRANSID` para uma transação que o usuário não pode executar **não falha no `BNKMENU`**: a negação ocorre no início da transação seguinte (o CICS rejeita a tarefa). O usuário veria a mensagem do CICS, não uma mensagem do Bank of Z, e o menu não seria reexibido. **[A VALIDAR]** o comportamento exato em `SEC=YES` com `XTRAN=YES` (a documentação consultada cobre o `QUERY SECURITY`, não esse fluxo).

### 3.3 Alteração proposta (opcional, UX)

| Item | Proposta |
|------|----------|
| Verificação prévia | Em `EDIT-MENU-DATA`, após validar o valor, consultar `BNKSECCK` com a operação correspondente à opção. Se não permitido, reexibir o menu com mensagem e **não** executar o `RETURN TRANSID` |
| Mapeamento opção → operação | `1`→`INQCUST`, `2`→`INQACC`, `3`→`CRECUST`, `4`→`CREACC`, `5`→`UPDACC`, `6`→`DBCRFUN`, `7`→`XFRFUN`, `A`→`INQACC` (consulta; sem perfil próprio) |
| Mensagem | `You are not authorised for this option.` |
| Opção `1` e `2` | Dão acesso a telas que, por PF5/PF10, excluem/atualizam; a decisão de excluir/atualizar é feita por `DELCUS`/`UPDCUST`/`DELACC`, não pelo menu |
| Ocultar opções | Exigiria alterar o mapa BMS `BNK1MAI`; **fora desta fase** (o texto do menu continua listando todas as opções) |
| Custo | 1 LINK adicional por seleção de menu |

Esta alteração **não** substitui L4/L5. Se rejeitada, o comportamento do §3.2 permanece.

## 4. Padrão de tratamento nas telas de negócio

Após o `LINK` ao subprograma, onde a tela hoje testa `success = 'N'`, incluir **antes** do ramo genérico:

```cobol
IF <fail-code> = 'S'
   MOVE SPACES TO MESSAGEO
   MOVE 'Sorry, you are not authorised to perform this operation.'
     TO MESSAGEO
   MOVE 'N' TO VALID-DATA-SW
END-IF
IF <fail-code> = 'X'
   MOVE SPACES TO MESSAGEO
   MOVE 'Security check unavailable. Please contact support.'
     TO MESSAGEO
   MOVE 'N' TO VALID-DATA-SW
END-IF
```

Os textos têm 56 e 51 caracteres e cabem no campo `MESSAGE` dos mapas BMS, que tem `LENGTH=79` (verificado em `BNK1MAI`, `BNK1CAM`, `BNK1CCM`, `BNK1DAM`, `BNK1DCM`, `BNK1TFM`, `BNK1UAM`, `BNK1ACC`, `BNK1CDM`). Não revelar nome de perfil ou de grupo RACF (RF-23).

## 5. Alterações por tela

### 5.1 BNK1CAC (cria conta)

- `LINK PROGRAM('CREACC')` na linha 776; teste `IF SUBPGM-SUCCESS = 'N'` na linha 845; `EVALUATE SUBPGM-FAIL-CODE` (849) com `'1'`–`'9'`, `'A'` e `WHEN OTHER` (918).
- Incluir `WHEN 'S'` e `WHEN 'X'` antes do `WHEN OTHER`.

### 5.2 BNK1CCS (cria cliente)

- `LINK PROGRAM('CRECUST')` na linha 998; teste de fail code em 1069–1084 com `'O'`, `'Y'`, `'Z'`.
- Incluir os `IF` para `'S'` e `'X'` ao lado dos existentes; a mensagem base ("Sorry but unable to create Customer record") é sobrescrita como nos demais.

### 5.3 BNK1CRA (depósito/saque)

- `LINK PROGRAM('DBCRFUN')` na linha 512; `IF SUBPGM-SUCCESS = 'N'` (581), `EVALUATE SUBPGM-FAIL-CODE` (585) com `WHEN OTHER` (612) que exibe o código (616).
- Incluir `WHEN 'S'` e `WHEN 'X'`.
- Aproveitar que o programa já captura `ODUSERID` (linhas ~503–509): sem alteração.

### 5.4 BNK1DAC (exclui conta)

- `PF5` (linha 399) → `PERFORM DEL-ACC-DATA` (407, seção em 702).
- Cadeia de `IF` em 734–779 (`'1'`, `'2'`, `'3'`, genérico). Incluir `'S'` e `'X'` **antes** do genérico (linha 770), no estilo existente (`MOVE 'N' TO VALID-DATA-SW`, `MOVE PARMS-SUBPGM-SCODE TO SORTCO`, `GO TO DAD999`).

### 5.5 BNK1DCS (exclui e atualiza cliente)

- Exclusão: `PF5` (486) → `DEL-CUST-DATA` (1002; `LINK DELCUS` na 1012). Cadeia de `IF` em 1084–1130; incluir `'S'` e `'X'` antes do genérico da linha 1121, no estilo existente (`GO TO DCD999`).
- Atualização: `PF10` (505) → `UNPROT-CUST-DATA`; envio em `UPDATE-CUST-DATA` (1167; `LINK UPDCUST` na 1217). `EVALUATE COMM-UPD-FAIL-CD` em 1293–1338 com `WHEN OTHER` (1338); incluir `WHEN 'S'` e `WHEN 'X'`.
- Observação de UX: com PF10 o usuário ainda consegue **desbloquear** os campos para edição mesmo sem permissão de update; a negação só ocorre ao confirmar. Alternativa (opcional): verificar `UPDCUST` ao pressionar PF10 via `BNKSECCK`, para não induzir o usuário a editar.

### 5.6 BNK1TFN (transferência)

- `LINK PROGRAM('XFRFUN')` na linha 497; `IF SUBPGM-SUCCESS = 'N'` (582); `EVALUATE SUBPGM-FAIL-CODE` (586) com `WHEN OTHER` (617). Incluir `WHEN 'S'` e `WHEN 'X'`.

### 5.7 BNK1UAC (atualiza conta) — **mudança de layout**

- `DFHCOMMAREA` local (linhas 179–193) deve receber `03 COMM-FAIL-CD PIC X.` **entre** `COMM-SUCCESS` e `COMM-PCB1-POINTER` (ver [`UPDACC-technical-spec.md`](UPDACC-technical-spec.md) §5).
- `LINK PROGRAM('UPDACC')` na linha 955; teste `IF COMM-SUCCESS = 'N'` na 1024 exibe "Update unsuccessful, try again later." para qualquer falha. Passar a testar `COMM-FAIL-CD` e exibir a mensagem de negação ou de erro de segurança antes da mensagem genérica.
- Atenção: `LINK ... COMMAREA(WS-COMM-AREA) LENGTH(99)` (297–298) refere-se ao pseudo-conversacional da tela e **não** muda.

## 6. Testes

| ID | Cenário | Esperado |
|----|---------|----------|
| TS-01 | `BZAUDIT` seleciona opção 3 do menu | Menu reexibido com mensagem (se §3.3 aprovado) ou negação L4 |
| TS-02 | `BZTELLER` em `ODCS` pressiona PF5 | Mensagem de não autorizado; cliente intacto |
| TS-03 | `BZTELLER` em `ODCS` pressiona PF10 e confirma | Mensagem de não autorizado |
| TS-04 | `BZMGR` em `ODAC` pressiona PF5 | Conta excluída |
| TS-05 | `BZAUDIT` em `OCRA` | Mensagem de não autorizado; sem lançamento |
| TS-06 | `BZTELLER` em `OUAC` | Negado no L4 ou mensagem da tela |
| TS-07 | `BNKSECCK` indisponível em `OTFN` | Mensagem de verificação indisponível |
| TS-08 | Regressão: caminhos felizes das 8 telas com `BZMGR` | Inalterados |
| TS-09 | `BNK1UAC` e `UPDACC` recompilados juntos; `COMM-PCB1-POINTER` continua `NULL` | verdadeiro |

## 7. Localização dos Artefatos

| Artefato | Caminho |
|----------|---------|
| Fontes das telas | `src/base/cics/cobol/BNK1*.cbl`, `BNKMENU.cbl` |
| Mapas BMS | `src/base/cics/bms/` |
| Definições de transação | [`bank-of-z-definitions.yaml`](../../.setup/zconfig/bank-of-z-definitions.yaml) |
