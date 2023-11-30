*&---------------------------------------------------------------------*
*& Include zperson_info_top
*&---------------------------------------------------------------------*
tables: zperson_info.

types: tt_data type standard table of zsperson_info.

data: gv_okcode      type syucomm,
      gs_person_info type zperson_info.

*-- Class Definition
class lcl_model      definition deferred.
class lcl_view       definition deferred.
class lcl_controller definition deferred.

data go_control type ref to lcl_controller.
