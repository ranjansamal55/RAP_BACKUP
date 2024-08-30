CLASS lhc_ZIFV_CDS_TRAVEL DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zifv_cds_travel RESULT result.
    METHODS accepttravel FOR MODIFY
      IMPORTING keys FOR ACTION zifv_cds_travel~accepttravel RESULT result.

    METHODS copytravel FOR MODIFY
      IMPORTING keys FOR ACTION zifv_cds_travel~copytravel.

    METHODS recalctotprice FOR MODIFY
      IMPORTING keys FOR ACTION zifv_cds_travel~recalctotprice.

    METHODS rejecttravel FOR MODIFY
      IMPORTING keys FOR ACTION zifv_cds_travel~rejecttravel RESULT result.

    METHODS earlynumbering_cba_booking FOR NUMBERING
      IMPORTING entities FOR CREATE zifv_cds_travel\_booking.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE zifv_cds_travel.

ENDCLASS.

CLASS lhc_ZIFV_CDS_TRAVEL IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA(lt_entities) = entities.

    DELETE lt_entities WHERE TravelId IS NOT INITIAL.
    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING
            nr_range_nr       = '01'
            object            = '/DMO/TRV_M'
            quantity          = CONV #( lines( lt_entities ) )
          IMPORTING
            number            =  DATA(lv_latest_num)
            returncode        =  DATA(lv_code)
            returned_quantity =  DATA(lv_qty)
        ).
      CATCH cx_nr_object_not_found.
      CATCH cx_number_ranges INTO DATA(lo_error).

        LOOP AT lt_entities  INTO DATA(ls_entities).
          APPEND VALUE #( %cid =  ls_entities-%cid
                          %key = ls_entities-%key  )
                 TO failed-zifv_cds_travel.
          APPEND VALUE #( %cid =  ls_entities-%cid
                          %key = ls_entities-%key
                          %msg =  lo_error )
                 TO reported-zifv_cds_travel.

        ENDLOOP.
        EXIT.
    ENDTRY.
    ASSERT lv_qty = lines( lt_entities ).
*    DATA: lt_travel_tech_m TYPE TABLE FOR MAPPED EARLY yi_travel_tech_m,
*          ls_travel_tech_m LIKE LINE OF lt_travel_tech_m.
    DATA(lv_curr_num)   =  lv_latest_num - lv_qty.

    LOOP AT lt_entities  INTO ls_entities.

      lv_curr_num = lv_curr_num + 1.
*      ls_travel_tech_m = VALUE #( %cid =  ls_entities-%cid
*                                  TravelId = lv_curr_num
*       ) .
*      APPEND ls_travel_tech_m TO mapped-yi_travel_tech_m.

      APPEND VALUE #( %cid =  ls_entities-%cid
                      TravelId = lv_curr_num  )
               TO mapped-zifv_cds_travel.
    ENDLOOP.

  ENDMETHOD.

  METHOD earlynumbering_cba_Booking.

    DATA : lv_max_booking TYPE /dmo/booking_id.

    READ ENTITIES OF zifv_cds_travel IN LOCAL MODE
     ENTITY zifv_cds_travel BY \_Booking
     FROM CORRESPONDING #( entities )
     LINK DATA(lt_link_data).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_group_entity>)
                               GROUP BY <ls_group_entity>-TravelId .

      lv_max_booking = REDUCE #( INIT lv_max = CONV /dmo/booking_id( '0' )
                                 FOR ls_link IN lt_link_data USING KEY entity
                                      WHERE ( source-TravelId = <ls_group_entity>-TravelId  )
                                 NEXT  lv_max = COND  /dmo/booking_id( WHEN lv_max < ls_link-target-BookingId
                                                                       THEN ls_link-target-BookingId
                                                                        ELSE lv_max ) ).
      lv_max_booking  = REDUCE #( INIT lv_max = lv_max_booking
                                   FOR ls_entity IN entities USING KEY entity
                                       WHERE ( TravelId = <ls_group_entity>-TravelId  )
                                     FOR ls_booking IN ls_entity-%target
                                     NEXT lv_max = COND  /dmo/booking_id( WHEN lv_max < ls_booking-BookingId
                                                                        THEN ls_booking-BookingId
                                                                         ELSE lv_max )
       ).

      LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entities>)
                        USING KEY entity
                         WHERE TravelId = <ls_group_entity>-TravelId.

        LOOP AT <ls_entities>-%target ASSIGNING FIELD-SYMBOL(<ls_booking>).
          APPEND CORRESPONDING #( <ls_booking> )  TO   mapped-zifv_cds_booking
             ASSIGNING FIELD-SYMBOL(<ls_new_map_book>).
          IF <ls_booking>-BookingId IS INITIAL.
            lv_max_booking += 10.

            <ls_new_map_book>-BookingId = lv_max_booking.
          ENDIF.

        ENDLOOP.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

  METHOD acceptTravel.
  MODIFY ENTITIES OF zifv_cds_travel IN LOCAL MODE
  ENTITY zifv_cds_travel
   UPDATE FIELDS ( OverallStatus )
   WITH VALUE #( FOR ls_keys IN keys ( %tky = ls_keys-%tky
                                       OverallStatus = 'A' ) ).

  READ ENTITIES OF zifv_cds_travel  IN LOCAL MODE
  ENTITY zifv_cds_travel
  ALL FIELDS WITH CORRESPONDING #( keys )
  RESULT DATA(lt_result).
  .

  result  = VALUE #( FOR ls_result IN lt_result ( %tky = ls_result-%tky
                                               %param  =  ls_result ) ).

  ENDMETHOD.

  METHOD copyTravel.

    DATA: it_travel        TYPE TABLE FOR CREATE zifv_cds_travel,
          it_booking_cba   TYPE TABLE FOR CREATE zifv_cds_travel\_Booking,
          it_booksuppl_cba TYPE TABLE FOR CREATE zifv_cds_booking\_Bookingsuppl.

    READ TABLE keys  ASSIGNING FIELD-SYMBOL(<ls_without_cid>) WITH KEY  %cid = ''.
    ASSERT <ls_without_cid> IS NOT ASSIGNED.

    READ ENTITIES OF zifv_cds_travel IN LOCAL MODE
    ENTITY zifv_cds_travel
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel_r)
    FAILED DATA(lt_failed).

    READ ENTITIES OF zifv_cds_travel IN LOCAL MODE
    ENTITY zifv_cds_travel BY \_Booking
    ALL FIELDS WITH CORRESPONDING #( lt_travel_r )
    RESULT DATA(lt_booking_r).

    READ ENTITIES OF zifv_cds_travel IN LOCAL MODE
    ENTITY zifv_cds_booking BY \_Bookingsuppl
    ALL FIELDS WITH CORRESPONDING #( lt_booking_r  )
    RESULT DATA(lt_booksupp_r).

    LOOP AT lt_travel_r ASSIGNING FIELD-SYMBOL(<fs_travel_r>).

