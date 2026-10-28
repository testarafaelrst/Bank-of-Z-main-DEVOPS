      ****************************************************************
      * LICENSED MATERIALS - PROPERTY OF IBM
      * "RESTRICTED MATERIALS OF IBM"
      * (C) COPYRIGHT IBM CORPORATION 2026. ALL RIGHTS RESERVED
      * US GOVERNMENT USERS RESTRICTED RIGHTS - USE, DUPLICATION,
      * OR DISCLOSURE RESTRICTED BY GSA ADP SCHEDULE
      * CONTRACT WITH IBM CORPORATION
      ****************************************************************
      * PROGRAM:  DEVOPSPL
      * Esteira DevOps IBM Z simulada via DISPLAY:
      * PLAN > CODE > Z CODE SCAN > BUILD > TEST (TAZ) > DEPLOY >
      * MONITOR. Programa apenas ilustrativo: nenhum produto IBM e
      * invocado e os resultados das etapas sao simulados.
      * Para simular falha, informe o numero da etapa em
      * WS-FALHA-SIMULADA (0 = nenhuma falha, 3 = Z CODE SCAN).
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DEVOPSPL.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-CONTROLE.
        05 WS-IDX             PIC 9(02) VALUE 0.
        05 WS-NUM-ETAPA       PIC 9(01) VALUE 0.
        05 WS-QTD-ETAPAS      PIC 9(02) VALUE 7.
        05 WS-QTD-OK          PIC 9(02) VALUE 0.
        05 WS-IDX-FALHA       PIC 9(02) VALUE 0.
        05 WS-FALHA-SIMULADA  PIC 9(02) VALUE 0.
        05 WS-TAM             PIC 9(02) VALUE 0.
        05 WS-RC-EXIBIR       PIC 9(04) VALUE 0.
        05 WS-FLAG-ABORTA     PIC X(01) VALUE 'N'.
         88 ESTEIRA-ABORTADA VALUE 'S'.
         88 ESTEIRA-EM-CURSO VALUE 'N'.
        05 WS-STATUS-ETAPA    PIC X(10) VALUE SPACES.
        05 WS-DATA-HORA       PIC X(21) VALUE SPACES.
        05 WS-RES-NOME        PIC X(16) VALUE SPACES.

       01 WS-TABELA-ETAPAS.
        05 WS-ETAPA OCCURS 7 TIMES.
         10 WS-ET-NOME        PIC X(12).
         10 WS-ET-PRODUTO     PIC X(50).
         10 WS-ET-ATIVIDADE   PIC X(50).
         10 WS-ET-STATUS      PIC X(10).

       PROCEDURE DIVISION.

       000-MAIN.
           PERFORM 100-INICIALIZAR
           PERFORM VARYING WS-IDX FROM 1 BY 1
              UNTIL WS-IDX > WS-QTD-ETAPAS
              OR ESTEIRA-ABORTADA
            PERFORM 200-EXECUTAR-ETAPA
           END-PERFORM
           IF ESTEIRA-ABORTADA
            PERFORM 800-ABORTAR-ESTEIRA
           END-IF
           PERFORM 900-RESUMO-FINAL
           GOBACK.

       100-INICIALIZAR.
           MOVE FUNCTION CURRENT-DATE TO WS-DATA-HORA
           PERFORM 110-CARREGAR-TABELA
           DISPLAY '=================================================='
           DISPLAY
              '*** ESTEIRA*DEVOPS IBM Z - SIMULACAO VIA DISPLAY ***'
           DISPLAY '=================================================='
           DISPLAY 'DATA/HORA: '
                   WS-DATA-HORA(1:8)
                   ' '
                   WS-DATA-HORA(9:6).

       110-CARREGAR-TABELA.
           PERFORM VARYING WS-IDX FROM 1 BY 1
              UNTIL WS-IDX > WS-QTD-ETAPAS
            MOVE 'PENDENTE' TO WS-ET-STATUS(WS-IDX)
           END-PERFORM

           MOVE 'PLAN' TO WS-ET-NOME(1)
           MOVE 'IBM Z Understand / IBM EWM'
              TO WS-ET-PRODUTO(1)
           MOVE 'Analise de impacto e planejamento da mudanca'
              TO WS-ET-ATIVIDADE(1)

           MOVE 'CODE' TO WS-ET-NOME(2)
           MOVE 'IBM Z Open Editor / IBM Developer for z/OS (IDz)'
              TO WS-ET-PRODUTO(2)
           MOVE 'Desenvolvimento e edicao do codigo COBOL'
              TO WS-ET-ATIVIDADE(2)

           MOVE 'Z CODE SCAN' TO WS-ET-NOME(3)
           MOVE 'IBM Z Code Scan (ZCodeScan)'
              TO WS-ET-PRODUTO(3)
           MOVE 'Analise estatica de qualidade e padroes'
              TO WS-ET-ATIVIDADE(3)

           MOVE 'BUILD' TO WS-ET-NOME(4)
           MOVE 'IBM Dependency Based Build (DBB)'
              TO WS-ET-PRODUTO(4)
           MOVE 'Compilacao e link-edit com dependencias'
              TO WS-ET-ATIVIDADE(4)

           MOVE 'TEST (TAZ)' TO WS-ET-NOME(5)
           MOVE 'IBM Test Accelerator for Z (TAZ)'
              TO WS-ET-PRODUTO(5)
           MOVE 'Execucao de testes automatizados (TAZ)'
              TO WS-ET-ATIVIDADE(5)

           MOVE 'DEPLOY' TO WS-ET-NOME(6)
           MOVE 'IBM Wazi Deploy'
              TO WS-ET-PRODUTO(6)
           MOVE 'Implantacao do pacote no ambiente alvo'
              TO WS-ET-ATIVIDADE(6)

           MOVE 'MONITOR' TO WS-ET-NOME(7)
           MOVE 'IBM Z Anomaly Analytics / IBM OMEGAMON'
              TO WS-ET-PRODUTO(7)
           MOVE 'Monitoramento de desempenho e anomalias'
              TO WS-ET-ATIVIDADE(7).

       200-EXECUTAR-ETAPA.
           MOVE WS-IDX TO WS-NUM-ETAPA
           PERFORM 210-EXIBIR-INICIO
           PERFORM 220-EXIBIR-PRODUTO
           PERFORM 230-EXIBIR-ATIVIDADE
           PERFORM 240-AVALIAR-STATUS
           PERFORM 250-EXIBIR-CONCLUSAO.

       210-EXIBIR-INICIO.
           DISPLAY '--------------------------------------------------'
           DISPLAY '['
                   WS-NUM-ETAPA
                   '/7] INICIO   : '
                   FUNCTION TRIM(WS-ET-NOME(WS-IDX) TRAILING).

       220-EXIBIR-PRODUTO.
           DISPLAY '['
                   WS-NUM-ETAPA
                   '/7] PRODUTO  : '
                   FUNCTION TRIM(WS-ET-PRODUTO(WS-IDX) TRAILING).

       230-EXIBIR-ATIVIDADE.
           DISPLAY '['
                   WS-NUM-ETAPA
                   '/7] ATIVIDADE: '
                   FUNCTION TRIM(WS-ET-ATIVIDADE(WS-IDX) TRAILING).

       240-AVALIAR-STATUS.
           IF WS-IDX = WS-FALHA-SIMULADA
            MOVE 'FALHA' TO WS-STATUS-ETAPA
           ELSE
            MOVE 'SUCESSO' TO WS-STATUS-ETAPA
           END-IF
           MOVE WS-STATUS-ETAPA TO WS-ET-STATUS(WS-IDX)
           IF WS-STATUS-ETAPA = 'SUCESSO'
            ADD 1 TO WS-QTD-OK
           ELSE
            MOVE WS-IDX TO WS-IDX-FALHA
            SET ESTEIRA-ABORTADA TO TRUE
           END-IF.

       250-EXIBIR-CONCLUSAO.
           DISPLAY '['
                   WS-NUM-ETAPA
                   '/7] STATUS   : '
                   FUNCTION TRIM(WS-STATUS-ETAPA TRAILING)
           IF WS-STATUS-ETAPA = 'SUCESSO'
            DISPLAY '['
                    WS-NUM-ETAPA
                    '/7] CONCLUIDA: '
                    FUNCTION TRIM(WS-ET-NOME(WS-IDX) TRAILING)
           ELSE
            DISPLAY '['
                    WS-NUM-ETAPA
                    '/7] FALHA    : '
                    FUNCTION TRIM(WS-ET-NOME(WS-IDX) TRAILING)
           END-IF.

       800-ABORTAR-ESTEIRA.
           DISPLAY '[ALERTA] ESTEIRA INTERROMPIDA NA ETAPA: '
                   FUNCTION TRIM(WS-ET-NOME(WS-IDX-FALHA) TRAILING)
           MOVE 8 TO RETURN-CODE.

       900-RESUMO-FINAL.
           DISPLAY '=================================================='
           DISPLAY 'RESUMO DA ESTEIRA'
           PERFORM VARYING WS-IDX FROM 1 BY 1
              UNTIL WS-IDX > WS-QTD-ETAPAS
            IF WS-ET-STATUS(WS-IDX) = 'PENDENTE'
             MOVE 'NAO EXEC.' TO WS-ET-STATUS(WS-IDX)
            END-IF
            MOVE ALL '.' TO WS-RES-NOME
            MOVE WS-ET-NOME(WS-IDX) TO WS-RES-NOME
            DISPLAY ' '
                    WS-RES-NOME
                    ' '
                    FUNCTION TRIM(WS-ET-STATUS(WS-IDX) TRAILING)
           END-PERFORM
           DISPLAY 'ETAPAS CONCLUIDAS: '
                   WS-QTD-OK
                   ' DE '
                   WS-QTD-ETAPAS
           MOVE RETURN-CODE TO WS-RC-EXIBIR
           DISPLAY 'RETURN-CODE FINAL: ' WS-RC-EXIBIR
           IF ESTEIRA-ABORTADA
            DISPLAY '*** ESTEIRA FINALIZADA COM FALHA ***'
           ELSE
            DISPLAY '*** ESTEIRA FINALIZADA COM SUCESSO ***'
           END-IF
           DISPLAY '=================================================='.