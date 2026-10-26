       CBL CICS('SP,EDF')
      ******************************************************************        
      *                                                                *        
      *  Copyright IBM Corp. 2023                                      *        
      *                                                                *        
      ******************************************************************        
      ******************************************************************        
      * This program is the dummy credit agency, used for credit
      * scoring. Data is passed to the program via a channel and
      * container and the role of this program is to delay for a
      * random amount of time (between 0 and 3 seconds) and to
      * create a random credit score (between 1 and 999), then finish.
      *
      * The purpose of the initial delay is to emulate data being
      * returned to the parent program (this program is driven using
      * the Async API). There is a delay of 3 seconds in the parent
      * so what this means is there a 1 in 4 chance that data will be
      * returned withing the overall 3 second delay - this emulates
      * not always being able to get a timely reply back to the parent.
      *
      *
      ******************************************************************        

       IDENTIFICATION DIVISION.
       PROGRAM-ID. CRDTAGY2.
       AUTHOR. Jon Collett.
 
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
      *SOURCE-COMPUTER.  IBM-370 WITH DEBUGGING MODE.
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


       01 WS-CONT-IN.
      *   COPY CUSTOMER.

      * Copybook Location: 
      * file:///Users/rafaeltesta.rt/Library/CloudStorage/OneDrive-IBM/B        
      * ank-of-Z-main/src/base/cics/copy/CUSTOMER.cpy

      ******************************************************************        
      *                                                                *        
      *  Copyright IBM Corp. 2023                                      *        
      *
      *                                                                *        
      ******************************************************************        
           03 CUSTOMER-RECORD.
              05 CUSTOMER-EYECATCHER                 PIC X(4).
                 88 CUSTOMER-EYECATCHER-VALUE        VALUE 'CUST'.
              05 CUSTOMER-KEY.
                 07 CUSTOMER-SORTCODE                PIC 9(6) DISPLAY.
                 07 CUSTOMER-NUMBER                  PIC 9(10) DISPLAY.
              05 CUSTOMER-NAME.
                 07 CUSTOMER-TITLE                   PIC X(10).
                 07 CUSTOMER-FIRST-NAME              PIC X(50).
                 07 CUSTOMER-LAST-NAME               PIC X(50).
              05 CUSTOMER-DOB.
                 07 CUSTOMER-DOB-DAY                 PIC 99 DISPLAY.
                 07 CUSTOMER-DOB-MONTH               PIC 99 DISPLAY.
                 07 CUSTOMER-DOB-YEAR                PIC 9999 DISPLAY.
              05 CUSTOMER-PHONE                      PIC X(20).
              05 CUSTOMER-ADDRESS.
                 07 CUSTOMER-ADDR-LINE1              PIC X(50).
                 07 CUSTOMER-ADDR-LINE2              PIC X(50).
                 07 CUSTOMER-CITY                    PIC X(50).
                 07 CUSTOMER-POSTCODE                PIC X(10).
                 07 CUSTOMER-COUNTRY                 PIC X(50).
              05 CUSTOMER-STATUS                     PIC X(10).
                 88 CUSTOMER-STATUS-ACTIVE           VALUE 'ACTIVE'.
                 88 CUSTOMER-STATUS-INACTIVE         VALUE 'INACTIVE'.
                 88 CUSTOMER-STATUS-SUSPENDED        VALUE 'SUSPENDED'.
              05 CUSTOMER-CREATED-DATE.
                 07 CUSTOMER-CREATED-DAY             PIC 99 DISPLAY.
                 07 CUSTOMER-CREATED-MONTH           PIC 99 DISPLAY.
                 07 CUSTOMER-CREATED-YEAR            PIC 9999 DISPLAY.
              05 CUSTOMER-CREDIT-SCORE               PIC 999.
              05 CUSTOMER-CS-REVIEW-DATE.
                 07 CUSTOMER-CS-REVIEW-DAY           PIC 99 DISPLAY.
                 07 CUSTOMER-CS-REVIEW-MONTH         PIC 99 DISPLAY.
                 07 CUSTOMER-CS-REVIEW-YEAR          PIC 9999 DISPLAY.

       01 WS-CICS-WORK-AREA.
          05 WS-CICS-RESP               PIC S9(8) COMP.
          05 WS-CICS-RESP2              PIC S9(8) COMP.


       01 WS-DELAY-AMT                  PIC S9(8) COMP
                                                   VALUE 0.

       01 WS-CONTAINER-NAME             PIC X(16)  VALUE SPACES.
       01 WS-CHANNEL-NAME               PIC X(16)  VALUE SPACES.

       01 WS-CONTAINER-LEN              PIC S9(8) COMP
                                                   VALUE 0.
       01 WS-NEW-CREDSCORE              PIC 999    VALUE 0.
       01 WS-SEED                       PIC S9(15) COMP.



       01 WS-U-TIME                     PIC S9(15) COMP-3.
       01 WS-ORIG-DATE                  PIC X(10).
       01 WS-ORIG-DATE-GRP REDEFINES WS-ORIG-DATE.
          03 WS-ORIG-DATE-DD            PIC 99.
          03 FILLER                     PIC X.
          03 WS-ORIG-DATE-MM            PIC 99.
          03 FILLER                     PIC X.
          03 WS-ORIG-DATE-YYYY          PIC 9999.

       01 WS-ORIG-DATE-GRP-X.
          03 WS-ORIG-DATE-DD-X          PIC XX.
          03 FILLER                     PIC X      VALUE '.'.
          03 WS-ORIG-DATE-MM-X          PIC XX.
          03 FILLER                     PIC X      VALUE '.'.
          03 WS-ORIG-DATE-YYYY-X        PIC X(4).


       01 WS-TIME-DATA.
          03 WS-TIME-NOW                PIC 9(6).
          03 WS-TIME-NOW-GRP REDEFINES WS-TIME-NOW.
             05 WS-TIME-NOW-GRP-HH      PIC 99.
             05 WS-TIME-NOW-GRP-MM      PIC 99.
             05 WS-TIME-NOW-GRP-SS      PIC 99.

       01 WS-ABEND-PGM                  PIC X(8)   VALUE 'ABNDPROC'.

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


       PROCEDURE DIVISION.
       PREMIERE SECTION.
       A010.
      *
      *    Generate a random  number of seconds between 0 & 3.
      *    This is the delay amount in seconds.
      *

           MOVE 'CIPB            ' TO WS-CONTAINER-NAME.
           MOVE 'CIPCREDCHANN    ' TO WS-CHANNEL-NAME.
           MOVE EIBTASKN           TO WS-SEED.

           COMPUTE WS-DELAY-AMT = ((3 - 1)
                            * FUNCTION RANDOM(WS-SEED)) + 1.

           EXEC CICS DELAY
                FOR SECONDS(WS-DELAY-AMT)
                RESP(WS-CICS-RESP)
                RESP2(WS-CICS-RESP2)
           END-EXEC.

           IF WS-CICS-RESP NOT = DFHRESP(NORMAL)
      *
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
              MOVE 'PLOP'      TO ABND-CODE

              EXEC CICS ASSIGN PROGRAM(ABND-PROGRAM)
              END-EXEC

              MOVE ZEROS      TO ABND-SQLCODE

              STRING 'A010  - *** The delay messed up! ***'
                      DELIMITED BY SIZE,
                      ' EIBRESP=' DELIMITED BY SIZE,
                      ABND-RESPCODE DELIMITED BY SIZE,
                      ' RESP2=' DELIMITED BY SIZE,
                      ABND-RESP2CODE DELIMITED BY SIZE
                      INTO ABND-FREEFORM
              END-STRING

              EXEC CICS LINK PROGRAM(WS-ABEND-PGM)
                          COMMAREA(ABNDINFO-REC)
              END-EXEC


              DISPLAY '*** The delay messed up ! ***'
              EXEC CICS ABEND
                 ABCODE('PLOP')
              END-EXEC
           END-IF.


           COMPUTE WS-CONTAINER-LEN = LENGTH OF WS-CONT-IN.

           EXEC CICS GET CONTAINER(WS-CONTAINER-NAME)
                     CHANNEL(WS-CHANNEL-NAME)
                     INTO(WS-CONT-IN)
                     FLENGTH(WS-CONTAINER-LEN)
                     RESP(WS-CICS-RESP)
                     RESP2(WS-CICS-RESP2)
           END-EXEC.

           IF WS-CICS-RESP NOT = DFHRESP(NORMAL)
              DISPLAY 'CRDTAGY2 - UNABLE TO GET CONTAINER. RESP='
                 WS-CICS-RESP ', RESP2=' WS-CICS-RESP2
              DISPLAY 'CONTAINER=' WS-CONTAINER-NAME ' CHANNEL='
                       WS-CHANNEL-NAME ' FLENGTH='
                       WS-CONTAINER-LEN
              PERFORM GET-ME-OUT-OF-HERE
           END-IF.
      *
      *    Now generate a credit score between 1 and 999. Because we
      *    used a SEED on the first RANDOM (above) we don't need to
      *    use a SEED again when using RANDOM for a subsequent time
      *

           COMPUTE WS-NEW-CREDSCORE = ((999 - 1)
                            * FUNCTION RANDOM) + 1.

           MOVE WS-NEW-CREDSCORE TO CUSTOMER-CREDIT-SCORE
              OF WS-CONT-IN.

      *
      *    Now PUT the data back into a container
      *
           COMPUTE WS-CONTAINER-LEN = LENGTH OF WS-CONT-IN.

           EXEC CICS PUT CONTAINER(WS-CONTAINER-NAME)
                         FROM(WS-CONT-IN)
                         FLENGTH(WS-CONTAINER-LEN)
                         CHANNEL(WS-CHANNEL-NAME)
                         RESP(WS-CICS-RESP)
                         RESP2(WS-CICS-RESP2)
           END-EXEC.

           IF WS-CICS-RESP NOT = DFHRESP(NORMAL)
              DISPLAY 'CRDTAGY2 - UNABLE TO PUT CONTAINER. RESP='
                 WS-CICS-RESP ', RESP2=' WS-CICS-RESP2
              DISPLAY  'CONTAINER='  WS-CONTAINER-NAME
              ' CHANNEL=' WS-CHANNEL-NAME ' FLENGTH='
                    WS-CONTAINER-LEN
              PERFORM GET-ME-OUT-OF-HERE
           END-IF.

           PERFORM GET-ME-OUT-OF-HERE.

       A999.
           EXIT.


       GET-ME-OUT-OF-HERE SECTION.
       GMOFH010.

           EXEC CICS RETURN
           END-EXEC.

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
