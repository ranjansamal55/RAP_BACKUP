CLASS lhc_zifv_cds_booking DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS earlynumbering_cba_Bookingsupp FOR NUMBERING
      IMPORTING entities FOR CREATE ZIFV_CDS_BOOKING\_Bookingsuppl.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR ZIFV_CDS_BOOKING RESULT result.

    METHODS validate_Connection FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZIFV_CDS_BOOKING~validate_Connection.

    METHODS validate_CurrencyCode FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZIFV_CDS_BOOKING~validate_CurrencyCode.

    METHODS validate_Customer FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZIFV_CDS_BOOKING~validate_Customer.

    METHODS validate_FlightPrice FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZIFV_CDS_BOOKING~validate_FlightPrice.

    METHODS validate_Status FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZIFV_CDS_BOOKING~validate_Status.

ENDCLASS.

CLASS lhc_zifv_cds_booking IMPLEMENTATION.

  METHOD earlynumbering_cba_Bookingsupp.

  DATA: max_booking_suppl_id TYPE /dmo/booking_supplement_id .

    READ ENTITIES OF zifv_cds_travel IN LOCAL MODE
      ENTITY zifv_cds_booking  BY \_Bookingsuppl
        FROM CORRESPONDING #( entities )
        LINK DATA(booking_supplements).

    " Loop over all unique tky (TravelID + BookingID)
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<booking_group>) GROUP BY <booking_group>-%tky.

      " Get highest bookingsupplement_id from bookings belonging to booking
      max_booking_suppl_id = REDUCE #( INIT max = CONV /dmo/booking_supplement_id( '0' )
                                       FOR  booksuppl IN booking_supplements USING KEY entity
                                                                             WHERE (     source-TravelId  = <booking_group>-TravelId
                                                                                     AND source-BookingId = <booking_group>-BookingId )
                                       NEXT max = COND /dmo/booking_supplement_id( WHEN   booksuppl-target-BookingSupplementId > max
                                                                          THEN booksuppl-target-BookingSupplementId
                                                                          ELSE max )
                                     ).
      " Get highest assigned bookingsupplement_id from incoming entities
      max_booking_suppl_id = REDUCE #( INIT max = max_booking_suppl_id
                                       FOR  entity IN entities USING KEY entity
                                                               WHERE (     TravelId  = <booking_group>-TravelId
                                                                       AND BookingId = <booking_group>-BookingId )
                                       FOR  target IN entity-%target
                                       NEXT max = COND /dmo/booking_supplement_id( WHEN   target-BookingSupplementId > max
                                                                                     THEN target-BookingSupplementId
                                                                                     ELSE max )
                                     ).


      " Loop over all entries in entities with the same TravelID and BookingID
      LOOP AT entities ASSIGNING FIELD-SYMBOL(<booking>) USING KEY entity WHERE TravelId  = <booking_group>-TravelId
                                                                            AND BookingId = <booking_group>-BookingId.

        " Assign new booking_supplement-ids
        LOOP AT <booking>-%target ASSIGNING FIELD-SYMBOL(<booksuppl_wo_numbers>).
          APPEND CORRESPONDING #( <booksuppl_wo_numbers> ) TO mapped-zifv_cds_supplier ASSIGNING FIELD-SYMBOL(<mapped_booksuppl>).
          IF <booksuppl_wo_numbers>-BookingSupplementId IS INITIAL.
            max_booking_suppl_id += 1 .
            <mapped_booksuppl>-BookingSupplementId = max_booking_suppl_id .
          ENDIF.
        ENDLOOP.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

  METHOD get_instance_features.
  ENDMETHOD.

  METHOD validate_Connection.
  ENDMETHOD.

  METHOD validate_CurrencyCode.
  ENDMETHOD.

  METHOD validate_Customer.
  ENDMETHOD.

  METHOD validate_FlightPrice.
  ENDMETHOD.

  METHOD validate_Status.
  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
