# DEVOPSPL — Especificação Técnica

## Identificação

| Atributo | Valor |
|----------|-------|
| **Program-ID** | `DEVOPSPL` |
| **Caminho** | `src/base/batch/cobol/DEVOPSPL.cbl` |
| **Tipo** | Batch COBOL — sem I/O de arquivo |
| **Linguagem** | Enterprise COBOL 6.x |
| **Compilador** | `IGYCRCTL` com opção `LIB` |
| **Link-edit** | `IEWBLINK MAP,RENT` |
| **deployType** | `LOAD` |
| **Return-Code sucesso** | `0` |
| **Return-Code falha** | `8` |

---

## Descrição Funcional

`DEVOPSPL` é um programa COBOL batch **ilustrativo** que simula e exibe via `DISPLAY` as 7 etapas de uma esteira DevOps IBM Z. Nenhum produto IBM é invocado em tempo de execução — os resultados das etapas são simulados internamente.

O programa serve como:
1. **Modelo educacional** da pipeline Bank of Z completa.
2. **Artefato de teste** para validar o fluxo TAZ → Wazi Deploy do pipeline GitHub Actions.
3. **Documentação executável** da sequência PLAN → CODE → Z CODE SCAN → BUILD → TEST → DEPLOY → MONITOR.

---

## Entradas

| Fonte | Campo | Tipo | Descrição |
|-------|-------|------|-----------|
| Working-Storage (hard-coded) | `WS-FALHA-SIMULADA` | `PIC S9(04) BINARY VALUE 0` | Número da etapa a simular falha. `0` = nenhuma falha (execução normal). Valor N (1–7) = falha na etapa N. |

> **Nota para TAZ:** o campo `WS-FALHA-SIMULADA` é o ponto de injeção de cenários negativos. Testes TAZ alteram este valor via parâmetro de execução antes de invocar o programa.

---

## Saídas

| Destino | Conteúdo |
|---------|----------|
| `SYSOUT` (DISPLAY) | Cabeçalho com data/hora, status de cada etapa (`SUCESSO` / `FALHA`), resumo final com contagem e alerta de abort |
| `RETURN-CODE` | `0` em fluxo normal; `8` quando qualquer etapa é abortada |

---

## Dependências

| Categoria | Detalhe |
|-----------|---------|
| Copybooks | Nenhum |
| Programas chamados (CALL) | Nenhum |
| DB2 / SQL | Não utilizado |
| CICS | Não utilizado |
| IMS / DL/I | Não utilizado |
| Arquivos de dados (FD) | Nenhum |

Compilação usa apenas a opção `LIB` — sem flags `CICS`, `SQL` ou `DLI`.

---

## Estrutura do Programa

### Working-Storage

```cobol
01 WS-CONTROLE.
   05 WS-IDX             PIC S9(04) BINARY SYNC VALUE 0.
   05 WS-NUM-ETAPA       PIC 9(01)  VALUE 0.
   05 WS-QTD-ETAPAS      PIC S9(04) BINARY SYNC VALUE 7.
   05 WS-QTD-OK          PIC S9(04) BINARY SYNC VALUE 0.
   05 WS-IDX-FALHA       PIC S9(04) BINARY SYNC VALUE 0.
   05 WS-FALHA-SIMULADA  PIC S9(04) BINARY SYNC VALUE 0.
   05 WS-FLAG-ABORTA     PIC X(01) VALUE 'N'.
      88 ESTEIRA-ABORTADA VALUE 'S'.
      88 ESTEIRA-EM-CURSO VALUE 'N'.

01 WS-TABELA-ETAPAS.
   05 WS-ETAPA OCCURS 7 TIMES.
      10 WS-ET-NOME      PIC X(12).
      10 WS-ET-PRODUTO   PIC X(50).
      10 WS-ET-ATIVIDADE PIC X(50).
      10 WS-ET-STATUS    PIC X(10).
```

### Parágrafos

| Parágrafo | Responsabilidade |
|-----------|-----------------|
| `000-MAIN` | Ponto de entrada. PERFORM loop 1→7, chama aborto se necessário, exibe resumo, GOBACK. |
| `100-INICIALIZAR` | Captura `FUNCTION CURRENT-DATE` e chama `110-CARREGAR-TABELA`. |
| `110-CARREGAR-TABELA` | Preenche os 7 registros de `WS-TABELA-ETAPAS` com nome, produto IBM e atividade de cada etapa. |
| `200-EXECUTAR-ETAPA` | Exibe nome/produto/atividade da etapa atual e chama `240-AVALIAR-STATUS`. |
| `240-AVALIAR-STATUS` | Compara `WS-IDX` com `WS-FALHA-SIMULADA`. Se iguais: `MOVE 'FALHA'`, `SET ESTEIRA-ABORTADA TO TRUE`, `MOVE WS-IDX TO WS-IDX-FALHA`. |
| `800-ABORTAR-ESTEIRA` | Exibe alerta com nome da etapa falha. `MOVE 8 TO RETURN-CODE`. |
| `900-RESUMO-FINAL` | Itera sobre as 7 etapas exibindo status (SUCESSO / FALHA / NAO EXEC.), total concluído e RC final. |

