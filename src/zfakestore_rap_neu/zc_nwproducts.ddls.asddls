@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@Endusertext: {
  Label: '###GENERATED Core Data Service Entity'
}
@Objectmodel: {
  Sapobjectnodetype.Name: 'ZNWPRODUCTS'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_NWPRODUCTS
  provider contract TRANSACTIONAL_QUERY
  as projection on ZR_NWPRODUCTS
  association [1..1] to ZR_NWPRODUCTS as _BaseEntity on $projection.PRODUCTID = _BaseEntity.PRODUCTID
{
  key ProductID,
  ProductName,
  UnitPrice,
  CategoryID,
  QtyPerUnit,
  Discontinued,
  @Semantics: {
    User.Createdby: true
  }
  CreatedBy,
  @Semantics: {
    Systemdatetime.Createdat: true
  }
  CreatedAt,
  @Semantics: {
    User.Lastchangedby: true
  }
  LastChangedBy,
  @Semantics: {
    Systemdatetime.Lastchangedat: true
  }
  LastChangedAt,
  @Semantics: {
    Systemdatetime.Localinstancelastchangedat: true
  }
  LocalLastChangedAt,
  _BaseEntity
}
