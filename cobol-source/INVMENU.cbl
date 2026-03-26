       IDENTIFICATION DIVISION.
      *
       PROGRAM-ID.  INVMENU.
      *
      ************************************************************
      * APPLICATION MENU PROGRAM (MENU TRANSACTION)             *
      *                                                          *
      * THIS PROGRAM DISPLAYS THE MAIN MENU FOR THE CUSTOMER    *
      * INQUIRY AND MAINTENANCE APPLICATION SUITE.              *
      *                                                          *
      * AVAILABLE TRANSACTIONS:                                 *
      *   1 = CUSTOMER INQUIRY (INQ1)                           *
      *   2 = CUSTOMER MAINTENANCE (MNT2)                       *
      *   3 = ORDER ENTRY (ORD1)                                *
      *                                                          *
      * ORIGINAL FROM: MURACH'S CICS FOR THE COBOL PROGRAMMER   *
      * CHAPTER 11 - MENU PROCESSING                            *
      ************************************************************
      *
       ENVIRONMENT DIVISION.
      *
       DATA DIVISION.
      *
       WORKING-STORAGE SECTION.
      *
       01  COMMUNICATION-AREA            PIC X.
      *
       01  ERROR-MESSAGE-LINE.
           05  ERROR-TEXT                PIC X(78).
      *
       COPY MENSET1.
      *
       LINKAGE SECTION.
      *
       01  DFHCOMMAREA                   PIC X.
      *
       PROCEDURE DIVISION.
      *
       0000-PROCESS-MENU-SCREEN.
      *
           EVALUATE TRUE
      *
               WHEN EIBCALEN = ZERO
                   MOVE LOW-VALUE TO MENMAP1O
                   MOVE -1 TO OPTIONL
                   PERFORM 1500-SEND-MENU-MAP
      *
               WHEN EIBAID = DFHCLEAR
                   EXEC CICS
                       SEND CONTROL
                            ERASE
                            FREEKB
                   END-EXEC
                   EXEC CICS
                       RETURN
                   END-EXEC
      *
               WHEN EIBAID = DFHPA1 OR DFHPA2 OR DFHPA3
                   CONTINUE
      *
               WHEN EIBAID = DFHPF3 OR DFHPF12
                   EXEC CICS
                       SEND CONTROL
                            ERASE
                            FREEKB
                   END-EXEC
                   EXEC CICS
                       RETURN
                   END-EXEC
      *
               WHEN OTHER
                   PERFORM 1000-PROCESS-MENU-SELECTION
      *
           END-EVALUATE.
      *
           EXEC CICS
               RETURN TRANSID('MENU')
                      COMMAREA(COMMUNICATION-AREA)
           END-EXEC.
      *
       1000-PROCESS-MENU-SELECTION.
      *
           PERFORM 1100-RECEIVE-MENU-MAP.
           PERFORM 1200-PROCESS-OPTION.
      *
       1100-RECEIVE-MENU-MAP.
      *
           EXEC CICS
               RECEIVE MAP('MENMAP1')
                       MAPSET('MENSET1')
                       INTO(MENMAP1I)
           END-EXEC.
      *
       1200-PROCESS-OPTION.
      *
           IF OPTIONL NOT = ZERO
               EVALUATE OPTIONI
                   WHEN '1'
                       EXEC CICS
                           XCTL PROGRAM('CUSTINQ2')
                       END-EXEC
                   WHEN '2'
                       EXEC CICS
                           XCTL PROGRAM('CUSTMNT2')
                       END-EXEC
                   WHEN '3'
                       EXEC CICS
                           XCTL PROGRAM('ORDRENT')
                       END-EXEC
                   WHEN OTHER
                       MOVE 'INVALID OPTION - PLEASE ENTER 1, 2, OR 3'
                           TO ERROR-TEXT
                       MOVE -1 TO OPTIONL
                       PERFORM 1500-SEND-MENU-MAP
               END-EVALUATE
           ELSE
               MOVE 'PLEASE SELECT AN OPTION' TO ERROR-TEXT
               MOVE -1 TO OPTIONL
               PERFORM 1500-SEND-MENU-MAP
           END-IF.
      *
       1500-SEND-MENU-MAP.
      *
           IF ERROR-TEXT NOT = SPACE
               MOVE ERROR-TEXT TO MESSAGEO
           ELSE
               MOVE SPACE TO MESSAGEO
           END-IF.
      *
           EXEC CICS
               SEND MAP('MENMAP1')
                    MAPSET('MENSET1')
                    FROM(MENMAP1O)
                    ERASE
                    CURSOR
           END-EXEC.
      *
           MOVE LOW-VALUE TO ERROR-MESSAGE-LINE.
           MOVE SPACE TO MENMAP1O.