---

## Etapas Modeladas

| # | Nome | Produto IBM | Atividade |
|---|------|-------------|-----------|
| 1 | `PLAN` | IBM Z Understand / IBM EWM | Análise de impacto e planejamento da mudança |
| 2 | `CODE` | IBM Z Open Editor / IDz | Desenvolvimento e edição do código COBOL |
| 3 | `Z CODE SCAN` | IBM Z Code Scan (ZCodeScan) | Análise estática de qualidade e padrões |
| 4 | `BUILD` | IBM Dependency Based Build (DBB) | Compilação e link-edit com dependências |
| 5 | `TEST (TAZ)` | IBM Test Accelerator for Z (TAZ) | Execução de testes automatizados |
| 6 | `DEPLOY` | IBM Wazi Deploy | Implantação do pacote no ambiente alvo |
| 7 | `MONITOR` | IBM Z Anomaly Analytics / OMEGAMON | Monitoramento de desempenho e anomalias |

---

## Lógica de Fluxo

```
000-MAIN
  ├─ 100-INICIALIZAR
  │    └─ 110-CARREGAR-TABELA  (preenche OCCURS 7)
  │
  ├─ PERFORM VARYING WS-IDX FROM 1 BY 1
  │    UNTIL WS-IDX > 7 OR ESTEIRA-ABORTADA
  │    └─ 200-EXECUTAR-ETAPA
  │         └─ 240-AVALIAR-STATUS
  │              ├─ WS-IDX = WS-FALHA-SIMULADA → FALHA + ESTEIRA-ABORTADA='S'
  │              └─ caso contrário             → SUCESSO + ADD 1 TO WS-QTD-OK
  │
  ├─ IF ESTEIRA-ABORTADA → 800-ABORTAR-ESTEIRA (RC=8)
  │
  └─ 900-RESUMO-FINAL (exibe tabela + RC)
       └─ GOBACK
```

---

## Cenários de Teste TAZ

| Cenário | `WS-FALHA-SIMULADA` | RC Esperado | Saída SYSOUT Esperada |
|---------|--------------------:|:-----------:|----------------------|
| `happy_path` | `0` | `0` | `*** ESTEIRA FINALIZADA COM SUCESSO ***` |
| `falha_etapa_3` | `3` | `8` | `ESTEIRA INTERROMPIDA NA ETAPA: Z CODE SCAN` |
| `falha_etapa_4` | `4` | `8` | `ESTEIRA INTERROMPIDA NA ETAPA: BUILD` |
| `falha_etapa_1` | `1` | `8` | `ESTEIRA INTERROMPIDA NA ETAPA: PLAN` |
| `falha_etapa_7` | `7` | `8` | `ESTEIRA INTERROMPIDA NA ETAPA: MONITOR` |

---

## Integração com o Pipeline GitHub Actions

| Workflow | Job | Interação com DEVOPSPL |
|----------|-----|------------------------|
| `BatchPipeline.yml` | `static-scan` | Escaneia `DEVOPSPL.cbl` com ZCodeScan (maxRC=4) |
| `BatchPipeline.yml` | `build` | Compila DEVOPSPL via DBB (opção `LIB`); gera `HLQ.LOAD(DEVOPSPL)` |
| `BatchPipeline.yml` | `taz-test` | Executa DEVOPSPL com os cenários TAZ; valida RC e SYSOUT |
| `BatchPipeline.yml` | `deploy` | Implanta `HLQ.LOAD(DEVOPSPL)` via Wazi Deploy |
| `Pipeline.yml` | `taz-test` | Job adicionado ao pipeline principal; mesma lógica de teste |

---

## Critérios de Aceitação (Definition of Done)

- [ ] ZCodeScan executa sem violação de severidade `HIGH` ou `ERROR` (RC ≤ 4)
- [ ] Compilação concluída com RC ≤ 4 (compile) e RC = 0 (link-edit)
- [ ] TAZ `happy_path` retorna RC = 0 e saída `ESTEIRA FINALIZADA COM SUCESSO`
- [ ] TAZ `falha_etapa_3` retorna RC = 8 e menciona `Z CODE SCAN` na saída
- [ ] TAZ `falha_etapa_4` retorna RC = 8 e menciona `BUILD` na saída
- [ ] Wazi Deploy implanta módulo sem erros no ambiente alvo

---

## Histórico de Alterações

| Data | Autor | Descrição |
|------|-------|-----------|
| 2026-11-11 | Rafael Testa | Criação da especificação técnica inicial |
