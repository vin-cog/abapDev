*&---------------------------------------------------------------------*
*& Include zperson_info_f01
*&---------------------------------------------------------------------*
**MODEL***************************************************************
class lcl_model definition.
  public section.

    data: mt_data       type tt_data,
          mt_person_tab type standard table of zperson_info,
          ms_return     type bapiret2.

    methods:
      constructor,

      select_data.
endclass.

class lcl_model implementation.
  method constructor.
    refresh: mt_data,
             mt_person_tab.

    clear: ms_return.
  endmethod.

  method select_data.
    data: lt_data type tt_data,
          ls_data type zsperson_info.

    clear: ms_return.

    call function 'ZPERSONNEL_GET_LIST'
      importing
        return       = ms_return
      tables
        pernr_selopt = s_pernr
        person_tab   = mt_person_tab.

    if ms_return is initial.
      sort mt_person_tab by pernr.

      loop at mt_person_tab into data(ls_zperson_tab).
        ls_data-pernr   = ls_zperson_tab-pernr.
        ls_data-name    = |{ ls_zperson_tab-fname } { ls_zperson_tab-lname }|.
        ls_data-dobdt   = ls_zperson_tab-dobdt.
        ls_data-email   = ls_zperson_tab-email.
        ls_data-phone   = ls_zperson_tab-telno.
        ls_data-address = ls_zperson_tab-addinfo.

        append ls_data to lt_data.

        clear: ls_zperson_tab,
               ls_data.
      endloop.

      mt_data = lt_data.
    endif.
  endmethod.
endclass.

**VIEW****************************************************************
class lcl_view definition.
  public section.
    data: mo_table type ref to cl_salv_table,
          mt_data  type tt_data,
          ms_data  type line of tt_data.

    methods:
      constructor,

      display_alv
        changing
          ct_data type tt_data,

      on_user_command for event added_function of cl_salv_events
        importing e_salv_function,

      on_double_click for event double_click of cl_salv_events_table
        importing row column,

      update_data.

  private section.
    methods:
      map_data_to_alv_table.
endclass.

class lcl_view implementation.
  method constructor.
    refresh: mt_data.
    clear: ms_data.
  endmethod.

  method display_alv.
*-- Full screen
    try.
        mt_data = ct_data.

        cl_salv_table=>factory(
          importing
            r_salv_table   = mo_table
          changing
            t_table        = mt_data
        ).
      catch cx_salv_msg into data(lo_salv_msg).
        data(lv_text) = lo_salv_msg->get_text( ).
        message lv_text type 'I'.
        return.
    endtry.

*-- New button named "New Employee" was added to SALV_STANDARD
    mo_table->set_screen_status(
      pfstatus      =  'SALV_STANDARD'
      report        =  sy-repid
      set_functions = mo_table->c_functions_all ).

*-- Setting up ADDED_FUNCTION event"
    data(lo_events) = mo_table->get_event( ).

    set handler on_user_command for lo_events.
    set handler on_double_click for lo_events.

*-- Columns settings
    data(lo_columns) = mo_table->get_columns( ).
    lo_columns->set_optimize( ).

    data(lo_column) = lo_columns->get_column( 'PERNR' ).
    lo_column->set_long_text( 'Employee Number' ).
    lo_column->set_medium_text( 'Employee No.' ).
    lo_column->set_short_text( 'EmplNo.' ).

    lo_column = lo_columns->get_column( 'NAME' ).
    lo_column->set_long_text( 'Name (First name and last name)' ).
    lo_column->set_medium_text( 'Fist Last Name ' ).
    lo_column->set_short_text( 'Name' ).

    mo_table->get_display_settings( )->set_striped_pattern( abap_true ).

    mo_table->display( ).
  endmethod.

  method on_user_command.
*-- Screen contains the new employee details and then update the ALV
*   table
    call screen 0100.

    map_data_to_alv_table( ).

    if ms_data is not initial.
      append ms_data to mt_data.
    endif.

    mo_table->refresh( refresh_mode = if_salv_c_refresh=>full ).

  endmethod.

  method on_double_click.
    clear: gs_person_info.

    read table mt_data into ms_data index row.

    gs_person_info-pernr = ms_data-pernr.

    split ms_data-name at ' '
      into gs_person_info-fname gs_person_info-lname.

    gs_person_info-dobdt   = ms_data-dobdt.
    gs_person_info-email   = ms_data-email.
    gs_person_info-telno   = ms_data-phone.
    gs_person_info-addinfo = ms_data-address.

*-- Calling the same screen with selected line to be updated
    call screen 0100.

    map_data_to_alv_table( ).

    if ms_data is not initial.
      modify mt_data from ms_data index row.
    endif.

    mo_table->refresh( refresh_mode = if_salv_c_refresh=>full ).

  endmethod.

  method update_data.
    data: ls_return type bapiret2.

    clear: ls_return.

    call function 'ZPERSONNEL_UPDATE_LIST'
      exporting
        person_info = gs_person_info
      importing
        return      = ls_return.
  endmethod.

  method map_data_to_alv_table.
    select single *
      from zperson_info
      into @data(ls_person_info)
      where pernr = ( SELECT MAX( pernr ) FROM zperson_info ).

    if ls_person_info is not initial.
      ms_data-pernr   = ls_person_info-pernr.
      ms_data-name    = |{ ls_person_info-fname } { ls_person_info-lname }|.
      ms_data-dobdt   = ls_person_info-dobdt.
      ms_data-email   = ls_person_info-email.
      ms_data-phone   = ls_person_info-telno.
      ms_data-address = ls_person_info-addinfo.
    endif.
  endmethod.

endclass.

**CONTROLLER**********************************************************
class lcl_controller definition.
  public section.

    methods:
      constructor,

      process_data,

      output_data,

      save_data.

  private section.
    data:
      lo_data   type ref to lcl_model,
      lo_output type ref to lcl_view.
endclass.

class lcl_controller implementation.
  method constructor.
    create object:
      lo_data,
      lo_output.
  endmethod.

  method process_data.
    lo_data->select_data( ).
  endmethod.

  method output_data.
    lo_output->display_alv(
      changing
        ct_data = lo_data->mt_data
    ).
  endmethod.

  method save_data.
    lo_output->update_data( ).
  endmethod.
endclass.

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module user_command_0100 input.
  case gv_okcode.
    when 'BACK' or 'EXIT' or 'CANC'.
      set screen 0.
      leave screen.

    when 'SAVE'.
      go_control->save_data( ).

      set screen 0.
      leave screen.
  endcase.
endmodule.
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
module status_0100 output.
  set pf-status 'SCR_0100'.
  set titlebar 'NEWEMP'.
endmodule.
