*&---------------------------------------------------------------------*
*& Report zperson_info_main
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
report zperson_info_main.

include:
  zperson_info_top, " Data Declaration
  zperson_info_scr, " Screens
  zperson_info_f01. " Class and Subroutine

*initialization.

start-of-selection.
  create object go_control.

  go_control->process_data( ).

  go_control->output_data(  ).
