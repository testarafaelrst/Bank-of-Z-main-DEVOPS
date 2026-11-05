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
