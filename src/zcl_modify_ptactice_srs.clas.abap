CLASS zcl_modify_ptactice_srs DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
   INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_MODIFY_PTACTICE_SRS IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
*MODIFY ENTITY, ENTITIES, field_spec
*1->...  { FROM fields_tab }
*       CREATE, CREATE BY, UP☺DATE, DELETE, EXECUTE
*       For DELETE, EXECUTE we can use this option only
*       The %control structure must be filled explicitly in the internal table fields_tab for CREATE, CREATE BY and UPDATE


**    DATA : lt_book TYPE TABLE FOR CREATE yi_travel_tech_m\_Booking.
**
**    MODIFY ENTITY zifv_cds_travel
**     CREATE FROM VALUE #(
**               ( %cid = 'cid1'
**                 %data-BeginDate = '20240225'
**                 %control-BeginDate = if_abap_behv=>mk-on ) )
**     CREATE BY \_Booking
**        FROM VALUE #( ( %cid_ref = 'cid1'
**                        %target  = VALUE #( ( %cid = 'cid11'
**                                              %data-bookingdate = '20240216'
**                                              %control-Bookingdate = if_abap_behv=>mk-on  ) ) ) )
**      FAILED FINAL(it_failed)
**      MAPPED FINAL(it_mapped)
**      REPORTED FINAL(it_result).
**
**    IF it_failed IS NOT INITIAL.
**      out->write( it_failed ).
**    ELSE.
**      COMMIT ENTITIES.
**    ENDIF.


*    MODIFY ENTITY zifv_cds_travel
*    DELETE FROM VALUE #( ( %key-TravelId = '0000004341' ) )
**        MODIFY ENTITY zifv_cds_booking
**    DELETE FROM VALUE #( ( %key-TravelId = '0000004342'
**                           %key-BookingId = '0010' ) )
**     FAILED FINAL(it_failed1)
**      MAPPED FINAL(it_mapped1)
**      REPORTED FINAL(it_result1).
**    .
**    IF it_failed1 IS NOT INITIAL.
**      out->write( it_failed1 ).
**    ELSE.
**      COMMIT ENTITIES.
**    ENDIF.

*2->   | { AUTO FILL CID WITH fields_tab }
*    MODIFY ENTITY zifv_cds_travel
*        CREATE AUTO FILL CID WITH VALUE #(
*                  (  %data-BeginDate = '20240229'
*                    %control-BeginDate = if_abap_behv=>mk-on ) )
*            FAILED FINAL(it_failed)
*         MAPPED FINAL(it_mapped)
*         REPORTED FINAL(it_result).
*
*    IF it_failed IS NOT INITIAL.
*      out->write( it_failed ).
*    ELSE.
*      COMMIT ENTITIES.
*    ENDIF.
*3->   | { [AUTO FILL CID] FIELDS ( comp1 comp2 ... ) WITH fields_tab }

    MODIFY ENTITIES OF zifv_cds_travel
     ENTITY zifv_cds_travel
     UPDATE FIELDS ( BeginDate )
     WITH  VALUE #( ( TravelId = '0000004343'
                             BeginDate = '20240331'  ) )
         ENTITY zifv_cds_travel
     DELETE FROM VALUE #( ( TravelId = '0000004342'
                             ) ) .
    COMMIT ENTITIES.

*4->  | { [AUTO FILL CID] SET FIELDS WITH fields_tab } ...☺

*    MODIFY ENTITY zifv_cds_travel
*    UPDATE SET FIELDS WITH VALUE #( ( %key-TravelId = '0000004343'
*                                          BeginDate = '20240330' ) ).
*
*    COMMIT ENTITIES.

  ENDMETHOD.
ENDCLASS.
