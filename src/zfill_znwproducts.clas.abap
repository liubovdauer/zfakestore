CLASS zfill_znwproducts DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zfill_znwproducts IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.


*   DATA lt_product TYPE Table of znw_products.
*   DATA ls_product Type znw_products.
*
*   APPEND VALUE #( product_id = 21 product_name = 'Tastatur' unit_price = 50 category_id = 8 qty_per_unit = '36 Boxes' discontinued = 'x'  ) TO lt_product.
*
*   INSERT znw_products FROM TABLE @lt_product.
*    DELETE from znw_products where product_id = 21.

        DELETE FROM znw_products
    WHERE product_id = 21.

COMMIT WORK.

  ENDMETHOD.
ENDCLASS.
