CLASS zcl_dbtable_update DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
  INTERFACES:
      if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_DBTABLE_UPDATE IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
 " delete existing entries in the database table
    DELETE FROM zdb_travel_srs.
    DELETE FROM zdb_booking_srs.
    DELETE FROM zdb_supplier_srs.
    COMMIT WORK.
    " insert travel demo data
    INSERT zdb_travel_srs FROM (
        SELECT *
          FROM /dmo/travel_m
      ).
    COMMIT WORK.

    " insert booking demo data
    INSERT zdb_booking_srs FROM (
        SELECT *
          FROM   /dmo/booking_m
*            JOIN ytravel_tech_m AS y
*            ON   booking~travel_id = y~travel_id

      ).
    COMMIT WORK.
    INSERT zdb_supplier_srs FROM (
        SELECT *
          FROM   /dmo/booksuppl_m
*            JOIN ytravel_tech_m AS y
*            ON   booking~travel_id = y~travel_id

      ).
    COMMIT WORK.

    out->write( 'Travel and booking demo data inserted.' ).
  ENDMETHOD.
ENDCLASS.
