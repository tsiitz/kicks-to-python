       IDENTIFICATION DIVISION.
      *
       PROGRAM-ID.  CUSTINQ2.
      *
      ************************************************************
      * CUSTOMER INQUIRY PROGRAM WITH BROWSE (INQ2 TRANSACTION) *
      *                                                          *
      * THIS PROGRAM PROVIDES CUSTOMER INQUIRY WITH BROWSE      *
      * CAPABILITY. THE USER CAN:                                *
      *   - ENTER A CUSTOMER NUMBER FOR DIRECT ACCESS           *
      *   - PRESS PF5 TO SEE THE FIRST CUSTOMER                 *
      *   - PRESS PF6 TO SEE THE LAST CUSTOMER                  *
      *   - PRESS PF7 TO SEE THE PREVIOUS CUSTOMER              *
      *   - PRESS PF8 TO SEE THE NEXT CUSTOMER                  *
      *                                                          *
      * ORIGINAL FROM: MURACH'S CICS FOR THE COBOL PROGRAMMER   *
      * CHAPTER 14 - FILE BROWSING                              *
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
           05  BROWSE-STARTED-SW         PIC X       VALUE 'N'.
               88  BROWSE-STARTED                    VALUE 'Y'.
      *
       01  FLAGS.
           05  SEND-FLAG                 PIC X.
               88  SEND-ERASE                        VALUE '1'.
               88  SEND-DATAONLY                     VALUE '2'.
               88  SEND-DATAONLY-ALARM               VALUE '3'.
      *
       01  COMMUNICATION-AREA.
           05  CA-CONTEXT-FLAG           PIC X.
               88  FIRST-TIME                        VALUE SPACE.
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
       COPY INQSET2.
      *
       LINKAGE SECTION.
      *
       01  DFHCOMMAREA.
           05  DFHCOMMAREA-DATA          PIC X(7).
      *
       PROCEDURE DIVISION.
      *
       0000-PROCESS-CUSTOMER-INQUIRY.
      *
           EVALUATE TRUE
      *
               WHEN EIBCALEN = ZERO
                   MOVE LOW-VALUE TO INQMAP2O
                   MOVE -1 TO CUSTNOL
                   SET SEND-ERASE TO TRUE
                   PERFORM 1500-SEND-INQUIRY-MAP
      *
               WHEN EIBAID = DFHCLEAR
                   MOVE LOW-VALUE TO INQMAP2O
                   MOVE -1 TO CUSTNOL
                   SET SEND-ERASE TO TRUE
                   PERFORM 1500-SEND-INQUIRY-MAP
      *
               WHEN EIBAID = DFHPA1 OR DFHPA2 OR DFHPA3
                   CONTINUE
      *
               WHEN EIBAID = DFHPF3 OR DFHPF12
                   IF BROWSE-STARTED
                       PERFORM 1600-END-BROWSE
                   END-IF
                   EXEC CICS
                       XCTL PROGRAM('INVMENU')
                   END-EXEC
      *
               WHEN EIBAID = DFHPF5
                   PERFORM 2000-GET-FIRST-CUSTOMER
                   PERFORM 1400-MOVE-CUSTOMER-DATA
                   PERFORM 1500-SEND-INQUIRY-MAP
      *
               WHEN EIBAID = DFHPF6
                   PERFORM 2100-GET-LAST-CUSTOMER
                   PERFORM 1400-MOVE-CUSTOMER-DATA
                   PERFORM 1500-SEND-INQUIRY-MAP
      *
               WHEN EIBAID = DFHPF7
                   PERFORM 2200-GET-PREVIOUS-CUSTOMER
                   PERFORM 1400-MOVE-CUSTOMER-DATA
                   PERFORM 1500-SEND-INQUIRY-MAP
      *
               WHEN EIBAID = DFHPF8
                   PERFORM 2300-GET-NEXT-CUSTOMER
                   PERFORM 1400-MOVE-CUSTOMER-DATA
                   PERFORM 1500-SEND-INQUIRY-MAP
      *
               WHEN OTHER
                   PERFORM 1000-PROCESS-INQUIRY-MAP
      *
           END-EVALUATE.
      *
           EXEC CICS
               RETURN TRANSID('INQ2')
                      COMMAREA(COMMUNICATION-AREA)
           END-EXEC.
      *
       1000-PROCESS-INQUIRY-MAP.
      *
           PERFORM 1100-RECEIVE-INQUIRY-MAP.
           PERFORM 1200-EDIT-INQUIRY-DATA.
           IF VALID-DATA
               PERFORM 1300-READ-CUSTOMER-RECORD
               IF CUSTOMER-FOUND
                   PERFORM 1400-MOVE-CUSTOMER-DATA
                   MOVE CM-CUSTOMER-NUMBER TO CA-CUSTOMER-NUMBER
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
               RECEIVE MAP('INQMAP2')
                       MAPSET('INQSET2')
                       INTO(INQMAP2I)
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
           IF RESPONSE-CODE = DFHRESP(NORMAL)
               MOVE 'Y' TO CUSTOMER-FOUND-SW
           ELSE
               MOVE 'N' TO CUSTOMER-FOUND-SW
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
           MOVE CM-CUSTOMER-NUMBER TO CA-CUSTOMER-NUMBER.
      *
       1500-SEND-INQUIRY-MAP.
      *
           IF ERROR-TEXT NOT = SPACE
               MOVE ERROR-TEXT TO MESSAGEO
               SET SEND-DATAONLY-ALARM TO TRUE
           ELSE
               SET SEND-DATAONLY TO TRUE
           END-IF.
      *
           EVALUATE TRUE
               WHEN SEND-ERASE
                   EXEC CICS
                       SEND MAP('INQMAP2')
                            MAPSET('INQSET2')
                            FROM(INQMAP2O)
                            ERASE
                            CURSOR
                   END-EXEC
               WHEN SEND-DATAONLY-ALARM
                   EXEC CICS
                       SEND MAP('INQMAP2')
                            MAPSET('INQSET2')
                            FROM(INQMAP2O)
                            DATAONLY
                            ALARM
                            CURSOR
                   END-EXEC
               WHEN SEND-DATAONLY
                   EXEC CICS
                       SEND MAP('INQMAP2')
                            MAPSET('INQSET2')
                            FROM(INQMAP2O)
                            DATAONLY
                            CURSOR
                   END-EXEC
           END-EVALUATE.
      *
           MOVE LOW-VALUE TO ERROR-MESSAGE-LINE.
           MOVE SPACE TO INQMAP2O.
           MOVE 'Y' TO VALID-DATA-SW.
      *
       1600-END-BROWSE.
      *
           EXEC CICS
               ENDBR FILE('CUSTMAS')
           END-EXEC.
           MOVE 'N' TO BROWSE-STARTED-SW.
      *
       2000-GET-FIRST-CUSTOMER.
      *
           MOVE ZERO TO CM-CUSTOMER-NUMBER.
      *
           IF BROWSE-STARTED
               PERFORM 1600-END-BROWSE
           END-IF.
      *
           EXEC CICS
               STARTBR FILE('CUSTMAS')
                       RIDFLD(CM-CUSTOMER-NUMBER)
                       GTEQ
                       RESP(RESPONSE-CODE)
           END-EXEC.
      *
           IF RESPONSE-CODE = DFHRESP(NORMAL)
               MOVE 'Y' TO BROWSE-STARTED-SW
               EXEC CICS
                   READNEXT FILE('CUSTMAS')
                            INTO(CUSTOMER-MASTER-RECORD)
                            RIDFLD(CM-CUSTOMER-NUMBER)
                            RESP(RESPONSE-CODE)
               END-EXEC
               IF RESPONSE-CODE = DFHRESP(NORMAL)
                   MOVE 'Y' TO CUSTOMER-FOUND-SW
               ELSE
                   MOVE 'N' TO CUSTOMER-FOUND-SW
                   MOVE 'NO CUSTOMERS ON FILE' TO ERROR-TEXT
               END-IF
           ELSE
               MOVE 'N' TO CUSTOMER-FOUND-SW
               MOVE 'ERROR STARTING BROWSE' TO ERROR-TEXT
           END-IF.
      *
       2100-GET-LAST-CUSTOMER.
      *
           MOVE HIGH-VALUE TO CM-CUSTOMER-NUMBER.
      *
           IF BROWSE-STARTED
               PERFORM 1600-END-BROWSE
           END-IF.
      *
           EXEC CICS
               STARTBR FILE('CUSTMAS')
                       RIDFLD(CM-CUSTOMER-NUMBER)
                       GTEQ
                       RESP(RESPONSE-CODE)
           END-EXEC.
      *
           IF RESPONSE-CODE = DFHRESP(NORMAL) OR
              RESPONSE-CODE = DFHRESP(NOTFND)
               MOVE 'Y' TO BROWSE-STARTED-SW
               EXEC CICS
                   READPREV FILE('CUSTMAS')
                            INTO(CUSTOMER-MASTER-RECORD)
                            RIDFLD(CM-CUSTOMER-NUMBER)
                            RESP(RESPONSE-CODE)
               END-EXEC
               IF RESPONSE-CODE = DFHRESP(NORMAL)
                   MOVE 'Y' TO CUSTOMER-FOUND-SW
               ELSE
                   MOVE 'N' TO CUSTOMER-FOUND-SW
                   MOVE 'NO CUSTOMERS ON FILE' TO ERROR-TEXT
               END-IF
           ELSE
               MOVE 'N' TO CUSTOMER-FOUND-SW
               MOVE 'ERROR STARTING BROWSE' TO ERROR-TEXT
           END-IF.
      *
       2200-GET-PREVIOUS-CUSTOMER.
      *
           MOVE CA-CUSTOMER-NUMBER TO CM-CUSTOMER-NUMBER.
      *
           IF BROWSE-STARTED
               PERFORM 1600-END-BROWSE
           END-IF.
      *
           EXEC CICS
               STARTBR FILE('CUSTMAS')
                       RIDFLD(CM-CUSTOMER-NUMBER)
                       GTEQ
                       RESP(RESPONSE-CODE)
           END-EXEC.
      *
           IF RESPONSE-CODE = DFHRESP(NORMAL)
               MOVE 'Y' TO BROWSE-STARTED-SW
               EXEC CICS
                   READPREV FILE('CUSTMAS')
                            INTO(CUSTOMER-MASTER-RECORD)
                            RIDFLD(CM-CUSTOMER-NUMBER)
                            RESP(RESPONSE-CODE)
               END-EXEC
               IF RESPONSE-CODE = DFHRESP(NORMAL)
                   MOVE 'Y' TO CUSTOMER-FOUND-SW
               ELSE
                   MOVE 'N' TO CUSTOMER-FOUND-SW
                   MOVE 'BEGINNING OF FILE REACHED' TO ERROR-TEXT
                   MOVE CA-CUSTOMER-NUMBER TO CM-CUSTOMER-NUMBER
                   PERFORM 1300-READ-CUSTOMER-RECORD
               END-IF
           ELSE
               MOVE 'N' TO CUSTOMER-FOUND-SW
               MOVE 'ERROR STARTING BROWSE' TO ERROR-TEXT
           END-IF.
      *
       2300-GET-NEXT-CUSTOMER.
      *
           MOVE CA-CUSTOMER-NUMBER TO CM-CUSTOMER-NUMBER.
      *
           IF BROWSE-STARTED
               PERFORM 1600-END-BROWSE
           END-IF.
      *
           EXEC CICS
               STARTBR FILE('CUSTMAS')
                       RIDFLD(CM-CUSTOMER-NUMBER)
                       GTEQ
                       RESP(RESPONSE-CODE)
           END-EXEC.
      *
           IF RESPONSE-CODE = DFHRESP(NORMAL)
               MOVE 'Y' TO BROWSE-STARTED-SW
      *        SKIP CURRENT RECORD
               EXEC CICS
                   READNEXT FILE('CUSTMAS')
                            INTO(CUSTOMER-MASTER-RECORD)
                            RIDFLD(CM-CUSTOMER-NUMBER)
                            RESP(RESPONSE-CODE)
               END-EXEC
      *        GET NEXT RECORD
               EXEC CICS
                   READNEXT FILE('CUSTMAS')
                            INTO(CUSTOMER-MASTER-RECORD)
                            RIDFLD(CM-CUSTOMER-NUMBER)
                            RESP(RESPONSE-CODE)
               END-EXEC
               IF RESPONSE-CODE = DFHRESP(NORMAL)
                   MOVE 'Y' TO CUSTOMER-FOUND-SW
               ELSE
                   MOVE 'N' TO CUSTOMER-FOUND-SW
                   MOVE 'END OF FILE REACHED' TO ERROR-TEXT
                   MOVE CA-CUSTOMER-NUMBER TO CM-CUSTOMER-NUMBER
                   PERFORM 1300-READ-CUSTOMER-RECORD
               END-IF
           ELSE
               MOVE 'N' TO CUSTOMER-FOUND-SW
               MOVE 'ERROR STARTING BROWSE' TO ERROR-TEXT
           END-IF.
