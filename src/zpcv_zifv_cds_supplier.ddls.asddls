@EndUserText.label: 'Projection/Consumption View for ZIFV_CDS_SUPPLIER'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZPCV_ZIFV_CDS_SUPPLIER
  as projection on ZIFV_CDS_SUPPLIER
{
  key TravelId,
  key BookingId,
  key BookingSupplementId,
      @ObjectModel.text.element: [ 'SupplemenDesc' ]
      SupplementId,
      _SupplementText.Description as SupplemenDesc : localized,
      Price,
      CurrencyCode,
      LastChangedAt,
      /* Associations */
      _Booking : redirected to parent ZPCV_ZIFV_CDS_BOOKING,
      _Supplement,
      _SupplementText,
      _Travel  : redirected to ZPCV_ZIFV_CDS_TRAVEL
}