*APPEND INITIAL LINE TO it_travel  ASSIGNING FIELD-SYMBOL(<fs_travel>).
*<fs_travel>-%cid  =  keys[ KEY entity TravelId  =   <fs_travel_r>-TravelId  ]-%cid  .
*<fs_travel>-%data = CORRESPONDING #( <fs_travel> EXCEPT TravelId ).

      APPEND VALUE #( %cid  =  keys[ KEY entity TravelId  =   <fs_travel_r>-TravelId  ]-%cid
                      %data = CORRESPONDING #( <fs_travel_r> EXCEPT TravelId ) )
                       TO it_travel ASSIGNING FIELD-SYMBOL(<fs_travel>).


      <fs_travel>-BeginDate     = cl_abap_context_info=>get_system_date( ).
      <fs_travel>-EndDate       = cl_abap_context_info=>get_system_date( ) + 30 .
      <fs_travel>-OverallStatus = 'O'.

      APPEND VALUE #( %cid_ref  = <fs_travel>-%cid )
       TO it_booking_cba  ASSIGNING FIELD-SYMBOL(<fs_booking>).

      LOOP AT lt_booking_r ASSIGNING FIELD-SYMBOL(<ls_booking_r>)
                            USING KEY entity
                           WHERE TravelId = <fs_travel_r>-TravelId.

        APPEND VALUE #( %cid = <fs_travel>-%cid && <ls_booking_r>-BookingId
                        %data = CORRESPONDING #( <ls_booking_r> EXCEPT TravelId ) )
                         TO <fs_booking>-%target ASSIGNING FIELD-SYMBOL(<ls_booking_n>) .

        <ls_booking_n>-BookingStatus = 'N'.


        APPEND VALUE #( %cid_ref  = <ls_booking_n>-%cid )
         TO it_booksuppl_cba  ASSIGNING FIELD-SYMBOL(<ls_booksupp_n>).

        LOOP AT  lt_booksupp_r  ASSIGNING FIELD-SYMBOL(<ls_booksupp_r>)
                                USING KEY entity
                                WHERE TravelId = <fs_travel_r>-TravelId
                                 AND BookingId = <ls_booking_r>-BookingId.

          APPEND VALUE #( %cid = <fs_travel>-%cid && <ls_booking_r>-BookingId && <ls_booksupp_r>-BookingSupplementId
              %data = CORRESPONDING #( <ls_booksupp_r> EXCEPT TravelId BookingId ) )
               TO <ls_booksupp_n>-%target .

        ENDLOOP.


      ENDLOOP.


    ENDLOOP.

    MODIFY ENTITIES OF zifv_cds_travel IN LOCAL MODE
    ENTITY zifv_cds_travel
    CREATE FIELDS ( AgencyId
                    CustomerId
                    BeginDate
                    EndDate
                    BookingFee
                    TotalPrice
                    CurrencyCode
                    OverallStatus
                    Description )
    WITH it_travel
    ENTITY zifv_cds_travel
    CREATE BY \_Booking
    FIELDS ( BookingId
             BookingDate
             CustomerId
             CarrierId
             ConnectionId
             FlightDate
             FlightPrice
             CurrencyCode
             BookingStatus )
    WITH it_booking_cba
    ENTITY zifv_cds_booking
    CREATE BY \_Bookingsuppl
    FIELDS ( BookingSupplementId
             SupplementId
             Price
             CurrencyCode )
    WITH it_booksuppl_cba MAPPED DATA(it_mapped).

    mapped-zifv_cds_travel = it_mapped-zifv_cds_travel.



  ENDMETHOD.

  METHOD recalcTotPrice.
  ENDMETHOD.

  METHOD rejectTravel.
  MODIFY ENTITIES OF zifv_cds_travel IN LOCAL MODE
 ENTITY zifv_cds_travel
  UPDATE FIELDS ( OverallStatus )
  WITH VALUE #( FOR ls_keys IN keys ( %tky = ls_keys-%tky
                                      OverallStatus = 'X' ) ).

  READ ENTITIES OF zifv_cds_travel IN LOCAL MODE
  ENTITY zifv_cds_travel
  ALL FIELDS WITH CORRESPONDING #( keys )
  RESULT DATA(lt_result).
  .

  result  = VALUE #( FOR ls_result IN lt_result ( %tky = ls_result-%tky
                                               %param  =  ls_result ) ).
  ENDMETHOD.

ENDCLASS.
