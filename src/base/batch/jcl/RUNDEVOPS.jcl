//DEVOPSRN JOB ,NOTIFY=&SYSUID,
// MSGCLASS=H,MSGLEVEL=(1,1),REGION=144M
//*****************************************************************
//* LICENSED MATERIALS - PROPERTY OF IBM
//* "RESTRICTED MATERIALS OF IBM"
//* (C) COPYRIGHT IBM CORPORATION 2026. ALL RIGHTS RESERVED
//*
//*  US GOVERNMENT USERS RESTRICTED RIGHTS - USE, DUPLICATION,
//*  OR DISCLOSURE RESTRICTED BY GSA ADP SCHEDULE
//*  CONTRACT WITH IBM CORPORATION
//*
//*****************************************************************
//*
//* RUN DEVOPSPL - ASSUMES LOAD MODULE ALREADY EXISTS IN LOAD LIBRARY
//*
//*****************************************************************
//    SET HLQ='RAFAELT'                       *TSO USER ID
//*
//***************************
//*                         *
//*  RUN DEVOPSPL           *
//*                         *
//***************************
//RUNDEVOP EXEC PGM=DEVOPSPL
//STEPLIB  DD DISP=SHR,DSN=&HLQ..SAMPLE.LOAD
//SYSOUT   DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
