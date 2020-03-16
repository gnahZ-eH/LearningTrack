*"* use this source file for your ABAP unit test classes

CLASS ltc_Eppm_Onemds_Mass_Change DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS
.
*?﻿<asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">
*?<asx:values>
*?<TESTCLASS_OPTIONS>
*?<TEST_CLASS>ltc_Eppm_Onemds_Mass_Change
*?</TEST_CLASS>
*?<TEST_MEMBER>f_Cut
*?</TEST_MEMBER>
*?<OBJECT_UNDER_TEST>ZCL_TST_MASS_CHANGE_REPLICATE
*?</OBJECT_UNDER_TEST>
*?<OBJECT_IS_LOCAL/>
*?<GENERATE_FIXTURE/>
*?<GENERATE_CLASS_FIXTURE/>
*?<GENERATE_INVOCATION/>
*?<GENERATE_ASSERT_EQUAL/>
*?</TESTCLASS_OPTIONS>
*?</asx:values>
*?</asx:abap>
  PRIVATE SECTION.

    CLASS-DATA go_sql_env TYPE REF TO if_osql_test_environment.

    TYPES: BEGIN OF ty_keys_proj,
             key TYPE /s4ppm/tv_entity_guid,
           END OF ty_keys_proj.
    TYPES:tt_keys_proj TYPE TABLE OF ty_keys_proj.
    TYPES: BEGIN OF ty_keys_wpkg,
             key      TYPE /s4ppm/tv_entity_guid,
             proj_key TYPE /s4ppm/tv_entity_guid,
           END OF ty_keys_wpkg.
    TYPES:tt_keys_wpkg TYPE TABLE OF ty_keys_wpkg.

    TYPES: BEGIN OF ty_wpkg,
             guid            TYPE /s4ppm/tv_entity_guid,
             external_id     TYPE /s4ppm/tv_external_id,
             name            TYPE /s4ppm/tv_name,
             project_guid    TYPE /s4ppm/tv_entity_guid,
             pspnr           TYPE ps_posnr,
             proc_status_own TYPE dpr_tv_proc_status_own,
             up              TYPE /s4ppm/tv_task_guid, "for table /s4ppm/hierarchy to get parent project uuid
             object_guid     TYPE /s4ppm/tv_task_guid, "for table /s4ppm/hierarchy to get parent project uuid
             profl           TYPE profidproj, "for table proj to get project profile code(YP04: staticstical project profile)
           END OF ty_wpkg.
    TYPES:tt_wpkg TYPE TABLE OF ty_wpkg.

    TYPES: BEGIN OF ty_pspnr,
             pspnr TYPE ps_posnr,
           END OF ty_pspnr.
    TYPES: tt_pspnr TYPE TABLE OF ty_pspnr.

    DATA:
      f_Cut TYPE REF TO zcl_Tst_Mass_Change_Replicate.  "class under test

    DATA: BEGIN OF gs_set_proc_other,
            current_status   TYPE i_ppm_projecttp-processingstatus,
            target_status    TYPE i_ppm_projecttp-processingstatus,
            set_other_fields TYPE c,
          END OF gs_set_proc_other.
    DATA gt_set_proc_other LIKE TABLE OF gs_set_proc_other.
    DATA: go_mass_change_runner        TYPE REF TO cl_tst_mass_change.
    DATA: BEGIN OF gs_set_proc,
            last_status    TYPE i_ppm_projecttp-processingstatus,
            current_status TYPE i_ppm_projecttp-processingstatus,
            target_status  TYPE i_ppm_projecttp-processingstatus,
          END OF gs_set_proc.
    DATA gt_set_proc_flow LIKE TABLE OF gs_set_proc.
    DATA gt_set_proc_error LIKE TABLE OF gs_set_proc.

    CONSTANTS:
      gv_create   TYPE char2 VALUE '00',
      gv_release  TYPE char2 VALUE '10',
      gv_lock     TYPE char2 VALUE '20',
      gv_unlock   TYPE char2 VALUE '99',
      gv_complete TYPE char2 VALUE '40',
      gv_close    TYPE char2 VALUE '42'.

    CLASS-METHODS: class_setup.
    CLASS-METHODS: class_teardown.
    METHODS: setup.
    METHODS: teardown.

    METHODS: execute FOR TESTING.

    METHODS: mass_change FOR TESTING.

    METHODS:
      prepare_mch_data
        IMPORTING iv_uuid      TYPE /s4ppm/tv_entity_guid
                  iv_fieldname TYPE /s4ppm/tv_mch_fieldname
                  iv_new_value TYPE /s4ppm/tv_mch_new_value
                  it_keys_proj TYPE tt_keys_proj OPTIONAL
                  it_keys_wpkg TYPE tt_keys_wpkg OPTIONAL
                  it_wpkg      TYPE tt_wpkg OPTIONAL.

