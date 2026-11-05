       CBL CICS('SP,EDF')
       CBL SQL
      ******************************************************************        
      *                                                                *        
      *  Copyright IBM Corp. 2023                                      *        
      *                                                                *        
      ******************************************************************        
      ******************************************************************        
      * This program takes an incoming account number it then accesses
      * the account datastore and retrieves the associated account
      * record matching on the customer number & the account_type
      * and then deletes it.
      *
      * If no matching customer_number and account_type combination can
      * found it will return an error flag and the visual1sation layer
      * should process this accordingly.
      *
      * Should there be any issues, the program will abend.
      *
      * It is assumed that the incoming customer number will be valid.
      *****************************************************************

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DELACC.
       AUTHOR. Jon Collett.

 
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
      *SOURCE-COMPUTER.   IBM-370 WITH DEBUGGING MODE.
       SOURCE-COMPUTER.  IBM-370.
       OBJECT-COMPUTER.  IBM-370.

       INPUT-OUTPUT SECTION.

       DATA DIVISION.
       FILE SECTION.

       WORKING-STORAGE SECTION.

      *COPY SORTCODE.

      * Copybook Location: 
      * file:///Users/rafaeltesta.rt/Library/CloudStorage/OneDrive-IBM/B        
      * ank-of-Z-main/src/base/cics/copy/SORTCODE.cpy

      ******************************************************************        
      *                                                                *        
      *  Copyright IBM Corp. 2023                                      *        
      *                                                                *        
      *                                                                *        
      ******************************************************************        
       77 SORTCODE           PIC 9(6) VALUE 987654.



       01 SYSIDERR-RETRY               PIC 999.
       01 FILE-RETRY                   PIC 999.
       01 WS-EXIT-RETRY-LOOP           PIC X VALUE ' '.

       01 BNKSEC-COMMAREA.
      *    COPY BNKSEC.

      * Copybook Location: 
      * file:///Users/rafaeltesta.rt/Library/CloudStorage/OneDrive-IBM/B        
      * ank-of-Z-main/src/base/cics/copy/BNKSEC.cpy

      ******************************************************************        
      *                                                                *        
      *  BNKSEC - COMMAREA of the BNKSECCK security check subprogram.  *        
      *  Include at level 03 under an 01 group (35 bytes).             *        
      *                                                                *        
      ******************************************************************        
           03 BNKSEC-OPERATION          PIC X(8).
           03 BNKSEC-FOR-USERID         PIC X(8).
           03 BNKSEC-USERID             PIC X(8).
           03 BNKSEC-RESULT             PIC X.
              88 BNKSEC-ALLOWED         VALUE 'A'.
              88 BNKSEC-DENIED          VALUE 'D'.
              88 BNKSEC-ERROR           VALUE 'E'.
           03 BNKSEC-REASON             PIC X(2).
           03 BNKSEC-RESP               PIC S9(8) COMP.
           03 BNKSEC-RESP2              PIC S9(8) COMP.

       01 WS-SEC-SW                       PIC X VALUE 'N'.
           88 SEC-OK                      VALUE 'Y'.
           88 SEC-NOT-OK                  VALUE 'N'.

      * Get the ACCOUNT DB2 copybook
      *    EXEC SQL
      *       INCLUDE ACCDB2
      *    END-EXEC.

      * Copybook Location: 
      * file:///Users/rafaeltesta.rt/Library/CloudStorage/OneDrive-IBM/B        
      * ank-of-Z-main/src/base/cics/copy/ACCDB2.cpy

      ******************************************************************        
      *                                                                *        
      *  Copyright IBM Corp. 2023                                      *        
      *                                                                *        
      *                                                                *        
      ******************************************************************        
           EXEC SQL DECLARE ACCOUNT TABLE
              ( ACCOUNT_EYECATCHER             CHAR(4),
                ACCOUNT_CUSTOMER_NUMBER        CHAR(10),
                ACCOUNT_SORTCODE               CHAR(6) NOT NULL,
                ACCOUNT_NUMBER                 CHAR(8) NOT NULL,
                ACCOUNT_TYPE                   CHAR(8),
                ACCOUNT_INTEREST_RATE          DECIMAL(4, 2),
                ACCOUNT_OPENED                 DATE,
                ACCOUNT_OVERDRAFT_LIMIT        INTEGER,
                ACCOUNT_LAST_STATEMENT         DATE,
                ACCOUNT_NEXT_STATEMENT         DATE,
                ACCOUNT_AVAILABLE_BALANCE      DECIMAL(10, 2),
                ACCOUNT_ACTUAL_BALANCE         DECIMAL(10, 2) )
           END-EXEC.

      * ACCOUNT Host variables for DB2
       01 HOST-ACCOUNT-ROW.
           03 HV-ACCOUNT-EYECATCHER     PIC X(4).
           03 HV-ACCOUNT-CUST-NO        PIC X(10).
           03 HV-ACCOUNT-SORTCODE       PIC X(6).
           03 HV-ACCOUNT-ACC-NO         PIC X(8).
           03 HV-ACCOUNT-ACC-TYPE       PIC X(8).
           03 HV-ACCOUNT-INT-RATE       PIC S9(4)V99 COMP-3.
           03 HV-ACCOUNT-OPENED         PIC X(10).
           03 HV-ACCOUNT-OVERDRAFT-LIM  PIC S9(9) COMP.
           03 HV-ACCOUNT-LAST-STMT      PIC X(10).
           03 HV-ACCOUNT-NEXT-STMT      PIC X(10).
           03 HV-ACCOUNT-AVAIL-BAL      PIC S9(10)V99 COMP-3.
           03 HV-ACCOUNT-ACTUAL-BAL     PIC S9(10)V99 COMP-3.

      * PROCTRAN DB2 copybook
      *    EXEC SQL
      *       INCLUDE PROCDB2
      *    END-EXEC.

      * Copybook Location: 
      * file:///Users/rafaeltesta.rt/Library/CloudStorage/OneDrive-IBM/B        
      * ank-of-Z-main/src/base/cics/copy/PROCDB2.cpy

      ******************************************************************        
      *                                                                *        
      *  Copyright IBM Corp. 2023                                      *        
      *                                                                *        
      *                                                                *        
      ******************************************************************        
           EXEC SQL DECLARE PROCTRAN TABLE
              (
               PROCTRAN_EYECATCHER             CHAR(4),
               PROCTRAN_SORTCODE               CHAR(6) NOT NULL,
               PROCTRAN_NUMBER                 CHAR(8) NOT NULL,
               PROCTRAN_DATE                   DATE,
               PROCTRAN_TIME                   CHAR(6),
               PROCTRAN_REF                    CHAR(12),
               PROCTRAN_TYPE                   CHAR(3),
               PROCTRAN_DESC                   CHAR(40),
               PROCTRAN_AMOUNT                 DECIMAL(12, 2)
              )
           END-EXEC.

      * PROCTRAN host variables for DB2
       01 HOST-PROCTRAN-ROW.
           03 HV-PROCTRAN-EYECATCHER    PIC X(4).
           03 HV-PROCTRAN-SORT-CODE     PIC X(6).
           03 HV-PROCTRAN-ACC-NUMBER    PIC X(8).
           03 HV-PROCTRAN-DATE          PIC X(10).
           03 HV-PROCTRAN-TIME          PIC X(6).
           03 HV-PROCTRAN-REF           PIC X(12).
           03 HV-PROCTRAN-TYPE          PIC X(3).
           03 HV-PROCTRAN-DESC          PIC X(40).
           03 HV-PROCTRAN-AMOUNT        PIC S9(10)V99 COMP-3.

      * Pull in the SQL COMMAREA
           EXEC SQL
              INCLUDE SQLCA
           END-EXEC.

       01 SQLCODE-DISPLAY              PIC S9(8) DISPLAY
           SIGN LEADING SEPARATE.

       01 WS-CICS-WORK-AREA.
           05 WS-CICS-RESP              PIC S9(8) COMP.
           05 WS-CICS-RESP2             PIC S9(8) COMP.
           05 WS-EIBRESP-DISPLAY        PIC S9(8) DISPLAY
                                   SIGN LEADING SEPARATE.

       01 WS-APPLID                    PIC X(8).

       01 EXIT-BROWSE-LOOP             PIC X VALUE 'N'.

       01 OUTPUT-DATA.
      *    COPY ACCOUNT.

      * Copybook Location: 
      * file:///Users/rafaeltesta.rt/Library/CloudStorage/OneDrive-IBM/B        
      * ank-of-Z-main/src/base/cics/copy/ACCOUNT.cpy

      ******************************************************************        
      *                                                                *        
      *  Copyright IBM Corp. 2023                                      *        
      *                                                                *        
      *                                                                *        
      ******************************************************************        
              03 ACCOUNT-DATA.
                 05 ACCOUNT-EYE-CATCHER        PIC X(4).
                 88 ACCOUNT-EYECATCHER-VALUE        VALUE 'ACCT'.
                 05 ACCOUNT-CUST-NO            PIC 9(10).
                 05 ACCOUNT-KEY.
                    07 ACCOUNT-SORT-CODE       PIC 9(6).
                    07 ACCOUNT-NUMBER          PIC 9(8).
                 05 ACCOUNT-TYPE               PIC X(8).
                 05 ACCOUNT-INTEREST-RATE      PIC 9(4)V99.
                 05 ACCOUNT-OPENED             PIC 9(8).
                 05 ACCOUNT-OPENED-GROUP REDEFINES ACCOUNT-OPENED.
                    07 ACCOUNT-OPENED-DAY       PIC 99.
                    07 ACCOUNT-OPENED-MONTH     PIC 99.
                    07 ACCOUNT-OPENED-YEAR      PIC 9999.
                 05 ACCOUNT-OVERDRAFT-LIMIT    PIC 9(8).
                 05 ACCOUNT-LAST-STMT-DATE     PIC 9(8).
                 05 ACCOUNT-LAST-STMT-GROUP
                    REDEFINES ACCOUNT-LAST-STMT-DATE.
                    07 ACCOUNT-LAST-STMT-DAY   PIC 99.
                    07 ACCOUNT-LAST-STMT-MONTH PIC 99.
                    07 ACCOUNT-LAST-STMT-YEAR  PIC 9999.
                 05 ACCOUNT-NEXT-STMT-DATE     PIC 9(8).
                 05 ACCOUNT-NEXT-STMT-GROUP
                   REDEFINES ACCOUNT-NEXT-STMT-DATE.
                    07 ACCOUNT-NEXT-STMT-DAY   PIC 99.
                    07 ACCOUNT-NEXT-STMT-MONTH PIC 99.
                    07 ACCOUNT-NEXT-STMT-YEAR  PIC 9999.
                 05 ACCOUNT-AVAILABLE-BALANCE  PIC S9(10)V99.
                 05 ACCOUNT-ACTUAL-BALANCE     PIC S9(10)V99.

       01 PROCTRAN-AREA.
      *   COPY PROCTRAN.

      * Copybook Location: 
      * file:///Users/rafaeltesta.rt/Library/CloudStorage/OneDrive-IBM/B        
      * ank-of-Z-main/src/base/cics/copy/PROCTRAN.cpy

      ******************************************************************        
      *                                                                *        
      *  Copyright IBM Corp. 2023                                      *        
      *                                                                *        
      *                                                                *        
      ******************************************************************        
           03 PROC-TRAN-DATA.
              05 PROC-TRAN-EYE-CATCHER        PIC X(4).
              88 PROC-TRAN-VALID VALUE 'PRTR'.
              05 PROC-TRAN-LOGICAL-DELETE-AREA REDEFINES
                 PROC-TRAN-EYE-CATCHER.
                 07 PROC-TRAN-LOGICAL-DELETE-FLAG PIC X.
                 88 PROC-TRAN-LOGICALLY-DELETED VALUE X'FF'.
                 07 FILLER PIC X(3).
              05 PROC-TRAN-ID.
                 07 PROC-TRAN-SORT-CODE       PIC 9(6).
                 07 PROC-TRAN-NUMBER          PIC 9(8).
              05 PROC-TRAN-DATE               PIC 9(8).
              05 PROC-TRAN-DATE-GRP REDEFINES PROC-TRAN-DATE.
                 07 PROC-TRAN-DATE-GRP-YYYY   PIC 9999.
                 07 PROC-TRAN-DATE-GRP-MM     PIC 99.
                 07 PROC-TRAN-DATE-GRP-DD     PIC 99.
              05 PROC-TRAN-TIME               PIC 9(6).
              05 PROC-TRAN-TIME-GRP REDEFINES PROC-TRAN-TIME.
                 07 PROC-TRAN-TIME-GRP-HH     PIC 99.
                 07 PROC-TRAN-TIME-GRP-MM     PIC 99.
                 07 PROC-TRAN-TIME-GRP-SS     PIC 99.
              05 PROC-TRAN-REF                PIC 9(12).
              05 PROC-TRAN-TYPE               PIC X(3).
              88 PROC-TY-CHEQUE-ACKNOWLEDGED      VALUE 'CHA'.
              88 PROC-TY-CHEQUE-FAILURE           VALUE 'CHF'.
              88 PROC-TY-CHEQUE-PAID-IN           VALUE 'CHI'.
              88 PROC-TY-CHEQUE-PAID-OUT          VALUE 'CHO'.
              88 PROC-TY-CREDIT                   VALUE 'CRE'.
              88 PROC-TY-DEBIT                    VALUE 'DEB'.
              88 PROC-TY-WEB-CREATE-ACCOUNT       VALUE 'ICA'.
              88 PROC-TY-WEB-CREATE-CUSTOMER      VALUE 'ICC'.
              88 PROC-TY-WEB-DELETE-ACCOUNT       VALUE 'IDA'.
              88 PROC-TY-WEB-DELETE-CUSTOMER      VALUE 'IDC'.
              88 PROC-TY-BRANCH-CREATE-ACCOUNT    VALUE 'OCA'.
              88 PROC-TY-BRANCH-CREATE-CUSTOMER   VALUE 'OCC'.
              88 PROC-TY-BRANCH-DELETE-ACCOUNT    VALUE 'ODA'.
              88 PROC-TY-BRANCH-DELETE-CUSTOMER   VALUE 'ODC'.
              88 PROC-TY-CREATE-SODD              VALUE 'OCS'.
              88 PROC-TY-PAYMENT-CREDIT           VALUE 'PCR'.
              88 PROC-TY-PAYMENT-DEBIT            VALUE 'PDR'.
              88 PROC-TY-TRANSFER                 VALUE 'TFR'.
              05 PROC-TRAN-DESC               PIC X(40).
              05 PROC-TRAN-DESC-XFR REDEFINES PROC-TRAN-DESC.
                07 PROC-TRAN-DESC-XFR-HEADER PIC X(26).
                88 PROC-TRAN-DESC-XFR-FLAG
                   VALUE 'TRANSFER'.
                07 PROC-TRAN-DESC-XFR-SORTCODE
                   PIC 9(6).
                07 PROC-TRAN-DESC-XFR-ACCOUNT
                   PIC 9(8).
              05 PROC-TRAN-DESC-DELACC REDEFINES PROC-TRAN-DESC.
                07 PROC-DESC-DELACC-CUSTOMER PIC 9(10).
                07 PROC-DESC-DELACC-ACCTYPE PIC X(8).
                07 PROC-DESC-DELACC-LAST-DD PIC 99.
                07 PROC-DESC-DELACC-LAST-MM PIC 99.
                07 PROC-DESC-DELACC-LAST-YYYY PIC 9999.
                07 PROC-DESC-DELACC-NEXT-DD PIC 99.
                07 PROC-DESC-DELACC-NEXT-MM PIC 99.
                07 PROC-DESC-DELACC-NEXT-YYYY PIC 9999.
                07 PROC-DESC-DELACC-FOOTER PIC X(6).
                88 PROC-DESC-DELACC-FLAG
                   VALUE 'DELETE'.
              05 PROC-TRAN-DESC-CREACC REDEFINES PROC-TRAN-DESC.
                07 PROC-DESC-CREACC-CUSTOMER PIC 9(10).
                07 PROC-DESC-CREACC-ACCTYPE PIC X(8).
                07 PROC-DESC-CREACC-LAST-DD PIC 99.
                07 PROC-DESC-CREACC-LAST-MM PIC 99.
                07 PROC-DESC-CREACC-LAST-YYYY PIC 9999.
                07 PROC-DESC-CREACC-NEXT-DD PIC 99.
                07 PROC-DESC-CREACC-NEXT-MM PIC 99.
                07 PROC-DESC-CREACC-NEXT-YYYY PIC 9999.
                07 PROC-DESC-CREACC-FOOTER PIC X(6).
                88 PROC-DESC-CREACC-FLAG
                   VALUE 'CREATE'.
              05 PROC-TRAN-DESC-DELCUS REDEFINES PROC-TRAN-DESC.
                07 PROC-DESC-DELCUS-SORTCODE PIC 9(6).
                07 PROC-DESC-DELCUS-CUSTOMER PIC 9(10).
                07 PROC-DESC-DELCUS-NAME     PIC X(14).
                07 PROC-DESC-DELCUS-DOB-YYYY  PIC 9999.
                07 PROC-DESC-DELCUS-FILLER    PIC X.
                88 PROC-DESC-DELCUS-FILLER-SET VALUE '-'.
                07 PROC-DESC-DELCUS-DOB-MM    PIC 99.
                07 PROC-DESC-DELCUS-FILLER2   PIC X.
                88 PROC-DESC-DELCUS-FILLER2-SET VALUE '-'.
                07 PROC-DESC-DELCUS-DOB-DD    PIC 99.
              05 PROC-TRAN-DESC-CRECUS REDEFINES PROC-TRAN-DESC.
                07 PROC-DESC-CRECUS-SORTCODE PIC 9(6).
                07 PROC-DESC-CRECUS-CUSTOMER PIC 9(10).
                07 PROC-DESC-CRECUS-NAME     PIC X(14).
                07 PROC-DESC-CRECUS-DOB-YYYY  PIC 9999.
                07 PROC-DESC-CRECUS-FILLER    PIC X.
                88 PROC-DESC-CRECUS-FILLER-SET VALUE '-'.
                07 PROC-DESC-CRECUS-DOB-MM    PIC 99.
                07 PROC-DESC-CRECUS-FILLER2   PIC X.
                88 PROC-DESC-CRECUS-FILLER2-SET VALUE '-'.
                07 PROC-DESC-CRECUS-DOB-DD    PIC 99.
              05 PROC-TRAN-AMOUNT             PIC S9(10)V99.

       01 PROCTRAN-RIDFLD              PIC S9(8) COMP.
       77 PROCTRAN-RETRY               PIC 999.

       01 ACCOUNT-ACT-BAL-STORE        PIC S9(10)V99 VALUE 0.

       01 RETURNED-DATA.
           03 RETURNED-EYE-CATCHER        PIC X(4).
           03 RETURNED-CUST-NO            PIC 9(10).
           03 RETURNED-KEY.
              05 RETURNED-SORT-CODE       PIC 9(6).
              05 RETURNED-NUMBER          PIC 9(8).
           03 RETURNED-TYPE               PIC X(8).
           03 RETURNED-INTEREST-RATE      PIC 9(4)V99.
           03 RETURNED-OPENED             PIC 9(8).
           03 RETURNED-OVERDRAFT-LIMIT    PIC 9(8).
           03 RETURNED-LAST-STMT-DATE     PIC 9(8).
           03 RETURNED-NEXT-STMT-DATE     PIC 9(8).
           03 RETURNED-AVAILABLE-BALANCE  PIC S9(10)V99.
           03 RETURNED-ACTUAL-BALANCE     PIC S9(10)V99.

       01 DESIRED-KEY                  PIC 9(10) BINARY.


       01 DB2-DATE-REFORMAT.
          03 DB2-DATE-REF-YR           PIC 9(4).
          03 FILLER                    PIC X.
          03 DB2-DATE-REF-MNTH         PIC 99.
          03 FILLER                    PIC X.
          03 DB2-DATE-REF-DAY          PIC 99.

       01 DATA-STORE-TYPE              PIC X.
          88 DATASTORE-TYPE-DB2           VALUE '2'.
          88 DATASTORE-TYPE-VSAM          VALUE 'V'.

       01 DB2-EXIT-LOOP                PIC X.
       01 FETCH-DATA-CNT               PIC 9(4) COMP.
       01 WS-CUST-ALT-KEY-LEN          PIC S9(4) COMP VALUE +10.

       01 WS-EIBTASKN12                PIC 9(12) VALUE 0.

       01 ACCOUNT-KEY-RID.
          03 REQUIRED-SORT-CODE        PIC 9(6)  VALUE 0.
          03 REQUIRED-ACC-NUM          PIC 9(8)  VALUE 0.

       01 MY-TCB                       PIC S9(8) BINARY.

       01 MY-TCB-STRING                PIC X(8).

       01 WS-ACC-KEY-LEN               PIC S9(4) COMP VALUE +14.
       01 WS-ACC-NUM                   PIC S9(4) COMP VALUE 0.

       01 WS-U-TIME                    PIC S9(15) COMP-3.
       01 WS-ORIG-DATE                 PIC X(10).
       01 WS-ORIG-DATE-GRP REDEFINES WS-ORIG-DATE.
          03 WS-ORIG-DATE-DD              PIC 99.
          03 FILLER                       PIC X.
          03 WS-ORIG-DATE-MM              PIC 99.
          03 FILLER                       PIC X.
          03 WS-ORIG-DATE-YYYY            PIC 9999.

       01 WS-ORIG-DATE-GRP-X.
          03 WS-ORIG-DATE-DD-X         PIC XX.
          03 FILLER                    PIC X VALUE '.'.
          03 WS-ORIG-DATE-MM-X         PIC XX.
          03 FILLER                    PIC X VALUE '.'.
          03 WS-ORIG-DATE-YYYY-X       PIC X(4).


       01 WS-TOKEN                     PIC S9(8) BINARY.


       01 STORM-DRAIN-CONDITION        PIC X(20).

       01 ACCOUNT-CONTROL.
      *    COPY ACCTCTRL.

      * Copybook Location: 
      * file:///Users/rafaeltesta.rt/Library/CloudStorage/OneDrive-IBM/B        
      * ank-of-Z-main/src/base/cics/copy/ACCTCTRL.cpy

      ******************************************************************        
      *                                                                *        
      *  Copyright IBM Corp. 2023                                      *        
      *                                                                *        
      *                                                                *        
      ******************************************************************        
              03 ACCOUNT-CONTROL-RECORD.
                 05 ACCOUNT-CONTROL-EYE-CATCHER        PIC X(4).
                 88 ACCOUNT-CONTROL-EYECATCHER-V   VALUE 'CTRL'.
                 05 FILLER                     PIC 9(10).
                 05 ACCOUNT-CONTROL-KEY.
                    07 ACCOUNT-CONTROL-SORT-CODE       PIC 9(6).
                    07 ACCOUNT-CONTROL-NUMBER          PIC 9(8).
                 05 NUMBER-OF-ACCOUNTS                 PIC 9(8).
                 05 LAST-ACCOUNT-NUMBER                PIC 9(8).
                 05 ACCOUNT-CONTROL-SUCCESS-FLAG       PIC X.
                 88 ACCOUNT-CONTROL-SUCCESS VALUE 'Y'.
                 05 ACCOUNT-CONTROL-FAIL-CODE PIC X.
                 05 FILLER                     PIC 9(4)V99.
                 05 FILLER                     PIC 9(8).
                 05 FILLER                     PIC 9(8).
                 05 FILLER                     PIC 9(8).
                 05 FILLER                     PIC 9(8).
                 05 FILLER                     PIC S9(10)V99.
                 05 FILLER                     PIC X(2).

       01 WS-TIME-DATA.
           03 WS-TIME-NOW              PIC 9(6).
           03 WS-TIME-NOW-GRP REDEFINES WS-TIME-NOW.
              05 WS-TIME-NOW-GRP-HH       PIC 99.
              05 WS-TIME-NOW-GRP-MM       PIC 99.
              05 WS-TIME-NOW-GRP-SS       PIC 99.

       01 WS-ABEND-PGM                    PIC X(8) VALUE 'ABNDPROC'.

       01 ABNDINFO-REC.
      *    COPY ABNDINFO.

      * Copybook Location: 
      * file:///Users/rafaeltesta.rt/Library/CloudStorage/OneDrive-IBM/B        
      * ank-of-Z-main/src/base/cics/copy/ABNDINFO.cpy

      ******************************************************************        
      *                                                                *        
      *  Copyright IBM Corp. 2023                                      *        
      *                                                                *        
      *                                                                *        
      ******************************************************************        
           03 ABND-VSAM-KEY.
              05 ABND-UTIME-KEY                  PIC S9(15) COMP-3.
              05 ABND-TASKNO-KEY                 PIC 9(4).
           03 ABND-APPLID                        PIC X(8).
           03 ABND-TRANID                        PIC X(4).
           03 ABND-DATE                          PIC X(10).
           03 ABND-TIME                          PIC X(8).
           03 ABND-CODE                          PIC X(4).
           03 ABND-PROGRAM                       PIC X(8).
           03 ABND-RESPCODE                      PIC S9(8) DISPLAY
                  SIGN LEADING SEPARATE.
           03 ABND-RESP2CODE                     PIC S9(8) DISPLAY
                  SIGN LEADING SEPARATE.
           03 ABND-SQLCODE                       PIC S9(8) DISPLAY
                  SIGN LEADING SEPARATE.
           03 ABND-FREEFORM                      PIC X(600).


       LINKAGE SECTION.
      *COPY DELACC REPLACING DELACC-COMMAREA BY DFHCOMMAREA.

      * Copybook Location: 
      * file:///Users/rafaeltesta.rt/Library/CloudStorage/OneDrive-IBM/B        
      * ank-of-Z-main/src/base/cics/copy/DELACC.cpy

      ******************************************************************        
      *                                                                *        
      *  Copyright IBM Corp. 2023                                      *        
      *                                                                *        
      *                                                                *        
      ******************************************************************        
        01 DFHCOMMAREA.
          03 DELACC-EYE                  PIC X(4).
          03 DELACC-CUSTNO               PIC X(10).
          03 DELACC-SCODE                PIC X(6).
          03 DELACC-ACCNO                PIC 9(8).
          03 DELACC-ACC-TYPE             PIC X(8).
          03 DELACC-INT-RATE             PIC 9(4)V99.
          03 DELACC-OPENED               PIC 9(8).
          03 DELACC-OPENED-GROUP REDEFINES DELACC-OPENED.
            05 DELACC-OPENED-DAY   PIC 99.
            05 DELACC-OPENED-MONTH PIC 99.
            05 DELACC-OPENED-YEAR  PIC 9999.
          03 DELACC-OVERDRAFT            PIC 9(8).
          03 DELACC-LAST-STMT-DT         PIC 9(8).
          03 DELACC-LAST-STMT-GROUP REDEFINES DELACC-LAST-STMT-DT.
            05 DELACC-LAST-STMT-DAY   PIC 99.
            05 DELACC-LAST-STMT-MONTH PIC 99.
            05 DELACC-LAST-STMT-YEAR  PIC 9999.
          03 DELACC-NEXT-STMT-DT         PIC 9(8).
          03 DELACC-NEXT-STMT-GROUP REDEFINES DELACC-NEXT-STMT-DT.
            05 DELACC-NEXT-STMT-DAY   PIC 99.
            05 DELACC-NEXT-STMT-MONTH PIC 99.
            05 DELACC-NEXT-STMT-YEAR  PIC 9999.
          03 DELACC-AVAIL-BAL            PIC S9(10)V99.
          03 DELACC-ACTUAL-BAL           PIC S9(10)V99.
          03 DELACC-SUCCESS              PIC X.
          03 DELACC-FAIL-CD              PIC X.
          03 DELACC-DEL-SUCCESS          PIC X.
          03 DELACC-DEL-FAIL-CD          PIC X.
          03 DELACC-DEL-APPLID           PIC X(8).
          03 DELACC-DEL-PCB1             POINTER.
          03 DELACC-DEL-PCB2             POINTER.
          03 DELACC-DEL-PCB3             POINTER.


       PROCEDURE DIVISION USING DFHCOMMAREA.
       PREMIERE SECTION.
       A010.

      *
      *          RACF security check before any data is touched
      *
           PERFORM SECURITY-CHECK.

           IF SEC-OK

             MOVE SORTCODE TO REQUIRED-SORT-CODE OF ACCOUNT-KEY-RID

      *
      *          Get the account record
      *
             PERFORM READ-ACCOUNT-DB2

      *
      *          If a matching account record was successfully
      *          retrieved then delete it
      *
             IF DELACC-DEL-SUCCESS = 'Y'

               PERFORM DEL-ACCOUNT-DB2
               IF DELACC-DEL-SUCCESS = 'Y'
                 PERFORM WRITE-PROCTRAN
               END-IF
             END-IF

           END-IF


           PERFORM GET-ME-OUT-OF-HERE.

       A999.
           EXIT.


      *
      * Ask BNKSECCK if the user may delete accounts. Fail-closed:
      * only an allowed result with a NORMAL response gives SEC-OK.
      * S = not authorised, X = security check unavailable.
      *
       SECURITY-CHECK SECTION.
       SC010.

           SET SEC-NOT-OK TO TRUE.
           INITIALIZE BNKSEC-COMMAREA.
           MOVE 'DELACC  ' TO BNKSEC-OPERATION.

           EXEC CICS LINK PROGRAM('BNKSECCK')
                COMMAREA(BNKSEC-COMMAREA)
                LENGTH(LENGTH OF BNKSEC-COMMAREA)
                RESP(WS-CICS-RESP)
                RESP2(WS-CICS-RESP2)
           END-EXEC.

           IF WS-CICS-RESP NOT = DFHRESP(NORMAL)
              MOVE 'N' TO DELACC-DEL-SUCCESS
              MOVE 'X' TO DELACC-DEL-FAIL-CD
              GO TO SC999
           END-IF.

           EVALUATE TRUE
              WHEN BNKSEC-ALLOWED
                 SET SEC-OK TO TRUE
              WHEN BNKSEC-DENIED
                 MOVE 'N' TO DELACC-DEL-SUCCESS
                 MOVE 'S' TO DELACC-DEL-FAIL-CD
              WHEN OTHER
                 MOVE 'N' TO DELACC-DEL-SUCCESS
                 MOVE 'X' TO DELACC-DEL-FAIL-CD
           END-EVALUATE.

       SC999.
           EXIT.


      *
      * Read the DB2 datastore and process the data
      *
       READ-ACCOUNT-DB2 SECTION.
       RAD010.

      *
      *    Take the Account number from the comm area and retrieve
      *    the account record from the datastore.
      *
           MOVE DELACC-ACCNO
              TO HV-ACCOUNT-ACC-NO.

           MOVE SORTCODE TO HV-ACCOUNT-SORTCODE.

           EXEC SQL
              SELECT ACCOUNT_EYECATCHER,
                     ACCOUNT_CUSTOMER_NUMBER,
                     ACCOUNT_SORTCODE,
                     ACCOUNT_NUMBER,
                     ACCOUNT_TYPE,
                     ACCOUNT_INTEREST_RATE,
                     ACCOUNT_OPENED,
                     ACCOUNT_OVERDRAFT_LIMIT,
                     ACCOUNT_LAST_STATEMENT,
                     ACCOUNT_NEXT_STATEMENT,
                     ACCOUNT_AVAILABLE_BALANCE,
                     ACCOUNT_ACTUAL_BALANCE
              INTO  :HV-ACCOUNT-EYECATCHER,
                    :HV-ACCOUNT-CUST-NO,
                    :HV-ACCOUNT-SORTCODE,
                    :HV-ACCOUNT-ACC-NO,
                    :HV-ACCOUNT-ACC-TYPE,
                    :HV-ACCOUNT-INT-RATE,
                    :HV-ACCOUNT-OPENED,
                    :HV-ACCOUNT-OVERDRAFT-LIM,
                    :HV-ACCOUNT-LAST-STMT,
                    :HV-ACCOUNT-NEXT-STMT,
                    :HV-ACCOUNT-AVAIL-BAL,
                    :HV-ACCOUNT-ACTUAL-BAL
              FROM ACCOUNT
              WHERE   ACCOUNT_NUMBER = :HV-ACCOUNT-ACC-NO AND
                    ACCOUNT_SORTCODE = :HV-ACCOUNT-SORTCODE
           END-EXEC.

      *
      *    If the SQLCODE returned anything other than OK or row not
      *    found then we have a problem (so abend it)
      *
           IF SQLCODE NOT = 0 AND SQLCODE NOT = +100
              MOVE SQLCODE TO SQLCODE-DISPLAY
      *
      *       Preserve the RESP and RESP2, then set up the
      *       standard ABEND info before getting the applid,
      *       date/time etc. and linking to the Abend Handler
      *       program.
      *
              INITIALIZE ABNDINFO-REC
              MOVE ZERO       TO ABND-RESPCODE
              MOVE ZERO       TO ABND-RESP2CODE
      *
      *       Get supplemental information
      *
              EXEC CICS ASSIGN APPLID(ABND-APPLID)
              END-EXEC

              MOVE EIBTASKN   TO ABND-TASKNO-KEY
              MOVE EIBTRNID   TO ABND-TRANID

              PERFORM POPULATE-TIME-DATE

              MOVE WS-ORIG-DATE TO ABND-DATE
              STRING WS-TIME-NOW-GRP-HH DELIMITED BY SIZE,
                     ':' DELIMITED BY SIZE,
                     WS-TIME-NOW-GRP-MM DELIMITED BY SIZE,
                     ':' DELIMITED BY SIZE,
                     WS-TIME-NOW-GRP-MM DELIMITED BY SIZE
                     INTO ABND-TIME
              END-STRING


              MOVE WS-U-TIME  TO ABND-UTIME-KEY
              MOVE 'HRAC'     TO ABND-CODE

              EXEC CICS ASSIGN PROGRAM(ABND-PROGRAM)
              END-EXEC

              MOVE SQLCODE-DISPLAY      TO ABND-SQLCODE

              STRING 'RAD010 - Issue with ACCOUNT row select, for '
                     DELIMITED BY SIZE,
                     'Account ' HV-ACCOUNT-ACC-NO
                     DELIMITED BY SIZE,
                     'and SORTCODE ' HV-ACCOUNT-SORTCODE
                     DELIMITED BY SIZE,
                     ' EIBRESP=' DELIMITED BY SIZE,
                     ABND-RESPCODE DELIMITED BY SIZE,
                     ' RESP2=' DELIMITED BY SIZE
                     INTO ABND-FREEFORM
              END-STRING


              DISPLAY 'Issue with ACCOUNT row select. SQLCODE='
                 SQLCODE-DISPLAY ' . For Account ' HV-ACCOUNT-ACC-NO
                 ' and Sortcode' HV-ACCOUNT-SORTCODE

              EXEC CICS ABEND ABCODE('HRAC')
                   NODUMP
              END-EXEC

           END-IF.

      *
      *    If the account is not found, then we need to finish
      *    processing and return an error (via the COMM AREA) to the
      *    calling program
      *
           IF SQLCODE = +100
              INITIALIZE OUTPUT-DATA
              MOVE SORTCODE TO ACCOUNT-SORT-CODE OF OUTPUT-DATA
              MOVE DELACC-ACCNO TO ACCOUNT-NUMBER OF OUTPUT-DATA
              MOVE 'N' TO DELACC-DEL-SUCCESS
              MOVE '1' TO DELACC-DEL-FAIL-CD
              GO TO RAD999
           END-IF.

      *
      *    If the SQL return code was OK, then set the flags
      *    accordingly.
      *
           IF SQLCODE = 0
              MOVE ' ' TO DELACC-SUCCESS
              MOVE 'Y' TO DELACC-DEL-SUCCESS
              MOVE ' ' TO DELACC-DEL-FAIL-CD
           END-IF.

      *
      *    Return the ACCOUNT data to the COMMAREA
      *
           MOVE HV-ACCOUNT-EYECATCHER TO
              ACCOUNT-EYE-CATCHER OF OUTPUT-DATA.
           MOVE HV-ACCOUNT-CUST-NO TO
              ACCOUNT-CUST-NO OF OUTPUT-DATA.
           MOVE HV-ACCOUNT-SORTCODE TO
              ACCOUNT-SORT-CODE OF OUTPUT-DATA.
           MOVE HV-ACCOUNT-ACC-NO TO
              ACCOUNT-NUMBER OF OUTPUT-DATA.
           MOVE HV-ACCOUNT-ACC-TYPE TO
              ACCOUNT-TYPE OF OUTPUT-DATA.
           MOVE HV-ACCOUNT-INT-RATE TO
              ACCOUNT-INTEREST-RATE OF OUTPUT-DATA.
           MOVE HV-ACCOUNT-OPENED TO DB2-DATE-REFORMAT.
           MOVE DB2-DATE-REF-DAY TO
              ACCOUNT-OPENED-DAY OF OUTPUT-DATA.
           MOVE DB2-DATE-REF-MNTH TO
              ACCOUNT-OPENED-MONTH OF OUTPUT-DATA.
           MOVE DB2-DATE-REF-YR TO
              ACCOUNT-OPENED-YEAR OF OUTPUT-DATA.
           MOVE HV-ACCOUNT-OVERDRAFT-LIM TO
              ACCOUNT-OVERDRAFT-LIMIT OF OUTPUT-DATA.
           MOVE HV-ACCOUNT-LAST-STMT TO DB2-DATE-REFORMAT.
           MOVE DB2-DATE-REF-DAY TO
              ACCOUNT-LAST-STMT-DAY OF OUTPUT-DATA.
           MOVE DB2-DATE-REF-MNTH TO
              ACCOUNT-LAST-STMT-MONTH OF OUTPUT-DATA.
           MOVE DB2-DATE-REF-YR TO
              ACCOUNT-LAST-STMT-YEAR OF OUTPUT-DATA.
           MOVE HV-ACCOUNT-NEXT-STMT TO DB2-DATE-REFORMAT
           MOVE DB2-DATE-REF-DAY TO
              ACCOUNT-NEXT-STMT-DAY OF OUTPUT-DATA.
           MOVE DB2-DATE-REF-MNTH TO
              ACCOUNT-NEXT-STMT-MONTH OF OUTPUT-DATA.
           MOVE DB2-DATE-REF-YR TO
              ACCOUNT-NEXT-STMT-YEAR OF OUTPUT-DATA.
           MOVE HV-ACCOUNT-AVAIL-BAL TO
              ACCOUNT-AVAILABLE-BALANCE OF OUTPUT-DATA.
           MOVE HV-ACCOUNT-ACTUAL-BAL TO
              ACCOUNT-ACTUAL-BALANCE OF OUTPUT-DATA.
           MOVE HV-ACCOUNT-ACTUAL-BAL TO ACCOUNT-ACT-BAL-STORE.

           MOVE ACCOUNT-EYE-CATCHER       TO DELACC-EYE.
           MOVE ACCOUNT-CUST-NO           TO DELACC-CUSTNO.
           MOVE ACCOUNT-SORT-CODE         TO DELACC-SCODE.
           MOVE ACCOUNT-NUMBER            TO DELACC-ACCNO.
           MOVE ACCOUNT-TYPE              TO DELACC-ACC-TYPE.
           MOVE ACCOUNT-INTEREST-RATE     TO DELACC-INT-RATE.
           MOVE ACCOUNT-OPENED            TO DELACC-OPENED.
           MOVE ACCOUNT-OVERDRAFT-LIMIT   TO DELACC-OVERDRAFT.
           MOVE ACCOUNT-LAST-STMT-DATE    TO DELACC-LAST-STMT-DT.
           MOVE ACCOUNT-NEXT-STMT-DATE    TO DELACC-NEXT-STMT-DT.
           MOVE ACCOUNT-AVAILABLE-BALANCE TO DELACC-AVAIL-BAL.
           MOVE ACCOUNT-ACTUAL-BALANCE    TO DELACC-ACTUAL-BAL.
           MOVE ACCOUNT-ACTUAL-BALANCE    TO ACCOUNT-ACT-BAL-STORE.

       RAD999.
           EXIT.


       DEL-ACCOUNT-DB2 SECTION.
       DADB010.

      *
      *    Delete the ACCOUNT row where the SORTCODE and ACCOUNT
      *    NUMBER match.
      *
           EXEC SQL
              DELETE FROM ACCOUNT
              WHERE ACCOUNT_SORTCODE = :HV-ACCOUNT-SORTCODE AND
                    ACCOUNT_NUMBER = :HV-ACCOUNT-ACC-NO
           END-EXEC.

           IF SQLCODE NOT = 0
              MOVE ' ' TO DELACC-SUCCESS
              MOVE 'N' TO DELACC-DEL-SUCCESS
              MOVE '3' TO DELACC-DEL-FAIL-CD
           END-IF.

       DADB999.
           EXIT.


       WRITE-PROCTRAN SECTION.
       WP010.

           PERFORM WRITE-PROCTRAN-DB2.
       WP999.
           EXIT.


       WRITE-PROCTRAN-DB2 SECTION.
       WPD010.

      *
      *    If the DELETE of the account row was successful then record
      *    this on the PROCTRAN datastore.
      *
           INITIALIZE HOST-PROCTRAN-ROW.
           INITIALIZE WS-EIBTASKN12.

           MOVE 'PRTR' TO HV-PROCTRAN-EYECATCHER.
           MOVE ACCOUNT-SORT-CODE  TO HV-PROCTRAN-SORT-CODE.
           MOVE ACCOUNT-NUMBER     TO HV-PROCTRAN-ACC-NUMBER.
           MOVE EIBTASKN           TO WS-EIBTASKN12.
           MOVE WS-EIBTASKN12      TO HV-PROCTRAN-REF.

      *
      *    Populate the time and date
      *
           EXEC CICS ASKTIME
              ABSTIME(WS-U-TIME)
           END-EXEC.

           EXEC CICS FORMATTIME
                     ABSTIME(WS-U-TIME)
                     DDMMYYYY(WS-ORIG-DATE)
                     TIME(HV-PROCTRAN-TIME)
                     DATESEP('.')
           END-EXEC.

           MOVE WS-ORIG-DATE TO WS-ORIG-DATE-GRP-X.
           MOVE WS-ORIG-DATE-GRP-X TO HV-PROCTRAN-DATE.

           MOVE ACCOUNT-CUST-NO    TO PROC-DESC-DELACC-CUSTOMER
            OF PROCTRAN-AREA
           MOVE ACCOUNT-TYPE       TO PROC-DESC-DELACC-ACCTYPE
            OF PROCTRAN-AREA
           MOVE ACCOUNT-LAST-STMT-DAY
             TO PROC-DESC-DELACC-LAST-DD  OF PROCTRAN-AREA
           MOVE ACCOUNT-LAST-STMT-MONTH
             TO PROC-DESC-DELACC-LAST-MM  OF PROCTRAN-AREA
           MOVE ACCOUNT-LAST-STMT-YEAR
             TO PROC-DESC-DELACC-LAST-YYYY  OF PROCTRAN-AREA
           MOVE ACCOUNT-NEXT-STMT-DAY
             TO PROC-DESC-DELACC-NEXT-DD  OF PROCTRAN-AREA
           MOVE ACCOUNT-NEXT-STMT-MONTH
             TO PROC-DESC-DELACC-NEXT-MM  OF PROCTRAN-AREA
           MOVE ACCOUNT-NEXT-STMT-YEAR
             TO PROC-DESC-DELACC-NEXT-YYYY  OF PROCTRAN-AREA

           SET PROC-DESC-DELACC-FLAG  OF PROCTRAN-AREA TO TRUE.
           SET PROC-TY-BRANCH-DELETE-ACCOUNT  OF PROCTRAN-AREA TO TRUE.

           MOVE PROC-TRAN-DESC  OF PROCTRAN-AREA TO HV-PROCTRAN-DESC


           MOVE PROC-TRAN-TYPE  OF PROCTRAN-AREA TO HV-PROCTRAN-TYPE.
           MOVE ACCOUNT-ACT-BAL-STORE    TO HV-PROCTRAN-AMOUNT.

           EXEC SQL
              INSERT INTO PROCTRAN
                     (
                      PROCTRAN_EYECATCHER,
                      PROCTRAN_SORTCODE,
                      PROCTRAN_NUMBER,
                      PROCTRAN_DATE,
                      PROCTRAN_TIME,
                      PROCTRAN_REF,
                      PROCTRAN_TYPE,
                      PROCTRAN_DESC,
                      PROCTRAN_AMOUNT
                     )
              VALUES
                     (
                      :HV-PROCTRAN-EYECATCHER,
                      :HV-PROCTRAN-SORT-CODE,
                      :HV-PROCTRAN-ACC-NUMBER,
                      :HV-PROCTRAN-DATE,
                      :HV-PROCTRAN-TIME,
                      :HV-PROCTRAN-REF,
                      :HV-PROCTRAN-TYPE,
                      :HV-PROCTRAN-DESC,
                      :HV-PROCTRAN-AMOUNT
                     )
           END-EXEC.

      *
      *    Check the SQLCODE
      *

           IF SQLCODE NOT = 0
              MOVE SQLCODE TO SQLCODE-DISPLAY

      *       Preserve the RESP and RESP2, then set up the
      *       standard ABEND info before getting the applid,
      *       date/time etc. and linking to the Abend Handler
      *       program.
      *
              INITIALIZE ABNDINFO-REC
              MOVE EIBRESP    TO ABND-RESPCODE
              MOVE EIBRESP2   TO ABND-RESP2CODE
      *
      *       Get supplemental information
      *
              EXEC CICS ASSIGN APPLID(ABND-APPLID)
              END-EXEC

              MOVE EIBTASKN   TO ABND-TASKNO-KEY
              MOVE EIBTRNID   TO ABND-TRANID

              PERFORM POPULATE-TIME-DATE

              MOVE WS-ORIG-DATE TO ABND-DATE
              STRING WS-TIME-NOW-GRP-HH DELIMITED BY SIZE,
                    ':' DELIMITED BY SIZE,
                     WS-TIME-NOW-GRP-MM DELIMITED BY SIZE,
                     ':' DELIMITED BY SIZE,
                     WS-TIME-NOW-GRP-MM DELIMITED BY SIZE
                     INTO ABND-TIME
              END-STRING

              MOVE WS-U-TIME   TO ABND-UTIME-KEY
              MOVE 'HWPT'      TO ABND-CODE

              EXEC CICS ASSIGN PROGRAM(ABND-PROGRAM)
              END-EXEC

              MOVE SQLCODE-DISPLAY    TO ABND-SQLCODE

              STRING 'WPD010 - Unable to  WRITE to PROCTRAN row '
                    DELIMITED BY SIZE,
                    'datastore with the following data:'
                    DELIMITED BY SIZE,
                    HOST-PROCTRAN-ROW DELIMITED BY SIZE,
                    ' EIBRESP=' DELIMITED BY SIZE,
                    ABND-RESPCODE DELIMITED BY SIZE,
                    ' RESP2=' DELIMITED BY SIZE,
                    ABND-RESP2CODE DELIMITED BY SIZE
                    INTO ABND-FREEFORM
              END-STRING

              EXEC CICS LINK PROGRAM(WS-ABEND-PGM)
                        COMMAREA(ABNDINFO-REC)
              END-EXEC

              DISPLAY 'In DELACC (WPD010) '
              'UNABLE TO WRITE TO PROCTRAN ROW DATASTORE'
              ' SQLCODE=' SQLCODE-DISPLAY
              'WITH THE FOLLOWING DATA:' HOST-PROCTRAN-ROW

              EXEC CICS ABEND
                 ABCODE ('HWPT')
              END-EXEC

           END-IF.

       WPD999.
           EXIT.


      *
      * Finish
      *
       GET-ME-OUT-OF-HERE SECTION.
       GMOFH010.

           GOBACK.

       GMOFH999.
           EXIT.


       POPULATE-TIME-DATE SECTION.
       PTD010.

           EXEC CICS ASKTIME
              ABSTIME(WS-U-TIME)
           END-EXEC.

           EXEC CICS FORMATTIME
                     ABSTIME(WS-U-TIME)
                     DDMMYYYY(WS-ORIG-DATE)
                     TIME(WS-TIME-NOW)
                     DATESEP
           END-EXEC.

       PTD999.
           EXIT.
