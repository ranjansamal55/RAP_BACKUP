CLASS zcl_read_ptactice_srs DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
  INTERFACES if_oo_adt_classrun .


  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_READ_PTACTICE_SRS IMPLEMENTATION.


 METHOD if_oo_adt_classrun~main.

*sort form read

**    READ ENTITY zifv_cds_travel
**     FROM VALUE #( ( %key-TravelId = '0000000020'
**                     %control = VALUE #( AgencyId    = if_abap_behv=>mk-on
**                                         CUSTOMERID  = if_abap_behv=>mk-on
**                                         BEGINDATE   = if_abap_behv=>mk-on   ) ) )
**     RESULT DATA(lt_result_short)
**     FAILED DATA(lt_failed_sort).
**
**    IF lt_failed_sort IS NOT INITIAL.
**      out->write( 'Read failed' ).
**    ELSE.
**      out->write( lt_result_short ).
**    ENDIF.



**    READ ENTITY zifv_cds_travel
**     by \_Booking
**     ALL FIELDS
**     WITH VALUE #( ( %key-TravelId = '0000000020'   )
**                   ( %key-TravelId = '0000000022' ) )
**
**     RESULT DATA(lt_result_short)
**     FAILED DATA(lt_failed_sort).
**
**    IF lt_failed_sort IS NOT INITIAL.
**      out->write( 'Read failed' ).
**    ELSE.
**      out->write( lt_result_short ).
**    ENDIF.



**    READ ENTITIES OF zifv_cds_travel
**    ENTITY zifv_cds_travel
**    ALL FIELDS
**    WITH VALUE #( ( %key-TravelId = '0000004535'   )
**                  ( %key-TravelId = '0000004455' )  )
**     RESULT DATA(lt_result_travel)
**    ENTITY zifv_cds_booking
**    ALL FIELDS WITH VALUE #( ( %key-TravelId  = '0000004535'
**                               %key-BookingId = '0010'  )
**                             ( %key-TravelId  = '0000004455'
**                               %key-BookingId = '0001'  ) )
**     RESULT DATA(lt_result_book)
**     ENTITY zifv_cds_supplier
**    ALL FIELDS WITH VALUE #( ( %key-TravelId            = '0000004455'
**                               %key-BookingId           = '0001'
**                               %key-BookingSupplementId = '0001'        )
**                             ( %key-TravelId            = '0000004455'
**                               %key-BookingId           = '0001'
**                               %key-BookingSupplementId = '0005'        ) )
**     RESULT DATA(lt_result_supplier)
**     FAILED DATA(lt_failed_sort).
**
**    IF lt_failed_sort IS NOT INITIAL.
**      out->write( 'Read failed' ).
**    ELSE.
**      out->write( lt_result_travel ).
**      out->write( lt_result_book ).
**      out->write( lt_result_supplier ).
**    ENDIF.



    DATA: it_optab          TYPE abp_behv_retrievals_tab,
          it_travel         TYPE TABLE FOR READ IMPORT zifv_cds_travel,
          it_travel_result  TYPE TABLE FOR READ RESULT zifv_cds_travel,
          it_booking        TYPE TABLE FOR READ IMPORT zifv_cds_travel\_Booking,
          it_booking_result TYPE TABLE FOR READ RESULT zifv_cds_travel\_Booking.

    it_travel = VALUE #( ( %key-TravelId = '0000004455'
                           %control = VALUE #(   AgencyId  = if_abap_behv=>mk-on
                                               customerid  = if_abap_behv=>mk-on
                                                begindate  = if_abap_behv=>mk-on  ) ) ).

   it_booking = VALUE #( ( %key-TravelId = '0000004455'
                           %control = VALUE #(
                               BookingDate   = if_abap_behv=>mk-on
                               BookingStatus = if_abap_behv=>mk-on
                               BookingId     = if_abap_behv=>mk-on ) ) ).

    it_optab = VALUE #( ( op = if_abap_behv=>op-r-read
                          entity_name = 'ZIFV_CDS_TRAVEL'
                          instances   = REF #( it_travel )
                          results     = REF #( it_travel_result )  )
                        ( op = if_abap_behv=>op-r-read_ba
                          entity_name = 'ZIFV_CDS_TRAVEL'
                          sub_name    = '_BOOKING'
                          instances   = REF #( it_booking )
                          results     = REF #( it_booking_result ) ) ).
    READ ENTITIES OPERATIONS it_optab
         FAILED DATA(lt_failed_dy).

    IF lt_failed_dy IS NOT INITIAL.
      out->write( 'Read failed' ).
    ELSE.
      out->write( it_travel_result ).
      out->write( it_booking_result ).
    ENDIF.

  ENDMETHOD.
ENDCLASS.
