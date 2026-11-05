       CBL CICS('SP,EDF')
      ******************************************************************
      *                                                                *
      *  BNKSECCK - Bank of Z security check subprogram.               *
      *                                                                *
      ******************************************************************
      ******************************************************************
      * This program is LINKed to by the business programs before they
      * touch any data. It receives an operation code in the BNKSEC
      * COMMAREA, finds the RACF FACILITY profile and the access level
      * required for that operation, and asks CICS (QUERY SECURITY)
      * whether the user may use it.
      *
      * Result (BNKSEC-RESULT): A = allowed, D = denied, E = error.
      *
      * The program is fail-closed: only a NORMAL response with the
      * required access level gives A. An unknown profile, an error
      * or a missing COMMAREA never gives A. It never abends because
      * of a security decision; the caller chooses what to do.
      ******************************************************************

       IDENTIFICATION DIVISION.
       PROGRAM-ID. BNKSECCK.
       AUTHOR. Bank of Z.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER.  IBM-370.
       OBJECT-COMPUTER.  IBM-370.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01 WS-CICS-WORK-AREA.
           05 WS-CICS-RESP              PIC S9(8) COMP.
           05 WS-CICS-RESP2             PIC S9(8) COMP.

       01 SWITCHES.
           03 WS-OP-FOUND-SW            PIC X VALUE 'N'.
              88 OP-FOUND               VALUE 'Y'.
              88 OP-NOT-FOUND           VALUE 'N'.
           03 WS-USERID-SW              PIC X VALUE 'N'.
              88 USERID-OK              VALUE 'Y'.
              88 USERID-NOT-OK          VALUE 'N'.

       01 WS-USERID                     PIC X(8).
       01 WS-RESID                      PIC X(16).
       01 WS-RESID-LEN                  PIC S9(4) COMP.
       01 WS-CVDA-RD                    PIC S9(8) COMP.
       01 WS-CVDA-UPD                   PIC S9(8) COMP.

      * Policy table: operation (8), RACF profile (16), profile
      * length (2) and required level (R = READ, U = UPDATE).
       01 WS-POLICY-VALUES.
           03 FILLER PIC X(27) VALUE 'INQCUST BANKZ.CUSTOMER  14R'.
           03 FILLER PIC X(27) VALUE 'INQACC  BANKZ.ACCOUNT   13R'.
           03 FILLER PIC X(27) VALUE 'CRECUST BANKZ.CREATE    12U'.
           03 FILLER PIC X(27) VALUE 'CREACC  BANKZ.CREATE    12U'.
           03 FILLER PIC X(27) VALUE 'DBCRFUN BANKZ.PAYMENT   13U'.
           03 FILLER PIC X(27) VALUE 'XFRFUN  BANKZ.PAYMENT   13U'.
           03 FILLER PIC X(27) VALUE 'UPDCUST BANKZ.CUSTOMER  14U'.
           03 FILLER PIC X(27) VALUE 'UPDACC  BANKZ.ACCOUNT   13U'.
           03 FILLER PIC X(27) VALUE 'DELCUS  BANKZ.DELETE    12U'.
           03 FILLER PIC X(27) VALUE 'DELACC  BANKZ.DELETE    12U'.

       01 WS-POLICY-TABLE REDEFINES WS-POLICY-VALUES.
           03 WS-POLICY-ENTRY OCCURS 10 TIMES INDEXED BY WS-POL-IX.
              05 WS-POL-OPERATION       PIC X(8).
              05 WS-POL-RESID           PIC X(16).
              05 WS-POL-RESID-LEN       PIC 9(2).
              05 WS-POL-LEVEL           PIC X.
                 88 POL-LEVEL-READ      VALUE 'R'.
                 88 POL-LEVEL-UPDATE    VALUE 'U'.

       LINKAGE SECTION.
       01 DFHCOMMAREA.
           COPY BNKSEC.

       PROCEDURE DIVISION USING DFHCOMMAREA.
       PREMIERE SECTION.
       A010.

      *
      *    Without a COMMAREA of the right size there is nowhere to
      *    return a result, so just go back to the caller.
      *
           IF EIBCALEN NOT = LENGTH OF DFHCOMMAREA
              PERFORM GET-ME-OUT-OF-HERE
           END-IF.

           MOVE 'E'    TO BNKSEC-RESULT.
           MOVE '00'   TO BNKSEC-REASON.
           MOVE SPACES TO BNKSEC-USERID.
           MOVE ZERO   TO BNKSEC-RESP.
           MOVE ZERO   TO BNKSEC-RESP2.
           MOVE 'N'    TO WS-OP-FOUND-SW.
           MOVE 'N'    TO WS-USERID-SW.

           PERFORM RESOLVE-OPERATION.

           IF OP-FOUND
              PERFORM GET-USERID
           END-IF.

           IF OP-FOUND AND USERID-OK
              PERFORM CHECK-ACCESS
           END-IF.

           IF NOT BNKSEC-ALLOWED
              PERFORM LOG-SECURITY-EVENT
           END-IF.

           PERFORM GET-ME-OUT-OF-HERE.

       A999.
           EXIT.


       RESOLVE-OPERATION SECTION.
       RO010.
      *
      *    Find the operation in the policy table
      *
           SET WS-POL-IX TO 1.

           SEARCH WS-POLICY-ENTRY
              AT END
                 MOVE '01' TO BNKSEC-REASON
              WHEN WS-POL-OPERATION(WS-POL-IX) = BNKSEC-OPERATION
                 SET OP-FOUND TO TRUE
           END-SEARCH.

       RO999.
           EXIT.


       GET-USERID SECTION.
       GU010.
      *
      *    Use the user supplied by the caller (for example when a
      *    technical link user is running the task); otherwise use
      *    the user ID of the task.
      *
           IF BNKSEC-FOR-USERID NOT = SPACES
              MOVE BNKSEC-FOR-USERID TO WS-USERID
              SET USERID-OK TO TRUE
           ELSE
              EXEC CICS ASSIGN USERID(WS-USERID)
                   RESP(WS-CICS-RESP)
                   RESP2(WS-CICS-RESP2)
              END-EXEC

              IF WS-CICS-RESP = DFHRESP(NORMAL)
                 SET USERID-OK TO TRUE
              ELSE
                 MOVE '04'          TO BNKSEC-REASON
                 MOVE WS-CICS-RESP  TO BNKSEC-RESP
                 MOVE WS-CICS-RESP2 TO BNKSEC-RESP2
              END-IF
           END-IF.

           IF USERID-OK
              MOVE WS-USERID TO BNKSEC-USERID
           END-IF.

       GU999.
           EXIT.


       CHECK-ACCESS SECTION.
       CA010.
      *
      *    Ask CICS for the access the user has to the profile. Both
      *    levels are requested; only the required one is used.
      *
           MOVE WS-POL-RESID(WS-POL-IX)     TO WS-RESID.
           MOVE WS-POL-RESID-LEN(WS-POL-IX) TO WS-RESID-LEN.

           IF BNKSEC-FOR-USERID NOT = SPACES
              EXEC CICS QUERY SECURITY
                   RESCLASS('FACILITY')
                   RESID(WS-RESID)
                   RESIDLENGTH(WS-RESID-LEN)
                   READ(WS-CVDA-RD)
                   UPDATE(WS-CVDA-UPD)
                   USERID(WS-USERID)
                   RESP(WS-CICS-RESP)
                   RESP2(WS-CICS-RESP2)
              END-EXEC
           ELSE
              EXEC CICS QUERY SECURITY
                   RESCLASS('FACILITY')
                   RESID(WS-RESID)
                   RESIDLENGTH(WS-RESID-LEN)
                   READ(WS-CVDA-RD)
                   UPDATE(WS-CVDA-UPD)
                   RESP(WS-CICS-RESP)
                   RESP2(WS-CICS-RESP2)
              END-EXEC
           END-IF.

           MOVE WS-CICS-RESP  TO BNKSEC-RESP.
           MOVE WS-CICS-RESP2 TO BNKSEC-RESP2.

           EVALUATE WS-CICS-RESP
              WHEN DFHRESP(NORMAL)
                 IF (POL-LEVEL-UPDATE(WS-POL-IX) AND
                    WS-CVDA-UPD = DFHVALUE(UPDATABLE))
                 OR (POL-LEVEL-READ(WS-POL-IX) AND
                    WS-CVDA-RD = DFHVALUE(READABLE))
                    MOVE 'A'  TO BNKSEC-RESULT
                    MOVE '00' TO BNKSEC-REASON
                 ELSE
                    MOVE 'D'  TO BNKSEC-RESULT
                    MOVE '03' TO BNKSEC-REASON
                 END-IF

              WHEN DFHRESP(NOTFND)
                 MOVE 'D'  TO BNKSEC-RESULT
                 MOVE '02' TO BNKSEC-REASON

              WHEN DFHRESP(NOTAUTH)
                 MOVE 'E'  TO BNKSEC-RESULT
                 MOVE '06' TO BNKSEC-REASON

              WHEN OTHER
                 MOVE 'E'  TO BNKSEC-RESULT
                 MOVE '05' TO BNKSEC-REASON
           END-EVALUATE.

       CA999.
           EXIT.


       LOG-SECURITY-EVENT SECTION.
       LS010.
      *
      *    One line per denial or error. No passwords are available
      *    to this program, so none can be written.
      *
           DISPLAY 'BNKSECCK: result=' BNKSEC-RESULT
                   ' reason=' BNKSEC-REASON
                   ' op=' BNKSEC-OPERATION
                   ' user=' BNKSEC-USERID
                   ' tran=' EIBTRNID
                   ' task=' EIBTASKN
                   ' resp=' BNKSEC-RESP
                   ' resp2=' BNKSEC-RESP2.

       LS999.
           EXIT.


       GET-ME-OUT-OF-HERE SECTION.
       GMOFH010.
      *
      *    Return to the program that LINKed to us
      *
           EXEC CICS RETURN
           END-EXEC.

           GOBACK.

       GMOFH999.
           EXIT.
