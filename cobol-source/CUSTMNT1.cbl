       IDENTIFICATION DIVISION.
      *
       PROGRAM-ID.  CUSTMNT1.
      *
      ************************************************************
      * CUSTOMER MAINTENANCE PROGRAM (MNT1 TRANSACTION)         *
      *                                                          *
      * THIS PROGRAM PROVIDES CUSTOMER MAINTENANCE FUNCTIONS:   *
      *   ACTION CODE 1 = ADD NEW CUSTOMER                      *
      *   ACTION CODE 2 = CHANGE EXISTING CUSTOMER              *
      *   ACTION CODE 3 = DELETE EXISTING CUSTOMER              *
      *                                                          *
      * TWO-SCREEN PSEUDO-CONVERSATIONAL DESIGN:                *
      *   SCREEN 1: ENTER CUSTOMER NUMBER AND ACTION CODE       *
      *   SCREEN 2: DISPLAY/EDIT CUSTOMER DATA                  *
      *                                                          *
      * ORIGINAL FROM: MURACH'S CICS FOR THE COBOL PROGRAMMER   *
      * CHAPTER 5 - CUSTOMER MAINTENANCE                        *
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
           05  CUSTOMER-FOUND-SW         PIC X       VALUE 'Y'.
               88  CUSTOMER-FOUND                    VALUE 'Y'.
      *
       01  FLAGS.
           05  SEND-FLAG                 PIC X.
               88  SEND-ERASE                        VALUE '1'.
               88  SEND-DATAONLY                     VALUE '2'.
               88  SEND-DATAONLY-ALARM               VALUE '3'.
      *
       01  COMMUNICATION-AREA.
           05  CA-CONTEXT-FLAG           PIC X.
               88  PROCESS-KEY-MAP                   VALUE '1'.
               88  PROCESS-ADD-CUSTOMER              VALUE '2'.
               88  PROCESS-CHANGE-CUSTOMER           VALUE '3'.
               88  PROCESS-DELETE-CUSTOMER           VALUE '4'.
           05  CA-CUSTOMER-NUMBER        PIC 9(6).
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
       COPY MNTSET1.
      *
       LINKAGE SECTION.
      *
       01  DFHCOMMAREA.
           05  DFHCOMMAREA-DATA          PIC X(7).
      *
       PROCEDURE DIVISION.
      *
       0000-PROCESS-CUSTOMER-MAINT.
      *
           EVALUATE TRUE
      *
               WHEN EIBCALEN = ZERO
                   MOVE LOW-VALUE TO MNTMAP1O
                   MOVE -1 TO CUSTNOL
                   SET SEND-ERASE TO TRUE
                   MOVE '1' TO CA-CONTEXT-FLAG
                   PERFORM 1500-SEND-KEY-MAP
      *
               WHEN EIBAID = DFHCLEAR
                   MOVE LOW-VALUE TO MNTMAP1O
                   MOVE -1 TO CUSTNOL
                   SET SEND-ERASE TO TRUE
                   MOVE '1' TO CA-CONTEXT-FLAG
                   PERFORM 1500-SEND-KEY-MAP
      *
               WHEN EIBAID = DFHPA1 OR DFHPA2 OR DFHPA3
                   CONTINUE
      *
               WHEN EIBAID = DFHPF3
                   EXEC CICS
                       XCTL PROGRAM('INVMENU')
                   END-EXEC
      *
               WHEN EIBAID = DFHPF12
                   MOVE LOW-VALUE TO MNTMAP1O
                   MOVE -1 TO CUSTNOL
                   SET SEND-ERASE TO TRUE
                   MOVE '1' TO CA-CONTEXT-FLAG
                   PERFORM 1500-SEND-KEY-MAP
      *
               WHEN PROCESS-KEY-MAP
                   PERFORM 1000-PROCESS-KEY-MAP
      *
               WHEN PROCESS-ADD-CUSTOMER
                   PERFORM 2000-PROCESS-ADD-CUSTOMER
      *
               WHEN PROCESS-CHANGE-CUSTOMER
                   PERFORM 3000-PROCESS-CHANGE-CUSTOMER
      *
               WHEN PROCESS-DELETE-CUSTOMER
                   PERFORM 4000-PROCESS-DELETE-CUSTOMER
      *
               WHEN OTHER
                   MOVE LOW-VALUE TO MNTMAP1O
                   MOVE -1 TO CUSTNOL
                   SET SEND-ERASE TO TRUE
                   MOVE '1' TO CA-CONTEXT-FLAG
                   PERFORM 1500-SEND-KEY-MAP
      *
           END-EVALUATE.
      *
           EXEC CICS
               RETURN TRANSID('MNT1')
                      COMMAREA(COMMUNICATION-AREA)
           END-EXEC.
      *
       1000-PROCESS-KEY-MAP.
      *
      *    FIRST SCREEN - GET CUSTOMER NUMBER AND ACTION CODE
      *
           PERFORM 1100-RECEIVE-KEY-MAP.
           PERFORM 1200-EDIT-KEY-DATA.
      *
           IF VALID-DATA
               PERFORM 1300-READ-CUSTOMER-RECORD
               EVALUATE ACTIONI
                   WHEN '1'
                       IF CUSTOMER-FOUND
                           MOVE 'CUSTOMER ALREADY EXISTS' TO ERROR-TEXT
                           MOVE -1 TO CUSTNOL
                           SET SEND-DATAONLY-ALARM TO TRUE
                           PERFORM 1500-SEND-KEY-MAP
                       ELSE
                           MOVE '2' TO CA-CONTEXT-FLAG
                           PERFORM 2100-SEND-ADD-MAP
                       END-IF
                   WHEN '2'
                       IF CUSTOMER-FOUND
                           MOVE '3' TO CA-CONTEXT-FLAG
                           PERFORM 3100-SEND-CHANGE-MAP
                       ELSE
                           MOVE 'CUSTOMER NOT FOUND' TO ERROR-TEXT
                           MOVE -1 TO CUSTNOL
                           SET SEND-DATAONLY-ALARM TO TRUE
                           PERFORM 1500-SEND-KEY-MAP
                       END-IF
                   WHEN '3'
                       IF CUSTOMER-FOUND
                           MOVE '4' TO CA-CONTEXT-FLAG
                           PERFORM 4100-SEND-DELETE-MAP
                       ELSE
                           MOVE 'CUSTOMER NOT FOUND' TO ERROR-TEXT
                           MOVE -1 TO CUSTNOL
                           SET SEND-DATAONLY-ALARM TO TRUE
                           PERFORM 1500-SEND-KEY-MAP
                       END-IF
                   WHEN OTHER
                       MOVE 'INVALID ACTION CODE' TO ERROR-TEXT
                       MOVE -1 TO ACTIONL
                       SET SEND-DATAONLY-ALARM TO TRUE
                       PERFORM 1500-SEND-KEY-MAP
               END-EVALUATE
           ELSE
               SET SEND-DATAONLY-ALARM TO TRUE
               PERFORM 1500-SEND-KEY-MAP
           END-IF.
      *
       1100-RECEIVE-KEY-MAP.
      *
           EXEC CICS
               RECEIVE MAP('MNTMAP1')
                       MAPSET('MNTSET1')
                       INTO(MNTMAP1I)
           END-EXEC.
      *
       1200-EDIT-KEY-DATA.
      *
           MOVE 'Y' TO VALID-DATA-SW.
      *
           IF CUSTNOL = ZERO OR CUSTNOI = SPACE
               MOVE 'CUSTOMER NUMBER IS REQUIRED' TO ERROR-TEXT
               MOVE -1 TO CUSTNOL
               MOVE 'N' TO VALID-DATA-SW
           ELSE
               IF CUSTNOI IS NUMERIC
                   MOVE CUSTNOI TO CM-CUSTOMER-NUMBER
                   MOVE CM-CUSTOMER-NUMBER TO CA-CUSTOMER-NUMBER
               ELSE
                   MOVE 'CUSTOMER NUMBER MUST BE NUMERIC' TO ERROR-TEXT
                   MOVE -1 TO CUSTNOL
                   MOVE 'N' TO VALID-DATA-SW
               END-IF
           END-IF.
      *
           IF ACTIONL = ZERO OR ACTIONI = SPACE
               MOVE 'ACTION CODE IS REQUIRED' TO ERROR-TEXT
               MOVE -1 TO ACTIONL
               MOVE 'N' TO VALID-DATA-SW
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
           IF RESPONSE-CODE = DFHRESP(NORMAL)
               MOVE 'Y' TO CUSTOMER-FOUND-SW
           ELSE
               MOVE 'N' TO CUSTOMER-FOUND-SW
           END-IF.
      *
       1500-SEND-KEY-MAP.
      *
           IF ERROR-TEXT NOT = SPACE
               MOVE ERROR-TEXT TO MESSAGEO
           END-IF.
      *
           EVALUATE TRUE
               WHEN SEND-ERASE
                   EXEC CICS
                       SEND MAP('MNTMAP1')
                            MAPSET('MNTSET1')
                            FROM(MNTMAP1O)
                            ERASE
                            CURSOR
                   END-EXEC
               WHEN SEND-DATAONLY-ALARM
                   EXEC CICS
                       SEND MAP('MNTMAP1')
                            MAPSET('MNTSET1')
                            FROM(MNTMAP1O)
                            DATAONLY
                            ALARM
                            CURSOR
                   END-EXEC
               WHEN SEND-DATAONLY
                   EXEC CICS
                       SEND MAP('MNTMAP1')
                            MAPSET('MNTSET1')
                            FROM(MNTMAP1O)
                            DATAONLY
                            CURSOR
                   END-EXEC
           END-EVALUATE.
      *
           MOVE LOW-VALUE TO ERROR-MESSAGE-LINE.
           MOVE SPACE TO MNTMAP1O.
      *
       2000-PROCESS-ADD-CUSTOMER.
      *
      *    SECOND SCREEN - ADD NEW CUSTOMER
      *
           PERFORM 2200-RECEIVE-DETAIL-MAP.
           PERFORM 2300-EDIT-CUSTOMER-DATA.
      *
           IF VALID-DATA
               PERFORM 2400-WRITE-CUSTOMER-RECORD
               MOVE 'CUSTOMER ADDED SUCCESSFULLY' TO ERROR-TEXT
               MOVE '1' TO CA-CONTEXT-FLAG
               SET SEND-DATAONLY TO TRUE
               PERFORM 1500-SEND-KEY-MAP
           ELSE
               SET SEND-DATAONLY-ALARM TO TRUE
               PERFORM 2100-SEND-ADD-MAP
           END-IF.
      *
       2100-SEND-ADD-MAP.
      *
           MOVE LOW-VALUE TO MNTMAP2O.
           MOVE CA-CUSTOMER-NUMBER TO CUSTNOO.
           MOVE 'ADD NEW CUSTOMER' TO INSTRUCTO.
           MOVE -1 TO FNAMEL.
      *
           IF ERROR-TEXT NOT = SPACE
               MOVE ERROR-TEXT TO MESSAGEO
           END-IF.
      *
           EXEC CICS
               SEND MAP('MNTMAP2')
                    MAPSET('MNTSET1')
                    FROM(MNTMAP2O)
                    ERASE
                    CURSOR
           END-EXEC.
      *
           MOVE LOW-VALUE TO ERROR-MESSAGE-LINE.
      *
       2200-RECEIVE-DETAIL-MAP.
      *
           EXEC CICS
               RECEIVE MAP('MNTMAP2')
                       MAPSET('MNTSET1')
                       INTO(MNTMAP2I)
           END-EXEC.
      *
       2300-EDIT-CUSTOMER-DATA.
      *
           MOVE 'Y' TO VALID-DATA-SW.
           MOVE CA-CUSTOMER-NUMBER TO CM-CUSTOMER-NUMBER.
      *
           IF FNAMEL = ZERO OR FNAMEI = SPACE
               MOVE 'FIRST NAME IS REQUIRED' TO ERROR-TEXT
               MOVE -1 TO FNAMEL
               MOVE 'N' TO VALID-DATA-SW
           ELSE
               MOVE FNAMEI TO CM-FIRST-NAME
           END-IF.
      *
           IF LNAMEL = ZERO OR LNAMEI = SPACE
               MOVE 'LAST NAME IS REQUIRED' TO ERROR-TEXT
               MOVE -1 TO LNAMEL
               MOVE 'N' TO VALID-DATA-SW
           ELSE
               MOVE LNAMEI TO CM-LAST-NAME
           END-IF.
      *
           MOVE ADDRESSI TO CM-ADDRESS.
           MOVE CITYI TO CM-CITY.
           MOVE STATEI TO CM-STATE.
           MOVE ZIPCODEI TO CM-ZIP-CODE.
      *
       2400-WRITE-CUSTOMER-RECORD.
      *
           EXEC CICS
               WRITE FILE('CUSTMAS')
                     FROM(CUSTOMER-MASTER-RECORD)
                     RIDFLD(CM-CUSTOMER-NUMBER)
           END-EXEC.
      *
       3000-PROCESS-CHANGE-CUSTOMER.
      *
      *    SECOND SCREEN - CHANGE EXISTING CUSTOMER
      *
           PERFORM 2200-RECEIVE-DETAIL-MAP.
           PERFORM 2300-EDIT-CUSTOMER-DATA.
      *
           IF VALID-DATA
               PERFORM 3200-REWRITE-CUSTOMER-RECORD
               MOVE 'CUSTOMER CHANGED SUCCESSFULLY' TO ERROR-TEXT
               MOVE '1' TO CA-CONTEXT-FLAG
               SET SEND-DATAONLY TO TRUE
               PERFORM 1500-SEND-KEY-MAP
           ELSE
               SET SEND-DATAONLY-ALARM TO TRUE
               PERFORM 3100-SEND-CHANGE-MAP
           END-IF.
      *
       3100-SEND-CHANGE-MAP.
      *
           MOVE LOW-VALUE TO MNTMAP2O.
           MOVE CM-CUSTOMER-NUMBER TO CUSTNOO.
           MOVE CM-FIRST-NAME TO FNAMEO.
           MOVE CM-LAST-NAME TO LNAMEO.
           MOVE CM-ADDRESS TO ADDRESSO.
           MOVE CM-CITY TO CITYO.
           MOVE CM-STATE TO STATEO.
           MOVE CM-ZIP-CODE TO ZIPCODEO.
           MOVE 'CHANGE CUSTOMER' TO INSTRUCTO.
           MOVE -1 TO FNAMEL.
      *
           IF ERROR-TEXT NOT = SPACE
               MOVE ERROR-TEXT TO MESSAGEO
           END-IF.
      *
           EXEC CICS
               SEND MAP('MNTMAP2')
                    MAPSET('MNTSET1')
                    FROM(MNTMAP2O)
                    ERASE
                    CURSOR
           END-EXEC.
      *
           MOVE LOW-VALUE TO ERROR-MESSAGE-LINE.
      *
       3200-REWRITE-CUSTOMER-RECORD.
      *
           EXEC CICS
               REWRITE FILE('CUSTMAS')
                       FROM(CUSTOMER-MASTER-RECORD)
                       RIDFLD(CM-CUSTOMER-NUMBER)
           END-EXEC.
      *
       4000-PROCESS-DELETE-CUSTOMER.
      *
      *    SECOND SCREEN - DELETE CUSTOMER
      *
           PERFORM 4200-DELETE-CUSTOMER-RECORD.
           MOVE 'CUSTOMER DELETED SUCCESSFULLY' TO ERROR-TEXT.
           MOVE '1' TO CA-CONTEXT-FLAG.
           SET SEND-DATAONLY TO TRUE.
           PERFORM 1500-SEND-KEY-MAP.
      *
       4100-SEND-DELETE-MAP.
      *
           MOVE LOW-VALUE TO MNTMAP2O.
           MOVE CM-CUSTOMER-NUMBER TO CUSTNOO.
           MOVE CM-FIRST-NAME TO FNAMEO.
           MOVE CM-LAST-NAME TO LNAMEO.
           MOVE CM-ADDRESS TO ADDRESSO.
           MOVE CM-CITY TO CITYO.
           MOVE CM-STATE TO STATEO.
           MOVE CM-ZIP-CODE TO ZIPCODEO.
           MOVE 'DELETE CUSTOMER - PRESS ENTER TO CONFIRM' 
               TO INSTRUCTO.
           MOVE -1 TO CUSTNOL.
      *
           EXEC CICS
               SEND MAP('MNTMAP2')
                    MAPSET('MNTSET1')
                    FROM(MNTMAP2O)
                    ERASE
                    CURSOR
           END-EXEC.
      *
       4200-DELETE-CUSTOMER-RECORD.
      *
           EXEC CICS
               DELETE FILE('CUSTMAS')
                      RIDFLD(CM-CUSTOMER-NUMBER)
           END-EXEC.