ENDCLASS.       "ltc_Eppm_Onemds_Mass_Change


CLASS ltc_Eppm_Onemds_Mass_Change IMPLEMENTATION.

  METHOD class_setup.

    go_sql_env = cl_osql_test_environment=>create( i_dependency_list = VALUE #( ( '/S4PPM/MCH_PARAM' )
                                                                                ( '/S4PPM/MCH_HDR' )
                                                                                ( '/S4PPM/HIERARCHY' )
                                                                                ( 'PROJ' )
                                                                                ( '/S4PPM/MCH_WPKG' )
                                                                                ( '/S4PPM/TASK' )
                                                                                )  ).

  ENDMETHOD.

  METHOD class_teardown.
    go_sql_env->destroy( ).
  ENDMETHOD.

  METHOD teardown.

  ENDMETHOD.

  METHOD setup.
    CREATE OBJECT go_mass_change_runner.
    f_Cut = NEW zcl_Tst_Mass_Change_Replicate( ).
  ENDMETHOD.

  METHOD execute.

    f_Cut->execute( ).

  ENDMETHOD.

  METHOD prepare_mch_data.

    DATA :lt_mch_hdr   TYPE STANDARD TABLE OF /s4ppm/mch_hdr WITH EMPTY KEY,
          lt_mch_param TYPE STANDARD TABLE OF /s4ppm/mch_param WITH EMPTY KEY,

          lt_mch_proj  TYPE STANDARD TABLE OF /s4ppm/mch_proj WITH EMPTY KEY,
          ls_mch_proj  TYPE /s4ppm/mch_proj,
          lt_mch_wpkg  TYPE STANDARD TABLE OF /s4ppm/mch_wpkg WITH EMPTY KEY,
          ls_mch_wpkg  TYPE /s4ppm/mch_wpkg.

    DATA:
      lt_task      TYPE STANDARD TABLE OF /s4ppm/task WITH EMPTY KEY,
      ls_task      TYPE /s4ppm/task,
      lt_hierarchy TYPE STANDARD TABLE OF /s4ppm/hierarchy WITH EMPTY KEY,
      lt_proj      TYPE STANDARD TABLE OF proj WITH EMPTY KEY.

    DATA: lv_timestamp TYPE timestamp. "UTC Time Stamp in Short Form (YYYYMMDDhhmmss)
    GET TIME STAMP FIELD lv_timestamp.
************/s4ppm/mch_HDR
    DATA(lv_job_name) = go_mass_change_runner->get_uuid_c32( ).
    lt_mch_hdr = VALUE #( ( guid = iv_uuid
                            jobname = lv_job_name
                             created_by = sy-uname
                             created_on = lv_timestamp )
                         ).
    DATA(test_mch_hdr) = cl_osql_test_data=>create( i_data = lt_mch_hdr ).
    DATA(pro_mch_hdr) = go_sql_env->get_double(  i_name = '/S4PPM/MCH_HDR' ).
    pro_mch_hdr->insert( test_mch_hdr ).

************/s4ppm/mch_WPKG
    LOOP AT it_keys_wpkg INTO DATA(ls_key_wpkg).
      ls_mch_wpkg-mch_hdr_guid = iv_uuid.
      ls_mch_wpkg-work_package_guid = ls_key_wpkg-key.
      ls_mch_wpkg-project_guid = ls_key_wpkg-proj_key.
      APPEND ls_mch_wpkg TO lt_mch_wpkg.
      CLEAR ls_mch_wpkg.
    ENDLOOP.

**************/S4PPM/TASK**************
    MOVE-CORRESPONDING it_wpkg TO lt_task.

    DATA(test_wpkg) = cl_osql_test_data=>create( i_data = lt_task ).
    DATA(pro_wpkg) = go_sql_env->get_double(  i_name = '/S4PPM/TASK' ).
    pro_wpkg->insert( test_wpkg ).


**************/S4PPM/HIERARCHY**************
    MOVE-CORRESPONDING it_wpkg TO lt_hierarchy.

    DATA(test_hierarchy) = cl_osql_test_data=>create( i_data = lt_hierarchy ).
    DATA(pro_hierarchy) = go_sql_env->get_double(  i_name = '/S4PPM/HIERARCHY' ).
    pro_hierarchy->insert( test_hierarchy ).

**************PROJ**************
    MOVE-CORRESPONDING it_wpkg TO lt_proj.

    DATA(test_proj) = cl_osql_test_data=>create( i_data = lt_proj ).
    DATA(pro_proj) = go_sql_env->get_double(  i_name = 'PROJ' ).
    pro_proj->insert( test_proj ).

    DATA(test_mch_wpkg) = cl_osql_test_data=>create( i_data = lt_mch_wpkg ).
    DATA(pro_mch_wpkg) = go_sql_env->get_double(  i_name = '/S4PPM/MCH_WPKG' ).
    pro_mch_wpkg->insert( test_mch_wpkg ).

