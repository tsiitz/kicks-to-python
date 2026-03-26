       IDENTIFICATION DIVISION.
      *
       PROGRAM-ID.  CUSTINQ1.
      *
      ************************************************************
      * CUSTOMER INQUIRY PROGRAM (INQ1 TRANSACTION)             *
      *                                                          *
      * THIS PROGRAM PROVIDES BASIC CUSTOMER INQUIRY CAPABILITY.*
      * THE USER ENTERS A CUSTOMER NUMBER AND THE PROGRAM       *
      * DISPLAYS THE CUSTOMER'S NAME AND ADDRESS INFORMATION.   *
      *                                                          *
      * ORIGINAL FROM: MURACH'S CICS FOR THE COBOL PROGRAMMER   *
      * CHAPTER 2 - BASIC CUSTOMER INQUIRY                      *
      ************************************************************
      *
       ENVIRONMENT DIVISION.
      *
       DATA DIVISION.
      *
       WORKING-STORAGE SECTION.
      *
       01  SWITCHES.
           05  VALID-DATA-SW             PIC X       VALUE 'Y'.
               88  VALID-DATA                        VALUE 'Y'.
      *
       01  COMMUNICATION-AREA            PIC X.
      *
       01  RESPONSE-CODE                 PIC S9(8)   COMP.
      *
       01  ERROR-MESSAGE-LINE.
           05  ERROR-TEXT                PIC X(78).
      *
      *    CUSTOMER MASTER RECORD
      *
       01  CUSTOMER-MASTER-RECORD.
           05  CM-CUSTOMER-NUMBER        PIC 9(6).
           05  CM-FIRST-NAME             PIC X(20).
           05  CM-LAST-NAME              PIC X(30).
           05  CM-ADDRESS                PIC X(30).
           05  CM-CITY                   PIC X(20).
           05  CM-STATE                  PIC XX.
           05  CM-ZIP-CODE               PIC X(10).
      *
       COPY INQSET1.
      *
       LINKAGE SECTION.
      *
       01  DFHCOMMAREA                   PIC X.
      *
       PROCEDURE DIVISION.
      *
       0000-PROCESS-CUSTOMER-INQUIRY.
      *
           EVALUATE TRUE
      *
               WHEN EIBCALEN = ZERO
                   MOVE LOW-VALUE TO INQMAP1O
                   MOVE -1 TO CUSTNOL
                   SET SEND-ERASE TO TRUE
                   PERFORM 1500-SEND-INQUIRY-MAP
      *
               WHEN EIBAID = DFHCLEAR
                   MOVE LOW-VALUE TO INQMAP1O
                   MOVE -1 TO CUSTNOL
                   SET SEND-ERASE TO TRUE
                   PERFORM 1500-SEND-INQUIRY-MAP
      *
               WHEN EIBAID = DFHPA1 OR DFHPA2 OR DFHPA3
                   CONTINUE
      *
               WHEN EIBAID = DFHPF3 OR DFHPF12
                   EXEC CICS
                       XCTL PROGRAM('INVMENU')
                   END-EXEC
      *
               WHEN OTHER
                   PERFORM 1000-PROCESS-INQUIRY-MAP
      *
           END-EVALUATE.
      *
           EXEC CICS
               RETURN TRANSID('INQ1')
                      COMMAREA(COMMUNICATION-AREA)
           END-EXEC.
      *
       1000-PROCESS-INQUIRY-MAP.
      *
           PERFORM 1100-RECEIVE-INQUIRY-MAP.
           PERFORM 1200-EDIT-INQUIRY-DATA.
           IF VALID-DATA
               PERFORM 1300-READ-CUSTOMER-RECORD
               IF VALID-DATA
                   PERFORM 1400-MOVE-CUSTOMER-DATA
               ELSE
                   MOVE 'CUSTOMER NOT FOUND' TO ERROR-TEXT
                   MOVE -1 TO CUSTNOL
               END-IF
           ELSE
               MOVE 'PLEASE ENTER A CUSTOMER NUMBER' TO ERROR-TEXT
               MOVE -1 TO CUSTNOL
           END-IF.
           PERFORM 1500-SEND-INQUIRY-MAP.
      *
       1100-RECEIVE-INQUIRY-MAP.
      *
           EXEC CICS
               RECEIVE MAP('INQMAP1')
                       MAPSET('INQSET1')
                       INTO(INQMAP1I)
           END-EXEC.
      *
       1200-EDIT-INQUIRY-DATA.
      *
           IF CUSTNOL = ZERO OR
              CUSTNOI = SPACE
               MOVE 'N' TO VALID-DATA-SW
           ELSE
               INSPECT CUSTNOI
                   REPLACING ALL '_' BY SPACE
               IF CUSTNOI IS NUMERIC
                   MOVE CUSTNOI TO CM-CUSTOMER-NUMBER
               ELSE
                   MOVE 'N' TO VALID-DATA-SW
               END-IF
           END-IF.
      *
       1300-READ-CUSTOMER-RECORD.
      *
           EXEC CICS
               READ FILE('CUSTMAS')
                    INTO(CUSTOMER-MASTER-RECORD)
                    RIDFLD(CM-CUSTOMER-NUMBER)
                    RESP(RESPONSE-CODE)
           END-EXEC.
      *
           IF RESPONSE-CODE NOT = DFHRESP(NORMAL)
               MOVE 'N' TO VALID-DATA-SW
           END-IF.
      *
       1400-MOVE-CUSTOMER-DATA.
      *
           MOVE CM-CUSTOMER-NUMBER TO CUSTNOO.
           MOVE CM-FIRST-NAME      TO FNAMEO.
           MOVE CM-LAST-NAME       TO LNAMEO.
           MOVE CM-ADDRESS         TO ADDRESSO.
           MOVE CM-CITY            TO CITYO.
           MOVE CM-STATE           TO STATEO.
           MOVE CM-ZIP-CODE        TO ZIPCODEO.
           MOVE 'CUSTOMER RECORD DISPLAYED' TO MESSAGEO.
      *
       1500-SEND-INQUIRY-MAP.
      *
           MOVE ERROR-TEXT TO MESSAGEO.
      *
           EXEC CICS
               SEND MAP('INQMAP1')
                    MAPSET('INQSET1')
                    FROM(INQMAP1O)
                    DATAONLY
                    CURSOR
           END-EXEC.
      *
           MOVE LOW-VALUE TO ERROR-MESSAGE-LINE.
           MOVE SPACE TO INQMAP1O.
           MOVE 'Y' TO VALID-DATA-SW.
