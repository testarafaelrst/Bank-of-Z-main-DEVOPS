//LSTCCMP  JOB 'Compile LSTCUST',NOTIFY=&SYSUID,CLASS=A,
//          MSGCLASS=H,MSGLEVEL=(1,1),REGION=256M
//*=============================================================
//* JOB:  LSTCCMP
//* DESC: COMPILACAO E LINKEDIT DO PROGRAMA LSTCUST
//*       LSTCUST E UM PROGRAMA COBOL COM SQL EMBARCADO (DB2)
//*
//* PASSOS:
//*   STEP1 - DSNHPC  : Pre-compilador DB2 (expande EXEC SQL)
//*   STEP2 - IGYCRCTL: Compilador COBOL Enterprise
//*   STEP3 - IEWL    : Link-Editor (gera modulo de carga)
//*
//* DATASETS REQUERIDOS ANTES DA PRIMEIRA EXECUCAO:
//*   &HLQ..BANKZ.OBJ   - PDS para modulos objeto  (se nao existe)
//*   BANKZ.V0R1M0.LOAD  - PDS para modulos de carga (deve existir)
//*
//* DATASETS DE FONTE E COPYBOOKS:
//*   &HLQ..BANK.COBOL(LSTCUST)  - fonte COBOL
//*   &HLQ..BANK.COPY            - copybooks (CUSTDB2, CUSTOMER, SORTCODE)
//*=============================================================
//    SET HLQ='RAFAELT'                       *TSO USER ID
//    SET CMPLLIB='COBOL.V6R2.SIGYCOMP'       *COMPILADOR COBOL
//    SET LINKLIB='SYS1.CEE.SCEELKED'         *LINK LIBRARY LE
//    SET DB2HLQ='DSN1310.DB2'                *HLQ DO DB2
//    SET LOADLIB=&HLQ..BANKZ.LOAD            *LOAD LIBRARY
//    SET OBJLIB=&HLQ..BANKZ.OBJ              *OBJECT LIBRARY
//    SET COBOLSRC=&HLQ..BANK.COBOL           *FONTE COBOL
//    SET COPYLIB=&HLQ..BANK.COPY             *COPYBOOKS
//    SET SPACE1='SYSALLDA,SPACE=(CYL,(2,1))' *ESPACO TEMP
//*
//*=============================================================
//* STEP1 - PRE-COMPILADOR DB2 (DSNHPC)
//*   Entrada : Fonte COBOL com EXEC SQL
//*   Saida   : Fonte COBOL modificado (DBRM dataset + fonte expandido)
//*   DBRM    : Database Request Module - usado no BIND posterior
//*=============================================================
//STEP1    EXEC PGM=DSNHPC,
//          PARM='HOST(IBMCOB),APOSTSQL,MARGINS(8,72),SOURCE,XREF'
//STEPLIB  DD  DISP=SHR,DSN=&DB2HLQ..SDSNLOAD
//DBRMLIB  DD  DISP=SHR,DSN=&HLQ..BANKZ.DBRMLIB(LSTCUST)
//SYSCIN   DD  DISP=(NEW,PASS),
//             UNIT=&SPACE1,
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=3200)
//SYSIN    DD  DISP=SHR,DSN=&COBOLSRC(LSTCUST)
//SYSLIB   DD  DISP=SHR,DSN=&COPYLIB
//SYSPRINT DD  SYSOUT=*
//SYSTERM  DD  SYSOUT=*
//SYSUT1   DD  UNIT=&SPACE1
//SYSUT2   DD  UNIT=&SPACE1
//SYSDBOUT DD  SYSOUT=*
//*
//*=============================================================
//* STEP2 - COMPILADOR COBOL (IGYCRCTL)
//*   Entrada : Saida do pre-compilador DB2 (SYSCIN passado)
//*   Saida   : Modulo objeto em &OBJLIB(LSTCUST)
//*   PARM    : OBJECT  - gera codigo objeto
//*             LIST    - listagem completa da compilacao
//*             MAP     - mapa de dados (variaveis e offsets)
//*             XREF    - referencias cruzadas de nomes
//*             TRUNC(BIN) - truncamento binario para host vars DB2
//*             OFFSET  - offsets para debug
//*=============================================================
//STEP2    EXEC PGM=IGYCRCTL,COND=(4,LT,STEP1),
//          PARM='OBJECT,LIST,MAP,XREF,TRUNC(BIN),OFFSET,NODYN'
//STEPLIB  DD  DISP=SHR,DSN=&CMPLLIB
//SYSIN    DD  DSN=*.STEP1.SYSCIN,DISP=(OLD,DELETE)
//SYSLIB   DD  DISP=SHR,DSN=&COPYLIB
//         DD  DISP=SHR,DSN=&DB2HLQ..SDSNC.H
//SYSLIN   DD  DISP=SHR,DSN=&OBJLIB(LSTCUST)
//SYSPRINT DD  SYSOUT=*
//SYSMDECK DD  UNIT=&SPACE1
//SYSUT1   DD  UNIT=&SPACE1
//SYSUT2   DD  UNIT=&SPACE1
//SYSUT3   DD  UNIT=&SPACE1
//SYSUT4   DD  UNIT=&SPACE1
//SYSUT5   DD  UNIT=&SPACE1
//SYSUT6   DD  UNIT=&SPACE1
//SYSUT7   DD  UNIT=&SPACE1
//SYSUT8   DD  UNIT=&SPACE1
//SYSUT9   DD  UNIT=&SPACE1
//SYSUT10  DD  UNIT=&SPACE1
//SYSUT11  DD  UNIT=&SPACE1
//SYSUT12  DD  UNIT=&SPACE1
//SYSUT13  DD  UNIT=&SPACE1
//SYSUT14  DD  UNIT=&SPACE1
//SYSUT15  DD  UNIT=&SPACE1
//*
//*=============================================================
//* STEP3 - LINK-EDITOR (IEWL)
//*   Entrada : Modulo objeto LSTCUST
//*             Modulo de interface DB2 (DSNELI - stub de entrada)
//*   Saida   : Modulo de carga em &LOADLIB(LSTCUST)
//*   ENTRY   : LSTCUST - define o ponto de entrada do modulo
//*=============================================================
//STEP3    EXEC PGM=IEWL,COND=(4,LT,STEP2),REGION=3000K,
//          PARM='MAP,LIST,XREF,LET,RENT'
//SYSLMOD  DD  DISP=SHR,DSN=&LOADLIB
//SYSPRINT DD  SYSOUT=*
//SYSUT1   DD  UNIT=&SPACE1
//SYSLIB   DD  DISP=SHR,DSN=&LINKLIB
//         DD  DISP=SHR,DSN=&DB2HLQ..SDSNLOAD
//         DD  DISP=SHR,DSN=SYS1.SIEALNKE
//         DD  DISP=SHR,DSN=&LOADLIB
//OBJ      DD  DISP=SHR,DSN=&OBJLIB
//SYSLIN   DD *
     INCLUDE OBJ(LSTCUST)
     ENTRY LSTCUST
     NAME  LSTCUST(R)
/*
//*=============================================================
//* OBSERVACOES POS-COMPILACAO:
//*
//* Apos compilacao bem-sucedida (todos os RCs = 0):
//*
//*   1. Executar BIND do DBRM para incluir LSTCUST no plano DB2:
//*      BIND PACKAGE(BANKZPKG/LSTCUST) -
//*           MEMBER(LSTCUST) -
//*           LIBRARY('&HLQ..BANKZ.DBRMLIB') -
//*           ISOLATION(CS) ACTION(REPLACE)
//*
//*      BIND PLAN(BANKZPLN) -
//*           PKLIST(BANKZPKG.LSTCUST) -
//*           ACTION(REPLACE)
//*
//*   2. Conceder autoridade de execucao (executar via SPUFI ou
//*      TSO com usuario SYSADM/DBADM):
//*      GRANT EXECUTE ON PLAN BANKZPLN TO PUBLIC
//*
//*=============================================================
