################################################################################
# POWER PLAN TCL – CONSOLIDATED & CLEAN
# Compatible with Synopsys ICC2
################################################################################

puts "RM-info : Starting Power Planning Flow"

remove_pg_strategies -all
remove_pg_patterns -all
remove_pg_regions -all
remove_pg_via_master_rules -all
remove_pg_strategy_via_rules -all
remove_routes -net_types {power ground} -ring -stripe -macro_pin_connect -lib_cell_pin_connect
########################################
# 0. Global PG Nets
########################################
set PG_NETS {VDD VSS}

########################################
# 1. Connect PG nets automatically
########################################
puts "RM-info : Connecting PG nets automatically"
connect_pg_net -automatic -all_blocks

########################################
# 2. CORE POWER RING
########################################
puts "RM-info : Creating Core PG Ring"

create_pg_ring_pattern ring_pattern -horizontal_layer metal10 \
    -horizontal_width {5} -horizontal_spacing {2} \
    -vertical_layer metal9 -vertical_width {5} \
    -vertical_spacing {2} -corner_bridge false
set_pg_strategy core_ring -core -pattern \
    {{pattern: ring_pattern}{nets: {VDD VSS}}{offset: {3 3}}} \
    -extension {{stop: innermost_ring}}

########################################
# 3. MACRO POWER RINGS
########################################
puts "RM-info : Creating Macro PG Rings"

create_pg_ring_pattern macro_ring_pattern -horizontal_layer metal10 \
    -horizontal_width {5} -horizontal_spacing {2} \
    -vertical_layer metal9 -vertical_width {5} \
    -vertical_spacing {2} -corner_bridge false
set_pg_strategy macro_core_ring -macros [get_cells -hierarchical -filter "is_hard_macro==true"] -pattern \
    {{pattern: macro_ring_pattern}{nets: {VDD VSS}}{offset: {10 10}}} 

########################################
# 4. PG MESH (CORE ONLY)
########################################
puts "RM-info : Creating PG Mesh"

create_pg_region pg_mesh_region -core -expand -2 -exclude_macros sram -macro_offset 20
create_pg_mesh_pattern pg_mesh1 \
   -parameters {w1 p1 w2 p2 f t} \
   -layers {{{vertical_layer: metal9} {width: @w1} {spacing: interleaving} \
        {pitch: @p1} {offset: @f} {trim: @t}} \
 	     {{horizontal_layer: metal10} {width: @w2} {spacing: interleaving} \
        {pitch: @p2} {offset: @f} {trim: @t}}}


set_pg_strategy s_mesh1 \
   -pattern {{pattern: pg_mesh1} {nets: {VDD VSS VSS VDD} } \
{offset_start: 10 20} {parameters: 4 80 6 120 3.344 false}} \
   -pg_region pg_mesh_region -extension {{stop: innermost_ring}} 

########################################
# 5. MACRO PG PIN CONNECTIONS
########################################
puts "RM-info : Connecting Macro PG Pins"

create_pg_macro_conn_pattern hm_pattern -pin_conn_type scattered_pin -layer {metal3 metal3}
set toplevel_hms [filter_collection [get_cells * -physical_context] "is_hard_macro == true"]
set_pg_strategy macro_con -macros $toplevel_hms -pattern {{name: hm_pattern} {nets: {VDD VSS}} }

########################################
# 6. STANDARD CELL RAILS
########################################
puts "RM-info : Creating Standard Cell PG Rails"

create_pg_std_cell_conn_pattern \
    std_cell_rail  \
    -layers {metal1} \
    -rail_width 0.06

set_pg_strategy rail_strat  -pg_region pg_mesh_region \
    -pattern {{name: std_cell_rail} {nets: VDD VSS} }

########################################
# 7. Compile PG
########################################
puts "RM-info : Compiling PG strategies"

compile_pg 

########################################
# 8. PG CHECKS
########################################
puts "RM-info : Running PG Checks"

check_pg_missing_vias
check_pg_drc -ignore_std_cells
check_pg_connectivity -check_std_cell_pins none

########################################
# 9. Save Block
########################################
puts "RM-info : Saving block after power planning"
save_block -hier -force -label CREATE_POWER
save_lib -all

puts "RM-info : Power Planning Completed Successfully"

estimate_timing
redirect -file $REPORTS_DIR_TIMING_ESTIMATION/${DESIGN_NAME}.post_estimated_timing.rpt     {report_timing -corner estimated_corner -mode [all_modes]}
redirect -file $REPORTS_DIR_TIMING_ESTIMATION/${DESIGN_NAME}.post_estimated_timing.qor     {report_qor    -corner estimated_corner}
redirect -file $REPORTS_DIR_TIMING_ESTIMATION/${DESIGN_NAME}.post_estimated_timing.qor.sum {report_qor    -summary}

save_block -hier -force   -label ${TIMING_ESTIMATION_LABEL_NAME}
save_lib -all


set path_dir [file normalize ${WORK_DIR_WRITE_DATA}]
set write_block_data_script ./write_block_data.tcl
source ${write_block_data_script}

