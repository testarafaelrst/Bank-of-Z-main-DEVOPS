      ******************************************************************
      *                                                                *
      *  Copyright IBM Corp. 2025                                      *
      *                                                                *
      *  Program:     LSTCUST                                          *
      *  Type:        Batch — Relatorio Sequencial                     *
      *  Description: Lista todos os customers da tabela DB2 CUSTOMER  *
      *               gerando relatorio sequencial com cabecalho de    *
      *               pagina, colunas alinhadas e totalizador final.   *
      *                                                                *
      *  Input:       Tabela DB2 CUSTOMER (cursor sequencial)          *
      *  Output:      DD LSTOUT — RAFAELT.BANK.LSTCUST.REPORT          *
      *               LRECL=133 RECFM=FB                               *
      *                                                                *
      *  Return codes:                                                 *
      *    0  = Execucao bem-sucedida                                  *
      *    4  = Aviso — nenhum customer encontrado                     *
      *    8  = Erro de I/O no arquivo de saida                        *
      *   12  = Erro DB2 (SQLCODE negativo)                            *
      *                                                                *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID.    LSTCUST.
       AUTHOR.        IBM Bank-of-Z.
       DATE-WRITTEN.  2025-07-09.

      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER.  IBM-Z.
       OBJECT-COMPUTER.  IBM-Z.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT REPORT-FILE
               ASSIGN TO LSTOUT
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE  IS SEQUENTIAL
               FILE STATUS  IS WS-FILE-STATUS.

      ******************************************************************
       DATA DIVISION.
       FILE SECTION.

       FD  REPORT-FILE
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 133 CHARACTERS.
       01  REPORT-RECORD               PIC X(133).

      ******************************************************************
       WORKING-STORAGE SECTION.

      *-----------------------------------------------------------------
      * DB2 — SQLCA e DECLARE TABLE
      *-----------------------------------------------------------------
           EXEC SQL
               INCLUDE SQLCA
           END-EXEC.

           EXEC SQL
               INCLUDE CUSTDB2
           END-EXEC.

      *-----------------------------------------------------------------
      * DB2 — Host Variables (dentro da DECLARE SECTION)
      *-----------------------------------------------------------------
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.

       01  HOST-CUSTOMER-ROW.
           03  HV-CUSTOMER-EYECATCHER   PIC X(4).
           03  HV-CUSTOMER-SORTCODE     PIC X(6).
           03  HV-CUSTOMER-NUMBER       PIC X(10).
           03  HV-CUSTOMER-TITLE        PIC X(10).
           03  HV-CUSTOMER-FIRST-NAME   PIC X(50).
           03  HV-CUSTOMER-LAST-NAME    PIC X(50).
           03  HV-CUSTOMER-DOB          PIC S9(9) COMP-5.
           03  HV-CUSTOMER-PHONE        PIC X(20).
           03  HV-CUSTOMER-ADDR-LINE1   PIC X(50).
           03  HV-CUSTOMER-ADDR-LINE2   PIC X(50).
           03  HV-CUSTOMER-CITY         PIC X(50).
           03  HV-CUSTOMER-POSTCODE     PIC X(10).
           03  HV-CUSTOMER-COUNTRY      PIC X(50).
           03  HV-CUSTOMER-STATUS       PIC X(10).
           03  HV-CUSTOMER-CREATE-DATE  PIC S9(9) COMP-5.
           03  HV-CUSTOMER-CREDIT-SCORE PIC S9(4) COMP-5.
           03  HV-CUSTOMER-CS-REVIEW    PIC S9(9) COMP-5.

      * Null Indicators — PIC S9(4) COMP-5 para qualquer tipo nullable
       01  NULL-INDICATORS.
           05  NI-EYECATCHER            PIC S9(4) COMP-5.
           05  NI-TITLE                 PIC S9(4) COMP-5.
           05  NI-FIRST-NAME            PIC S9(4) COMP-5.
           05  NI-LAST-NAME             PIC S9(4) COMP-5.
           05  NI-DOB                   PIC S9(4) COMP-5.
           05  NI-PHONE                 PIC S9(4) COMP-5.
           05  NI-ADDR-LINE1            PIC S9(4) COMP-5.
           05  NI-ADDR-LINE2            PIC S9(4) COMP-5.
           05  NI-CITY                  PIC S9(4) COMP-5.
           05  NI-POSTCODE              PIC S9(4) COMP-5.
           05  NI-COUNTRY               PIC S9(4) COMP-5.
           05  NI-STATUS                PIC S9(4) COMP-5.
           05  NI-CREATE-DATE           PIC S9(4) COMP-5.
           05  NI-CREDIT-SCORE          PIC S9(4) COMP-5.
           05  NI-CS-REVIEW             PIC S9(4) COMP-5.

           EXEC SQL END DECLARE SECTION END-EXEC.

      *-----------------------------------------------------------------
      * Flags e chaves de controle
      *-----------------------------------------------------------------
       01  WS-SWITCHES.
           05  WS-EOF-SW                PIC X VALUE 'N'.
               88  WS-EOF              VALUE 'Y'.
           05  WS-DB2-ERROR-SW          PIC X VALUE 'N'.
               88  WS-DB2-ERROR        VALUE 'Y'.
           05  WS-FILE-STATUS           PIC XX VALUE SPACES.
               88  WS-FILE-OK          VALUE '00'.

      *-----------------------------------------------------------------
      * Contadores e controle de pagina
      *-----------------------------------------------------------------
       01  WS-COUNTERS.
           05  WS-LINE-COUNT            PIC 9(5) VALUE ZEROS.
           05  WS-PAGE-COUNT            PIC 9(5) VALUE ZEROS.
           05  WS-CUST-COUNT            PIC 9(9) VALUE ZEROS.
           05  WS-LINES-PER-PAGE        PIC 9(3) VALUE 60.

      *-----------------------------------------------------------------
      * Data e hora correntes
      *-----------------------------------------------------------------
       01  WS-DATE-WORK.
           05  WS-CURRENT-DATE          PIC 9(8).
           05  WS-CURR-DATE-GRP REDEFINES WS-CURRENT-DATE.
               10  WS-CURR-YYYY         PIC 9(4).
               10  WS-CURR-MM           PIC 9(2).
               10  WS-CURR-DD           PIC 9(2).
           05  WS-CURRENT-TIME          PIC 9(6).

       01  WS-DATE-FORMATTED            PIC X(10).
       01  WS-TIME-FORMATTED            PIC X(8).

      *-----------------------------------------------------------------
      * Conversao de datas INTEGER (YYYYMMDD) -> DD/MM/YYYY
      * Regra IBM: REDEFINES fora da DECLARE SECTION, sobre area display
      *-----------------------------------------------------------------
       01  WS-DATE-INT-WORK             PIC 9(8).
       01  WS-DATE-INT-GRP REDEFINES WS-DATE-INT-WORK.
           05  WS-DATE-YYYY             PIC 9(4).
           05  WS-DATE-MM               PIC 9(2).
           05  WS-DATE-DD               PIC 9(2).

       01  WS-DATE-OUT                  PIC X(10).

      *-----------------------------------------------------------------
      * Codigo de retorno do programa
      *-----------------------------------------------------------------
       01  WS-RETURN-CODE               PIC S9(4) COMP VALUE ZEROS.

      *-----------------------------------------------------------------
      * Linhas de relatorio — cabecalho 1 (titulo)
      *-----------------------------------------------------------------
       01  RPT-HEADER-1.
           05  FILLER       PIC X(1)  VALUE SPACES.
           05  FILLER       PIC X(40) VALUE
               'BANCO XYZ - LISTAGEM GERAL DE CUSTOMERS'.
           05  FILLER       PIC X(22) VALUE SPACES.
           05  FILLER       PIC X(6)  VALUE 'DATA: '.
           05  HDR1-DATE    PIC X(10).
           05  FILLER       PIC X(3)  VALUE SPACES.
           05  FILLER       PIC X(6)  VALUE 'HORA: '.
           05  HDR1-TIME    PIC X(8).
           05  FILLER       PIC X(3)  VALUE SPACES.
           05  FILLER       PIC X(6)  VALUE 'PAG.: '.
           05  HDR1-PAGE    PIC ZZZZZ.
           05  FILLER       PIC X(21) VALUE SPACES.

      *-----------------------------------------------------------------
      * Cabecalho 2 — linha em branco separadora
      *-----------------------------------------------------------------
       01  RPT-HEADER-2.
           05  FILLER       PIC X(133) VALUE SPACES.

      *-----------------------------------------------------------------
      * Cabecalho 3 — titulos de colunas
      *-----------------------------------------------------------------
       01  RPT-HEADER-3.
           05  FILLER       PIC X(1)  VALUE SPACES.
           05  FILLER       PIC X(4)  VALUE 'LIN '.
           05  FILLER       PIC X(3)  VALUE SPACES.
           05  FILLER       PIC X(8)  VALUE 'SORTCODE'.
           05  FILLER       PIC X(2)  VALUE SPACES.
           05  FILLER       PIC X(11) VALUE 'CUST-NUMBER'.
           05  FILLER       PIC X(3)  VALUE SPACES.
           05  FILLER       PIC X(6)  VALUE 'TITULO'.
           05  FILLER       PIC X(6)  VALUE SPACES.
           05  FILLER       PIC X(34) VALUE
               'NOME COMPLETO                     '.
           05  FILLER       PIC X(10) VALUE 'STATUS    '.
           05  FILLER       PIC X(4)  VALUE SPACES.
           05  FILLER       PIC X(20) VALUE 'TELEFONE            '.
           05  FILLER       PIC X(3)  VALUE SPACES.
           05  FILLER       PIC X(19) VALUE 'CIDADE             '.
           05  FILLER       PIC X(3)  VALUE SPACES.
           05  FILLER       PIC X(8)  VALUE 'CR-SCORE'.
           05  FILLER       PIC X(6)  VALUE SPACES.

      *-----------------------------------------------------------------
      * Cabecalho 4 — linha de separacao com tracejado
      *-----------------------------------------------------------------
       01  RPT-HEADER-4.
           05  FILLER       PIC X(1)  VALUE SPACES.
           05  FILLER       PIC X(4)  VALUE '----'.
           05  FILLER       PIC X(3)  VALUE SPACES.
           05  FILLER       PIC X(8)  VALUE '--------'.
           05  FILLER       PIC X(2)  VALUE SPACES.
           05  FILLER       PIC X(10) VALUE '----------'.
           05  FILLER       PIC X(3)  VALUE SPACES.
           05  FILLER       PIC X(10) VALUE '----------'.
           05  FILLER       PIC X(2)  VALUE SPACES.
           05  FILLER       PIC X(34) VALUE
               '----------------------------------'.
           05  FILLER       PIC X(10) VALUE '----------'.
           05  FILLER       PIC X(4)  VALUE SPACES.
           05  FILLER       PIC X(20) VALUE '--------------------'.
           05  FILLER       PIC X(3)  VALUE SPACES.
           05  FILLER       PIC X(19) VALUE '-------------------'.
           05  FILLER       PIC X(3)  VALUE SPACES.
           05  FILLER       PIC X(3)  VALUE '---'.
           05  FILLER       PIC X(11) VALUE SPACES.

      *-----------------------------------------------------------------
      * Linha de detalhe principal (linha 1 por registro)
      *-----------------------------------------------------------------
       01  RPT-DETAIL-1.
           05  FILLER       PIC X(1)  VALUE SPACES.
           05  DET1-LINE-NO PIC ZZZZZ.
           05  FILLER       PIC X(2)  VALUE SPACES.
           05  DET1-SORTCODE PIC X(6).
           05  FILLER       PIC X(3)  VALUE SPACES.
           05  DET1-CUST-NO  PIC X(10).
           05  FILLER       PIC X(3)  VALUE SPACES.
           05  DET1-TITLE    PIC X(10).
           05  FILLER       PIC X(2)  VALUE SPACES.
           05  DET1-FNAME    PIC X(50).
           05  FILLER       PIC X(1)  VALUE SPACES.
           05  DET1-LNAME    PIC X(10).
           05  FILLER       PIC X(3)  VALUE SPACES.
           05  DET1-STATUS   PIC X(10).
           05  FILLER       PIC X(4)  VALUE SPACES.
           05  DET1-PHONE    PIC X(20).
           05  FILLER       PIC X(3)  VALUE SPACES.
           05  DET1-CITY     PIC X(20).

      *-----------------------------------------------------------------
      * Campo adicional para score de credito (formatado separadamente)
      *-----------------------------------------------------------------
       01  WS-CREDIT-SCORE-DISP         PIC ZZZ.
       01  WS-CREDIT-SCORE-NA           PIC X(3) VALUE 'N/A'.

      *-----------------------------------------------------------------
      * Linha de continuacao (linha 2 por registro — datas e endereco)
      *-----------------------------------------------------------------
       01  RPT-DETAIL-2.
           05  FILLER       PIC X(6)  VALUE SPACES.
           05  FILLER       PIC X(4)  VALUE 'NAC:'.
           05  DET2-DOB      PIC X(10).
           05  FILLER       PIC X(2)  VALUE SPACES.
           05  FILLER       PIC X(8)  VALUE 'CRIADO: '.
           05  DET2-CREATED  PIC X(10).
           05  FILLER       PIC X(2)  VALUE SPACES.
           05  FILLER       PIC X(10) VALUE 'REV.CRED: '.
           05  DET2-CS-REV   PIC X(10).
           05  FILLER       PIC X(2)  VALUE SPACES.
           05  FILLER       PIC X(6)  VALUE 'PAIS: '.
           05  DET2-COUNTRY  PIC X(20).
           05  FILLER       PIC X(2)  VALUE SPACES.
           05  FILLER       PIC X(5)  VALUE 'CEP: '.
           05  DET2-POSTCODE PIC X(10).
           05  FILLER       PIC X(26) VALUE SPACES.

      *-----------------------------------------------------------------
      * Linha de totalizador final
      *-----------------------------------------------------------------
       01  RPT-TOTAL-LINE.
           05  FILLER       PIC X(6)  VALUE SPACES.
           05  FILLER       PIC X(32) VALUE
               '================================'.
           05  FILLER       PIC X(32) VALUE
               '================================'.
           05  FILLER       PIC X(63) VALUE SPACES.

       01  RPT-TOTAL-VALUE.
           05  FILLER       PIC X(6)  VALUE SPACES.
           05  FILLER       PIC X(30) VALUE
               'TOTAL DE CUSTOMERS LISTADOS: '.
           05  TOT-CUST-CNT  PIC ZZZZZZZZZ.
           05  FILLER       PIC X(88) VALUE SPACES.

      *-----------------------------------------------------------------
      * Linha de separacao generica
      *-----------------------------------------------------------------
       01  RPT-BLANK-LINE.
           05  FILLER       PIC X(133) VALUE SPACES.

      ******************************************************************
       PROCEDURE DIVISION.

      *-----------------------------------------------------------------
      * DECLARE CURSOR — instrucao nao-executavel; processada pelo
      * pre-compilador. Posicionada antes do primeiro uso do cursor.
      *-----------------------------------------------------------------
           EXEC SQL
               DECLARE CUST-CURSOR CURSOR FOR
                   SELECT CUSTOMER_EYECATCHER,
                          CUSTOMER_SORTCODE,
                          CUSTOMER_NUMBER,
                          CUSTOMER_TITLE,
                          CUSTOMER_FIRST_NAME,
                          CUSTOMER_LAST_NAME,
                          CUSTOMER_DATE_OF_BIRTH,
                          CUSTOMER_PHONE,
                          CUSTOMER_ADDR_LINE1,
                          CUSTOMER_ADDR_LINE2,
                          CUSTOMER_CITY,
                          CUSTOMER_POSTCODE,
                          CUSTOMER_COUNTRY,
                          CUSTOMER_STATUS,
                          CUSTOMER_CREATED_DATE,
                          CUSTOMER_CREDIT_SCORE,
                          CUSTOMER_CS_REVIEW_DATE
                   FROM   CUSTOMER
                   ORDER  BY CUSTOMER_SORTCODE ASC,
                             CUSTOMER_NUMBER   ASC
           END-EXEC.

      *-----------------------------------------------------------------
      * MAIN-PROCESS
      *   Ponto de entrada: coordena o fluxo geral do programa.
      *-----------------------------------------------------------------
       MAIN-PROCESS.
           PERFORM OPEN-FILES.
           IF WS-DB2-ERROR
               MOVE 12 TO WS-RETURN-CODE
               PERFORM CLOSE-FILES
               MOVE WS-RETURN-CODE TO RETURN-CODE
               STOP RUN
           END-IF.

           PERFORM PRINT-HEADER.

      *   Primeiro FETCH fora do loop (padrao IBM):
      *   O PERFORM UNTIL testa a condicao ANTES de executar o corpo.
      *   Se o FETCH nao fosse antecipado, a primeira linha seria ignorada.
           EXEC SQL
               FETCH CUST-CURSOR
               INTO :HV-CUSTOMER-EYECATCHER  :NI-EYECATCHER,
                    :HV-CUSTOMER-SORTCODE,
                    :HV-CUSTOMER-NUMBER,
                    :HV-CUSTOMER-TITLE        :NI-TITLE,
                    :HV-CUSTOMER-FIRST-NAME   :NI-FIRST-NAME,
                    :HV-CUSTOMER-LAST-NAME    :NI-LAST-NAME,
                    :HV-CUSTOMER-DOB          :NI-DOB,
                    :HV-CUSTOMER-PHONE        :NI-PHONE,
                    :HV-CUSTOMER-ADDR-LINE1   :NI-ADDR-LINE1,
                    :HV-CUSTOMER-ADDR-LINE2   :NI-ADDR-LINE2,
                    :HV-CUSTOMER-CITY         :NI-CITY,
                    :HV-CUSTOMER-POSTCODE     :NI-POSTCODE,
                    :HV-CUSTOMER-COUNTRY      :NI-COUNTRY,
                    :HV-CUSTOMER-STATUS       :NI-STATUS,
                    :HV-CUSTOMER-CREATE-DATE  :NI-CREATE-DATE,
                    :HV-CUSTOMER-CREDIT-SCORE :NI-CREDIT-SCORE,
                    :HV-CUSTOMER-CS-REVIEW    :NI-CS-REVIEW
           END-EXEC.

           PERFORM FETCH-LOOP
               UNTIL SQLCODE NOT EQUAL ZERO.

      *   Apos sair do loop: distinguir fim normal de erro DB2
           IF SQLCODE = +100
               IF WS-CUST-COUNT = ZERO
                   MOVE 4 TO WS-RETURN-CODE
               END-IF
               PERFORM PRINT-TOTALS
               PERFORM CLOSE-FILES
           ELSE
               PERFORM DB2-ERROR-HANDLING
               MOVE 12 TO WS-RETURN-CODE
               PERFORM CLOSE-FILES
           END-IF.

           MOVE WS-RETURN-CODE TO RETURN-CODE.
           STOP RUN.

      *-----------------------------------------------------------------
      * OPEN-FILES
      *   Abre REPORT-FILE e cursor DB2.
      *-----------------------------------------------------------------
       OPEN-FILES.
      *   Obter data e hora correntes
           MOVE FUNCTION CURRENT-DATE(1:8)  TO WS-CURRENT-DATE.
           MOVE FUNCTION CURRENT-DATE(9:6)  TO WS-CURRENT-TIME.

      *   Formatar data corrente: YYYYMMDD -> DD/MM/YYYY
           STRING WS-CURR-DD    DELIMITED SIZE
                  '/'            DELIMITED SIZE
                  WS-CURR-MM    DELIMITED SIZE
                  '/'            DELIMITED SIZE
                  WS-CURR-YYYY  DELIMITED SIZE
               INTO WS-DATE-FORMATTED.

      *   Formatar hora corrente: HHMMSS -> HH:MM:SS
           MOVE WS-CURRENT-TIME(1:6) TO WS-TIME-FORMATTED(1:6).
           MOVE WS-CURRENT-TIME(1:2) TO WS-TIME-FORMATTED(1:2).
           MOVE ':'                   TO WS-TIME-FORMATTED(3:1).
           MOVE WS-CURRENT-TIME(3:2) TO WS-TIME-FORMATTED(4:2).
           MOVE ':'                   TO WS-TIME-FORMATTED(6:1).
           MOVE WS-CURRENT-TIME(5:2) TO WS-TIME-FORMATTED(7:2).

      *   Abrir arquivo de saida
           OPEN OUTPUT REPORT-FILE.
           IF NOT WS-FILE-OK
               DISPLAY 'LSTCUST - ERRO AO ABRIR REPORT-FILE'
               DISPLAY 'FILE-STATUS: ' WS-FILE-STATUS
               MOVE 8 TO WS-RETURN-CODE
               SET WS-DB2-ERROR TO TRUE
               EXIT PARAGRAPH
           END-IF.

      *   Abrir cursor DB2
           EXEC SQL OPEN CUST-CURSOR END-EXEC.
           IF SQLCODE NOT EQUAL ZERO
               PERFORM DB2-ERROR-HANDLING
               SET WS-DB2-ERROR TO TRUE
           END-IF.

      *-----------------------------------------------------------------
      * PRINT-HEADER
      *   Imprime cabecalho de pagina e incrementa numero de pagina.
      *-----------------------------------------------------------------
       PRINT-HEADER.
           ADD 1 TO WS-PAGE-COUNT.
           MOVE WS-PAGE-COUNT   TO HDR1-PAGE.
           MOVE WS-DATE-FORMATTED TO HDR1-DATE.
           MOVE WS-TIME-FORMATTED TO HDR1-TIME.

           WRITE REPORT-RECORD FROM RPT-HEADER-1.
           IF NOT WS-FILE-OK
               PERFORM IO-ERROR-HANDLING
           END-IF.
           WRITE REPORT-RECORD FROM RPT-HEADER-2.
           WRITE REPORT-RECORD FROM RPT-HEADER-3.
           WRITE REPORT-RECORD FROM RPT-HEADER-4.

           MOVE ZERO TO WS-LINE-COUNT.

      *-----------------------------------------------------------------
      * FETCH-LOOP
      *   Processa a linha atual, depois executa o proximo FETCH.
      *   O loop termina quando SQLCODE <> 0 (fim ou erro).
      *-----------------------------------------------------------------
       FETCH-LOOP.
           PERFORM FORMAT-DETAIL-LINE.
           PERFORM FORMAT-CONT-LINE.
           PERFORM PRINT-DETAIL.

           ADD 1 TO WS-CUST-COUNT.
           ADD 1 TO WS-LINE-COUNT.

           IF WS-LINE-COUNT >= WS-LINES-PER-PAGE
               PERFORM PRINT-HEADER
           END-IF.

      *   FETCH proximo registro
           EXEC SQL
               FETCH CUST-CURSOR
               INTO :HV-CUSTOMER-EYECATCHER  :NI-EYECATCHER,
                    :HV-CUSTOMER-SORTCODE,
                    :HV-CUSTOMER-NUMBER,
                    :HV-CUSTOMER-TITLE        :NI-TITLE,
                    :HV-CUSTOMER-FIRST-NAME   :NI-FIRST-NAME,
                    :HV-CUSTOMER-LAST-NAME    :NI-LAST-NAME,
                    :HV-CUSTOMER-DOB          :NI-DOB,
                    :HV-CUSTOMER-PHONE        :NI-PHONE,
                    :HV-CUSTOMER-ADDR-LINE1   :NI-ADDR-LINE1,
                    :HV-CUSTOMER-ADDR-LINE2   :NI-ADDR-LINE2,
                    :HV-CUSTOMER-CITY         :NI-CITY,
                    :HV-CUSTOMER-POSTCODE     :NI-POSTCODE,
                    :HV-CUSTOMER-COUNTRY      :NI-COUNTRY,
                    :HV-CUSTOMER-STATUS       :NI-STATUS,
                    :HV-CUSTOMER-CREATE-DATE  :NI-CREATE-DATE,
                    :HV-CUSTOMER-CREDIT-SCORE :NI-CREDIT-SCORE,
                    :HV-CUSTOMER-CS-REVIEW    :NI-CS-REVIEW
           END-EXEC.

      *-----------------------------------------------------------------
      * FORMAT-DETAIL-LINE
      *   Formata a linha principal de detalhe do registro.
      *-----------------------------------------------------------------
       FORMAT-DETAIL-LINE.
           INITIALIZE RPT-DETAIL-1.

           MOVE WS-CUST-COUNT          TO DET1-LINE-NO.
           MOVE HV-CUSTOMER-SORTCODE   TO DET1-SORTCODE.
           MOVE HV-CUSTOMER-NUMBER     TO DET1-CUST-NO.

           IF NI-TITLE < ZERO
               MOVE SPACES             TO DET1-TITLE
           ELSE
               MOVE HV-CUSTOMER-TITLE  TO DET1-TITLE
           END-IF.

           IF NI-FIRST-NAME < ZERO
               MOVE SPACES             TO DET1-FNAME
           ELSE
               MOVE HV-CUSTOMER-FIRST-NAME TO DET1-FNAME
           END-IF.

           IF NI-LAST-NAME < ZERO
               MOVE SPACES             TO DET1-LNAME
           ELSE
               MOVE HV-CUSTOMER-LAST-NAME(1:10) TO DET1-LNAME
           END-IF.

           IF NI-STATUS < ZERO
               MOVE SPACES             TO DET1-STATUS
           ELSE
               MOVE HV-CUSTOMER-STATUS TO DET1-STATUS
           END-IF.

           IF NI-PHONE < ZERO
               MOVE SPACES             TO DET1-PHONE
           ELSE
               MOVE HV-CUSTOMER-PHONE  TO DET1-PHONE
           END-IF.

           IF NI-CITY < ZERO
               MOVE SPACES             TO DET1-CITY
           ELSE
               MOVE HV-CUSTOMER-CITY(1:20) TO DET1-CITY
           END-IF.

      *   Score de credito: ZZZ ou N/A se null
           IF NI-CREDIT-SCORE < ZERO
               MOVE WS-CREDIT-SCORE-NA TO RPT-DETAIL-1(130:3)
           ELSE
               MOVE HV-CUSTOMER-CREDIT-SCORE TO WS-CREDIT-SCORE-DISP
               MOVE WS-CREDIT-SCORE-DISP     TO RPT-DETAIL-1(130:3)
           END-IF.

      *-----------------------------------------------------------------
      * FORMAT-CONT-LINE
      *   Formata a linha de continuacao (datas e endereco completo).
      *-----------------------------------------------------------------
       FORMAT-CONT-LINE.
           INITIALIZE RPT-DETAIL-2.

      *   Data de nascimento
           IF NI-DOB < ZERO
               MOVE 'N/A       ' TO DET2-DOB
           ELSE
               MOVE HV-CUSTOMER-DOB TO WS-DATE-INT-WORK
               STRING WS-DATE-DD   DELIMITED SIZE
                      '/'           DELIMITED SIZE
                      WS-DATE-MM   DELIMITED SIZE
                      '/'           DELIMITED SIZE
                      WS-DATE-YYYY DELIMITED SIZE
                  INTO WS-DATE-OUT
               MOVE WS-DATE-OUT TO DET2-DOB
           END-IF.

      *   Data de criacao
           IF NI-CREATE-DATE < ZERO
               MOVE 'N/A       ' TO DET2-CREATED
           ELSE
               MOVE HV-CUSTOMER-CREATE-DATE TO WS-DATE-INT-WORK
               STRING WS-DATE-DD   DELIMITED SIZE
                      '/'           DELIMITED SIZE
                      WS-DATE-MM   DELIMITED SIZE
                      '/'           DELIMITED SIZE
                      WS-DATE-YYYY DELIMITED SIZE
                  INTO WS-DATE-OUT
               MOVE WS-DATE-OUT TO DET2-CREATED
           END-IF.

      *   Data de revisao de credito
           IF NI-CS-REVIEW < ZERO
               MOVE 'N/A       ' TO DET2-CS-REV
           ELSE
               MOVE HV-CUSTOMER-CS-REVIEW TO WS-DATE-INT-WORK
               STRING WS-DATE-DD   DELIMITED SIZE
                      '/'           DELIMITED SIZE
                      WS-DATE-MM   DELIMITED SIZE
                      '/'           DELIMITED SIZE
                      WS-DATE-YYYY DELIMITED SIZE
                  INTO WS-DATE-OUT
               MOVE WS-DATE-OUT TO DET2-CS-REV
           END-IF.

      *   Pais
           IF NI-COUNTRY < ZERO
               MOVE SPACES                    TO DET2-COUNTRY
           ELSE
               MOVE HV-CUSTOMER-COUNTRY(1:20) TO DET2-COUNTRY
           END-IF.

      *   CEP
           IF NI-POSTCODE < ZERO
               MOVE SPACES                    TO DET2-POSTCODE
           ELSE
               MOVE HV-CUSTOMER-POSTCODE      TO DET2-POSTCODE
           END-IF.

      *-----------------------------------------------------------------
      * PRINT-DETAIL
      *   Escreve as duas linhas do registro no arquivo de saida.
      *-----------------------------------------------------------------
       PRINT-DETAIL.
           WRITE REPORT-RECORD FROM RPT-DETAIL-1.
           IF NOT WS-FILE-OK
               PERFORM IO-ERROR-HANDLING
           END-IF.
           WRITE REPORT-RECORD FROM RPT-DETAIL-2.
           IF NOT WS-FILE-OK
               PERFORM IO-ERROR-HANDLING
           END-IF.

      *-----------------------------------------------------------------
      * PRINT-TOTALS
      *   Imprime linha totalizadora no final do relatorio.
      *-----------------------------------------------------------------
       PRINT-TOTALS.
           WRITE REPORT-RECORD FROM RPT-BLANK-LINE.
           WRITE REPORT-RECORD FROM RPT-TOTAL-LINE.
           MOVE WS-CUST-COUNT TO TOT-CUST-CNT.
           WRITE REPORT-RECORD FROM RPT-TOTAL-VALUE.
           WRITE REPORT-RECORD FROM RPT-TOTAL-LINE.
           WRITE REPORT-RECORD FROM RPT-BLANK-LINE.

      *-----------------------------------------------------------------
      * CLOSE-FILES
      *   Fecha REPORT-FILE e cursor DB2.
      *-----------------------------------------------------------------
       CLOSE-FILES.
           EXEC SQL CLOSE CUST-CURSOR END-EXEC.
           CLOSE REPORT-FILE.

      *-----------------------------------------------------------------
      * DB2-ERROR-HANDLING
      *   Registra SQLCODE e mensagem de erro em SYSOUT.
      *   O chamador define o RETURN-CODE apos retornar desta secao.
      *-----------------------------------------------------------------
       DB2-ERROR-HANDLING.
           DISPLAY '*** LSTCUST - ERRO DB2 ***'.
           DISPLAY 'SQLCODE  : ' SQLCODE.
           DISPLAY 'SQLERRM  : ' SQLERRM.
           DISPLAY 'SQLERRP  : ' SQLERRP.
           DISPLAY 'SQLERRD 1: ' SQLERRD(1).
           DISPLAY 'SQLERRD 2: ' SQLERRD(2).
           DISPLAY 'SQLERRD 3: ' SQLERRD(3).
           DISPLAY 'SQLERRD 4: ' SQLERRD(4).
           DISPLAY 'SQLERRD 5: ' SQLERRD(5).
           DISPLAY 'SQLERRD 6: ' SQLERRD(6).
           SET WS-DB2-ERROR TO TRUE.

      *-----------------------------------------------------------------
      * IO-ERROR-HANDLING
      *   Registra erro de I/O no arquivo de saida.
      *-----------------------------------------------------------------
       IO-ERROR-HANDLING.
           DISPLAY '*** LSTCUST - ERRO DE I/O ***'.
           DISPLAY 'FILE-STATUS: ' WS-FILE-STATUS.
           MOVE 8 TO WS-RETURN-CODE.
           MOVE WS-RETURN-CODE TO RETURN-CODE.
           STOP RUN.

