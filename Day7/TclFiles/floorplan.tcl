################################################################################
# SYNOPSYS ICC2 FLOORPLAN SCRIPT
################################################################################

################################################################################
# COMMON SETUP
################################################################################
source -echo ./icc2_common_setup.tcl
source -echo ./icc2_dp_setup.tcl


################################################################################
# OPEN / CREATE LIBRARY
################################################################################
if {![file exists ${WORK_DIR}/${DESIGN_LIBRARY}]} {
   puts "RM-info : Creating library $DESIGN_LIBRARY"
   create_lib ${WORK_DIR}/${DESIGN_LIBRARY} \
      -ref_libs $REFERENCE_LIBRARY \
      -tech $TECH_FILE
} else {
   puts "RM-info : Opening existing library $DESIGN_LIBRARY"
}

open_lib ${WORK_DIR}/${DESIGN_LIBRARY}


################################################################################
# READ NETLIST
################################################################################
puts "RM-info : Reading netlist"

read_verilog \
   -design ${DESIGN_NAME}/${INIT_DP_LABEL_NAME} \
   -top ${DESIGN_NAME} \
   ${VERILOG_NETLIST_FILES}


################################################################################
# TECH + TLU+
################################################################################
if {[file exists [which $TCL_TECH_SETUP_FILE]]} {
   source -echo $TCL_TECH_SETUP_FILE
}

if {[file exists [which $TCL_PARASITIC_SETUP_FILE]]} {
   source -echo $TCL_PARASITIC_SETUP_FILE
}


################################################################################
# FLOORPLAN
################################################################################
puts "RM-info : Initializing floorplan"

initialize_floorplan \
   -control_type die \
   -boundary {{0 0} {3588 5188}} \
   -core_offset {300 300 300 300}

save_block -force -label floorplan


################################################################################
# POWER NET CONNECTION (EARLY)
################################################################################
connect_pg_net -automatic -all_blocks
save_block -force -label pre_shape


################################################################################
# IO PAD PLACEMENT
################################################################################
if {[file exists [which $TCL_PAD_CONSTRAINTS_FILE]]} {
   source -echo $TCL_PAD_CONSTRAINTS_FILE
   place_io
}

# Fix IO locations
set_attribute \
   [get_cells -hier -filter "pad_cell==true"] \
   status fixed


################################################################################
# PAD KEEP-OUTS (HARD)
################################################################################
puts "RM-info : Creating hard keepout around IO pads"

create_keepout_margin \
   -type hard \
   -outer {8 8 8 8} \
   [get_cells -hier -filter "pad_cell==true"]


################################################################################
# HARD PLACEMENT BLOCKAGES AROUND CORE EDGE
################################################################################
puts "RM-info : Creating hard placement blockages around core boundary"

# Core boundary = {{300 300} {3288 4888}}
# Creating 20um hard blockage band inside core edge

create_placement_blockage -type hard \
   -boundary {{300 300} {3288 320}} \
   -name core_hard_blockage_bottom

create_placement_blockage -type hard \
   -boundary {{300 4868} {3288 4888}} \
   -name core_hard_blockage_top

create_placement_blockage -type hard \
   -boundary {{300 320} {320 4868}} \
   -name core_hard_blockage_left

create_placement_blockage -type hard \
   -boundary {{3268 320} {3288 4868}} \
   -name core_hard_blockage_right


################################################################################
# SRAM MACRO PLACEMENT
################################################################################
puts "RM-info : Placing SRAM macro"

set sram [get_cells -quiet sram]

if {[sizeof_collection $sram] > 0} {

   set_attribute $sram origin {365.4500 4544.9250}
   set_attribute $sram orientation MXR90
   set_attribute $sram status placed
}


################################################################################
# MACRO HALOS WITH ASYMMETRIC SPACING
################################################################################
set macros [get_cells -hier -filter "is_hard_macro==true"]

if {[sizeof_collection $macros] > 0} {

   puts "RM-info : Creating asymmetric halos around macros"

   # Create minimum halo (2um) on top, bottom, right
   # No halo on left side (will be blocked separately)
   create_keepout_margin \
      -type hard \
      -outer {0 2 2 2} \
      $macros
}


################################################################################
# HARD BLOCKAGE ON LEFT SIDE OF MACRO TO CORE EDGE
################################################################################
puts "RM-info : Creating hard blockage from macro left side to core edge"

if {[sizeof_collection $sram] > 0} {
   
   # Create hard blockage with specified coordinates
   create_placement_blockage -type hard \
      -boundary {{320.0000 4522.9250} {594.5300 4802.9150}} \
      -name macro_left_side_blockage
   
   puts "RM-info : Hard blockage created from (320.0000, 4522.9250) to (594.5300, 4802.9150)"
}


################################################################################
# MCMM CONSTRAINTS
################################################################################
if {[file exists $TCL_MCMM_SETUP_FILE]} {
   source -echo $TCL_MCMM_SETUP_FILE
}


################################################################################
# PLACEMENT CONFIG
################################################################################
set plan.place.auto_generate_blockages true
set_app_options -name place_opt.flow.do_spg -value true
set_app_options -name route.global.timing_driven -value true


################################################################################
# GLOBAL DENSITY CONTROL
################################################################################
set_attribute [current_design] place_global_density 0.65


################################################################################
# FIX MACROS
################################################################################
if {[sizeof_collection $macros] > 0} {
   set_attribute $macros status fixed
}


################################################################################
# PIN PLACEMENT
################################################################################
if {[file exists [which $TCL_PIN_CONSTRAINT_FILE]] && !$PLACEMENT_PIN_CONSTRAINT_AWARE} {
   source -echo $TCL_PIN_CONSTRAINT_FILE
}

set_app_options -as_user_default -list {route.global.timing_driven true}

if {$CHECK_DESIGN} {
   redirect -file ${REPORTS_DIR_PLACE_PINS}/check_design.pre_pin_placement {check_design -ems_database check_design.pre_pin_placement.ems -checks dp_pre_pin_placement}
}

if {$PLACE_PINS_SELF} {
   place_pins -self
}

if {$PLACE_PINS_SELF} {
   # Write top-level port constraint file based on actual port locations
   write_pin_constraints -self \
      -file_name $OUTPUTS_DIR/preferred_port_locations.tcl \
      -physical_pin_constraint {side | offset | layer} \
      -from_existing_pins

   # Verify Top-level Port Placement Results
   check_pin_placement -self -pre_route true -pin_spacing true -sides true -layers true -stacking true

   # Generate Top-level Port Placement Report
   report_pin_placement -self > $REPORTS_DIR_PLACE_PINS/report_port_placement.rpt
}

save_block -hier -force -label ${PLACE_PINS_LABEL_NAME}
save_lib -all


################################################################################
# SAVE SNAPSHOT
################################################################################
save_block -hier -force -label placement_ready
save_lib -all

puts "\n===== FLOORPLAN COMPLETED SUCCESSFULLY =====\n"

