//LSTCUST  JOB 'Customer List',NOTIFY=&SYSUID,CLASS=A,
//          MSGCLASS=H,MSGLEVEL=(1,1),REGION=4M
//*=============================================================
//* JOB:  LSTCUST
//* DESC: LISTAGEM GERAL DE CUSTOMERS - BANCO XYZ
//* PROG: LSTCUST
//* SAIDA: RAFAELT.BANK.LSTCUST.REPORT
//*        RECFM=FB  LRECL=133  BLKSIZE=27930
//*
//* CODIGOS DE RETORNO:
//*   RC= 0  Execucao bem-sucedida
//*   RC= 4  Nenhum customer encontrado (tabela vazia)
//*   RC= 8  Erro de I/O no dataset de saida
//*   RC=12  Erro DB2 (SQLCODE negativo)
//*
//* PRE-REQUISITOS:
//*   - Plano DB2 BANKZPLN deve incluir o programa LSTCUST
//*   - Dataset de saida NAO deve existir (DISP=NEW)
//*   - Autoridade SELECT na tabela CUSTOMER
//*=============================================================
//STEP1    EXEC PGM=IKJEFT01
//STEPLIB  DD  DISP=SHR,DSN=DB2V13.SDSNEXIT
//         DD  DISP=SHR,DSN=DB2V13.SDSNLOAD
//         DD  DISP=SHR,DSN=BANKZ.V0R1M0.LOAD
//LSTOUT   DD  DSN=RAFAELT.BANK.LSTCUST.REPORT,
//             DISP=(NEW,CATLG,DELETE),
//             SPACE=(TRK,(50,10),RLSE),
//             DCB=(RECFM=FB,LRECL=133,BLKSIZE=27930)
//SYSPRINT DD  SYSOUT=*
//SYSOUT   DD  SYSOUT=*
//SYSTSPRT DD  SYSOUT=*
//SYSTSIN  DD *
 DSN SYSTEM(DBD1)
 RUN  PROGRAM(LSTCUST) PLAN(BANKZPLN) -
      LIB('BANKZ.V0R1M0.LOAD')
 END
/*
