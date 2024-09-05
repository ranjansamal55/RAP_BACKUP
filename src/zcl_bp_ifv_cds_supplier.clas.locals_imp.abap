CLASS lhc_zifv_cds_supplier DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateCurrencyCode FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZIFV_CDS_SUPPLIER~validateCurrencyCode.

    METHODS validatePrice FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZIFV_CDS_SUPPLIER~validatePrice.

    METHODS validateSupplement FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZIFV_CDS_SUPPLIER~validateSupplement.
    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ZIFV_CDS_SUPPLIER~calculateTotalPrice.

ENDCLASS.

CLASS lhc_zifv_cds_supplier IMPLEMENTATION.

  METHOD validateCurrencyCode.
  ENDMETHOD.

  METHOD validatePrice.
  ENDMETHOD.

  METHOD validateSupplement.
  ENDMETHOD.

  METHOD calculateTotalPrice.

     DATA: lt_travel TYPE STANDARD TABLE OF zifv_cds_travel WITH UNIQUE HASHED KEY key  COMPONENTS TravelId.

    lt_travel = CORRESPONDING #( keys DISCARDING DUPLICATES MAPPING TravelId = TravelId ).

    MODIFY ENTITIES OF zifv_cds_travel IN LOCAL MODE
   ENTITY zifv_cds_travel
   EXECUTE recalcTotPrice
   FROM CORRESPONDING #( lt_travel ).

  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
