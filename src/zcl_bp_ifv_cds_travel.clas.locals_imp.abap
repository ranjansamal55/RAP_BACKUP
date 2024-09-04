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
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zifv_cds_travel RESULT result.

    METHODS validate_bookingfee FOR VALIDATE ON SAVE
      IMPORTING keys FOR zifv_cds_travel~validate_bookingfee.

    METHODS validate_currencycode FOR VALIDATE ON SAVE
      IMPORTING keys FOR zifv_cds_travel~validate_currencycode.

    METHODS validate_customer FOR VALIDATE ON SAVE
      IMPORTING keys FOR zifv_cds_travel~validate_customer.

    METHODS validate_dates FOR VALIDATE ON SAVE
      IMPORTING keys FOR zifv_cds_travel~validate_dates.

    METHODS validate_status FOR VALIDATE ON SAVE
      IMPORTING keys FOR zifv_cds_travel~validate_status.

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

    MODIFY ENTITIES OF zifv_cds_travel IN LOCAL MODE
    ENTITY zifv_cds_travel
    EXECUTE recalcTotPrice
    FROM CORRESPONDING #( keys ).
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

  METHOD get_instance_features.

   READ ENTITIES OF zifv_cds_travel IN LOCAL MODE
   ENTITY zifv_cds_travel
   FIELDS ( TravelId OverallStatus )
   WITH CORRESPONDING #( keys )
   RESULT DATA(lt_travel).

  result  = VALUE #( FOR ls_travel IN lt_travel
                      (  %tky = ls_travel-%tky
                         %features-%action-acceptTravel = COND #( WHEN ls_travel-OverallStatus = 'A'
                                                                  THEN if_abap_behv=>fc-o-disabled
                                                                  ELSE if_abap_behv=>fc-o-enabled )
                         %features-%action-rejectTravel = COND #( WHEN ls_travel-OverallStatus = 'X'
                                                                  THEN if_abap_behv=>fc-o-disabled
                                                                  ELSE if_abap_behv=>fc-o-enabled )
                         %features-%assoc-_Booking  = COND #( WHEN ls_travel-OverallStatus = 'X'
                                                                  THEN if_abap_behv=>fc-o-disabled
                                                                  ELSE if_abap_behv=>fc-o-enabled )
                                                                   )
                 ).


  ENDMETHOD.

  METHOD validate_BookingFee.
  ENDMETHOD.

  METHOD validate_CurrencyCode.
  ENDMETHOD.

  METHOD validate_customer.
  READ ENTITY  IN LOCAL MODE zifv_cds_travel
   FIELDS ( CustomerId )
   WITH CORRESPONDING #( keys )
   RESULT DATA(lt_travel).

  DATA: lt_cust TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

  lt_cust = CORRESPONDING #( lt_travel DISCARDING DUPLICATES MAPPING customer_id = CustomerId  ).
  DELETE lt_cust WHERE customer_id IS INITIAL.
  SELECT
   FROM /dmo/customer
   FIELDS customer_id
   FOR ALL ENTRIES IN @lt_cust
   WHERE customer_id = @lt_cust-customer_id
   INTO TABLE @DATA(lt_cust_db).
    IF sy-subrc IS INITIAL.

    ENDIF.

    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<ls_travel>).

      IF <ls_travel>-CustomerId IS INITIAL
         OR  NOT line_exists( lt_cust_db[ customer_id = <ls_travel>-CustomerId  ] )   .

        APPEND VALUE #( %tky = <ls_travel>-%tky )
                   TO failed-zifv_cds_travel.
        APPEND VALUE #( %tky = <ls_travel>-%tky
                        %msg = NEW /dmo/cm_flight_messages(
                                            textid                = /dmo/cm_flight_messages=>customer_unkown
                                           customer_id           = <ls_travel>-CustomerId
                                severity              = if_abap_behv_message=>severity-error
                                )
                        %element-CustomerId = if_abap_behv=>mk-on

        )
                   TO reported-zifv_cds_travel.



      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validate_Dates.
   READ ENTITIES OF zifv_cds_travel IN LOCAL MODE
              ENTITY zifv_cds_travel
                FIELDS ( BeginDate EndDate )
                WITH CORRESPONDING #( keys )
              RESULT DATA(lt_travels).

    LOOP AT lt_travels INTO DATA(travel).

      IF travel-EndDate < travel-BeginDate.  "end_date before begin_date

        APPEND VALUE #( %tky = travel-%tky ) TO failed-zifv_cds_travel.

        APPEND VALUE #( %tky = travel-%tky
                        %msg = NEW /dmo/cm_flight_messages(
                                   textid     = /dmo/cm_flight_messages=>begin_date_bef_end_date
                                   severity   = if_abap_behv_message=>severity-error
                                   begin_date = travel-BeginDate
                                   end_date   = travel-EndDate
                                   travel_id  = travel-TravelId )
                        %element-BeginDate   = if_abap_behv=>mk-on
                        %element-EndDate     = if_abap_behv=>mk-on
                     ) TO reported-zifv_cds_travel.

      ELSEIF travel-BeginDate < cl_abap_context_info=>get_system_date( ).  "begin_date must be in the future

        APPEND VALUE #( %tky        = travel-%tky ) TO failed-zifv_cds_travel.

        APPEND VALUE #( %tky = travel-%tky
                        %msg = NEW /dmo/cm_flight_messages(
                                    textid   = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
                                    severity = if_abap_behv_message=>severity-error )
                        %element-BeginDate  = if_abap_behv=>mk-on
                        %element-EndDate    = if_abap_behv=>mk-on
                      ) TO reported-zifv_cds_travel.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validate_Status.
      READ ENTITIES OF zifv_cds_travel IN LOCAL MODE
        ENTITY zifv_cds_travel
          FIELDS ( OverallStatus )
          WITH CORRESPONDING #( keys )
        RESULT DATA(lt_travels).

    LOOP AT lt_travels INTO DATA(ls_travel).
      CASE ls_travel-OverallStatus.
        WHEN 'O'.  " Open
        WHEN 'X'.  " Cancelled
        WHEN 'A'.  " Accepted

        WHEN OTHERS.
          APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-zifv_cds_travel.

          APPEND VALUE #( %tky = ls_travel-%tky
                          %msg = NEW /dmo/cm_flight_messages(
                                     textid = /dmo/cm_flight_messages=>status_invalid
                                     severity = if_abap_behv_message=>severity-error
                                     status = ls_travel-OverallStatus )
                          %element-OverallStatus = if_abap_behv=>mk-on
                        ) TO reported-zifv_cds_travel.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
