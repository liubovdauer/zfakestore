CLASS LHC_ZR_NWPRODUCTS DEFINITION INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR Products
        RESULT result,
      LoadFromIFlow FOR MODIFY
            IMPORTING keys FOR ACTION Products~LoadFromIFlow.
ENDCLASS.

CLASS LHC_ZR_NWPRODUCTS IMPLEMENTATION.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
  ENDMETHOD.
  METHOD LoadFromIFlow.
    TRY.
        DATA(lo_http) = cl_web_http_client_manager=>create_by_http_destination(
  cl_http_destination_provider=>create_by_url(
    i_url = 'https://0005046btrial.it-cpitrial06-rt.cfapps.us10-001.hana.ondemand.com/http/fakestore/products'
  )
).

    DATA(lo_request) = lo_http->get_http_request( ).



     " Basic Auth - bereits Base64 kodiert
        lo_request->set_header_field(

          i_name  = 'Authorization'
          i_value = 'Basic c2ItOWMxYzAzMjQtNTYwZi00YWUzLWE5MmQtMTk2MzZjYTA1Y2ZiIWI2NTY2OTV8aXQtcnQtMDAwNTA0NmJ0cmlhbCFiNTUyMTU6OWMyYTU3MmUtZjY4Yi00MWM4LTg4NDktNDY0NGZkZDNmMmU0JEVfckJpZVRvT0prQkdCY2NJMWh6dlRqSUhYZFZkUkVkZjBXaDZ1SnFLZDg9'
        ).

        DATA(lo_response) = lo_http->execute( if_web_http_client=>get ).
        DATA(lv_status) = lo_response->get_status( ).
        DATA(lv_reason) = lo_response->get_last_error(  ).
        DATA(lv_json)     = lo_response->get_text( ).



       CATCH cx_http_dest_provider_error
            cx_web_http_client_error
            cx_web_message_error INTO DATA(lx_error).
        RAISE SHORTDUMP lx_error.
    ENDTRY.

    " JSON parsen - Northwind Format: {"d":{"results":[...]}}
    TYPES: BEGIN OF ty_product,
             productid       TYPE i,
             productname     TYPE string,
             unitprice       TYPE string,
             categoryid      TYPE i,
             quantityperunit TYPE string,
             discontinued    TYPE abap_bool,
           END OF ty_product,
           BEGIN OF ty_results,
             results TYPE STANDARD TABLE OF ty_product WITH DEFAULT KEY,
           END OF ty_results,
           BEGIN OF ty_root,
             d TYPE ty_results,
           END OF ty_root.

    DATA ls_root TYPE ty_root.

    /ui2/cl_json=>deserialize(
      EXPORTING json        = lv_json
*                pretty_name = /ui2/cl_json=>pretty_mode-camel_case
      CHANGING  data        = ls_root
    ).

    " Daten als RAP Entities speichern
    DATA lt_products_create TYPE TABLE FOR CREATE ZR_NWPRODUCTS.
    DATA lt_products_update TYPE TABLE FOR UPDATE ZR_NWPRODUCTS.

    LOOP AT ls_root-d-results INTO DATA(ls_prod).

    "---------------------------------------
    " BOOLEAN CONVERSION FIX
    "---------------------------------------
    DATA lv_disc TYPE abap_bool.

    IF ls_prod-discontinued = abap_true OR ls_prod-discontinued = 'true'.
      lv_disc = abap_true.
    ELSE.
      lv_disc = abap_false.
    ENDIF.

      " Prüfen ob Produkt schon existiert
      SELECT SINGLE product_id FROM znw_products
        WHERE product_id = @ls_prod-productid
        INTO @DATA(lv_exists).

      IF sy-subrc = 0.
        APPEND VALUE #(
          %key-ProductID = ls_prod-productid
          ProductName    = ls_prod-productname
          UnitPrice      = ls_prod-unitprice
          CategoryID     = ls_prod-categoryid
          QtyPerUnit     = ls_prod-quantityperunit
          Discontinued   = ls_prod-discontinued
          %control = VALUE #(
            ProductName  = if_abap_behv=>mk-on
            UnitPrice    = if_abap_behv=>mk-on
            CategoryID   = if_abap_behv=>mk-on
            QtyPerUnit   = if_abap_behv=>mk-on
            Discontinued = if_abap_behv=>mk-on
          )
        ) TO lt_products_update.
      ELSE.
        APPEND VALUE #(
          %cid       = |CID_{ ls_prod-productid }|
          ProductID  = ls_prod-productid
          ProductName = ls_prod-productname
          UnitPrice   = ls_prod-unitprice
          CategoryID  = ls_prod-categoryid
          QtyPerUnit  = ls_prod-quantityperunit
          Discontinued = ls_prod-discontinued
          %control = VALUE #(
            ProductID    = if_abap_behv=>mk-on
            ProductName  = if_abap_behv=>mk-on
            UnitPrice    = if_abap_behv=>mk-on
            CategoryID   = if_abap_behv=>mk-on
            QtyPerUnit   = if_abap_behv=>mk-on
            Discontinued = if_abap_behv=>mk-on
          )
        ) TO lt_products_create.
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF ZR_NWPRODUCTS IN LOCAL MODE
      ENTITY Products
      CREATE FROM lt_products_create
      UPDATE FROM lt_products_update
      REPORTED DATA(lt_reported)
      FAILED DATA(lt_failed)
      MAPPED DATA(lt_mapped).

    "---------------------------------------
  " ERROR CHECK (WICHTIG!)
  "---------------------------------------
  IF lt_failed IS NOT INITIAL.

    APPEND VALUE #( %msg = new_message(
                       id       = 'ZRW'
                       number   = '002'
                       severity = if_abap_behv_message=>severity-error
                       v1       = 'RAP SAVE FAILED'
                     ) ) TO reported-products.

    RETURN.
  ENDIF.

  ENDMETHOD.

ENDCLASS.