*************/s4ppm/mch_PARAM
    DATA(pro_mch_param) = go_sql_env->get_double(  i_name = '/S4PPM/MCH_PARAM' ).

    "Workpackage parameters
    IF it_keys_wpkg IS NOT INITIAL.
      REFRESH lt_mch_param.
      lt_mch_param = VALUE #( ( mch_hdr_guid = iv_uuid
                           entity = 'W'
                           fieldname = iv_fieldname
                           new_value = iv_new_value )
                       ).
      DATA(test_mch_param_w) = cl_osql_test_data=>create( i_data = lt_mch_param ).
      pro_mch_param->insert( test_mch_param_w ).


    ENDIF.

  ENDMETHOD.

  METHOD mass_change.
    DATA:lt_keys_proj TYPE tt_keys_proj,
         ls_keys_proj TYPE ty_keys_proj,
         lt_keys_wpkg TYPE tt_keys_wpkg,
         ls_keys_wpkg TYPE ty_keys_wpkg,
         lt_wpkg      TYPE tt_wpkg,
         ls_tmp_wpkg  TYPE ty_wpkg,
         ls_wpkg      TYPE ty_wpkg.
    DATA lv_uuid TYPE sysuuid_x16.
    DATA lv_new_value TYPE /s4ppm/tv_mch_new_value.
    DATA:ls_msg TYPE bapiret2.
    DATA:lt_set_proc_flow LIKE TABLE OF gs_set_proc,
         ls_set_proc_flow LIKE gs_set_proc.
    DATA lv_task TYPE i_ppm_projecttasktp-task.
    DATA:
         lt_pspnr TYPE tt_pspnr,
         ls_pspnr TYPE ty_pspnr.

    DATA: lv_timestamp TYPE tzntstmps.

    "change status from create 00 to release 10
    ls_set_proc_flow-current_status = '00'.
    ls_set_proc_flow-target_status = '10'.
    APPEND ls_set_proc_flow TO lt_set_proc_flow.

    lv_uuid = go_mass_change_runner->get_uuid_x16( ).
    "Prepare MCH entries for change processing status
    lv_new_value = ls_set_proc_flow-target_status.

    "1, prepare the first parent WBS Element
    ls_keys_wpkg-key = go_mass_change_runner->get_uuid_x16( ).
    ls_keys_wpkg-proj_key = go_mass_change_runner->get_uuid_x16( ).
    APPEND ls_keys_wpkg TO lt_keys_wpkg.

    ls_wpkg-guid = ls_keys_wpkg-key.
    ls_tmp_wpkg-guid = ls_keys_wpkg-key.
    ls_wpkg-external_id = 'Z6TID301'.
    ls_wpkg-name = 'Z6TNAME301'.
    ls_wpkg-project_guid = ls_keys_wpkg-proj_key.
    ls_tmp_wpkg-project_guid = ls_wpkg-project_guid.
    ls_wpkg-up = ls_keys_wpkg-proj_key.
    ls_wpkg-object_guid = ls_keys_wpkg-key.
    ls_wpkg-proc_status_own = ls_set_proc_flow-current_status.
    ls_wpkg-pspnr = '99914665'.
    ls_wpkg-profl = 'YP04'.
    APPEND ls_wpkg TO lt_wpkg.
    APPEND ls_wpkg-pspnr TO lt_pspnr.
    "1, prepart the first child WBS Element
    CLEAR ls_keys_wpkg.
    ls_keys_wpkg-key = go_mass_change_runner->get_uuid_x16( ).
    ls_keys_wpkg-proj_key = ls_tmp_wpkg-project_guid .
    "APPEND ls_keys_wpkg TO lt_keys_wpkg.

    ls_wpkg-guid = ls_keys_wpkg-key.
    ls_wpkg-external_id = 'Z6TID302'.
    ls_wpkg-name = 'Z6TNAME302'.
    ls_wpkg-project_guid = ls_tmp_wpkg-project_guid .
    ls_wpkg-up = ls_tmp_wpkg-guid.
    ls_wpkg-object_guid = ls_keys_wpkg-key.
    ls_wpkg-proc_status_own = ls_set_proc_flow-current_status.
    ls_wpkg-pspnr = '99914666'.
    ls_wpkg-profl = 'YP04'.
    APPEND ls_wpkg TO lt_wpkg.
    APPEND ls_wpkg-pspnr TO lt_pspnr.

    CLEAR: ls_keys_wpkg, ls_wpkg, ls_tmp_wpkg.


    "2, prepare the second parent WBS Element
    ls_keys_wpkg-key = go_mass_change_runner->get_uuid_x16( ).
    ls_keys_wpkg-proj_key = go_mass_change_runner->get_uuid_x16( ).
    APPEND ls_keys_wpkg TO lt_keys_wpkg.

    ls_wpkg-guid = ls_keys_wpkg-key.
    ls_tmp_wpkg-guid = ls_keys_wpkg-key.
    ls_wpkg-external_id = 'Z6TID303'.
    ls_wpkg-name = 'Z6TNAME303'.
    ls_wpkg-project_guid = ls_keys_wpkg-proj_key.
    ls_tmp_wpkg-project_guid = ls_wpkg-project_guid.
    ls_wpkg-up = ls_keys_wpkg-proj_key.
    ls_wpkg-object_guid = ls_keys_wpkg-key.
    ls_wpkg-proc_status_own = ls_set_proc_flow-current_status.
    ls_wpkg-pspnr = '99914667'.
    ls_wpkg-profl = 'YP04'.
    APPEND ls_wpkg TO lt_wpkg.
    APPEND ls_wpkg-pspnr TO lt_pspnr.
    "2, prepart the second child WBS Element
    CLEAR ls_keys_wpkg.
    ls_keys_wpkg-key = go_mass_change_runner->get_uuid_x16( ).
    ls_keys_wpkg-proj_key = ls_tmp_wpkg-project_guid .
    "APPEND ls_keys_wpkg TO lt_keys_wpkg.

    ls_wpkg-guid = ls_keys_wpkg-key.
    ls_wpkg-external_id = 'Z6TID304'.
    ls_wpkg-name = 'Z6TNAME304'.
    ls_wpkg-project_guid = ls_tmp_wpkg-project_guid .
    ls_wpkg-up = ls_keys_wpkg-proj_key.
    ls_wpkg-object_guid = ls_keys_wpkg-key.
    ls_wpkg-proc_status_own = ls_set_proc_flow-current_status.
    ls_wpkg-pspnr = '99914668'.
    ls_wpkg-profl = 'YP04'.
    APPEND ls_wpkg TO lt_wpkg.
    APPEND ls_wpkg-pspnr TO lt_pspnr.

    "CLEAR: ls_keys_wpkg, ls_wpkg, ls_tmp_wpkg.

    " from create(00) to release(10)
    prepare_mch_data(
      EXPORTING
        iv_uuid      = lv_uuid
        iv_fieldname = /s4ppm/if_mass_change_req_bo=>gc_field_names-processingstatus
        iv_new_value = lv_new_value
        it_keys_wpkg = lt_keys_wpkg
        it_wpkg      = lt_wpkg
    ).

    GET TIME STAMP FIELD lv_timestamp.

    "Execute mass change
    go_mass_change_runner->execute( iv_guid = lv_uuid ).

    LOOP AT lt_pspnr INTO ls_pspnr.
      zcl_ppm_utility_get_bus_data=>get_business_data(
        EXPORTING
          iv_timestamp               = lv_timestamp                 " UTC Time Stamp in Long Form (YYYYMMDDhhmmssmmmuuun)
          iv_wbs_element_internal_id = ls_pspnr-pspnr                 " Sequence number
        IMPORTING
          ev_flag                    = DATA(lv_flag)
          et_business_data           = DATA(lt_business_data)                 " Buiness data in sent-out payload
      ).

      "cl_abap_unit_assert=>assert_equals( exp = abap_true act = lv_flag ).
    ENDLOOP.


    "from release(10) to lock(20)
    prepare_mch_data(
      EXPORTING
        iv_uuid      = lv_uuid
        iv_fieldname = /s4ppm/if_mass_change_req_bo=>gc_field_names-processingstatus
        iv_new_value = '20'
        it_keys_wpkg = lt_keys_wpkg
    ).

    GET TIME STAMP FIELD lv_timestamp.

    "Execute mass change
    go_mass_change_runner->execute( iv_guid = lv_uuid ).

    LOOP AT lt_pspnr INTO ls_pspnr.
      zcl_ppm_utility_get_bus_data=>get_business_data(
        EXPORTING
          iv_timestamp               = lv_timestamp                 " UTC Time Stamp in Long Form (YYYYMMDDhhmmssmmmuuun)
          iv_wbs_element_internal_id = ls_pspnr-pspnr                 " Sequence number
        IMPORTING
          ev_flag                    = lv_flag
          et_business_data           = lt_business_data                " Buiness data in sent-out payload
      ).

      "cl_abap_unit_assert=>assert_equals( exp = abap_true act = lv_flag ).
    ENDLOOP.


  ENDMETHOD.





ENDCLASS.