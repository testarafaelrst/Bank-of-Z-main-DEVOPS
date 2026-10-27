       PROCESS NODLL,NODYNAM,TEST(NOSEP),NOCICS,NOSQL,PGMN(LU),NOSEQ
       PROCESS ARITH(COMPAT)
      *-----------------------------------------------------------------
      * IBM Early Development Testing generated test
      *  Product ID: 5900-BBG
      *  Build: 2026-10-16T15:43:08Z (v3.1.0-SNAPSHOT)
      *   Level: [20261016T154014Z-30ec1c24]
      *  Version: COBOL_DRUN V3.0.0
      *
      * Project: Bank-of-Z-main
      * Program: DEVOPSPL
      * Data origin: Collected
      * Data source: /Users/rafaeltesta.rt/Library/CloudStorage/OneDrive
      *    -IBM/Bank-of-Z-main/.edt-unit-test/recordings/batch-devopspl-
      *    rundevop-2026-10-27t11-39-31-097z.rec
      * Codepage: IBM1047
      * Host: ESYSMVS.wsclab.washington.ibm.com
      * User: rafaelt
      *
      * Test ID: 3a7a7554-fab4-4f4a-a664-2a8a7e8fe713
      * Generated: 10/27/2026 08:39
      *-----------------------------------------------------------------
       IDENTIFICATION DIVISION.
       PROGRAM-ID. 'BEFORE_ALL'.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  TEST-CASE-DATA.
           03 TEST-VERSION       PIC  9(05) COMP VALUE 1.
           03 NUM-TESTS          PIC  9(05) COMP VALUE 1.
           03 TEST-CASE-TYPE     PIC  X(04)      VALUE 'BTCH'.
           03 TEST-CASE-UUID     PIC  X(36)
                           VALUE '3a7a7554-fab4-4f4a-a664-2a8a7e8fe713'.
           03 FILLER             PIC  X(128).
           03 TEST-ARRAY             OCCURS 1 TIMES.
             05 TEST-UUID        PIC  X(36).
             05 TEST-NAME        PIC  X(80).
             05 TEST-EP-NAME     PIC  X(160).
             05 TEST-BEFORE-EACH PIC  X(160)     VALUE 'BEFORE_EACH'.
             05 TEST-AFTER-EACH  PIC  X(160)     VALUE 'AFTER_EACH'.
             05 LOAD-MODULE-NAME PIC  X(08)      VALUE 'DEVOPSPL'.
             05 CSECT-NAME       PIC  X(72)      VALUE SPACES.
       01  TC-DATA-PTR           POINTER.
       01  EQAUTCFG              PIC  X(08)      VALUE 'EQAUTCFG'.
       PROCEDURE DIVISION.
      *****************************************************************
      * Establish the test case information
      *****************************************************************
           DISPLAY 'RUNNING TEST CASE'.
      *****************************************************************
      * Establish individual test case arguments for TEST1
      *****************************************************************
           MOVE 'TEST1' TO TEST-NAME(1).
           MOVE 'TEST_TEST1' TO TEST-EP-NAME(1).
           MOVE '35e8eae7-8c45-4a25-8d85-7cf5c5c6c536'
               TO TEST-UUID(1).
      *****************************************************************
      * Inform the engine of the test case configuration
      *****************************************************************
           SET TC-DATA-PTR TO ADDRESS OF TEST-CASE-DATA.
           CALL EQAUTCFG USING TC-DATA-PTR.
           GOBACK.
       END PROGRAM 'BEFORE_ALL'.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. 'TEST_TEST1'.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  LOAD-MODULE-NAME    PIC  X(08) VALUE 'DEVOPSPL'.
       01  CSECT-NAME          PIC  X(72) VALUE SPACES.
       01  TEST-NAME-LENGTH    PIC S9(04) COMP-5 VALUE ZERO.
       01  TEST-NAME-TRIMMED   PIC  X(80)        VALUE SPACES.
      *
       01  BZUASSRT          PIC  X(08)        VALUE 'BZUASSRT'.
       01  BZ-ASSERT.
           03 MESSAGE-LEN    PIC S9(04) COMP-4 VALUE 5.
           03 MESSAGE-TXT    PIC  X(254)       VALUE 'HELLO'.
       01  BZ-P1             PIC S9(09) COMP-4 VALUE 4.
       01  BZ-P2             PIC S9(09) COMP-4 VALUE 2001.
       01  BZ-P3             PIC  X(03)        VALUE 'AZU'.
      *
       01  BZ-TRACE.
           03 TRACE-LEN        PIC S9(04) COMP-4 VALUE 5.
           03 TRACE-TXT        PIC  X(254)       VALUE 'TRACE'.
       01  BZUGETEP            PIC  X(08)        VALUE 'BZUGETEP'.
       01  BZUTRACE            PIC  X(08)        VALUE 'BZUTRACE'.
       01  AZ-EP-PTR           POINTER.
       01  AZ-TRACE-PTR        POINTER.
       01  ASSERT-ST.
           03 ASSERT-RC        PIC  9(09) BINARY VALUE 4.
           03 ASSERT-TEXT      PIC  9(04) BINARY VALUE 0.
       01  AZ-RC-WORK          PIC S9(04) BINARY VALUE 0.
       LINKAGE SECTION.
       01  TEST-NAME           PIC  X(80).
       01  AZ-ARG-LIST.
           03 ARG-LENGTH       PIC  9(04) COMP-4.
           03 ARG-DATA         PIC  X(256).
       01  AZ-INFO-BLOCK.
           COPY EQAITERC.
       01  AZ-PROC-PTR         PROCEDURE-POINTER.
       PROCEDURE DIVISION USING TEST-NAME
                                AZ-ARG-LIST
                                AZ-INFO-BLOCK
           .
       0000-MAINLINE-SECTION SECTION.
       0010-MAINLINE.
           DISPLAY 'AZU0000I TEST_TEST1 STARTED...'
           PERFORM 9010-TRIM-TEST-NAME
      * INITIALIZE PARAMETER
      * SET AREA ADDRESS TO POINTER
      * SET INPUT VALUE
           MOVE 0 TO RETURN-CODE.
      * CALL TEST PROGRAM
           DISPLAY 'AZU0000I CALL DEVOPSPL'
           CALL BZUGETEP USING BY REFERENCE LOAD-MODULE-NAME
                               CSECT-NAME
                         RETURNING AZ-EP-PTR
           IF AZ-EP-PTR = NULL
             MOVE 1 TO MESSAGE-LEN OF BZ-ASSERT
             STRING 'UNABLE TO GET THE ENTRY POINT BY BZUGETEP.'
               DELIMITED BY SIZE
               INTO MESSAGE-TXT OF BZ-ASSERT
               WITH POINTER MESSAGE-LEN OF BZ-ASSERT
             END-STRING
             SUBTRACT 1 FROM MESSAGE-LEN OF BZ-ASSERT
             PERFORM THROW-ASSERTION-M
             GOBACK
           .
           SET ADDRESS OF AZ-PROC-PTR TO AZ-EP-PTR
           CALL AZ-PROC-PTR
           .
      * EVALUATE OUTPUT VALUE
           MOVE 0 TO RETURN-CODE
      * END
           DISPLAY 'AZU0000I TEST_TEST1 END.'
           GOBACK
           .
       THROW-ASSERTION-M.
           DISPLAY 'AZU0000I ------------------------------------------'
           DISPLAY 'AZU2001W THE TEST "' TEST-NAME-TRIMMED
                                         '" FAILED DUE TO AN ASSERTION.'
           DISPLAY 'AZU1101I ' MESSAGE-TXT OF
                                   BZ-ASSERT(1:MESSAGE-LEN OF BZ-ASSERT)
           DISPLAY 'AZU0000I ------------------------------------------'
           CALL BZUASSRT USING BZ-P1
                               BZ-P2
                               BZ-P3
                               BZ-ASSERT
           .
       9000-UTILITY-SECTION SECTION.
       9010-TRIM-TEST-NAME.
           MOVE 0 TO TEST-NAME-LENGTH
           INSPECT TEST-NAME TALLYING TEST-NAME-LENGTH
               FOR CHARACTERS BEFORE INITIAL SPACE
           MOVE TEST-NAME(1:TEST-NAME-LENGTH) TO TEST-NAME-TRIMMED
           .
       END PROGRAM 'TEST_TEST1'.
      *-----------------------------------------------------------------
      * TEST'S MAIN CALLBACK ROUTINE
      *-----------------------------------------------------------------
       IDENTIFICATION DIVISION.
       PROGRAM-ID. 'BZU_TEST'.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  LOAD-MODULE-NAME    PIC  X(08) VALUE 'DEVOPSPL'.
       01  CSECT-NAME          PIC  X(72) VALUE SPACES.
       01 TESTCASE-METADATA.
           05 TM-PGM-UNDER-TEST-PATH PIC X(200) VALUE
           "src/base/batch/cobol/DEVOPSPL.cbl".
       01  TEST-NAME-LENGTH    PIC S9(04) COMP-5 VALUE ZERO.
       01  TEST-NAME-TRIMMED   PIC  X(80)        VALUE SPACES.
      *
       01  BZUASSRT          PIC  X(08)        VALUE 'BZUASSRT'.
       01  BZ-ASSERT.
           03 MESSAGE-LEN    PIC S9(04) COMP-4 VALUE 5.
           03 MESSAGE-TXT    PIC  X(254)       VALUE 'HELLO'.
       01  BZ-P1             PIC S9(09) COMP-4 VALUE 4.
       01  BZ-P2             PIC S9(09) COMP-4 VALUE 2001.
       01  BZ-P3             PIC  X(03)        VALUE 'AZU'.
      *
       01  BZ-TRACE.
           03 TRACE-LEN        PIC S9(04) COMP-4 VALUE 5.
           03 TRACE-TXT        PIC  X(254)       VALUE 'TRACE'.
       01  BZUTRACE            PIC  X(08)        VALUE 'BZUTRACE'.
       01  AZ-TRACE-PTR        POINTER.
       01  ASSERT-ST.
           03 ASSERT-RC        PIC  9(09) BINARY VALUE 4.
           03 ASSERT-TEXT      PIC  9(04) BINARY VALUE 0.
       LINKAGE SECTION.
       01  TEST-NAME           PIC  X(80).
       01  AZ-INFO-BLOCK.
          COPY EQAITERC.
       01  AZ-ARG-LIST.
           03 ARG-LENGTH       PIC  9(04) COMP-4.
           03 ARG-DATA         PIC  X(256).
      /
       PROCEDURE DIVISION.
       0000-MAINLINE-SECTION SECTION.
       0010-ENTRY-FOR-PGM-INPUT.
           ENTRY "PGM_INPT_DEVOPSPL"
                 USING TEST-NAME
                       AZ-INFO-BLOCK
           .
           DISPLAY 'AZU0000I PGM_INPT_DEVOPSPL INPUT VALUES...'.
           MOVE 0 TO RETURN-CODE
           PERFORM 9010-TRIM-TEST-NAME
      *
           EVALUATE TEST-NAME-TRIMMED
           WHEN SPACE
             CONTINUE
           WHEN OTHER
             CONTINUE
           END-EVALUATE
      *
           PERFORM 9020-TEARDOWN
           GOBACK
           .
       0020-ENTRY-FOR-PGM-OUTPUT.
           ENTRY "PGM_OUTP_DEVOPSPL"
                 USING TEST-NAME
                       AZ-INFO-BLOCK
           .
           DISPLAY 'AZU0000I PGM_OUTP_DEVOPSPL CHECK VALUES...'.
           MOVE 0 TO RETURN-CODE
           PERFORM 9010-TRIM-TEST-NAME
      *
           EVALUATE TEST-NAME-TRIMMED
           WHEN SPACE
             MOVE 4 TO RETURN-CODE
           WHEN 'TEST1'
             MOVE 0 TO RETURN-CODE
           WHEN OTHER
             MOVE 4 TO RETURN-CODE
           END-EVALUATE
      *
           PERFORM 9020-TEARDOWN
           GOBACK
           .
       9000-UTILITY-SECTION SECTION.
       9010-TRIM-TEST-NAME.
           MOVE 0 TO TEST-NAME-LENGTH
           INSPECT TEST-NAME TALLYING TEST-NAME-LENGTH
               FOR CHARACTERS BEFORE INITIAL SPACE
           MOVE TEST-NAME(1:TEST-NAME-LENGTH) TO TEST-NAME-TRIMMED
           .
       9020-TEARDOWN.
           DISPLAY 'AZU0000I BZU_TEST END.'
           .
       END PROGRAM 'BZU_TEST'.
      *-----------------------------------------------------------------
      * TEST'S INITIALIZATION ROUTINE
      *-----------------------------------------------------------------
       IDENTIFICATION DIVISION.
       PROGRAM-ID. 'BEFORE_EACH'.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  TEST-NAME-LENGTH    PIC S9(04) COMP-5 VALUE ZERO.
       01  TEST-NAME-TRIMMED   PIC  X(80)        VALUE SPACES.
       01  UNIQUE-TEST-ID      PIC  X(36)
                           VALUE '3a7a7554-fab4-4f4a-a664-2a8a7e8fe713'.
       LINKAGE SECTION.
       01  TEST-NAME           PIC  X(80).
       01  TEST-ID             PIC  X(80).
       01  AZ-INFO-BLOCK.
           COPY EQAITERC.
       PROCEDURE DIVISION USING TEST-NAME
                                TEST-ID
                                AZ-INFO-BLOCK
           .
       0000-MAINLINE-SECTION SECTION.
       0010-MAINLINE.
           PERFORM 9010-TRIM-TEST-NAME
           DISPLAY 'AZU0000I BEFORE_EACH: ' TEST-NAME-TRIMMED
           MOVE UNIQUE-TEST-ID TO TEST-ID
           GOBACK
           .
       9000-UTILITY-SECTION SECTION.
       9010-TRIM-TEST-NAME.
           MOVE 0 TO TEST-NAME-LENGTH
           INSPECT TEST-NAME TALLYING TEST-NAME-LENGTH
               FOR CHARACTERS BEFORE INITIAL SPACE
           MOVE TEST-NAME(1:TEST-NAME-LENGTH) TO TEST-NAME-TRIMMED
           .
       END PROGRAM 'BEFORE_EACH'.
      *-----------------------------------------------------------------
      * TEST'S TERMINATION ROUTINE
      *-----------------------------------------------------------------
       IDENTIFICATION DIVISION.
       PROGRAM-ID. 'AFTER_EACH'.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  TEST-NAME-LENGTH    PIC S9(04) COMP-5 VALUE ZERO.
       01  TEST-NAME-TRIMMED   PIC  X(80)        VALUE SPACES.
       LINKAGE SECTION.
       01  TEST-NAME            PIC  X(80).
       01  AZ-INFO-BLOCK.
           COPY EQAITERC.
       PROCEDURE DIVISION USING TEST-NAME
                                AZ-INFO-BLOCK
           .
       0000-MAINLINE-SECTION SECTION.
       0010-MAINLINE.
           PERFORM 9010-TRIM-TEST-NAME
           DISPLAY 'AZU0000I AFTER_EACH: ' TEST-NAME-TRIMMED
           GOBACK
           .
       9000-UTILITY-SECTION SECTION.
       9010-TRIM-TEST-NAME.
           MOVE 0 TO TEST-NAME-LENGTH
           INSPECT TEST-NAME TALLYING TEST-NAME-LENGTH
               FOR CHARACTERS BEFORE INITIAL SPACE
           MOVE TEST-NAME(1:TEST-NAME-LENGTH) TO TEST-NAME-TRIMMED
           .
       END PROGRAM 'AFTER_EACH'.
