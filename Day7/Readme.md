# Raven Physical Design Documentation
## Complete ICC2 Implementation Flow

<img width="714" height="650" alt="image" src="https://github.com/user-attachments/assets/91c2eed4-5cf5-47b1-8429-fd20d2fc9898" />


---

## Table of Contents
1. [Overview](#overview)
2. [Design Specifications](#design-specifications)
3. [Prerequisites](#prerequisites)
4. [Design Setup](#design-setup)
5. [Floorplanning](#floorplanning)
6. [Power Planning](#power-planning)
7. [Placement, CTS, and Routing](#placement-cts-and-routing)
8. [Results and Verification](#results-and-verification)
9. [Directory Structure](#directory-structure)

---

## Overview

This repository contains the complete physical design implementation of the **Raven wrapper** chip using **Synopsys IC Compiler II (ICC2)**. The design uses the **NangateOpenCellLibrary** standard cell library with **FreePDK45** technology.

### Design Information
- **Design Name:** `raven_wrapper`
- **Technology:** FreePDK45 (45nm)
- **Standard Cell Library:** NangateOpenCellLibrary
- **SRAM Macro:** `sram_32_1024_freepdk45`
- **Die Size:** 3588µm × 5188µm
- **Core Area:** 2988µm × 4588µm (after 300µm offset)
- **Target Clock Frequency:** 100 MHz (10ns period)

---

## Design Specifications

### Technology Stack
- **Tool:** Synopsys IC Compiler II (P-2019.03-SP4)
- **Technology File:** `nangate.tf`
- **LEF Files:** 
  - `nangate_stdcell.lef`
  - `sram_32_1024_freepdk45.lef`
- **Library Files:**
  - `nangate_typical.db`
  - `sram_32_1024_freepdk45_TT_1p0V_25C_lib.db`

### Metal Stack
- **Routing Layers:** Metal1 - Metal10
- **Power Grid:** Metal9 (Vertical), Metal10 (Horizontal)
- **Standard Cell Rails:** Metal1

| Layer | Direction | Usage |
|-------|-----------|-------|
| Metal1 | Horizontal | Standard cell rails, local routing |
| Metal2 | Vertical | Local routing |
| Metal3 | Horizontal | Macro pin connections |
| Metal4 | Vertical | Signal routing |
| Metal5 | Horizontal | Signal routing |
| Metal6 | Vertical | Signal routing |
| Metal7 | Horizontal | Signal routing |
| Metal8 | Vertical | Signal routing |
| Metal9 | Horizontal | Power mesh (vertical stripes) |
| Metal10 | Vertical | Power mesh (horizontal stripes) |

### Clock Specifications
```tcl
# Three clock domains at 100 MHz (10ns period)
- ext_clk:  10.0 ns period
- pll_clk:  10.0 ns period  
- spi_sck:  10.0 ns period
```

---

## Prerequisites

### Required Files
1. **Verilog Netlist:** `raven_wrapper.synth.v`
2. **Technology File:** `nangate.tf`
3. **LEF Files:** Standard cell and SRAM LEF files
4. **Timing Libraries:** `.db` files for standard cells and SRAM
5. **TLU+ Files:** Parasitic extraction models
6. **Constraint Files:** MCMM setup, timing constraints

### Directory Setup
```bash
# clone the repository
git clone https://github.com/kunalg123/icc2_workshop_collaterals
```

---

## Design Setup

<details>
  <summary>icc2_common_setup.tcl</summary>

```
puts "RM-info : Running script [info script]\n"

##########################################################################################
# Tool: IC Compiler II
# Script: icc2_common_setup.tcl
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

##########################################################################################
## Required variables
## These variables must be correctly filled in for the flow to run properly
##########################################################################################
set DESIGN_NAME 		"raven_wrapper" ;# Required; name of the design to be worked on; also used as the block name when scripts save or copy a block
set LIBRARY_SUFFIX		"Nangate" ;# Suffix for the design library name ; default is unspecified   
set DESIGN_LIBRARY 		"${DESIGN_NAME}${LIBRARY_SUFFIX}" ;# Name of the design library; default is ${DESIGN_NAME}${LIBRARY_SUFFIX}
set REFERENCE_LIBRARY 		[list /home/b_jayeshk/icc2_workshop_collaterals/nangate_stdcell.lef /home/b_jayeshk/icc2_workshop_collaterals/sram_32_1024_freepdk45.lef]	;# Required; a list of reference libraries for the design library.
					;#	for library configuration flow (LIBRARY_CONFIGURATION_FLOW set to true below): 
					;#		- specify the list of physical source files to be used for library configuration during create_lib
				       	;# 	for hierarchical designs using bottom-up flows: include subblock design libraries in the list;
					;# 	for hierarchical designs using ETMs: include the ETM library in the list.
					;# 		- If unpack_rm_dirs.pl is used to create dir structures for hierarchical designs, 
					;#		  in order to transition between hierarchical DP and hierarchical PNR flows properly, 
					;#		  absolute paths are a requirement.
set COMPRESS_LIBS               "false" ;# Save libs as compressed NDM; only used in DP.
#set VERILOG_NETLIST_FILES      "/home/kunal/workshop/icc2_workshop_collaterals/pnrScripts/spi_slave.synth.v"
set VERILOG_NETLIST_FILES	"/home/b_jayeshk/icc2_workshop_collaterals/raven_wrapper.synth.v"	;# Verilog netlist files;
					;# 	for DP: required
					;# 	for PNR: required if INIT_DESIGN_INPUT is ASCII in icc2_pnr_setup.tcl; not required for DC_ASCII or DP_RM_NDM
set UPF_FILE 			""	;# A UPF file
					;# 	for DP: required
					;# 	for PNR: required if INIT_DESIGN_INPUT is ASCII in icc2_pnr_setup.tcl; not required for DC_ASCII or DP_RM_NDM
                                        ;#          for hierarchical designs using ETMs, load the block upf file
                                        ;#          for each sub-block linked to ETM, include the following line in the UPF_FILE 
                			;#              load_upf block.upf -scope block_instance_name
set UPF_SUPPLEMENTAL_FILE	""      ;# The supplemental UPF file. Only needed if you are running golden UPF flow, in which case, you need both UPF_FILE and this.
					;# 	for DP: required
					;# 	for PNR: required if INIT_DESIGN_INPUT is ASCII in icc2_pnr_setup.tcl; not required for DC_ASCII or DP_RM_NDM
					;#	    If UPF_SUPPLEMENTAL_FILE is specified, scripts assume golden UPF flow. load_upf and save_upf commands will be different.	

set TCL_PARASITIC_SETUP_FILE	"./init_design.read_parasitic_tech_example.tcl"	;# Specify a Tcl script to read in your TLU+ files by using the read_parasitic_tech command;
					;# refer to the example in templates/init_design.read_parasitic_tech_example.tcl 

#set TCL_MCMM_SETUP_FILE         ""
set TCL_MCMM_SETUP_FILE		"./init_design.mcmm_example.auto_expanded.tcl"	;# Specify a Tcl script to create your corners, modes, scenarios and load respective constraints;
					;# two examples are provided in templates/: 
					;# init_design.mcmm_example.explicit.tcl: provide mode, corner, and scenario constraints; create modes, corners, 
					;# and scenarios; source mode, corner, and scenario constraints, respectively 
					;# init_design.mcmm_example.auto_expanded.tcl: provide constraints for the scenarios; create modes, corners, 
					;# and scenarios; source scenario constraints which are then expanded to associated modes and corners
					;# 	for DP: required
					;# 	for PNR: required if INIT_DESIGN_INPUT is ASCII in icc2_pnr_setup.tcl; not required for DC_ASCII or DP_RM_NDM

set TECH_FILE 			"/home/b_jayeshk/icc2_workshop_collaterals/nangate.tf" 	;# A technology file; TECH_FILE and TECH_LIB are mutually exclusive ways to specify technology information; 
					;# TECH_FILE is recommended, although TECH_LIB is also supported in ICC2 RM. 
set TECH_LIB			""	;# Specify the reference library to be used as a dedicated technology library;
                        		;# as a best practice, please list it as the first library in the REFERENCE_LIBRARY list 
set TECH_LIB_INCLUDES_TECH_SETUP_INFO true 
					;# Indicate whether TECH_LIB contains technology setup information such as routing layer direction, offset, 
					;# site default, and site symmetry, etc. TECH_LIB may contain this information if loaded during library prep.
					;# true|false; this variable is associated with TECH_LIB. 
set TCL_TECH_SETUP_FILE		"./init_design.tech_setup.tcl"
					;# Specify a TCL script for setting routing layer direction, offset, site default, and site symmetry list, etc.
					;# init_design.tech_setup.tcl is the default. Use it as a template or provide your own script.
					;# This script will only get sourced if the following conditions are met: 
					;# (1) TECH_FILE is specified (2) TECH_LIB is specified && TECH_LIB_INCLUDES_TECH_SETUP_INFO is false 
set ROUTING_LAYER_DIRECTION_OFFSET_LIST "{metal1 horizontal} {metal2 vertical} {metal3 horizontal} {metal4 vertical} {metal5 horizontal} {metal6 vertical} {metal7 horizontal} {metal8 vertical} {metal9 horizontal} {metal10 vertical}" 
					;# Specify the routing layers as well as their direction and offset in a list of space delimited pairs;
					;# This variable should be defined for all metal routing layers in technology file;
					;# Syntax is "{metal_layer_1 direction offset} {metal_layer_2 direction offset} ...";
					;# It is required to at least specify metal layers and directions. Offsets are optional. 
					;# Example1 is with offsets specified: "{M1 vertical 0.2} {M2 horizontal 0.0} {M3 vertical 0.2}"
					;# Example2 is without offsets specified: "{M1 vertical} {M2 horizontal} {M3 vertical}"
##########################################################################################
## Optional variables
## Specify these variables if the corresponding functions are desired 
##########################################################################################
set DESIGN_LIBRARY_SCALE_FACTOR	""	;# Specify the length precision for the library. Length precision for the design
					;# library and its ref libraries must be identical. Tool default is 10000, which
					;# implies one unit is one Angstrom or 0.1nm.

set UPF_UPDATE_SUPPLY_SET_FILE	""	;# A UPF file to resolve UPF supply sets

#set DEF_FLOORPLAN_FILES		"/home/kunal/design/scripts/pnr/ICC2-RM_P-2019.03-SP4/write_data_dir/picorv32/picorv32.icc.floorplan/floorplan.def.gz"	;# DEF files which contain the floorplan information;
set DEF_FLOORPLAN_FILES                ""  ;# DEF files which contain the floorplan information;
					;# 	for DP: not required
					;# 	for PNR: required if INIT_DESIGN_INPUT = ASCII in icc2_pnr_setup.tcl and neither TCL_FLOORPLAN_FILE or 
					;#		 initialize_floorplan is used; DEF_FLOORPLAN_FILES and TCL_FLOORPLAN_FILE are mutually exclusive;
					;# 	         not required if INIT_DESIGN_INPUT = DC_ASCII or DP_RM_NDM

set DEF_SCAN_FILE		""	;# A scan DEF file for scan chain information;
					;# 	for PNR: not required if INIT_DESIGN_INPUT = DC_ASCII or DP_RM_NDM, as SCANDEF is expected to be loaded already

set DEF_SITE_NAME_PAIRS		{}	;# A list of site name pairs for read_def -convert; 
					;# specify site name pairs with from_site first followed by to_site;
					;# Example: set DEF_SITE_NAME_PAIRS {{from_site_1 to_site_1} {from_site_2 to_site_2}} 	
set SITE_DEFAULT		""	;# Specify the default site name if there are multiple site defs in the technology file;
					;# this is to be used by initialize_floorplan command; example: set SITE_DEFAULT "unit";
					;# this is applied in the init_design.tech_setup.tcl script 
set SITE_SYMMETRY_LIST	""		;# Specify a list of site def and its symmetry value;
					;# this is to be used by read_def or initialize_floorplan command to control the site symmetry;
					;# example: set SITE_SYMMETRY_LIST "{unit Y} {unit1 Y}"; this is applied in the init_design.tech_setup.tcl script 

set MIN_ROUTING_LAYER		"metal1"	;# Min routing layer name; normally should be specified; otherwise tool can use all metal layers
set MAX_ROUTING_LAYER		"metal10"	;# Max routing layer name; normally should be specified; otherwise tool can use all metal layers

set LIBRARY_CONFIGURATION_FLOW	false	;# Set it to true enables library configuration flow which calls the library manager under the hood to generate .nlibs, 
					;# save them to disk, and automatically link them to the design.
					;# Requires LINK_LIBRARY to be specified with .db files and REFERENCE_LIBRARY to be specified with physical
					;# source files for the library configuration flow. Also search_path (in icc2_pnr_setup.tcl) should include paths 
					;# to these .db and physical source files.

set LINK_LIBRARY		[list /home/b_jayeshk/icc2_workshop_collaterals/nangate_typical.db /home/b_jayeshk/icc2_workshop_collaterals/sram_32_1024_freepdk45_TT_1p0V_25C_lib.db]	;# Specify .db files;
					;# 	for running VC-LP (vc_lp.tcl) and Formality (fm.tcl): required
					;# 	for ICC-II without LIBRARY_CONFIGURATION_FLOW enabled: not required
					;#	for ICC-II with LIBRARY_CONFIGURATION_FLOW enabled: required; 
					;#      	- the .db files specified will be used for the library configuration under the hood during create_lib 

##########################################################################################
## Variables related to flow controls of flat PNR, hierarchical PNR and transition with DP
##########################################################################################
set DESIGN_STYLE		"hier"	;# Specify the design style; flat|hier; default is flat; 
					;# specify flat for a totally flat flow (flat PNR for short) and 
					;# specify hier for a hierarchical flow (hier PNR for short);
					;# 	for hier PNR: required and auto set if unpack_rm_dirs.pl is used; (see README.unpack_rm_dirs.txt for details)
					;# 	for flat PNR: this should set to flat (default)
					;#	for DP: not used 

set PHYSICAL_HIERARCHY_LEVEL	"" 	;# Specify the current level of hierarchy for the hierarchical PNR flow; top|intermediate|bottom;
					;# 	for hier PNR: required and auto set if unpack_rm_dirs.pl is used; (see README.unpack_rm_dirs.txt for details)
					;# 	for flat PNR and for DP: not used.
set RELEASE_DIR_DP		"write_data_dir_hier" 	;# Specify the release directory of DP RM; 
					;# this is where init_design.tcl of PNR flow gets DP RM released libraries;
					;# 	for hier PNR: required and auto set if unpack_rm_dirs.pl is used; (see README.unpack_rm_dirs.txt for details)
					;# 	for flat PNR: required if INIT_DESIGN_INPUT = DP_RM_NDM, as init_design.tcl needs to know where DP RM libraries are
					;#	for DP: not used 
set RELEASE_LABEL_NAME_DP 	"rave_wrapperNangate"	
					;# Specify the label name of the block in the DP RM released library;
					;# this is the label name which init_design.tcl of PNR flow will open. 
set RELEASE_DIR_PNR		"" 	;# Specify the release directory of PNR RM; 
					;# this is where the init_design.tcl of hierarchical PNR flow gets the sub-block libraries;	
					;# 	for hier PNR: required and auto set if unpack_rm_dirs.pl is used; (see README.unpack_rm_dirs.txt for details)
					;# 	for flat PNR and for DP: not used.
##########################################################################################
## Variables related to REDHAWK ANALYSIS FUSION
##########################################################################################
set REDHAWK_SEARCH_PATH		"" 	;# Required. Search path to the NDM, reference libraries, and etc.

puts "RM-info : Completed script [info script]\n"


```

</details>

### 1. Common Setup Script (`icc2_common_setup.tcl`)

This script defines all global variables and paths required for the design.

#### Key Variables Configured:

**Design Identity**
```tcl
set DESIGN_NAME "raven_wrapper"
set LIBRARY_SUFFIX "Nangate"
set DESIGN_LIBRARY "${DESIGN_NAME}${LIBRARY_SUFFIX}"
```

**Reference Libraries**
```tcl
set REFERENCE_LIBRARY [list \
    /path/to/nangate_stdcell.lef \
    /path/to/sram_32_1024_freepdk45.lef]
```

**Input Files**
```tcl
set VERILOG_NETLIST_FILES "/path/to/raven_wrapper.synth.v"
set TECH_FILE "/path/to/nangate.tf"
set TCL_MCMM_SETUP_FILE "./init_design.mcmm_example.auto_expanded.tcl"
set TCL_PARASITIC_SETUP_FILE "./init_design.read_parasitic_tech_example.tcl"
```

**Metal Layer Configuration**
```tcl
set ROUTING_LAYER_DIRECTION_OFFSET_LIST \
    "{metal1 horizontal} {metal2 vertical} {metal3 horizontal} \
     {metal4 vertical} {metal5 horizontal} {metal6 vertical} \
     {metal7 horizontal} {metal8 vertical} {metal9 horizontal} \
     {metal10 vertical}"

set MIN_ROUTING_LAYER "metal1"
set MAX_ROUTING_LAYER "metal10"
```

---

### 2. Design Planning Setup (`icc2_dp_setup.tcl`)

This script configures design planning specific options.

<details>
  <summary>icc2_dp_setup.tcl</summary>
	
```
puts "RM-info : Running script [info script]\n"
##########################################################################################
# Tool: IC Compiler II 
# Script: icc2_dp_setup.tcl 
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################

##########################################################################################
# 				Flow Setup
##########################################################################################
set DP_FLOW         "flat"    ;# hier or flat
set FLOORPLAN_STYLE "channel" ;# Supported design styles channel, abutted
set CHECK_DESIGN    "true"    ;# run atomic check_design pre checks prior to DP commands

set DISTRIBUTED 0  ;# Use distributed runs
### It is required to include the set_host_options command to enable distributed mode tasks. For example,
set_host_options -max_cores 8
#set_host_options -name block_script -submit_command [list qsub -P bnormal -l mem_free=6G,qsc=o -cwd]

set BLOCK_DIST_JOB_FILE             ""     ;# File to set block specific resource requests for distributed jobs
# For example:
#   set_host_options -name block_script  -submit_command "bsub -q normal"
#   set_host_options -name large_block   -submit_command "bsub -q huge"
#   set_host_options -name special_block -submit_command "rsh" local_machine
#   set_app_options -block [get_block block4] -list {plan.distributed_run.block_host large_block}
#   set_app_options -block [get_block block5] -list {plan.distributed_run.block_host large_block}
#   set_app_options -block [get_block block2] -list {plan.distributed_run.block_host special_block}
#  
#   All the jobs associated with blocks that do not have the plan.distributed_run.block_host app option specified
#   will run using the block_script host option. The jobs for blocks block4 and block5 will use the large_block 
#   host option. The job form  block2  will  use  the  special_block host option.


##########################################################################################
# If the design is run with MIBs then change the block list appropriately
##########################################################################################
set DP_BLOCK_REFS                     [list] ;# design names for each physical block (including black boxes) in the design;
                                             ;# this includes bottom and mid level blocks in a Multiple Physical Hierarchy (MPH) design
set DP_INTERMEDIATE_LEVEL_BLOCK_REFS  [list data_memory] ;# design reference names for mid level blocks only
set DP_BB_BLOCK_REFS                  [list] ;# Black Box reference names 
set BOTTOM_BLOCK_VIEW             "abstract" ;# Support abstract or design view for bottom blocks
                                             ;# in the hier flow
set INTERMEDIATE_BLOCK_VIEW       "abstract" ;# Support abstract or design view for intermediate blocks

if { [info exists INTERMEDIATE_BLOCK_VIEW] && $INTERMEDIATE_BLOCK_VIEW == "abstract" } {
   set_app_options -name abstract.allow_all_level_abstract -value true  ;# Dafult value is false
}

# Provide blackbox instanace: target area, BB UPF file, BB Timing file, boundary
#set DP_BB_BLOCK_REFS "leon3s_bb"
#set DP_BB_BLOCKS(leon3s_bb,area)        [list 1346051] ;
#set DP_BB_BLOCKS(leon3s_bb,upf)         [list ${des_dir}/leon3s_bb.upf] ;
#set DP_BB_BLOCKS(leon3s_bb,timing)      [list ${des_dir}/leon3s_bbt.tcl] ;
#set DP_BB_BLOCKS(leon3s_bb,boundary)    { {x1 y1} {x2 y1} {x2 y2} {x1 y2} {x1 y1} } ;
#set DP_BB_SPLIT    "true"


##########################################################################################
# 				CONSTRAINTS / UPF INTENT
##########################################################################################
set TCL_TIMING_RULER_SETUP_FILE       "" ;# file sourced to define parasitic constraints for use with timing ruler 
                                          # before full extraction environment is defined
                                          # Example setup file:
                                          #       set_parasitic_parameters \
                                          #         -early_spec para_WORST \
                                          #         -late_spec para_WORST
set CONSTRAINT_MAPPING_FILE           "" ;# Constraint Mapping File. Default is "split/mapfile"
set TCL_UPF_FILE                      "" ;# Optional power intent TCL script


##########################################################################################
# 				TOP LEVEL FLOORPLAN CREATION (die, pad, RDL) / PLACE IO
##########################################################################################
set TCL_PHYSICAL_CONSTRAINTS_FILE     "" ;# TCL script for primary die area creation. If specified, DEF_FLOORPLAN_FILES will be loaded after TCL_PHYSICAL_CONSTRAINTS_FILE
set TCL_PRE_COMMIT_FILE               "" ;# file sourced to set attributes, lib cell purposes, .. etc on specific cells, prior to running commit_block
set TCL_USER_INIT_DP_POST_SCRIPT      "" ;# An optional Tcl file to be sourced at the very end of init_dp.tcl before save_block.


##########################################################################################
# 				PRE_SHAPING
##########################################################################################
set TCL_USER_PRE_SHAPING_PRE_SCRIPT   "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_PRE_SHAPING_POST_SCRIPT  "" ;# An optional Tcl file to be sourced at the very end of the task

##########################################################################################
# 				PLACE_IO
##########################################################################################
set TCL_PAD_CONSTRAINTS_FILE          "/home/b_jayeshk/icc2_workshop_collaterals/pad_placement_constraints.tcl" ;# file sourced to create everything needed by place_io to complete IO placement
                                         ;# including flip chip bumps, and io constraints
set TCL_RDL_FILE                      "" ;# file sourced to create RDL routes
set TCL_USER_PLACE_IO_PRE_SCRIPT      "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_PLACE_IO_POST_SCRIPT     "" ;# An optional Tcl file to be sourced at the very end of the task


##########################################################################################
# 				SHAPING
##########################################################################################
switch $FLOORPLAN_STYLE {
   channel {set SHAPING_CMD_OPTIONS           "-channels true"} 
   abutted {set SHAPING_CMD_OPTIONS           "-channels false"} 
}

set TCL_SHAPING_CONSTRAINTS_FILE      "" ;# Specify any constraints prior to shaping i.e. set_shaping_options
                                          # or specify some block shapes manually, for example:
                                          #    set_block_boundary -cell block1 -boundary {{2.10 2.16} {2.10 273.60} \
                                          #    {262.02 273.60} {262.02 2.16}} -orientation R0
                                          #    set_fixed_objects [get_cells block1]
                                          # Support TCL based shaping constraints
                                          # An example is in rm_icc2_dp_scripts/tcl_shaping_constraints_example.tcl
set SHAPING_CONSTRAINTS_FILE          "" ;# Will be included as the -constraint_file option for shape_blocks
set TCL_SHAPING_PNS_STRATEGY_FILE     "" ;# file sourced to create PG strategies for block grid creation
set TCL_MANUAL_SHAPING_FILE           "" ;# File sourced to re-create all block shapes.
                                          # If this file exists, automatic shaping will be by-passed.
                                          # Existing auto or manual block shapes can be written out using the following:
                                          #    write_floorplan -objects <BLOCK_INSTS>
set TCL_USER_SHAPING_PRE_SCRIPT       "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_SHAPING_POST_SCRIPT      "" ;# An optional Tcl file to be sourced at the very end of the task


##########################################################################################
# 				PLACEMENT
##########################################################################################
set TCL_PLACEMENT_CONSTRAINTS_FILE    "" ;# Placeholder for any macro or standard cell placement constraints & options.
                                          # File is sourced prior to DP placement
set PLACEMENT_PIN_CONSTRAINT_AWARE    "false" ;# tells create_placement to consider pin constraints during placement
set USE_INCREMENTAL_DATA              "0" ;# Use floorplan constraints that were written out on a previous run
set CONGESTION_DRIVEN_PLACEMENT       "" ;# Set to one of the following: std_cell, macro, or both to enable congestion driven placement
set TIMING_DRIVEN_PLACEMENT           "" ;# Set to one of the following: std_cell, macro, or both to enable timing driven placement
set TCL_USER_PLACEMENT_PRE_SCRIPT     "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_PLACEMENT_POST_SCRIPT    "" ;# An optional Tcl file to be sourced at the very end of the task


##########################################################################################
#				GLOBAL PLANNING
##########################################################################################
set TCL_GLOBAL_PLANNING_FILE          "" ;#Global planning for bus/critical nets


##########################################################################################
# 				PNS
##########################################################################################
set TCL_PNS_FILE                      "./pns_example.tcl" ;# File sourced to define all power structures. 
                                          # This file will include the following types of PG commands:
                                          #   PG Regions
                                          #   PG Patterns
                                          #   PG Strategies
                                          # Note: The file should not contain compile_pg statements
                                          # An example is in rm_icc2_dp_scripts/pns_example.tcl
set PNS_CHARACTERIZE_FLOW             "true"  ;# Perform PG characterization and implementation
set TCL_COMPILE_PG_FILE               "./compile_pg_example.tcl" ;# File should contain all the compile_pg_* commands to create the power networks 
                                          # specified in the strategies in the TCL_PNS_FILE. 
                                          # An example is in rm_icc2_dp_scripts/compile_pg_example.tcl
set TCL_PG_PUSHDOWN_FILE              "" ;# Create this file to facilitate manual pushdown and bypass auto pushdown in the flow.
set TCL_POST_PNS_FILE                 "" ;# If it exists, this file will be sourced after PG creation.
set TCL_USER_CREATE_POWER_PRE_SCRIPT  "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_CREATE_POWER_POST_SCRIPT "" ;# An optional Tcl file to be sourced at the very end of the task


##########################################################################################
# 				PLACE PINS
##########################################################################################
##Note:Feedthroughs are disabled by default. Enable feedthroughs either through set_*_pin_constraints  Tcl commands or through Pin constraints file
set TCL_PIN_CONSTRAINT_FILE           "" ;# file sourced to apply set_*_pin_constraints to the design
set CUSTOM_PIN_CONSTRAINT_FILE        "" ;# will be loaded via read_pin_constraints -file
                                         ;# used for more complex pin constraints, 
                                         ;# or in constraint replay
set PLACE_PINS_SELF                   "true" ;# Set to true if the block's top level pins are not all connected to IO drivers.
set TIMING_PIN_PLACEMENT              "true" ;# Set to true for timing driven pin placement
set TCL_USER_PLACE_PINS_PRE_SCRIPT    "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_PLACE_PINS_POST_SCRIPT   "" ;# An optional Tcl file to be sourced at the very end of the task


##########################################################################################
# 				PRE-TIMING
##########################################################################################
set TCL_USER_PRE_TIMING_PRE_SCRIPT    "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_PRE_TIMING_POST_SCRIPT   "" ;# An optional Tcl file to be sourced at the very end of the task


##########################################################################################
# 				TIMING ESTIMATION
##########################################################################################
set TCL_TIMING_ESTIMATION_SETUP_FILE       "" ;# Specify any constraints prior to timing estimation
set TCL_USER_TIMING_ESTIMATION_PRE_SCRIPT  "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_TIMING_ESTIMATION_POST_SCRIPT "" ;# An optional Tcl file to be sourced at the very end of the task
set TCL_LIB_CELL_DONT_USE_FILE             "" ;# A Tcl file for customized don't use ("set_lib_cell_purpose -exclude <purpose>" commands);
                                              ;#  to prevent estimate_timing picking a lib_cell not used by pnr flow.
                                              ;#  please specify non-optimization purpose lib cells in the file. 


##########################################################################################
# 				BUDGETING
##########################################################################################
set TCL_BUDGETING_SETUP_FILE                "" ;# Specify any constraints prior to budgeting
set TCL_BOUNDARY_BUDGETING_CONSTRAINTS_FILE "" ;# An optional user constraints file to override compute_budget_constraints
set TCL_USER_BUDGETING_PRE_SCRIPT           "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_BUDGETING_POST_SCRIPT          "" ;# An optional Tcl file to be sourced at the very end of the task


##########################################################################################
## System Variables (there's no need to change the following)
##########################################################################################
set WORK_DIR ./work
set WORK_DIR_WRITE_DATA ./write_data_dir
if !{[file exists $WORK_DIR]} {file mkdir $WORK_DIR}

set SPLIT_CONSTRAINTS_LABEL_NAME split_constraints
set INIT_DP_LABEL_NAME init_dp
set PRE_SHAPING_LABEL_NAME pre_shaping
set PLACE_IO_LABEL_NAME place_io
set SHAPING_LABEL_NAME shaping
set PLACEMENT_LABEL_NAME placement
set CREATE_POWER_LABEL_NAME create_power
set CLOCK_TRUNK_PLANNING_LABEL_NAME clock_trunk_planning
set PLACE_PINS_LABEL_NAME place_pins
set PRE_TIMING_LABEL_NAME pre_timing
set TIMING_ESTIMATION_LABEL_NAME timing_estimation
set BUDGETING_LABEL_NAME budgeting

# Block label to be release by write_data
if {$DP_FLOW == "flat"} {
   set WRITE_DATA_LABEL_NAME timing_estimation
} else {
   set WRITE_DATA_LABEL_NAME budgeting
}

## Directories
set OUTPUTS_DIR	"./outputs_icc2"	;# Directory to write output data files; mainly used by write_data.tcl
set REPORTS_DIR	"./rpts_icc2"		;# Directory to write reports; mainly used by report_qor.tcl

set REPORTS_DIR_SPLIT_CONSTRAINTS $REPORTS_DIR/$SPLIT_CONSTRAINTS_LABEL_NAME
set REPORTS_DIR_INIT_DP $REPORTS_DIR/$INIT_DP_LABEL_NAME
set REPORTS_DIR_PRE_SHAPING $REPORTS_DIR/$PRE_SHAPING_LABEL_NAME
set REPORTS_DIR_PLACE_IO $REPORTS_DIR/$PLACE_IO_LABEL_NAME
set REPORTS_DIR_SHAPING $REPORTS_DIR/$SHAPING_LABEL_NAME
set REPORTS_DIR_PLACEMENT $REPORTS_DIR/$PLACEMENT_LABEL_NAME
set REPORTS_DIR_CREATE_POWER $REPORTS_DIR/$CREATE_POWER_LABEL_NAME
set REPORTS_DIR_CLOCK_TRUNK_PLANNING $REPORTS_DIR/$CLOCK_TRUNK_PLANNING_LABEL_NAME
set REPORTS_DIR_PLACE_PINS $REPORTS_DIR/$PLACE_PINS_LABEL_NAME
set REPORTS_DIR_PRE_TIMING $REPORTS_DIR/$PRE_TIMING_LABEL_NAME
set REPORTS_DIR_TIMING_ESTIMATION $REPORTS_DIR/$TIMING_ESTIMATION_LABEL_NAME
set REPORTS_DIR_BUDGETING $REPORTS_DIR/$BUDGETING_LABEL_NAME

if !{[file exists $REPORTS_DIR]} {file mkdir $REPORTS_DIR}
if !{[file exists $OUTPUTS_DIR]} {file mkdir $OUTPUTS_DIR}
if !{[file exists $REPORTS_DIR_SPLIT_CONSTRAINTS]} {file mkdir $REPORTS_DIR_SPLIT_CONSTRAINTS}
if !{[file exists $REPORTS_DIR_INIT_DP]} {file mkdir $REPORTS_DIR_INIT_DP}
if !{[file exists $REPORTS_DIR_PRE_SHAPING]} {file mkdir $REPORTS_DIR_PRE_SHAPING}
if !{[file exists $REPORTS_DIR_PLACE_IO]} {file mkdir $REPORTS_DIR_PLACE_IO}
if !{[file exists $REPORTS_DIR_SHAPING]} {file mkdir $REPORTS_DIR_SHAPING}
if !{[file exists $REPORTS_DIR_PLACEMENT]} {file mkdir $REPORTS_DIR_PLACEMENT}
if !{[file exists $REPORTS_DIR_CREATE_POWER]} {file mkdir $REPORTS_DIR_CREATE_POWER}
if !{[file exists $REPORTS_DIR_CLOCK_TRUNK_PLANNING]} {file mkdir $REPORTS_DIR_CLOCK_TRUNK_PLANNING}
if !{[file exists $REPORTS_DIR_PLACE_PINS]} {file mkdir $REPORTS_DIR_PLACE_PINS}
if !{[file exists $REPORTS_DIR_PRE_TIMING]} {file mkdir $REPORTS_DIR_PRE_TIMING}
if !{[file exists $REPORTS_DIR_TIMING_ESTIMATION]} {file mkdir $REPORTS_DIR_TIMING_ESTIMATION}
if !{[file exists $REPORTS_DIR_BUDGETING]} {file mkdir $REPORTS_DIR_BUDGETING}


if {[info exists env(LOGS_DIR)]} {
   set log_dir $env(LOGS_DIR)
} else {
   set log_dir ./logs_icc2 
}


set search_path [list ./rm_icc2_dp_scripts ./rm_icc2_pnr_scripts $WORK_DIR ] 
lappend search_path .

##########################################################################################
# 				Optional Settings
##########################################################################################
set_message_info -id PVT-012 -limit 1
set_message_info -id PVT-013 -limit 1
set search_path "/home/b_jayeshk/icc2_workshop_collaterals/"
set_app_var link_library "nangate_typical.db sram_32_1024_freepdk45_TT_1p0V_25C_lib.db"

puts "RM-info : Completed script [info script]\n"
```
</details>


#### Flow Configuration:
```tcl
set DP_FLOW "flat"                  # Flat design flow
set FLOORPLAN_STYLE "channel"       # Channel-based floorplan
set CHECK_DESIGN "true"             # Enable design checks
set_host_options -max_cores 8       # Parallel processing
```

#### Key File Pointers:
```tcl
set TCL_PAD_CONSTRAINTS_FILE "/path/to/pad_placement_constraints.tcl"
set TCL_PNS_FILE "./pns_example.tcl"
set TCL_COMPILE_PG_FILE "./compile_pg_example.tcl"
set PLACE_PINS_SELF "true"
set TIMING_PIN_PLACEMENT "true"
```

---

#### IO Pad Placement Guides:
<details>
  <summary>pad_placement_constraints.tcl</summary>
	
```
set_attribute -objects [get_cells analog_out_sel_buf ] -name physical_status -value placed
set_attribute -objects [get_cells bg_ena_buf ] -name physical_status -value placed
set_attribute -objects [get_cells comp_ena_buf ] -name physical_status -value placed
set_attribute -objects [get_cells comp_in_buf ] -name physical_status -value placed
set_attribute -objects [get_cells comp_ninputsrc_buf ] -name physical_status -value placed
set_attribute -objects [get_cells comp_pinputsrc_buf ] -name physical_status -value placed
set_attribute -objects [get_cells ext_clk_buf ] -name physical_status -value placed
set_attribute -objects [get_cells ext_clk_sel_buf ] -name physical_status -value placed
set_attribute -objects [get_cells ext_reset_buf ] -name physical_status -value placed
set_attribute -objects [get_cells flash_clk_buf ] -name physical_status -value placed
set_attribute -objects [get_cells flash_csb_buf ] -name physical_status -value placed
set_attribute -objects [get_cells flash_io_buf_0 ] -name physical_status -value placed
set_attribute -objects [get_cells flash_io_buf_1 ] -name physical_status -value placed
set_attribute -objects [get_cells flash_io_buf_2 ] -name physical_status -value placed
set_attribute -objects [get_cells flash_io_buf_3 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio0 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio1 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio10 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio11 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio12 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio13 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio14 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio15 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio2 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio3 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio4 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio5 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio6 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio7 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio8 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio9 ] -name physical_status -value placed
set_attribute -objects [get_cells irq_pin_buf ] -name physical_status -value placed
set_attribute -objects [get_cells opamp_bias_ena_buf ] -name physical_status -value placed
set_attribute -objects [get_cells opamp_ena_buf ] -name physical_status -value placed
set_attribute -objects [get_cells overtemp_buf ] -name physical_status -value placed
set_attribute -objects [get_cells overtemp_ena_buf ] -name physical_status -value placed
set_attribute -objects [get_cells pll_clk_buf ] -name physical_status -value placed
set_attribute -objects [get_cells rcosc_ena_buf ] -name physical_status -value placed
set_attribute -objects [get_cells rcosc_in_buf ] -name physical_status -value placed
set_attribute -objects [get_cells reset_buf ] -name physical_status -value placed
set_attribute -objects [get_cells ser_rx_buf ] -name physical_status -value placed
set_attribute -objects [get_cells ser_tx_buf ] -name physical_status -value placed
set_attribute -objects [get_cells spi_sck_buf ] -name physical_status -value placed
set_attribute -objects [get_cells trap_buf ] -name physical_status -value placed
set_attribute -objects [get_cells xtal_in_buf ] -name physical_status -value placed
create_io_guide -side right -pad_cells {analog_out_sel_buf bg_ena_buf comp_ena_buf comp_in_buf comp_ninputsrc_buf comp_pinputsrc_buf ext_clk_buf ext_clk_sel_buf ext_reset_buf flash_clk_buf flash_csb_buf} -line {{1701 1402} 1101}
create_io_guide -side left -pad_cells {flash_io_buf_0 flash_io_buf_1 flash_io_buf_2 flash_io_buf_3 gpio0 gpio1 gpio10 gpio11 gpio12 gpio13 gpio14} -line {{ 0 300} 1101}
create_io_guide -side top -pad_cells {gpio15 gpio2 gpio3 gpio4 gpio5 gpio6 gpio7 gpio8 gpio9 irq_pin_buf opamp_bias_ena_buf} -line {{ 300 1701} 1101}
create_io_guide -side bottom -pad_cells {opamp_ena_buf overtemp_buf overtemp_ena_buf pll_clk_buf rcosc_ena_buf rcosc_in_buf reset_buf ser_rx_buf ser_tx_buf spi_sck_buf trap_buf xtal_in_buf} -line {{ 1402 0} 1101}


```

</details>

**Purpose:** Distributes IO pads along all four sides of the die for optimal signal routing

---

## Floorplanning

### Script Overview
The floorplanning script performs die/core definition, IO pad placement, macro placement, and blockage creation.

<details>
  <summary>floorplan.tcl</summary>

```
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

```

</details>


<details>
  <summary>floorplan.log</summary>

```
[SCL] 12/30/2025 11:11:02 PID:8158 Client:nanodc.iitgn.ac.in Authorization failed Synopsys 2022.12
[SCL] 12/30/2025 11:11:03 PID:8158 Client:nanodc.iitgn.ac.in Authorization failed Synopsys-Release 2022.12
[SCL] 12/30/2025 11:11:03 PID:8158 Client:nanodc.iitgn.ac.in Authorization failed Galaxy-Internal-Debug 2022.12
[icc2-lic Tue Dec 30 11:11:03 2025] Sending authorization request for 'ICCompilerII'
[SCL] 12/30/2025 11:11:03 PID:8158 Client:nanodc.iitgn.ac.in Authorization failed ICCompilerII 2022.12
[icc2-lic Tue Dec 30 11:11:03 2025] Authorization request for 'ICCompilerII' failed (-5)
[icc2-lic Tue Dec 30 11:11:03 2025] Sending authorization request for 'ICCompilerII-NX'
[SCL] 12/30/2025 11:11:04 PID:8158 Client:nanodc.iitgn.ac.in Server:27020@c2s.cdacb.in Authorization succeeded ICCompilerII-NX 2022.12
[icc2-lic Tue Dec 30 11:11:04 2025] Authorization request for 'ICCompilerII-NX' succeeded



                              IC Compiler II (TM)

                Version U-2022.12-SP3 for linux64 - Apr 18, 2023
  This release has significant feature enhancements. Please review the Release
                       Notes associated with this release.

                    Copyright (c) 1988 - 2023 Synopsys, Inc.
   This software and the associated documentation are proprietary to Synopsys,
 Inc. This software may only be used in accordance with the terms and conditions
 of a written license agreement with Synopsys, Inc. All other use, reproduction,
   or distribution of this software is strictly prohibited.  Licensed Products
     communicate with Synopsys servers for the purpose of providing software
    updates, detecting software piracy and verifying that customers are using
    Licensed Products in conformity with the applicable License Key for such
  Licensed Products. Synopsys will use information gathered in connection with
    this process to deliver software updates and pursue software pirates and
                                   infringers.

 Inclusivity & Diversity - Visit SolvNetPlus to read the "Synopsys Statement on
            Inclusivity and Diversity" (Refer to article 000036315 at
                        https://solvnetplus.synopsys.com)
 
################################################################################
# SYNOPSYS ICC2 FLOORPLAN SCRIPT
################################################################################
################################################################################
# COMMON SETUP
################################################################################
source -echo ./icc2_common_setup.tcl
puts "RM-info : Running script [info script]\n"
RM-info : Running script /home/prakhan/task_6/icc2_workshop_collaterals/standaloneFlow/icc2_common_setup.tcl

##########################################################################################
# Tool: IC Compiler II
# Script: icc2_common_setup.tcl
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################
##########################################################################################
## Required variables
## These variables must be correctly filled in for the flow to run properly
##########################################################################################
set DESIGN_NAME 		"raven_wrapper" ;# Required; name of the design to be worked on; also used as the block name when scripts save or copy a block
set LIBRARY_SUFFIX		"Nangate" ;# Suffix for the design library name ; default is unspecified   
set DESIGN_LIBRARY 		"${DESIGN_NAME}${LIBRARY_SUFFIX}" ;# Name of the design library; default is ${DESIGN_NAME}${LIBRARY_SUFFIX}
set REFERENCE_LIBRARY 		[list /home/prakhan/task_6/icc2_workshop_collaterals/nangate_stdcell.lef /home/prakhan/task_6/icc2_workshop_collaterals/sram/sram_32_1024_freepdk45.lef]	;# Required; a list of reference libraries for the design library.
;#	for library configuration flow (LIBRARY_CONFIGURATION_FLOW set to true below): 
;#		- specify the list of physical source files to be used for library configuration during create_lib
;# 	for hierarchical designs using bottom-up flows: include subblock design libraries in the list;
;# 	for hierarchical designs using ETMs: include the ETM library in the list.
;# 		- If unpack_rm_dirs.pl is used to create dir structures for hierarchical designs, 
;#		  in order to transition between hierarchical DP and hierarchical PNR flows properly, 
;#		  absolute paths are a requirement.
set COMPRESS_LIBS               "false" ;# Save libs as compressed NDM; only used in DP.
#set VERILOG_NETLIST_FILES      "/home/kunal/workshop/icc2_workshop_collaterals/pnrScripts/spi_slave.synth.v"
set VERILOG_NETLIST_FILES	"/home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v"	;# Verilog netlist files;
;# 	for DP: required
;# 	for PNR: required if INIT_DESIGN_INPUT is ASCII in icc2_pnr_setup.tcl; not required for DC_ASCII or DP_RM_NDM
set UPF_FILE 			""	;# A UPF file
;# 	for DP: required
;# 	for PNR: required if INIT_DESIGN_INPUT is ASCII in icc2_pnr_setup.tcl; not required for DC_ASCII or DP_RM_NDM
;#          for hierarchical designs using ETMs, load the block upf file
;#          for each sub-block linked to ETM, include the following line in the UPF_FILE 
;#              load_upf block.upf -scope block_instance_name
set UPF_SUPPLEMENTAL_FILE	""      ;# The supplemental UPF file. Only needed if you are running golden UPF flow, in which case, you need both UPF_FILE and this.
;# 	for DP: required
;# 	for PNR: required if INIT_DESIGN_INPUT is ASCII in icc2_pnr_setup.tcl; not required for DC_ASCII or DP_RM_NDM
;#	    If UPF_SUPPLEMENTAL_FILE is specified, scripts assume golden UPF flow. load_upf and save_upf commands will be different.	
set TCL_PARASITIC_SETUP_FILE	"./init_design.read_parasitic_tech_example.tcl"	;# Specify a Tcl script to read in your TLU+ files by using the read_parasitic_tech command;
;# refer to the example in templates/init_design.read_parasitic_tech_example.tcl 
#set TCL_MCMM_SETUP_FILE         ""
set TCL_MCMM_SETUP_FILE		"./init_design.mcmm_example.auto_expanded.tcl"	;# Specify a Tcl script to create your corners, modes, scenarios and load respective constraints;
;# two examples are provided in templates/: 
;# init_design.mcmm_example.explicit.tcl: provide mode, corner, and scenario constraints; create modes, corners, 
;# and scenarios; source mode, corner, and scenario constraints, respectively 
;# init_design.mcmm_example.auto_expanded.tcl: provide constraints for the scenarios; create modes, corners, 
;# and scenarios; source scenario constraints which are then expanded to associated modes and corners
;# 	for DP: required
;# 	for PNR: required if INIT_DESIGN_INPUT is ASCII in icc2_pnr_setup.tcl; not required for DC_ASCII or DP_RM_NDM
set TECH_FILE 			"/home/prakhan/task_6/icc2_workshop_collaterals/nangate.tf" 	;# A technology file; TECH_FILE and TECH_LIB are mutually exclusive ways to specify technology information; 
;# TECH_FILE is recommended, although TECH_LIB is also supported in ICC2 RM. 
set TECH_LIB			""	;# Specify the reference library to be used as a dedicated technology library;
;# as a best practice, please list it as the first library in the REFERENCE_LIBRARY list 
set TECH_LIB_INCLUDES_TECH_SETUP_INFO true 
;# Indicate whether TECH_LIB contains technology setup information such as routing layer direction, offset, 
;# site default, and site symmetry, etc. TECH_LIB may contain this information if loaded during library prep.
;# true|false; this variable is associated with TECH_LIB. 
set TCL_TECH_SETUP_FILE		"./init_design.tech_setup.tcl"
;# Specify a TCL script for setting routing layer direction, offset, site default, and site symmetry list, etc.
;# init_design.tech_setup.tcl is the default. Use it as a template or provide your own script.
;# This script will only get sourced if the following conditions are met: 
;# (1) TECH_FILE is specified (2) TECH_LIB is specified && TECH_LIB_INCLUDES_TECH_SETUP_INFO is false 
set ROUTING_LAYER_DIRECTION_OFFSET_LIST "{metal1 horizontal} {metal2 vertical} {metal3 horizontal} {metal4 vertical} {metal5 horizontal} {metal6 vertical} {metal7 horizontal} {metal8 vertical} {metal9 horizontal} {metal10 vertical}" 
;# Specify the routing layers as well as their direction and offset in a list of space delimited pairs;
;# This variable should be defined for all metal routing layers in technology file;
;# Syntax is "{metal_layer_1 direction offset} {metal_layer_2 direction offset} ...";
;# It is required to at least specify metal layers and directions. Offsets are optional. 
;# Example1 is with offsets specified: "{M1 vertical 0.2} {M2 horizontal 0.0} {M3 vertical 0.2}"
;# Example2 is without offsets specified: "{M1 vertical} {M2 horizontal} {M3 vertical}"
##########################################################################################
## Optional variables
## Specify these variables if the corresponding functions are desired 
##########################################################################################
set DESIGN_LIBRARY_SCALE_FACTOR	""	;# Specify the length precision for the library. Length precision for the design
;# library and its ref libraries must be identical. Tool default is 10000, which
;# implies one unit is one Angstrom or 0.1nm.
set UPF_UPDATE_SUPPLY_SET_FILE	""	;# A UPF file to resolve UPF supply sets
#set DEF_FLOORPLAN_FILES		"/home/kunal/design/scripts/pnr/ICC2-RM_P-2019.03-SP4/write_data_dir/picorv32/picorv32.icc.floorplan/floorplan.def.gz"	;# DEF files which contain the floorplan information;
set DEF_FLOORPLAN_FILES                ""  ;# DEF files which contain the floorplan information;
;# 	for DP: not required
;# 	for PNR: required if INIT_DESIGN_INPUT = ASCII in icc2_pnr_setup.tcl and neither TCL_FLOORPLAN_FILE or 
;#		 initialize_floorplan is used; DEF_FLOORPLAN_FILES and TCL_FLOORPLAN_FILE are mutually exclusive;
;# 	         not required if INIT_DESIGN_INPUT = DC_ASCII or DP_RM_NDM
set DEF_SCAN_FILE		""	;# A scan DEF file for scan chain information;
;# 	for PNR: not required if INIT_DESIGN_INPUT = DC_ASCII or DP_RM_NDM, as SCANDEF is expected to be loaded already
set DEF_SITE_NAME_PAIRS		{}	;# A list of site name pairs for read_def -convert; 
;# specify site name pairs with from_site first followed by to_site;
;# Example: set DEF_SITE_NAME_PAIRS {{from_site_1 to_site_1} {from_site_2 to_site_2}} 	
set SITE_DEFAULT		""	;# Specify the default site name if there are multiple site defs in the technology file;
;# this is to be used by initialize_floorplan command; example: set SITE_DEFAULT "unit";
;# this is applied in the init_design.tech_setup.tcl script 
set SITE_SYMMETRY_LIST	""		;# Specify a list of site def and its symmetry value;
;# this is to be used by read_def or initialize_floorplan command to control the site symmetry;
;# example: set SITE_SYMMETRY_LIST "{unit Y} {unit1 Y}"; this is applied in the init_design.tech_setup.tcl script 
set MIN_ROUTING_LAYER		"metal1"	;# Min routing layer name; normally should be specified; otherwise tool can use all metal layers
set MAX_ROUTING_LAYER		"metal10"	;# Max routing layer name; normally should be specified; otherwise tool can use all metal layers
set LIBRARY_CONFIGURATION_FLOW	false	;# Set it to true enables library configuration flow which calls the library manager under the hood to generate .nlibs, 
;# save them to disk, and automatically link them to the design.
;# Requires LINK_LIBRARY to be specified with .db files and REFERENCE_LIBRARY to be specified with physical
;# source files for the library configuration flow. Also search_path (in icc2_pnr_setup.tcl) should include paths 
;# to these .db and physical source files.
set LINK_LIBRARY		[list /home/prakhan/task_6/icc2_workshop_collaterals/nangate_typical.db /home/prakhan/task_6/icc2_workshop_collaterals/sram_32_1024_freepdk45_TT_1p0V_25C_lib.db]	;# Specify .db files;
;# 	for running VC-LP (vc_lp.tcl) and Formality (fm.tcl): required
;# 	for ICC-II without LIBRARY_CONFIGURATION_FLOW enabled: not required
;#	for ICC-II with LIBRARY_CONFIGURATION_FLOW enabled: required; 
;#      	- the .db files specified will be used for the library configuration under the hood during create_lib 
##########################################################################################
## Variables related to flow controls of flat PNR, hierarchical PNR and transition with DP
##########################################################################################
set DESIGN_STYLE		"hier"	;# Specify the design style; flat|hier; default is flat; 
;# specify flat for a totally flat flow (flat PNR for short) and 
;# specify hier for a hierarchical flow (hier PNR for short);
;# 	for hier PNR: required and auto set if unpack_rm_dirs.pl is used; (see README.unpack_rm_dirs.txt for details)
;# 	for flat PNR: this should set to flat (default)
;#	for DP: not used 
set PHYSICAL_HIERARCHY_LEVEL	"" 	;# Specify the current level of hierarchy for the hierarchical PNR flow; top|intermediate|bottom;
;# 	for hier PNR: required and auto set if unpack_rm_dirs.pl is used; (see README.unpack_rm_dirs.txt for details)
;# 	for flat PNR and for DP: not used.
set RELEASE_DIR_DP		"write_data_dir_hier" 	;# Specify the release directory of DP RM; 
;# this is where init_design.tcl of PNR flow gets DP RM released libraries;
;# 	for hier PNR: required and auto set if unpack_rm_dirs.pl is used; (see README.unpack_rm_dirs.txt for details)
;# 	for flat PNR: required if INIT_DESIGN_INPUT = DP_RM_NDM, as init_design.tcl needs to know where DP RM libraries are
;#	for DP: not used 
set RELEASE_LABEL_NAME_DP 	"rave_wrapperNangate"	
;# Specify the label name of the block in the DP RM released library;
;# this is the label name which init_design.tcl of PNR flow will open. 
set RELEASE_DIR_PNR		"" 	;# Specify the release directory of PNR RM; 
;# this is where the init_design.tcl of hierarchical PNR flow gets the sub-block libraries;	
;# 	for hier PNR: required and auto set if unpack_rm_dirs.pl is used; (see README.unpack_rm_dirs.txt for details)
;# 	for flat PNR and for DP: not used.
##########################################################################################
## Variables related to REDHAWK ANALYSIS FUSION
##########################################################################################
set REDHAWK_SEARCH_PATH		"" 	;# Required. Search path to the NDM, reference libraries, and etc.
puts "RM-info : Completed script [info script]\n"
RM-info : Completed script /home/prakhan/task_6/icc2_workshop_collaterals/standaloneFlow/icc2_common_setup.tcl

source -echo ./icc2_dp_setup.tcl
puts "RM-info : Running script [info script]\n"
RM-info : Running script /home/prakhan/task_6/icc2_workshop_collaterals/standaloneFlow/icc2_dp_setup.tcl

##########################################################################################
# Tool: IC Compiler II 
# Script: icc2_dp_setup.tcl 
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################
##########################################################################################
# 				Flow Setup
##########################################################################################
set DP_FLOW         "flat"    ;# hier or flat
set FLOORPLAN_STYLE "channel" ;# Supported design styles channel, abutted
set CHECK_DESIGN    "true"    ;# run atomic check_design pre checks prior to DP commands
set DISTRIBUTED 0  ;# Use distributed runs
### It is required to include the set_host_options command to enable distributed mode tasks. For example,
set_host_options -max_cores 8
#set_host_options -name block_script -submit_command [list qsub -P bnormal -l mem_free=6G,qsc=o -cwd]
set BLOCK_DIST_JOB_FILE             ""     ;# File to set block specific resource requests for distributed jobs
# For example:
#   set_host_options -name block_script  -submit_command "bsub -q normal"
#   set_host_options -name large_block   -submit_command "bsub -q huge"
#   set_host_options -name special_block -submit_command "rsh" local_machine
#   set_app_options -block [get_block block4] -list {plan.distributed_run.block_host large_block}
#   set_app_options -block [get_block block5] -list {plan.distributed_run.block_host large_block}
#   set_app_options -block [get_block block2] -list {plan.distributed_run.block_host special_block}
#  
#   All the jobs associated with blocks that do not have the plan.distributed_run.block_host app option specified
#   will run using the block_script host option. The jobs for blocks block4 and block5 will use the large_block 
#   host option. The job form  block2  will  use  the  special_block host option.
##########################################################################################
# If the design is run with MIBs then change the block list appropriately
##########################################################################################
set DP_BLOCK_REFS                     [list] ;# design names for each physical block (including black boxes) in the design;
;# this includes bottom and mid level blocks in a Multiple Physical Hierarchy (MPH) design
set DP_INTERMEDIATE_LEVEL_BLOCK_REFS  [list data_memory] ;# design reference names for mid level blocks only
set DP_BB_BLOCK_REFS                  [list] ;# Black Box reference names 
set BOTTOM_BLOCK_VIEW             "abstract" ;# Support abstract or design view for bottom blocks
;# in the hier flow
set INTERMEDIATE_BLOCK_VIEW       "abstract" ;# Support abstract or design view for intermediate blocks
if { [info exists INTERMEDIATE_BLOCK_VIEW] && $INTERMEDIATE_BLOCK_VIEW == "abstract" } {
   set_app_options -name abstract.allow_all_level_abstract -value true  ;# Dafult value is false
}
Warning: Application option 'abstract.allow_all_level_abstract' will be made block-scoped in the upcoming 2019.12 release. (ABS-549)
# Provide blackbox instanace: target area, BB UPF file, BB Timing file, boundary
#set DP_BB_BLOCK_REFS "leon3s_bb"
#set DP_BB_BLOCKS(leon3s_bb,area)        [list 1346051] ;
#set DP_BB_BLOCKS(leon3s_bb,upf)         [list ${des_dir}/leon3s_bb.upf] ;
#set DP_BB_BLOCKS(leon3s_bb,timing)      [list ${des_dir}/leon3s_bbt.tcl] ;
#set DP_BB_BLOCKS(leon3s_bb,boundary)    { {x1 y1} {x2 y1} {x2 y2} {x1 y2} {x1 y1} } ;
#set DP_BB_SPLIT    "true"
##########################################################################################
# 				CONSTRAINTS / UPF INTENT
##########################################################################################
set TCL_TIMING_RULER_SETUP_FILE       "" ;# file sourced to define parasitic constraints for use with timing ruler 
# before full extraction environment is defined
# Example setup file:
#       set_parasitic_parameters \
                                          #         -early_spec para_WORST \
                                          #         -late_spec para_WORST
set CONSTRAINT_MAPPING_FILE           "" ;# Constraint Mapping File. Default is "split/mapfile"
set TCL_UPF_FILE                      "" ;# Optional power intent TCL script
##########################################################################################
# 				TOP LEVEL FLOORPLAN CREATION (die, pad, RDL) / PLACE IO
##########################################################################################
set TCL_PHYSICAL_CONSTRAINTS_FILE     "" ;# TCL script for primary die area creation. If specified, DEF_FLOORPLAN_FILES will be loaded after TCL_PHYSICAL_CONSTRAINTS_FILE
set TCL_PRE_COMMIT_FILE               "" ;# file sourced to set attributes, lib cell purposes, .. etc on specific cells, prior to running commit_block
set TCL_USER_INIT_DP_POST_SCRIPT      "" ;# An optional Tcl file to be sourced at the very end of init_dp.tcl before save_block.
##########################################################################################
# 				PRE_SHAPING
##########################################################################################
set TCL_USER_PRE_SHAPING_PRE_SCRIPT   "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_PRE_SHAPING_POST_SCRIPT  "" ;# An optional Tcl file to be sourced at the very end of the task
##########################################################################################
# 				PLACE_IO
##########################################################################################
set TCL_PAD_CONSTRAINTS_FILE          "/home/prakhan/task_6/icc2_workshop_collaterals/standaloneFlow/pad_placement_constraints.tcl" ;# file sourced to create everything needed by place_io to complete IO placement
;# including flip chip bumps, and io constraints
set TCL_RDL_FILE                      "" ;# file sourced to create RDL routes
set TCL_USER_PLACE_IO_PRE_SCRIPT      "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_PLACE_IO_POST_SCRIPT     "" ;# An optional Tcl file to be sourced at the very end of the task
##########################################################################################
# 				SHAPING
##########################################################################################
switch $FLOORPLAN_STYLE {
   channel {set SHAPING_CMD_OPTIONS           "-channels true"} 
   abutted {set SHAPING_CMD_OPTIONS           "-channels false"} 
}
set TCL_SHAPING_CONSTRAINTS_FILE      "" ;# Specify any constraints prior to shaping i.e. set_shaping_options
# or specify some block shapes manually, for example:
#    set_block_boundary -cell block1 -boundary {{2.10 2.16} {2.10 273.60} \
                                          #    {262.02 273.60} {262.02 2.16}} -orientation R0
#    set_fixed_objects [get_cells block1]
# Support TCL based shaping constraints
# An example is in rm_icc2_dp_scripts/tcl_shaping_constraints_example.tcl
set SHAPING_CONSTRAINTS_FILE          "" ;# Will be included as the -constraint_file option for shape_blocks
set TCL_SHAPING_PNS_STRATEGY_FILE     "" ;# file sourced to create PG strategies for block grid creation
set TCL_MANUAL_SHAPING_FILE           "" ;# File sourced to re-create all block shapes.
# If this file exists, automatic shaping will be by-passed.
# Existing auto or manual block shapes can be written out using the following:
#    write_floorplan -objects <BLOCK_INSTS>
set TCL_USER_SHAPING_PRE_SCRIPT       "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_SHAPING_POST_SCRIPT      "" ;# An optional Tcl file to be sourced at the very end of the task
##########################################################################################
# 				PLACEMENT
##########################################################################################
set TCL_PLACEMENT_CONSTRAINTS_FILE    "" ;# Placeholder for any macro or standard cell placement constraints & options.
# File is sourced prior to DP placement
set PLACEMENT_PIN_CONSTRAINT_AWARE    "false" ;# tells create_placement to consider pin constraints during placement
set USE_INCREMENTAL_DATA              "0" ;# Use floorplan constraints that were written out on a previous run
set CONGESTION_DRIVEN_PLACEMENT       "" ;# Set to one of the following: std_cell, macro, or both to enable congestion driven placement
set TIMING_DRIVEN_PLACEMENT           "" ;# Set to one of the following: std_cell, macro, or both to enable timing driven placement
set TCL_USER_PLACEMENT_PRE_SCRIPT     "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_PLACEMENT_POST_SCRIPT    "" ;# An optional Tcl file to be sourced at the very end of the task
##########################################################################################
#				GLOBAL PLANNING
##########################################################################################
set TCL_GLOBAL_PLANNING_FILE          "" ;#Global planning for bus/critical nets
##########################################################################################
# 				PNS
##########################################################################################
set TCL_PNS_FILE                      "./pns_example.tcl" ;# File sourced to define all power structures. 
# This file will include the following types of PG commands:
#   PG Regions
#   PG Patterns
#   PG Strategies
# Note: The file should not contain compile_pg statements
# An example is in rm_icc2_dp_scripts/pns_example.tcl
set PNS_CHARACTERIZE_FLOW             "true"  ;# Perform PG characterization and implementation
set TCL_COMPILE_PG_FILE               "./compile_pg_example.tcl" ;# File should contain all the compile_pg_* commands to create the power networks 
# specified in the strategies in the TCL_PNS_FILE. 
# An example is in rm_icc2_dp_scripts/compile_pg_example.tcl
set TCL_PG_PUSHDOWN_FILE              "" ;# Create this file to facilitate manual pushdown and bypass auto pushdown in the flow.
set TCL_POST_PNS_FILE                 "" ;# If it exists, this file will be sourced after PG creation.
set TCL_USER_CREATE_POWER_PRE_SCRIPT  "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_CREATE_POWER_POST_SCRIPT "" ;# An optional Tcl file to be sourced at the very end of the task
##########################################################################################
# 				PLACE PINS
##########################################################################################
##Note:Feedthroughs are disabled by default. Enable feedthroughs either through set_*_pin_constraints  Tcl commands or through Pin constraints file
set TCL_PIN_CONSTRAINT_FILE           "" ;# file sourced to apply set_*_pin_constraints to the design
set CUSTOM_PIN_CONSTRAINT_FILE        "" ;# will be loaded via read_pin_constraints -file
;# used for more complex pin constraints, 
;# or in constraint replay
set PLACE_PINS_SELF                   "true" ;# Set to true if the block's top level pins are not all connected to IO drivers.
set TIMING_PIN_PLACEMENT              "true" ;# Set to true for timing driven pin placement
set TCL_USER_PLACE_PINS_PRE_SCRIPT    "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_PLACE_PINS_POST_SCRIPT   "" ;# An optional Tcl file to be sourced at the very end of the task
##########################################################################################
# 				PRE-TIMING
##########################################################################################
set TCL_USER_PRE_TIMING_PRE_SCRIPT    "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_PRE_TIMING_POST_SCRIPT   "" ;# An optional Tcl file to be sourced at the very end of the task
##########################################################################################
# 				TIMING ESTIMATION
##########################################################################################
set TCL_TIMING_ESTIMATION_SETUP_FILE       "" ;# Specify any constraints prior to timing estimation
set TCL_USER_TIMING_ESTIMATION_PRE_SCRIPT  "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_TIMING_ESTIMATION_POST_SCRIPT "" ;# An optional Tcl file to be sourced at the very end of the task
set TCL_LIB_CELL_DONT_USE_FILE             "" ;# A Tcl file for customized don't use ("set_lib_cell_purpose -exclude <purpose>" commands);
;#  to prevent estimate_timing picking a lib_cell not used by pnr flow.
;#  please specify non-optimization purpose lib cells in the file. 
##########################################################################################
# 				BUDGETING
##########################################################################################
set TCL_BUDGETING_SETUP_FILE                "" ;# Specify any constraints prior to budgeting
set TCL_BOUNDARY_BUDGETING_CONSTRAINTS_FILE "" ;# An optional user constraints file to override compute_budget_constraints
set TCL_USER_BUDGETING_PRE_SCRIPT           "" ;# An optional Tcl file to be sourced at the very beginning of the task
set TCL_USER_BUDGETING_POST_SCRIPT          "" ;# An optional Tcl file to be sourced at the very end of the task
##########################################################################################
## System Variables (there's no need to change the following)
##########################################################################################
set WORK_DIR ./work
set WORK_DIR_WRITE_DATA ./write_data_dir
if !{[file exists $WORK_DIR]} {file mkdir $WORK_DIR}
set SPLIT_CONSTRAINTS_LABEL_NAME split_constraints
set INIT_DP_LABEL_NAME init_dp
set PRE_SHAPING_LABEL_NAME pre_shaping
set PLACE_IO_LABEL_NAME place_io
set SHAPING_LABEL_NAME shaping
set PLACEMENT_LABEL_NAME placement
set CREATE_POWER_LABEL_NAME create_power
set CLOCK_TRUNK_PLANNING_LABEL_NAME clock_trunk_planning
set PLACE_PINS_LABEL_NAME place_pins
set PRE_TIMING_LABEL_NAME pre_timing
set TIMING_ESTIMATION_LABEL_NAME timing_estimation
set BUDGETING_LABEL_NAME budgeting
# Block label to be release by write_data
if {$DP_FLOW == "flat"} {
   set WRITE_DATA_LABEL_NAME timing_estimation
} else {
   set WRITE_DATA_LABEL_NAME budgeting
}
## Directories
set OUTPUTS_DIR	"./outputs_icc2"	;# Directory to write output data files; mainly used by write_data.tcl
set REPORTS_DIR	"./rpts_icc2"		;# Directory to write reports; mainly used by report_qor.tcl
set REPORTS_DIR_SPLIT_CONSTRAINTS $REPORTS_DIR/$SPLIT_CONSTRAINTS_LABEL_NAME
set REPORTS_DIR_INIT_DP $REPORTS_DIR/$INIT_DP_LABEL_NAME
set REPORTS_DIR_PRE_SHAPING $REPORTS_DIR/$PRE_SHAPING_LABEL_NAME
set REPORTS_DIR_PLACE_IO $REPORTS_DIR/$PLACE_IO_LABEL_NAME
set REPORTS_DIR_SHAPING $REPORTS_DIR/$SHAPING_LABEL_NAME
set REPORTS_DIR_PLACEMENT $REPORTS_DIR/$PLACEMENT_LABEL_NAME
set REPORTS_DIR_CREATE_POWER $REPORTS_DIR/$CREATE_POWER_LABEL_NAME
set REPORTS_DIR_CLOCK_TRUNK_PLANNING $REPORTS_DIR/$CLOCK_TRUNK_PLANNING_LABEL_NAME
set REPORTS_DIR_PLACE_PINS $REPORTS_DIR/$PLACE_PINS_LABEL_NAME
set REPORTS_DIR_PRE_TIMING $REPORTS_DIR/$PRE_TIMING_LABEL_NAME
set REPORTS_DIR_TIMING_ESTIMATION $REPORTS_DIR/$TIMING_ESTIMATION_LABEL_NAME
set REPORTS_DIR_BUDGETING $REPORTS_DIR/$BUDGETING_LABEL_NAME
if !{[file exists $REPORTS_DIR]} {file mkdir $REPORTS_DIR}
if !{[file exists $OUTPUTS_DIR]} {file mkdir $OUTPUTS_DIR}
if !{[file exists $REPORTS_DIR_SPLIT_CONSTRAINTS]} {file mkdir $REPORTS_DIR_SPLIT_CONSTRAINTS}
if !{[file exists $REPORTS_DIR_INIT_DP]} {file mkdir $REPORTS_DIR_INIT_DP}
if !{[file exists $REPORTS_DIR_PRE_SHAPING]} {file mkdir $REPORTS_DIR_PRE_SHAPING}
if !{[file exists $REPORTS_DIR_PLACE_IO]} {file mkdir $REPORTS_DIR_PLACE_IO}
if !{[file exists $REPORTS_DIR_SHAPING]} {file mkdir $REPORTS_DIR_SHAPING}
if !{[file exists $REPORTS_DIR_PLACEMENT]} {file mkdir $REPORTS_DIR_PLACEMENT}
if !{[file exists $REPORTS_DIR_CREATE_POWER]} {file mkdir $REPORTS_DIR_CREATE_POWER}
if !{[file exists $REPORTS_DIR_CLOCK_TRUNK_PLANNING]} {file mkdir $REPORTS_DIR_CLOCK_TRUNK_PLANNING}
if !{[file exists $REPORTS_DIR_PLACE_PINS]} {file mkdir $REPORTS_DIR_PLACE_PINS}
if !{[file exists $REPORTS_DIR_PRE_TIMING]} {file mkdir $REPORTS_DIR_PRE_TIMING}
if !{[file exists $REPORTS_DIR_TIMING_ESTIMATION]} {file mkdir $REPORTS_DIR_TIMING_ESTIMATION}
if !{[file exists $REPORTS_DIR_BUDGETING]} {file mkdir $REPORTS_DIR_BUDGETING}
if {[info exists env(LOGS_DIR)]} {
   set log_dir $env(LOGS_DIR)
} else {
   set log_dir ./logs_icc2 
}
set search_path [list ./rm_icc2_dp_scripts ./rm_icc2_pnr_scripts $WORK_DIR ] 
lappend search_path .
##########################################################################################
# 				Optional Settings
##########################################################################################
set_message_info -id PVT-012 -limit 1
set_message_info -id PVT-013 -limit 1
set search_path "/home/prakhan/task_6/icc2_workshop_collaterals/"
set_app_var link_library "nangate_typical.db sram_32_1024_freepdk45_TT_1p0V_25C_lib.db"
puts "RM-info : Completed script [info script]\n"
RM-info : Completed script /home/prakhan/task_6/icc2_workshop_collaterals/standaloneFlow/icc2_dp_setup.tcl

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
RM-info : Opening existing library raven_wrapperNangate
open_lib ${WORK_DIR}/${DESIGN_LIBRARY}
Information: Loading library file '/home/prakhan/task_6/icc2_workshop_collaterals/standaloneFlow/work/raven_wrapperNangate' (FILE-007)
Information: Loading library file '/home/prakhan/task_6/icc2_workshop_collaterals/standaloneFlow/CLIBs/NangateOpenCellLibrary.ndm' (FILE-007)
Information: Loading library file '/home/prakhan/task_6/icc2_workshop_collaterals/standaloneFlow/CLIBs/sram_32_1024_freepdk45_TT_1p0V_25C_lib.ndm' (FILE-007)
Information: Auto created reference libraries are up-to-date, no need to rebuild. (LIB-084)
{raven_wrapperNangate}
################################################################################
# READ NETLIST
################################################################################
puts "RM-info : Reading netlist"
RM-info : Reading netlist
read_verilog \
   -design ${DESIGN_NAME}/${INIT_DP_LABEL_NAME} \
   -top ${DESIGN_NAME} \
   ${VERILOG_NETLIST_FILES}
Information: Reading Verilog into existing design 'raven_wrapper/init_dp' in library 'raven_wrapperNangate'; the existing design contents has been truncated. (VR-013)
Loading verilog file '/home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v'
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 20577 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 20578 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 20756 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 20760 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 21487 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 21536 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 21781 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 21830 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 21879 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 21928 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 22320 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 22369 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 22418 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 22467 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 22516 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 22565 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 22614 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 22663 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 23555 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 23571 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '1' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 23582 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 23632 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '1' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 23879 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '1' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 23890 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 23915 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 23992 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '1' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24000 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24007 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24041 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24049 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24056 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24096 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24097 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '1' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24102 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24143 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24153 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24159 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '1' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24182 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24192 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24198 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24217 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24226 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24235 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24253 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24283 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '1' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24331 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 24353 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 28473 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 90408 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 90847 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 90883 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 90895 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 90979 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 90991 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 91003 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 91015 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 91027 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 91039 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 91051 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 91063 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 91075 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 91087 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 91099 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 91111 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 91123 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 91135 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 91147 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 91159 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 91171 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 91183 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 91195 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 91207 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 91219 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 126359 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 126364 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 128780 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 128805 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 129060 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 129130 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 132269 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 133910 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 133918 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 134248 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 134249 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 2. Truncated.
        	At line 134250 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '00' requires 8 bits
        	which is too large for width 5. Truncated.
        	At line 134251 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 134252 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 134253 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0000000000000' requires 52 bits
        	which is too large for width 49. Truncated.
        	At line 134254 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 2. Truncated.
        	At line 134257 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '00' requires 8 bits
        	which is too large for width 6. Truncated.
        	At line 134262 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Warning: hex constant '0' requires 4 bits
        	which is too large for width 1. Truncated.
        	At line 134263 in /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.synth.v. (SVR-42)
Number of modules read: 1
Top level ports: 47
Total ports in all modules: 47
Total nets in all modules: 23486
Total instances in all modules: 20301
Elapsed = 00:00:00.09, CPU = 00:00:00.08
1
################################################################################
# TECH + TLU+
################################################################################
if {[file exists [which $TCL_TECH_SETUP_FILE]]} {
   source -echo $TCL_TECH_SETUP_FILE
}
puts "RM-info : Running script [info script]\n"
RM-info : Running script /home/prakhan/task_6/icc2_workshop_collaterals/standaloneFlow/init_design.tech_setup.tcl

##########################################################################################
# Tool: IC Compiler II 
# Script: tech_setup.tcl
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################
## Set routing_direction and track_offset
if {$ROUTING_LAYER_DIRECTION_OFFSET_LIST != ""} {
	foreach direction_offset_pair $ROUTING_LAYER_DIRECTION_OFFSET_LIST {
		set layer [lindex $direction_offset_pair 0]
		set direction [lindex $direction_offset_pair 1]
		set offset [lindex $direction_offset_pair 2]
		set_attribute [get_layers $layer] routing_direction $direction
		if {$offset != ""} {
			set_attribute [get_layers $layer] track_offset $offset
		}
	}
} else {
	puts "RM-error : ROUTING_LAYER_DIRECTION_OFFSET_LIST is not specified. You must manually set routing layer directions and offsets!"
}
Information: The design specific attribute override for layer 'metal1' is set in the current block 'raven_wrapper', because the actual library setting may not be overwritten. (ATTR-12)
Information: The design specific attribute override for layer 'metal2' is set in the current block 'raven_wrapper', because the actual library setting may not be overwritten. (ATTR-12)
Information: The design specific attribute override for layer 'metal3' is set in the current block 'raven_wrapper', because the actual library setting may not be overwritten. (ATTR-12)
Information: The design specific attribute override for layer 'metal4' is set in the current block 'raven_wrapper', because the actual library setting may not be overwritten. (ATTR-12)
Information: The design specific attribute override for layer 'metal5' is set in the current block 'raven_wrapper', because the actual library setting may not be overwritten. (ATTR-12)
Information: The design specific attribute override for layer 'metal6' is set in the current block 'raven_wrapper', because the actual library setting may not be overwritten. (ATTR-12)
Information: The design specific attribute override for layer 'metal7' is set in the current block 'raven_wrapper', because the actual library setting may not be overwritten. (ATTR-12)
Information: The design specific attribute override for layer 'metal8' is set in the current block 'raven_wrapper', because the actual library setting may not be overwritten. (ATTR-12)
Information: The design specific attribute override for layer 'metal9' is set in the current block 'raven_wrapper', because the actual library setting may not be overwritten. (ATTR-12)
Information: The design specific attribute override for layer 'metal10' is set in the current block 'raven_wrapper', because the actual library setting may not be overwritten. (ATTR-12)
## Set site default
if {$SITE_DEFAULT != ""} {
	set_attribute [get_site_defs] is_default false
	set_attribute [get_site_defs $SITE_DEFAULT] is_default true
}
## Set site symmetry
if {$SITE_SYMMETRY_LIST != ""} {
	foreach sym_pair $SITE_SYMMETRY_LIST {
		set site_name [lindex $sym_pair 0]
		set site_sym [lindex $sym_pair 1]
		set_attribute [get_site_defs $site_name] symmetry $site_sym
	}   	
}
puts "RM-info : Completed script [info script]\n"
RM-info : Completed script /home/prakhan/task_6/icc2_workshop_collaterals/standaloneFlow/init_design.tech_setup.tcl

if {[file exists [which $TCL_PARASITIC_SETUP_FILE]]} {
   source -echo $TCL_PARASITIC_SETUP_FILE
}
puts "RM-info: Running script [info script]\n"
RM-info: Running script /home/prakhan/task_6/icc2_workshop_collaterals/standaloneFlow/init_design.read_parasitic_tech_example.tcl

##########################################################################################
# Tool: IC Compiler II
# Script: init_design.read_parasitic_tech_example.tcl (template)
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################
##############################################################################################
# The following is a sample script to read two TLU+ files, 
# which you can expand to accomodate your design.
##############################################################################################
########################################
## Variables
########################################
## Parasitic tech files for read_parasitic_tech command; expand the section as needed
set parasitic1				"temp1" ;# name of parasitic tech model 1
set tluplus_file($parasitic1)           "/home/prakhan/task_6/icc2_workshop_collaterals/sample_45nm.tluplus" ;# TLU+ files to read for parasitic 1
set layer_map_file($parasitic1)         "" ;# layer mapping file between ITF and tech for parasitic 1
#set parasitic2				"temp2" ;# name of parasitic tech model 2
#set tluplus_file($parasitic2)           "/home/kunal/design/picosoc/pdk/sample_180nm.tluplus" ;# TLU+ files to read for parasitic 2
#set layer_map_file($parasitic2)         "" ;# layer mapping file between ITF and tech for parasitic 2
########################################
## Read parasitic files
########################################
## Read in the TLUPlus files first.
#  Later on in the corner constraints, you can then refer to these parasitic models.
foreach p [array name tluplus_file] {  
	puts "RM-info: read_parasitic_tech -tlup $tluplus_file($p) -layermap $layer_map_file($p) -name $p"
	#read_parasitic_tech -tlup $tluplus_file($p) -layermap $layer_map_file($p) -name $p
	read_parasitic_tech -tlup $tluplus_file($p)  -name $p

}
RM-info: read_parasitic_tech -tlup /home/prakhan/task_6/icc2_workshop_collaterals/sample_45nm.tluplus -layermap  -name temp1
Information: The command 'read_parasitic_tech' cleared the undo history. (UNDO-016)
puts "RM-info: Completed script [info script]\n"
RM-info: Completed script /home/prakhan/task_6/icc2_workshop_collaterals/standaloneFlow/init_design.read_parasitic_tech_example.tcl

################################################################################
# FLOORPLAN
################################################################################
puts "RM-info : Initializing floorplan"
RM-info : Initializing floorplan
initialize_floorplan \
   -control_type die \
   -boundary {{0 0} {3588 5188}} \
   -core_offset {300 300 300 300}
[icc2-lic Tue Dec 30 11:11:06 2025] Command 'initialize_floorplan' requires licenses
[icc2-lic Tue Dec 30 11:11:06 2025] Sending authorization request for 'ICCompilerII'
[SCL] 12/30/2025 11:11:06 PID:8158 Client:nanodc.iitgn.ac.in Authorization failed ICCompilerII 2022.12
[icc2-lic Tue Dec 30 11:11:06 2025] Authorization request for 'ICCompilerII' failed (-5)
[icc2-lic Tue Dec 30 11:11:06 2025] Sending authorization request for 'ICCompilerII-4'
[SCL] 12/30/2025 11:11:06 PID:8158 Client:nanodc.iitgn.ac.in Authorization failed ICCompilerII-4 2022.12
[icc2-lic Tue Dec 30 11:11:06 2025] Authorization request for 'ICCompilerII-4' failed (-5)
[icc2-lic Tue Dec 30 11:11:06 2025] Sending authorization request for 'ICCompilerII-8'
[SCL] 12/30/2025 11:11:07 PID:8158 Client:nanodc.iitgn.ac.in Server:27020@c2s.cdacb.in Authorization succeeded ICCompilerII-8 2022.12
[icc2-lic Tue Dec 30 11:11:07 2025] Authorization request for 'ICCompilerII-8' succeeded
[icc2-lic Tue Dec 30 11:11:07 2025] Sending authorization request for 'ICCompilerII-NX'
[SCL] 12/30/2025 11:11:07 PID:8158 Client:nanodc.iitgn.ac.in Server:27020@c2s.cdacb.in Authorization succeeded ICCompilerII-NX 2022.12
[icc2-lic Tue Dec 30 11:11:07 2025] Authorization request for 'ICCompilerII-NX' succeeded
[icc2-lic Tue Dec 30 11:11:07 2025] Attempting to check-out alternate set of keys directly with queueing
[icc2-lic Tue Dec 30 11:11:07 2025] Sending count request for 'ICCompilerII-8' 
[icc2-lic Tue Dec 30 11:11:07 2025] Count request for 'ICCompilerII-8' returned 0 
[icc2-lic Tue Dec 30 11:11:07 2025] Sending check-out request for 'ICCompilerII-8' (1) with wait option
[SCL] 12/30/2025 11:11:07 Checking status for feature ICCompilerII-8
[SCL] 12/30/2025 11:11:07 PID:8158 Client:nanodc.iitgn.ac.in Server:27020@c2s.cdacb.in Checkout succeeded ICCompilerII-8 2022.12
[icc2-lic Tue Dec 30 11:11:07 2025] Check-out request for 'ICCompilerII-8' with wait option succeeded
[icc2-lic Tue Dec 30 11:11:07 2025] Sending checkout check request for 'ICCompilerII-8' 
[icc2-lic Tue Dec 30 11:11:07 2025] Checkout check request for 'ICCompilerII-8' returned 0 
[icc2-lic Tue Dec 30 11:11:07 2025] Sending count request for 'ICCompilerII-8' 
[icc2-lic Tue Dec 30 11:11:07 2025] Count request for 'ICCompilerII-8' returned 1 
[icc2-lic Tue Dec 30 11:11:07 2025] Sending count request for 'ICCompilerII-NX' 
[icc2-lic Tue Dec 30 11:11:07 2025] Count request for 'ICCompilerII-NX' returned 0 
[icc2-lic Tue Dec 30 11:11:07 2025] Sending check-out request for 'ICCompilerII-NX' (1) with wait option
[SCL] 12/30/2025 11:11:07 Checking status for feature ICCompilerII-NX
[SCL] 12/30/2025 11:11:07 PID:8158 Client:nanodc.iitgn.ac.in Server:27020@c2s.cdacb.in Checkout succeeded ICCompilerII-NX 2022.12
[icc2-lic Tue Dec 30 11:11:07 2025] Check-out request for 'ICCompilerII-NX' with wait option succeeded
[icc2-lic Tue Dec 30 11:11:07 2025] Sending checkout check request for 'ICCompilerII-NX' 
[icc2-lic Tue Dec 30 11:11:07 2025] Checkout check request for 'ICCompilerII-NX' returned 0 
[icc2-lic Tue Dec 30 11:11:07 2025] Sending count request for 'ICCompilerII-NX' 
[icc2-lic Tue Dec 30 11:11:07 2025] Count request for 'ICCompilerII-NX' returned 1 
[icc2-lic Tue Dec 30 11:11:07 2025] Check-out of alternate set of keys directly with queueing was successful
Using libraries: raven_wrapperNangate NangateOpenCellLibrary sram_32_1024_freepdk45_TT_1p0V_25C_lib
Linking block raven_wrapperNangate:raven_wrapper/init_dp.design
Information: User units loaded from library 'NangateOpenCellLibrary' (LNK-040)
Design 'raven_wrapper' was successfully linked.
Removing existing floorplan objects
Creating core...
Core utilization ratio = 0.57%
Unplacing all cells...
Creating site array...
Creating routing tracks...
Initializing floorplan completed.
save_block -force -label floorplan
Information: The command 'save_block' cleared the undo history. (UNDO-016)
Information: Overwriting block 'raven_wrapper/floorplan.design' in library 'raven_wrapperNangate'. (DES-025)
1
################################################################################
# POWER NET CONNECTION (EARLY)
################################################################################
connect_pg_net -automatic -all_blocks
****************************************
Report : Power/Ground Connection Summary
Design : raven_wrapper
Version: U-2022.12-SP3
Date   : Tue Dec 30 11:11:08 2025
****************************************
P/G net name                  P/G pin count(previous/current)
--------------------------------------------------------------------------------
Power net VDD                 0/20301
Ground net VSS                0/20301
--------------------------------------------------------------------------------
Information: connections of 40602 power/ground pin(s) are created or changed.
1
save_block -force -label pre_shape
Information: The command 'save_block' cleared the undo history. (UNDO-016)
Information: Overwriting block 'raven_wrapper/pre_shape.design' in library 'raven_wrapperNangate'. (DES-025)
1
################################################################################
# IO PAD PLACEMENT
################################################################################
if {[file exists [which $TCL_PAD_CONSTRAINTS_FILE]]} {
   source -echo $TCL_PAD_CONSTRAINTS_FILE
   place_io
}
set_attribute -objects [get_cells analog_out_sel_buf ] -name physical_status -value placed
set_attribute -objects [get_cells bg_ena_buf ] -name physical_status -value placed
set_attribute -objects [get_cells comp_ena_buf ] -name physical_status -value placed
set_attribute -objects [get_cells comp_in_buf ] -name physical_status -value placed
set_attribute -objects [get_cells comp_ninputsrc_buf ] -name physical_status -value placed
set_attribute -objects [get_cells comp_pinputsrc_buf ] -name physical_status -value placed
set_attribute -objects [get_cells ext_clk_buf ] -name physical_status -value placed
set_attribute -objects [get_cells ext_clk_sel_buf ] -name physical_status -value placed
set_attribute -objects [get_cells ext_reset_buf ] -name physical_status -value placed
set_attribute -objects [get_cells flash_clk_buf ] -name physical_status -value placed
set_attribute -objects [get_cells flash_csb_buf ] -name physical_status -value placed
set_attribute -objects [get_cells flash_io_buf_0 ] -name physical_status -value placed
set_attribute -objects [get_cells flash_io_buf_1 ] -name physical_status -value placed
set_attribute -objects [get_cells flash_io_buf_2 ] -name physical_status -value placed
set_attribute -objects [get_cells flash_io_buf_3 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio0 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio1 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio10 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio11 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio12 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio13 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio14 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio15 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio2 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio3 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio4 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio5 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio6 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio7 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio8 ] -name physical_status -value placed
set_attribute -objects [get_cells gpio9 ] -name physical_status -value placed
set_attribute -objects [get_cells irq_pin_buf ] -name physical_status -value placed
set_attribute -objects [get_cells opamp_bias_ena_buf ] -name physical_status -value placed
set_attribute -objects [get_cells opamp_ena_buf ] -name physical_status -value placed
set_attribute -objects [get_cells overtemp_buf ] -name physical_status -value placed
set_attribute -objects [get_cells overtemp_ena_buf ] -name physical_status -value placed
set_attribute -objects [get_cells pll_clk_buf ] -name physical_status -value placed
set_attribute -objects [get_cells rcosc_ena_buf ] -name physical_status -value placed
set_attribute -objects [get_cells rcosc_in_buf ] -name physical_status -value placed
set_attribute -objects [get_cells reset_buf ] -name physical_status -value placed
set_attribute -objects [get_cells ser_rx_buf ] -name physical_status -value placed
set_attribute -objects [get_cells ser_tx_buf ] -name physical_status -value placed
set_attribute -objects [get_cells spi_sck_buf ] -name physical_status -value placed
set_attribute -objects [get_cells trap_buf ] -name physical_status -value placed
set_attribute -objects [get_cells xtal_in_buf ] -name physical_status -value placed
#sram #added new
#set_attribute [get_cells sram] origin {2713.5550 750.3550}  
#set_attribute [get_cells sram] status fixed
create_io_guide -side right -pad_cells {analog_out_sel_buf bg_ena_buf comp_ena_buf comp_in_buf comp_ninputsrc_buf comp_pinputsrc_buf ext_clk_buf ext_clk_sel_buf ext_reset_buf flash_clk_buf flash_csb_buf} -line {{3588 5188} 5188}
create_io_guide -side left -pad_cells {flash_io_buf_0 flash_io_buf_1 flash_io_buf_2 flash_io_buf_3 gpio0 gpio1 gpio10 gpio11 gpio12 gpio13 gpio14} -line {{0 0} 5188}
create_io_guide -side top -pad_cells {gpio2 gpio3 gpio4 gpio5 gpio6 gpio7 gpio8 gpio9 irq_pin_buf} -line {{0 5188} 3588}
create_io_guide -side bottom -pad_cells {overtemp_buf overtemp_ena_buf pll_clk_buf rcosc_ena_buf rcosc_in_buf reset_buf ser_rx_buf ser_tx_buf spi_sck_buf trap_buf} -line {{3588 0} 3588}
[icc2-lic Tue Dec 30 11:11:08 2025] Command 'place_io' requires licenses
[icc2-lic Tue Dec 30 11:11:08 2025] Attempting to check-out alternate set of keys directly with queueing
[icc2-lic Tue Dec 30 11:11:08 2025] Sending count request for 'ICCompilerII-8' 
[icc2-lic Tue Dec 30 11:11:08 2025] Count request for 'ICCompilerII-8' returned 1 
[icc2-lic Tue Dec 30 11:11:08 2025] Sending check-out request for 'ICCompilerII-8' (1) with wait option
[SCL] 12/30/2025 11:11:08 Checking status for feature ICCompilerII-8
[SCL] 12/30/2025 11:11:08 PID:8158 Client:nanodc.iitgn.ac.in Server:27020@c2s.cdacb.in Checkout succeeded ICCompilerII-8 2022.12
[icc2-lic Tue Dec 30 11:11:08 2025] Check-out request for 'ICCompilerII-8' with wait option succeeded
[icc2-lic Tue Dec 30 11:11:08 2025] Sending checkout check request for 'ICCompilerII-8' 
[icc2-lic Tue Dec 30 11:11:08 2025] Checkout check request for 'ICCompilerII-8' returned 0 
[icc2-lic Tue Dec 30 11:11:08 2025] Sending count request for 'ICCompilerII-8' 
[icc2-lic Tue Dec 30 11:11:08 2025] Count request for 'ICCompilerII-8' returned 1 
[icc2-lic Tue Dec 30 11:11:08 2025] Sending count request for 'ICCompilerII-NX' 
[icc2-lic Tue Dec 30 11:11:08 2025] Count request for 'ICCompilerII-NX' returned 1 
[icc2-lic Tue Dec 30 11:11:08 2025] Sending check-out request for 'ICCompilerII-NX' (1) with wait option
[SCL] 12/30/2025 11:11:08 Checking status for feature ICCompilerII-NX
[SCL] 12/30/2025 11:11:08 PID:8158 Client:nanodc.iitgn.ac.in Server:27020@c2s.cdacb.in Checkout succeeded ICCompilerII-NX 2022.12
[icc2-lic Tue Dec 30 11:11:08 2025] Check-out request for 'ICCompilerII-NX' with wait option succeeded
[icc2-lic Tue Dec 30 11:11:08 2025] Sending checkout check request for 'ICCompilerII-NX' 
[icc2-lic Tue Dec 30 11:11:08 2025] Checkout check request for 'ICCompilerII-NX' returned 0 
[icc2-lic Tue Dec 30 11:11:08 2025] Sending count request for 'ICCompilerII-NX' 
[icc2-lic Tue Dec 30 11:11:08 2025] Count request for 'ICCompilerII-NX' returned 1 
[icc2-lic Tue Dec 30 11:11:08 2025] Check-out of alternate set of keys directly with queueing was successful
Information: Starting 'place_io' (FLW-8000)
Information: Time: 2025-12-30 11:11:08 / Session: 0.00 hr / Command: 0.00 hr / Memory: 410 MB (FLW-8100)
Information: The command 'place_io' cleared the undo history. (UNDO-016)
Overall runtime for IO placement: 0.019u 0.000s 0:00.02e 100.0%
Information: Ending 'place_io' (FLW-8001)
Information: Time: 2025-12-30 11:11:08 / Session: 0.00 hr / Command: 0.00 hr / Memory: 410 MB (FLW-8100)
1
# Fix IO locations
set_attribute \
   [get_cells -hier -filter "pad_cell==true"] \
   status fixed
{analog_out_sel_buf bg_ena_buf comp_ena_buf comp_in_buf comp_ninputsrc_buf comp_pinputsrc_buf ext_clk_buf ext_clk_sel_buf ext_reset_buf flash_clk_buf flash_csb_buf flash_io_buf_0 flash_io_buf_1 flash_io_buf_2 flash_io_buf_3 gpio0 gpio1 gpio10 gpio11 gpio12 gpio13 gpio14 gpio15 gpio2 gpio3 gpio4 gpio5 gpio6 gpio7 gpio8 gpio9 irq_pin_buf opamp_bias_ena_buf opamp_ena_buf overtemp_buf overtemp_ena_buf pll_clk_buf rcosc_ena_buf rcosc_in_buf reset_buf ser_rx_buf ser_tx_buf spi_sck_buf trap_buf xtal_in_buf}
################################################################################
# PAD KEEP-OUTS (HARD)
################################################################################
puts "RM-info : Creating hard keepout around IO pads"
RM-info : Creating hard keepout around IO pads
create_keepout_margin \
   -type hard \
   -outer {8 8 8 8} \
   [get_cells -hier -filter "pad_cell==true"]
{analog_out_sel_buf/KEEPOUT_hard_OUTER_20255 bg_ena_buf/KEEPOUT_hard_OUTER_20256 comp_ena_buf/KEEPOUT_hard_OUTER_20257 comp_in_buf/KEEPOUT_hard_OUTER_20258 comp_ninputsrc_buf/KEEPOUT_hard_OUTER_20259 comp_pinputsrc_buf/KEEPOUT_hard_OUTER_20260 ext_clk_buf/KEEPOUT_hard_OUTER_20261 ext_clk_sel_buf/KEEPOUT_hard_OUTER_20262 ext_reset_buf/KEEPOUT_hard_OUTER_20263 flash_clk_buf/KEEPOUT_hard_OUTER_20264 flash_csb_buf/KEEPOUT_hard_OUTER_20265 flash_io_buf_0/KEEPOUT_hard_OUTER_20266 flash_io_buf_1/KEEPOUT_hard_OUTER_20267 flash_io_buf_2/KEEPOUT_hard_OUTER_20268 flash_io_buf_3/KEEPOUT_hard_OUTER_20269 gpio0/KEEPOUT_hard_OUTER_20270 gpio1/KEEPOUT_hard_OUTER_20271 gpio10/KEEPOUT_hard_OUTER_20272 gpio11/KEEPOUT_hard_OUTER_20273 gpio12/KEEPOUT_hard_OUTER_20274 gpio13/KEEPOUT_hard_OUTER_20275 gpio14/KEEPOUT_hard_OUTER_20276 gpio15/KEEPOUT_hard_OUTER_20277 gpio2/KEEPOUT_hard_OUTER_20278 gpio3/KEEPOUT_hard_OUTER_20279 gpio4/KEEPOUT_hard_OUTER_20280 gpio5/KEEPOUT_hard_OUTER_20281 gpio6/KEEPOUT_hard_OUTER_20282 gpio7/KEEPOUT_hard_OUTER_20283 gpio8/KEEPOUT_hard_OUTER_20284 gpio9/KEEPOUT_hard_OUTER_20285 irq_pin_buf/KEEPOUT_hard_OUTER_20286 opamp_bias_ena_buf/KEEPOUT_hard_OUTER_20287 opamp_ena_buf/KEEPOUT_hard_OUTER_20288 overtemp_buf/KEEPOUT_hard_OUTER_20289 overtemp_ena_buf/KEEPOUT_hard_OUTER_20290 pll_clk_buf/KEEPOUT_hard_OUTER_20291 rcosc_ena_buf/KEEPOUT_hard_OUTER_20292 rcosc_in_buf/KEEPOUT_hard_OUTER_20293 reset_buf/KEEPOUT_hard_OUTER_20294 ser_rx_buf/KEEPOUT_hard_OUTER_20295 ser_tx_buf/KEEPOUT_hard_OUTER_20296 spi_sck_buf/KEEPOUT_hard_OUTER_20297 trap_buf/KEEPOUT_hard_OUTER_20299 xtal_in_buf/KEEPOUT_hard_OUTER_20300}
################################################################################
# HARD PLACEMENT BLOCKAGES AROUND CORE EDGE
################################################################################
puts "RM-info : Creating hard placement blockages around core boundary"
RM-info : Creating hard placement blockages around core boundary
# Core boundary = {{300 300} {3288 4888}}
# Creating 20um hard blockage band inside core edge
create_placement_blockage -type hard \
   -boundary {{300 300} {3288 320}} \
   -name core_hard_blockage_bottom
{core_hard_blockage_bottom}
create_placement_blockage -type hard \
   -boundary {{300 4868} {3288 4888}} \
   -name core_hard_blockage_top
{core_hard_blockage_top}
create_placement_blockage -type hard \
   -boundary {{300 320} {320 4868}} \
   -name core_hard_blockage_left
{core_hard_blockage_left}
create_placement_blockage -type hard \
   -boundary {{3268 320} {3288 4868}} \
   -name core_hard_blockage_right
{core_hard_blockage_right}
################################################################################
# SRAM MACRO PLACEMENT
################################################################################
puts "RM-info : Placing SRAM macro"
RM-info : Placing SRAM macro
set sram [get_cells -quiet sram]
{sram}
if {[sizeof_collection $sram] > 0} {

   set_attribute $sram origin {365.4500 4544.9250}
   set_attribute $sram orientation MXR90
   set_attribute $sram status placed
}
{sram}
################################################################################
# MACRO HALOS WITH ASYMMETRIC SPACING
################################################################################
set macros [get_cells -hier -filter "is_hard_macro==true"]
{sram}
if {[sizeof_collection $macros] > 0} {

   puts "RM-info : Creating asymmetric halos around macros"

   # Create minimum halo (2um) on top, bottom, right
   # No halo on left side (will be blocked separately)
   create_keepout_margin \
      -type hard \
      -outer {0 2 2 2} \
      $macros
}
RM-info : Creating asymmetric halos around macros
{sram/KEEPOUT_hard_OUTER_20298}
################################################################################
# HARD BLOCKAGE ON LEFT SIDE OF MACRO TO CORE EDGE
################################################################################
puts "RM-info : Creating hard blockage from macro left side to core edge"
RM-info : Creating hard blockage from macro left side to core edge
if {[sizeof_collection $sram] > 0} {
   
   # Create hard blockage with specified coordinates
   create_placement_blockage -type hard \
      -boundary {{320.0000 4522.9250} {594.5300 4802.9150}} \
      -name macro_left_side_blockage
   
   puts "RM-info : Hard blockage created from (320.0000, 4522.9250) to (594.5300, 4802.9150)"
}
RM-info : Hard blockage created from (320.0000, 4522.9250) to (594.5300, 4802.9150)
################################################################################
# MCMM CONSTRAINTS
################################################################################
if {[file exists $TCL_MCMM_SETUP_FILE]} {
   source -echo $TCL_MCMM_SETUP_FILE
}
puts "RM-info: Running script [info script]\n"
RM-info: Running script /home/prakhan/task_6/icc2_workshop_collaterals/standaloneFlow/init_design.mcmm_example.auto_expanded.tcl

##########################################################################################
# Tool: IC Compiler II
# Script: init_design.mcmm_example.auto_expanded.tcl (template)
# Version: P-2019.03-SP4
# Copyright (C) 2014-2019 Synopsys, Inc. All rights reserved.
##########################################################################################
## Note :
#  1. To see the full list of mode / corner / scenario specific commands, 
#      refer to SolvNet 1777585 : "Multicorner-multimode constraint classification" 
#
#  2. Corner operating conditions are recommended to be specified directly through 
#     set_process_number, set_voltage and set_temperature
#
#	The PVT resolution function always finds the closest PVT match between the operating conditions and 
#      	the library pane.
#	A Corner operating condition may be specified directly with the set_process_number, set_voltage and 
#	set_temperature commands or indirectly with the set_operating_conditions command.
#	The set_process_label command may be used to distinguish between library panes with the same PVT 
#	values but different process labels.
##############################################################################################
# The following is a sample script to create two scenarios with scenario constraints provided,
# and let the constraints auto expanded to associated modes and scenarios. At the end of script,
# remove_duplicate_timing_contexts is used to improve runtime and capacity without loss of constraints.
# Reading of the TLUPlus files should be done beforehand,
# so the parasitic models can be referred to in the constraints.
# Specify TCL_PARASITIC_SETUP_FILE in icc2_common_setup.tcl for your read_parasitic_tech commands.
# read_parasitic_tech_example.tcl is provided as an example.
##############################################################################################
########################################
## Variables
########################################
## Scenario constraints; expand the section as needed
set scenario1 				"func1" ;# name of scenario1
set scenario_constraints($scenario1)    "/home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.sdc" ;# for all scenario1 specific constraints
#set scenario2 				"func2" ;# name of scenario2
#set scenario_constraints($scenario2)    "/home/kunal/design/picosoc/rtl/picorv32.sdc" ;# for all scenario2 specific constraints
########################################
## Create modes, corners, and scenarios
########################################
remove_modes -all; remove_corners -all; remove_scenarios -all
Information: The command 'remove_modes' cleared the undo history. (UNDO-016)
foreach s [array name scenario_constraints] {
	create_mode $s
	create_corner $s
	create_scenario -name $s -mode $s -corner $s
	set_parasitic_parameters -late_spec temp1 -early_spec temp1 -library ${DESIGN_NAME}${LIBRARY_SUFFIX} 
	set_voltage 1.10 -corner [current_corner] -object_list [get_supply_nets VDD] 
}
Created scenario func1 for mode func1 and corner func1
All analysis types are activated.
########################################
## Populate constraints 
########################################
## Populate scenario constraints which will then be automatically expanded to its associated modes and corners
foreach s [array name scenario_constraints] {
	current_scenario $s
	puts "RM-info: current_scenario $s"
	puts "RM-info: source $scenario_constraints($s)"
	source $scenario_constraints($s)

	# pls ensure $scenario_constraints($s) includes set_parasitic_parameters command for the corresponding corner,
	# for example, set_parasitic_parameters -late_spec $parasitics1 -early_spec $parasitics2,
	# where the command points to the parasitics read by the read_parasitic_tech commands.
	# Specify TCL_PARASITIC_SETUP_FILE in icc2_common_setup.tcl for your read_parasitic_tech commands.
	# read_parasitic_tech_example.tcl is provided as an example.	
}
RM-info: current_scenario func1
RM-info: source /home/prakhan/task_6/icc2_workshop_collaterals/raven_wrapper.sdc
Information: Timer using 8 threads
########################################
## Configure analysis settings for scenarios
########################################
# Below are just examples to show usage of set_scenario_status (actual usage shold depend on your objective)
# scenario1 is a setup scenario and scenario2 is a hold scenario
set_scenario_status $scenario1 -none -setup true -hold true -leakage_power true -dynamic_power true -max_transition true -max_capacitance true -min_capacitance false -active true
Scenario func1 (mode func1 corner func1) is active for setup/hold/leakage_power/dynamic_power/max_transition/max_capacitance analysis.
#set_scenario_status $scenario2 -none -setup false -hold true -leakage_power true -dynamic_power false -max_transition true -max_capacitance false -min_capacitance true -active true
#redirect -file ${REPORTS_DIR}/${INIT_DESIGN_BLOCK_NAME}.report_scenarios.rpt {report_scenarios} 
redirect -file ${DESIGN_NAME}.report_scenarios.rpt {report_scenarios}
## To remove duplicate modes, corners, scenarios, and to improve runtime and capacity without loss of constraints :
remove_duplicate_timing_contexts
Information: No Scenario reduction opportunities were found
Information: No Mode reduction opportunities were found
Information: No Corner reduction opportunities were found
Information: No Mode, Corner or Scenario reduction was possible
puts "RM-info: Completed script [info script]\n"
RM-info: Completed script /home/prakhan/task_6/icc2_workshop_collaterals/standaloneFlow/init_design.mcmm_example.auto_expanded.tcl

################################################################################
# PLACEMENT CONFIG
################################################################################
set plan.place.auto_generate_blockages true
true
set_app_options -name place_opt.flow.do_spg -value true
place_opt.flow.do_spg true
set_app_options -name route.global.timing_driven -value true
route.global.timing_driven true
################################################################################
# GLOBAL DENSITY CONTROL
################################################################################
set_attribute [current_design] place_global_density 0.65
Warning: Attribute 'place_global_density' has not been defined for the block object class. (ATTR-1)
################################################################################
# FIX MACROS
################################################################################
if {[sizeof_collection $macros] > 0} {
   set_attribute $macros status fixed
}
{sram}
################################################################################
# PIN PLACEMENT
################################################################################
if {[file exists [which $TCL_PIN_CONSTRAINT_FILE]] && !$PLACEMENT_PIN_CONSTRAINT_AWARE} {
   source -echo $TCL_PIN_CONSTRAINT_FILE
}
set_app_options -as_user_default -list {route.global.timing_driven true}
route.global.timing_driven true
if {$CHECK_DESIGN} {
   redirect -file ${REPORTS_DIR_PLACE_PINS}/check_design.pre_pin_placement {check_design -ems_database check_design.pre_pin_placement.ems -checks dp_pre_pin_placement}
}
[SCL] 12/30/2025 11:11:08 Checking status for feature ICCompilerII-8
[SCL] 12/30/2025 11:11:08 PID:8158 Client:nanodc.iitgn.ac.in Server:27020@c2s.cdacb.in Checkout succeeded ICCompilerII-8 2022.12
[SCL] 12/30/2025 11:11:08 Checking status for feature ICCompilerII-NX
[SCL] 12/30/2025 11:11:08 PID:8158 Client:nanodc.iitgn.ac.in Server:27020@c2s.cdacb.in Checkout succeeded ICCompilerII-NX 2022.12
if {$PLACE_PINS_SELF} {
   place_pins -self
}
[icc2-lic Tue Dec 30 11:11:08 2025] Command 'place_pins' requires licenses
[icc2-lic Tue Dec 30 11:11:08 2025] Attempting to check-out alternate set of keys directly with queueing
[icc2-lic Tue Dec 30 11:11:08 2025] Sending count request for 'ICCompilerII-8' 
[icc2-lic Tue Dec 30 11:11:08 2025] Count request for 'ICCompilerII-8' returned 1 
[icc2-lic Tue Dec 30 11:11:08 2025] Sending check-out request for 'ICCompilerII-8' (1) with wait option
[SCL] 12/30/2025 11:11:08 Checking status for feature ICCompilerII-8
[SCL] 12/30/2025 11:11:08 PID:8158 Client:nanodc.iitgn.ac.in Server:27020@c2s.cdacb.in Checkout succeeded ICCompilerII-8 2022.12
[icc2-lic Tue Dec 30 11:11:08 2025] Check-out request for 'ICCompilerII-8' with wait option succeeded
[icc2-lic Tue Dec 30 11:11:08 2025] Sending checkout check request for 'ICCompilerII-8' 
[icc2-lic Tue Dec 30 11:11:08 2025] Checkout check request for 'ICCompilerII-8' returned 0 
[icc2-lic Tue Dec 30 11:11:08 2025] Sending count request for 'ICCompilerII-8' 
[icc2-lic Tue Dec 30 11:11:08 2025] Count request for 'ICCompilerII-8' returned 1 
[icc2-lic Tue Dec 30 11:11:08 2025] Sending count request for 'ICCompilerII-NX' 
[icc2-lic Tue Dec 30 11:11:08 2025] Count request for 'ICCompilerII-NX' returned 1 
[icc2-lic Tue Dec 30 11:11:08 2025] Sending check-out request for 'ICCompilerII-NX' (1) with wait option
[SCL] 12/30/2025 11:11:08 Checking status for feature ICCompilerII-NX
[SCL] 12/30/2025 11:11:08 PID:8158 Client:nanodc.iitgn.ac.in Server:27020@c2s.cdacb.in Checkout succeeded ICCompilerII-NX 2022.12
[icc2-lic Tue Dec 30 11:11:08 2025] Check-out request for 'ICCompilerII-NX' with wait option succeeded
[icc2-lic Tue Dec 30 11:11:08 2025] Sending checkout check request for 'ICCompilerII-NX' 
[icc2-lic Tue Dec 30 11:11:08 2025] Checkout check request for 'ICCompilerII-NX' returned 0 
[icc2-lic Tue Dec 30 11:11:08 2025] Sending count request for 'ICCompilerII-NX' 
[icc2-lic Tue Dec 30 11:11:08 2025] Count request for 'ICCompilerII-NX' returned 1 
[icc2-lic Tue Dec 30 11:11:08 2025] Check-out of alternate set of keys directly with queueing was successful
Information: Starting 'place_pins' (FLW-8000)
Information: Time: 2025-12-30 11:11:08 / Session: 0.00 hr / Command: 0.00 hr / Memory: 450 MB (FLW-8100)
Information: The command 'place_pins' cleared the undo history. (UNDO-016)
Load DB...
CPU Time for load db: 00:00:00.01u 00:00:00.00s 00:00:00.01e: 

Min routing layer: metal1
Max routing layer: metal10


CPU Time for Top Level Pre-Route Processing: 00:00:00.00u 00:00:00.00s 00:00:00.00e: 
Number of block ports: 31
Number of block pin locations assigned from router: 0
CPU Time for Pin Preparation: 00:00:00.00u 00:00:00.00s 00:00:00.00e: 
Number of PG ports on blocks: 0
Number of pins created: 31
CPU Time for Pin Creation: 00:00:00.00u 00:00:00.00s 00:00:00.00e: 
Total Pin Placement CPU Time: 00:00:00.06u 00:00:00.01s 00:00:00.06e: 
Information: Ending 'place_pins' (FLW-8001)
Information: Time: 2025-12-30 11:11:08 / Session: 0.00 hr / Command: 0.00 hr / Memory: 482 MB (FLW-8100)
1
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
Writing out physical pin constraints based on existing pins ... done
0 total number of pre-routes loaded
0 total number of vias loaded
4 total number of edges loaded
------------------------ Start Of Pin Layer Check -------------------------
------------------------- End Of Pin Layer Check --------------------------

----------------------- Start Of Missing Pin Check ------------------------
------------------------ End Of Missing Pin Check -------------------------

----------------------- Start Of Pin Spacing Check ------------------------
------------------------ End Of Pin Spacing Check -------------------------

-------------------- Start Of Technology Spacing Check --------------------
--------------------- End Of Technology Spacing Check ---------------------

------------------------- Start Of Pin Side Check -------------------------
-------------------------- End Of Pin Side Check --------------------------

----------------------- Start Of Pin Stacking Check -----------------------
------------------------ End Of Pin Stacking Check ------------------------

------------------------ Start Of Pin Short Check -------------------------
------------------------- End Of Pin Short Check --------------------------

------------------- Start Of Pin Pre-Route Short Check --------------------
-------------------- End Of Pin Pre-Route Short Check ---------------------

No violation has been found
***Summary***
---------------------------------------------------------------------------
Type of Violation        |                                            Count
-------------------------+-------------------------------------------------
Layer Violation          |                                               0
Missing Pins             |                                               0
Pin PreRoute             |                                               0
Pin Short                |                                               0
Pin Side                 |                                               0
Pin Spacing              |                                               0
Stacking Violation       |                                               0
Technology Spacing       |                                               0
-------------------------+-------------------------------------------------
Total Violations         |                                               0
---------------------------------------------------------------------------
save_block -hier -force -label ${PLACE_PINS_LABEL_NAME}
Information: Overwriting block 'raven_wrapper/place_pins.design' in library 'raven_wrapperNangate'. (DES-025)
1
save_lib -all
Saving all libraries...
1
################################################################################
# SAVE SNAPSHOT
################################################################################
save_block -hier -force -label placement_ready
Information: Overwriting block 'raven_wrapper/placement_ready.design' in library 'raven_wrapperNangate'. (DES-025)
1
save_lib -all
Saving all libraries...
1
puts "\n===== FLOORPLAN COMPLETED SUCCESSFULLY =====\n"

===== FLOORPLAN COMPLETED SUCCESSFULLY =====

icc2_shell> 
```

</details>


---

### Block 1: Setup and Initialization

```tcl
################################################################################
# COMMON SETUP
################################################################################
source -echo ./icc2_common_setup.tcl
source -echo ./icc2_dp_setup.tcl
```

**What it does:**
- Sources common configuration files
- Loads all design variables and paths
- Sets up the execution environment


---

### Block 2: Library Creation/Opening

```tcl
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
```

**What it does:**
- Checks if design library exists
- Creates new library if not present (with reference libraries and technology file)
- Opens existing library if already created
- Links standard cell and SRAM reference libraries

**Key Files Referenced:**
- Reference LEF files (standard cells + SRAM)
- Technology file (.tf)

---

### Block 3: Netlist Import

```tcl
################################################################################
# READ NETLIST
################################################################################
puts "RM-info : Reading netlist"

read_verilog \
   -design ${DESIGN_NAME}/${INIT_DP_LABEL_NAME} \
   -top ${DESIGN_NAME} \
   ${VERILOG_NETLIST_FILES}
```

**What it does:**
- Reads synthesized Verilog netlist
- Creates design block with label "init_dp"
- Sets top-level module
- Links netlist to library cells

---

### Block 4: Technology Setup

```tcl
################################################################################
# TECH + TLU+
################################################################################
if {[file exists [which $TCL_TECH_SETUP_FILE]]} {
   source -echo $TCL_TECH_SETUP_FILE
}

if {[file exists [which $TCL_PARASITIC_SETUP_FILE]]} {
   source -echo $TCL_PARASITIC_SETUP_FILE
}
```

**What it does:**
- Sources technology setup (layer directions, site definitions)
- Loads TLU+ parasitic models for RC extraction
- Configures min/max extraction corners

**Files sourced:**
- `init_design.tech_setup.tcl` - Layer properties
- `init_design.read_parasitic_tech_example.tcl` - TLU+ files


---

### Block 5: Floorplan Initialization

```tcl
################################################################################
# FLOORPLAN
################################################################################
puts "RM-info : Initializing floorplan"

initialize_floorplan \
   -control_type die \
   -boundary {{0 0} {3588 5188}} \
   -core_offset {300 300 300 300}

save_block -force -label floorplan
```

**What it does:**
- Creates die boundary: 3588µm × 5188µm
- Defines core area with 300µm offset on all sides
- Core area becomes: 2988µm × 4588µm
- Saves snapshot with label "floorplan"

**Area Calculations:**
- **Die Area:** 3588 × 5188 = 18.61 mm²
- **Core Area:** 2988 × 4588 = 13.71 mm²
- **Core Utilization:** Available for standard cells and routing


---

### Block 6: Early Power Connection

```tcl
################################################################################
# POWER NET CONNECTION (EARLY)
################################################################################
connect_pg_net -automatic -all_blocks
save_block -force -label pre_shape
```

**What it does:**
- Automatically connects VDD/VSS to all standard cells
- Connects power/ground pins for all hierarchical blocks
- Prepares design for subsequent PG planning
- Saves checkpoint before shaping


---

### Block 7: IO Pad Placement

<img width="833" height="671" alt="image" src="https://github.com/user-attachments/assets/07b758c1-d387-464f-b2d2-5ff311800cd8" />


```tcl
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
```

**What it does:**
- Sources pad placement constraints (IO guides created earlier)
- Executes automated IO pad placement
- Places 52 IO pads along die periphery
- Fixes all pad locations to prevent movement

**Pad Distribution:**
- Right side: 11 pads (analog, clock, flash control)
- Left side: 11 pads (flash IO, GPIO 0-10)
- Top side: 9 pads (GPIO 11-15, interrupt)
- Bottom side: 10 pads (temperature, PLL, serial, SPI)


---

### Block 8: Pad Keepout Margins

<img width="955" height="381" alt="image" src="https://github.com/user-attachments/assets/574b5a7c-9635-41ef-aee2-7d3471465f28" />


```tcl
################################################################################
# PAD KEEP-OUTS (HARD)
################################################################################
puts "RM-info : Creating hard keepout around IO pads"

create_keepout_margin \
   -type hard \
   -outer {8 8 8 8} \
   [get_cells -hier -filter "pad_cell==true"]
```

**What it does:**
- Creates 8µm hard keepout around all IO pads
- Prevents standard cell placement too close to pads
- Ensures proper spacing for pad routing
- Applied on all 4 sides of each pad


---

### Block 9: Core Edge Hard Blockages

<img width="1215" height="814" alt="image" src="https://github.com/user-attachments/assets/75f17886-9f88-4945-a6da-4ba27fcb54f4" />


```tcl
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
```

**What it does:**
- Creates 20µm blockage band inside core perimeter
- Prevents cell placement at core edges
- Provides space for power ring routing
- Four separate blockages for bottom, top, left, right

**Blockage Coordinates:**
| Edge | Coordinates | Thickness |
|------|-------------|-----------|
| Bottom | (300,300) to (3288,320) | 20µm |
| Top | (300,4868) to (3288,4888) | 20µm |
| Left | (300,320) to (320,4868) | 20µm |
| Right | (3268,320) to (3288,4868) | 20µm |


---

### Block 10: SRAM Macro Placement

<img width="1077" height="761" alt="image" src="https://github.com/user-attachments/assets/c725c9fd-d3a6-4886-b329-eb067186623f" />


```tcl
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
```

**What it does:**
- Identifies SRAM macro instance
- Places SRAM at coordinates (365.45, 4544.925)
- Sets orientation to MXR90 (mirrored, rotated 90°)
- Marks as "placed" (not fixed yet)

**SRAM Specifications:**
- Type: `sram_32_1024_freepdk45`
- Configuration: 32-bit word, 1024 entries
- Location: Upper-left region of core
- Orientation: Rotated for optimal routing

---

### Block 11: Macro Halo Creation

<img width="1271" height="708" alt="image" src="https://github.com/user-attachments/assets/be2a268d-9324-43af-b888-9396f493c9c1" />


```tcl
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
```

**What it does:**
- Identifies all hard macros (SRAM)
- Creates asymmetric keepout margins
- Left: 0µm (custom blockage later)
- Top/Bottom/Right: 2µm each
- Prevents standard cells from being placed too close

**Halo Purpose:**
- Provides routing space around macro
- Prevents DRC violations
- Allows power strap access


---

### Block 12: Macro Left Side Blockage

```tcl
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
```

**What it does:**
- Creates large blockage from core edge to SRAM left side
- Extends from left core boundary (320.0) to past SRAM (594.53)
- Vertical coverage matches SRAM height plus margins
- Prevents cells in this channel region

**Rationale:**
- Creates routing channel for macro connections
- Provides dedicated space for power/signal routing
- Improves routability to SRAM pins

**Blockage Dimensions:**
- Width: 274.53µm (594.53 - 320.0)
- Height: 279.99µm (4802.915 - 4522.925)


---

### Block 13: MCMM Constraints

```tcl
################################################################################
# MCMM CONSTRAINTS
################################################################################
if {[file exists $TCL_MCMM_SETUP_FILE]} {
   source -echo $TCL_MCMM_SETUP_FILE
}
```

**What it does:**
- Sources Multi-Corner Multi-Mode (MCMM) setup file
- Defines timing scenarios (best/typical/worst case)
- Creates analysis corners with different PVT conditions
- Loads SDC constraints for each scenario

**Typical MCMM Setup:**
- **Fast corner:** Best case (low delay)
- **Typical corner:** Nominal conditions
- **Slow corner:** Worst case (high delay)


---

### Block 14: Placement Configuration

```tcl
################################################################################
# PLACEMENT CONFIG
################################################################################
set plan.place.auto_generate_blockages true
set_app_options -name place_opt.flow.do_spg -value true
set_app_options -name route.global.timing_driven -value true
```

**What it does:**
- Enables automatic blockage generation during placement
- Enables Standard cell Physical Guidance (SPG)
- Enables timing-driven global routing
- Optimizes placement for better timing and routability

**Options Explained:**
- `auto_generate_blockages`: Creates soft blockages for better QoR
- `do_spg`: Guides placement near timing-critical paths
- `timing_driven`: Routes critical nets with priority

---

### Block 15: Global Density Control

```tcl
################################################################################
# GLOBAL DENSITY CONTROL
################################################################################
set_attribute [current_design] place_global_density 0.65
```

**What it does:**
- Sets target placement density to 65%
- Leaves 35% white space for routing
- Prevents congestion hotspots
- Balances cell utilization vs routability

**Density Impact:**
- **Higher (0.8-0.9):** Dense placement, potential congestion
- **Medium (0.6-0.7):** Balanced, good for most designs
- **Lower (0.4-0.5):** Sparse, better routability but larger area

---

### Block 16: Fix Macro Status

```tcl
################################################################################
# FIX MACROS
################################################################################
if {[sizeof_collection $macros] > 0} {
   set_attribute $macros status fixed
}
```

**What it does:**
- Changes SRAM status from "placed" to "fixed"
- Prevents macro from moving during placement/optimization
- Locks macro position and orientation
- Ensures macro remains at specified location

---

### Block 17: Pin Placement

```tcl
################################################################################
# PIN PLACEMENT
################################################################################
if {[file exists [which $TCL_PIN_CONSTRAINT_FILE]] && !$PLACEMENT_PIN_CONSTRAINT_AWARE} {
   source -echo $TCL_PIN_CONSTRAINT_FILE
}

set_app_options -as_user_default -list {route.global.timing_driven true}

if {$CHECK_DESIGN} {
   redirect -file ${REPORTS_DIR_PLACE_PINS}/check_design.pre_pin_placement \
      {check_design -ems_database check_design.pre_pin_placement.ems -checks dp_pre_pin_placement}
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
   check_pin_placement -self -pre_route true -pin_spacing true \
      -sides true -layers true -stacking true

   # Generate Top-level Port Placement Report
   report_pin_placement -self > $REPORTS_DIR_PLACE_PINS/report_port_placement.rpt
}

save_block -hier -force -label ${PLACE_PINS_LABEL_NAME}
save_lib -all
```

**What it does:**
1. Sources pin placement constraints (if exists)
2. Runs pre-pin placement design checks
3. Executes automatic pin placement with timing consideration
4. Writes out pin constraints for reference
5. Verifies pin placement quality
6. Generates pin placement report
7. Saves checkpoint with label "place_pins"

**Pin Placement Checks:**
- Pre-route legality
- Pin-to-pin spacing violations
- Layer assignment correctness
- Pin stacking violations


---

### Block 18: Final Save

```tcl
################################################################################
# SAVE SNAPSHOT
################################################################################
save_block -hier -force -label placement_ready
save_lib -all

puts "\n===== FLOORPLAN COMPLETED SUCCESSFULLY =====\n"
```

**What it does:**
- Saves final floorplan snapshot as "placement_ready"
- Writes all libraries to disk
- Prints completion message
- Creates restore point before placement

<img width="583" height="816" alt="image" src="https://github.com/user-attachments/assets/821d820e-acbf-4197-a95c-6ce20f4adf6b" />


---

## Power Planning

### Script Overview
The power planning script creates a robust power distribution network (PDN) with rings, straps, and mesh.

<details>
  <summary>powerplan.tcl</summary>
	
```
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

```

</details>


---

### Block 1: Cleanup and Initialization

```tcl
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
```

**What it does:**
- Clears any existing PG structures
- Removes previous strategies, patterns, regions
- Removes existing power routes
- Ensures clean slate for new PG creation

**Why cleanup is needed:**
- Avoids conflicts with old structures
- Enables re-run capability
- Prevents duplicate routing

---

### Block 2: Define PG Nets

```tcl
########################################
# 0. Global PG Nets
########################################
set PG_NETS {VDD VSS}
```

**What it does:**
- Defines power net names
- VDD: Positive supply (power)
- VSS: Ground
- These nets will be used throughout PG creation

---

### Block 3: Connect PG Nets

```tcl
########################################
# 1. Connect PG nets automatically
########################################
puts "RM-info : Connecting PG nets automatically"
connect_pg_net -automatic -all_blocks
```

**What it does:**
- Automatically connects VDD/VSS pins of all cells
- Connects standard cell power/ground rails
- Connects macro power/ground pins
- Updates pin-to-net associations


---

### Block 4: Core Power Ring

<img width="1223" height="816" alt="image" src="https://github.com/user-attachments/assets/feb675f1-ebef-4195-8686-b418c5476fbe" />


```tcl
########################################
# 2. CORE POWER RING
########################################
puts "RM-info : Creating Core PG Ring"

create_pg_ring_pattern ring_pattern \
    -horizontal_layer metal10 \
    -horizontal_width {5} -horizontal_spacing {2} \
    -vertical_layer metal9 \
    -vertical_width {5} -vertical_spacing {2} \
    -corner_bridge false

set_pg_strategy core_ring -core -pattern \
    {{pattern: ring_pattern}{nets: {VDD VSS}}{offset: {3 3}}} \
    -extension {{stop: innermost_ring}}
```

**What it does:**
1. Creates ring pattern template:
   - Horizontal straps on Metal10 (5µm wide, 2µm spacing)
   - Vertical straps on Metal9 (5µm wide, 2µm spacing)
   - No corner bridging (keeps corners open)

2. Applies pattern to core:
   - Places ring around core boundary
   - 3µm offset from core edge
   - Alternates VDD and VSS
   - Stops at innermost ring boundary

**Ring Configuration:**
| Parameter | Value | Description |
|-----------|-------|-------------|
| Horizontal Layer | Metal10 | Top metal layer |
| Vertical Layer | Metal9 | Second from top |
| Width | 5µm | Wide for low IR drop |
| Spacing | 2µm | VDD-to-VSS gap |
| Offset | 3µm | Distance from core edge |


---

### Block 5: Macro Power Rings

<img width="959" height="572" alt="image" src="https://github.com/user-attachments/assets/9d8c40c3-19cd-47a5-99ce-d8a52be4459d" />


```tcl
########################################
# 3. MACRO POWER RINGS
########################################
puts "RM-info : Creating Macro PG Rings"

create_pg_ring_pattern macro_ring_pattern \
    -horizontal_layer metal10 \
    -horizontal_width {5} -horizontal_spacing {2} \
    -vertical_layer metal9 \
    -vertical_width {5} -vertical_spacing {2} \
    -corner_bridge false

set_pg_strategy macro_core_ring \
    -macros [get_cells -hierarchical -filter "is_hard_macro==true"] \
    -pattern {{pattern: macro_ring_pattern}{nets: {VDD VSS}}{offset: {10 10}}}
```

**What it does:**
- Creates power ring pattern similar to core ring
- Applies to all hard macros (SRAM)
- 10µm offset from macro boundary
- Provides dedicated power delivery to macro
- Uses same metal layers (M9/M10)

**Why macro rings are important:**
- Macros draw significant current
- Dedicated rings reduce IR drop
- Isolate macro noise from core logic
- Provide stable power supply


---

### Block 6: PG Mesh Region

<img width="1006" height="598" alt="image" src="https://github.com/user-attachments/assets/792c3b34-d4d3-4fbf-8d36-306e7f552c50" />
<img width="1216" height="815" alt="image" src="https://github.com/user-attachments/assets/a4bd233c-95c2-47d4-8313-43fd5527da98" />


```tcl
########################################
# 4. PG MESH (CORE ONLY)
########################################
puts "RM-info : Creating PG Mesh"

create_pg_region pg_mesh_region \
    -core -expand -2 \
    -exclude_macros sram \
    -macro_offset 20
```

**What it does:**
- Defines region for power mesh
- Expands 2µm inward from core ring
- Excludes SRAM macro area
- Maintains 20µm offset from macro boundary
- Mesh will only cover standard cell regions

**Region Purpose:**
- Defines where mesh stripes will be placed
- Prevents mesh overlap with macros
- Ensures proper clearance from blockages

---

### Block 7: PG Mesh Pattern

<img width="855" height="743" alt="image" src="https://github.com/user-attachments/assets/c8d60dc0-3387-4f57-96eb-2222cc53fa40" />
<img width="576" height="813" alt="image" src="https://github.com/user-attachments/assets/514d9aad-8693-49a7-b132-3b1d86515421" />


```tcl
create_pg_mesh_pattern pg_mesh1 \
   -parameters {w1 p1 w2 p2 f t} \
   -layers {{{vertical_layer: metal9} {width: @w1} {spacing: interleaving} \
        {pitch: @p1} {offset: @f} {trim: @t}} \
        {{horizontal_layer: metal10} {width: @w2} {spacing: interleaving} \
        {pitch: @p2} {offset: @f} {trim: @t}}}
```

**What it does:**
- Creates parameterized mesh pattern
- Defines interleaving VDD/VSS stripes
- Variables allow flexible configuration:
  - `w1/w2`: Stripe widths
  - `p1/p2`: Pitch (spacing between same net)
  - `f`: Offset from origin
  - `t`: Trim at boundaries

**Interleaving Pattern:**
```
VDD ---- VSS ---- VDD ---- VSS ---- VDD (pitch = p1)
|        |        |        |        |
```

---

### Block 8: Apply PG Mesh Strategy

```tcl
set_pg_strategy s_mesh1 \
   -pattern {{pattern: pg_mesh1} {nets: {VDD VSS VSS VDD}} \
   {offset_start: 10 20} {parameters: 4 80 6 120 3.344 false}} \
   -pg_region pg_mesh_region \
   -extension {{stop: innermost_ring}}
```

**What it does:**
- Applies mesh pattern to defined region
- Sets stripe parameters:
  - Vertical (M9): 4µm wide, 80µm pitch
  - Horizontal (M10): 6µm wide, 120µm pitch
  - Offset: 10µm (vertical), 20µm (horizontal)
  - Trim: false (extend to region boundary)
- Alternates VDD-VSS-VSS-VDD for symmetry
- Stops at innermost ring

**Mesh Specifications:**
| Layer | Width | Pitch | Count (estimated) |
|-------|-------|-------|-------------------|
| Metal9 (V) | 4µm | 80µm | ~37 stripes |
| Metal10 (H) | 6µm | 120µm | ~38 stripes |

**Mesh Density:**
- Creates ~1,400 intersection points
- Provides multiple current paths
- Reduces IR drop significantly


---

### Block 9: Macro Pin Connections

<img width="820" height="727" alt="image" src="https://github.com/user-attachments/assets/3f97f7e2-deb2-4f27-a8ee-f8234fc70a8d" />


```tcl
########################################
# 5. MACRO PG PIN CONNECTIONS
########################################
puts "RM-info : Connecting Macro PG Pins"

create_pg_macro_conn_pattern hm_pattern \
    -pin_conn_type scattered_pin \
    -layer {metal3 metal3}

set toplevel_hms [filter_collection [get_cells * -physical_context] \
    "is_hard_macro == true"]

set_pg_strategy macro_con \
    -macros $toplevel_hms \
    -pattern {{name: hm_pattern} {nets: {VDD VSS}}}
```

**What it does:**
- Creates pattern for macro pin connections
- Uses Metal3 for horizontal connection
- Connects scattered pins (distributed around macro)
- Links SRAM power pins to power mesh/rings
- Ensures proper current delivery to macro

**Connection Strategy:**
- Metal3 chosen for intermediate layer routing
- Scattered pins connected individually
- Connects to both VDD and VSS
- Multiple connection points reduce resistance


---

### Block 10: Standard Cell Rails

```tcl
########################################
# 6. STANDARD CELL RAILS
########################################
puts "RM-info : Creating Standard Cell PG Rails"

create_pg_std_cell_conn_pattern \
    std_cell_rail \
    -layers {metal1} \
    -rail_width 0.06

set_pg_strategy rail_strat \
    -pg_region pg_mesh_region \
    -pattern {{name: std_cell_rail} {nets: VDD VSS}}
```

**What it does:**
- Creates Metal1 power rails for standard cells
- Rail width: 0.06µm (60nm)
- Runs horizontally across rows
- Connects cell power pins to vertical stripes
- Standard cells tap power from these rails

**Rail Characteristics:**
- Automatically aligned with standard cell rows
- VDD rail at top of row, VSS at bottom
- Continuous across entire row
- Via connections to M9 vertical stripes

**Why Metal1:**
- Lowest metal layer
- Direct connection to cell pins
- Standard cell height determines rail placement
- Minimal via stacks required


---

### Block 11: Compile PG

```tcl
########################################
# 7. Compile PG
########################################
puts "RM-info : Compiling PG strategies"

compile_pg
```

**What it does:**
- Executes all PG strategies defined
- Generates actual metal shapes
- Creates vias between layers
- Resolves conflicts and DRC issues
- Builds complete PDN structure

**What compile_pg does internally:**
1. Validates all patterns and strategies
2. Generates shapes on metal layers
3. Creates via arrays at intersections
4. Checks for shorts and spacing violations
5. Optimizes via placement
6. Generates final PG routing


---

### Block 12: PG Verification

```tcl
########################################
# 8. PG CHECKS
########################################

<img width="1095" height="908" alt="image" src="https://github.com/user-attachments/assets/49bd4f51-b53e-4d04-9ed1-20d0ea9bed79" />


puts "RM-info : Running PG Checks"

check_pg_missing_vias
check_pg_drc -ignore_std_cells
check_pg_connectivity -check_std_cell_pins none
```

**What it does:**
- **check_pg_missing_vias:** Verifies all layer transitions have vias
- **check_pg_drc:** Checks for width, spacing, short violations
- **check_pg_connectivity:** Verifies all nets are properly connected

**Checks Performed:**
1. **Missing Vias:**
   - Finds floating shapes without connections
   - Identifies incomplete via stacks

2. **DRC Violations:**
   - Width violations (too thin)
   - Spacing violations (too close)
   - Short circuits between VDD/VSS

3. **Connectivity:**
   - All VDD shapes connected together
   - All VSS shapes connected together
   - No open circuits


---

### Block 13: Save Power Plan

```tcl
########################################
# 9. Save Block
########################################
puts "RM-info : Saving block after power planning"
save_block -hier -force -label CREATE_POWER
save_lib -all

puts "RM-info : Power Planning Completed Successfully"
```

**What it does:**
- Saves design with label "CREATE_POWER"
- Writes all changes to disk
- Creates checkpoint for next stage
- Prints completion message

---

### Block 14: Timing Estimation

<img width="812" height="882" alt="image" src="https://github.com/user-attachments/assets/c8ed4ce3-73ad-477c-9812-8b952f2afa25" />


```tcl
estimate_timing
redirect -file $REPORTS_DIR_TIMING_ESTIMATION/${DESIGN_NAME}.post_estimated_timing.rpt \
    {report_timing -corner estimated_corner -mode [all_modes]}
redirect -file $REPORTS_DIR_TIMING_ESTIMATION/${DESIGN_NAME}.post_estimated_timing.qor \
    {report_qor -corner estimated_corner}
redirect -file $REPORTS_DIR_TIMING_ESTIMATION/${DESIGN_NAME}.post_estimated_timing.qor.sum \
    {report_qor -summary}

save_block -hier -force -label ${TIMING_ESTIMATION_LABEL_NAME}
save_lib -all
```

**What it does:**
- Estimates timing after power planning
- Accounts for PG network parasitics
- Generates timing reports for all paths
- Creates QoR (Quality of Results) reports
- Saves checkpoint with timing data

**Reports Generated:**
1. **Timing Report:** Critical path delays
2. **QoR Report:** Setup/hold slack, TNS, WNS
3. **QoR Summary:** High-level metrics


---

### Block 15: Write Block Data

```tcl
set path_dir [file normalize ${WORK_DIR_WRITE_DATA}]
set write_block_data_script ./write_block_data.tcl
source ${write_block_data_script}
```

**What it does:**
- Exports design data for archival
- Writes DEF, LEF, Verilog
- Creates handoff package
- Enables design sharing/backup

---

## Placement, CTS, and Routing

### Script Overview
This final script performs placement, clock tree synthesis, and detailed routing to complete the physical design.

```
<details>
  <summary>place_cts_route</summary>
####################################
# Place, CTS, Route
####################################
eval create_placement $CMD_OPTIONS
report_placement    -physical_hierarchy_violations all    -wirelength all -hard_macro_overlap    -verbose high > $REPORTS_DIR_PLACEMENT/report_placement.rpt
set_host_options -max_cores 8
remove_corners [get_corners estimated_corner]
set_app_options -name place.coarse.continue_on_missing_scandef -value true
place_opt
clock_opt
route_auto -max_detail_route_iterations 5
set FILLER_CELLS [get_object_name [sort_collection -descending [get_lib_cells NangateOpenCellLibrary/FILL*] area]]
create_stdcell_fillers -lib_cells $FILLER_CELLS

save_block -hier -force   -label post_route
save_lib -all
```
</details>
---

### Block 1: Placement

```tcl
####################################
# Place, CTS, Route
####################################
eval create_placement $CMD_OPTIONS
report_placement \
    -physical_hierarchy_violations all \
    -wirelength all \
    -hard_macro_overlap \
    -verbose high > $REPORTS_DIR_PLACEMENT/report_placement.rpt
```

**What it does:**
- Places all standard cells in rows
- Considers timing, congestion, density
- Respects blockages and keepouts
- Optimizes wirelength
- Generates detailed placement report

**Placement Objectives:**
1. Meet timing requirements
2. Minimize total wirelength
3. Avoid congestion hotspots
4. Respect density constraints (65%)
5. No macro overlaps

---

### Block 2: Configure Optimization

```tcl
set_host_options -max_cores 8
remove_corners [get_corners estimated_corner]
set_app_options -name place.coarse.continue_on_missing_scandef -value true
```

**What it does:**
- Enables 8-core parallel processing
- Removes estimation corner (no longer needed)
- Allows placement without scan chains
- Prepares for optimization

---

### Block 3: Place Optimization

<img width="1591" height="910" alt="image" src="https://github.com/user-attachments/assets/d633c794-be50-4196-973d-ebe237458a1f" />
<img width="1608" height="1018" alt="image" src="https://github.com/user-attachments/assets/b816eba4-e64e-4af1-9b7c-7fbc22c30c94" />
<img width="1606" height="986" alt="image" src="https://github.com/user-attachments/assets/a8669e51-6c60-4efa-90e8-f684a938e61f" />


```tcl
place_opt
```

**What it does:**
- Refines initial placement
- Performs timing-driven optimization
- Adds buffers to fix violations
- Resizes cells for timing/power
- Legalizes cell positions

**place_opt Stages:**
1. **Initial Optimization:** Fix major violations
2. **Hold Fixing:** Insert hold buffers
3. **Setup Recovery:** Resize critical cells
4. **Final Legalization:** Snap to grid

---

### Block 4: Clock Tree Synthesis

<img width="1608" height="1023" alt="image" src="https://github.com/user-attachments/assets/2b718792-f310-4f9b-abc9-025ee38b9349" />


```tcl
clock_opt
```

**What it does:**
- Builds balanced clock trees for all clocks
- Minimizes clock skew and latency
- Inserts clock buffers and inverters
- Performs clock-aware optimization
- Fixes setup/hold on clock paths

**CTS Objectives:**
1. **Skew:** < 100ps between flops
2. **Latency:** Minimize insertion delay
3. **Transition:** Meet slew constraints
4. **Power:** Minimize clock tree power

**Clock Tree Structure:**
```
Root (clock source)
  ├─ Level 1 Buffers (8-16)
  │   ├─ Level 2 Buffers (64-128)
  │   │   ├─ Level 3 Buffers (512-1024)
  │   │   │   └─ Sink Flops (45K+)
```

---

### Block 5: Detailed Routing

<img width="1610" height="1023" alt="image" src="https://github.com/user-attachments/assets/e75ff692-217f-48ee-a65b-20734de55335" />

<img width="1605" height="1023" alt="image" src="https://github.com/user-attachments/assets/fe8da82c-8814-4374-87a1-637a20078b06" />


```tcl
route_auto -max_detail_route_iterations 5
```

**What it does:**
- Performs global routing (coarse)
- Performs track assignment
- Performs detailed routing (fine)
- Fixes DRC violations
- Runs up to 5 iterations for cleanup

**Routing Stages:**
1. **Global Routing:**
   - Assigns nets to routing regions
   - Estimates congestion
   - Plans major paths

2. **Track Assignment:**
   - Assigns nets to specific tracks
   - Resolves overlaps
   - Creates detailed topology

3. **Detailed Routing:**
   - Generates actual wire shapes
   - Places vias
   - Fixes spacing violations
   - Optimizes parasitics


---

### Block 6: Filler Cell Insertion

<img width="1608" height="1022" alt="image" src="https://github.com/user-attachments/assets/93c96257-48a3-4732-b38b-7a9d82186dfc" />


```tcl
set FILLER_CELLS [get_object_name [sort_collection -descending \
    [get_lib_cells NangateOpenCellLibrary/FILL*] area]]
create_stdcell_fillers -lib_cells $FILLER_CELLS
```

**What it does:**
- Identifies available filler cells (FILL*)
- Sorts by area (largest first)
- Fills gaps between standard cells
- Ensures continuous N-well and power rails
- Prevents DRC violations in empty spaces

**Filler Cell Types:**
- **FILLCELL_X32:** 32x width
- **FILLCELL_X16:** 16x width
- **FILLCELL_X8:** 8x width
- **FILLCELL_X4:** 4x width
- **FILLCELL_X2:** 2x width
- **FILLCELL_X1:** 1x width (minimum)

**Why Fillers are Needed:**
- Maintain well continuity
- Prevent N-well/substrate gaps
- Ensure power rail continuity
- Meet foundry DRC rules

---

### Block 7: Final Save

```tcl
save_block -hier -force -label post_route
save_lib -all
```

**What it does:**
- Saves final design with label "post_route"
- Writes complete routed design to disk
- Creates final checkpoint
- Preserves all PNR data

---

## Results and Verification

### Design Statistics

> **📋 Final Statistics Log:**

```

icc2_shell> report_design
****************************************
Report : design
Design : raven_wrapper
Version: U-2022.12-SP3
Date   : Tue Dec 30 13:22:29 2025
****************************************

Total number of std cells in library : 134
Total number of dont_use lib cells   : 9
Total number of dont_touch lib cells : 9
Total number of buffers              : 9
Total number of inverters            : 6
Total number of flip-flops           : 16
Total number of latches              : 5
Total number of ICGs                 : 8

Cell Instance Type  Count         Area
--------------------------------------
TOTAL LEAF CELLS  1825022 14586946.379
unit              1824976 13323078.160
Standard cells    1824976 13323078.160
unit              1824976 13323078.160
Hard macro cells        1    48868.219
unit              1824976 13323078.160
Soft macro cells        0        0.000
unit              1824976 13323078.160
Always on cells         0        0.000
unit              1824976 13323078.160
Physical only     1742751 13165315.422
unit              1824976 13323078.160
Fixed cells            46  1263868.219
unit              1824976 13323078.160
Moveable cells    1824976 13323078.160
unit              1824976 13323078.160
Sequential           2658    60922.541
unit              1824976 13323078.160
Buffer/inverter     65423   804290.896
unit              1824976 13323078.160
ICG cells               0        0.000
unit              1824976 13323078.160

Logic Hierarchies                    : 0
Design Masters count                 : 93
Total Flat nets count                : 85076
Total FloatingNets count             : 2564
Total no of Ports                    : 49
Number of Master Clocks in design    : 3
Number of Generated Clocks in design : 0
Number of Path Groups in design      : 9 (3 of them Non Default)
Number of Scan Chains in design      : 0
List of Modes                        : func1
List of Corners                      : func1
List of Scenarios                    : func1

Core Area                            : 13708071.132
Chip Area                            : 18614544.000
Total Site Row Area                  : 13708071.132
Number of Blockages                  : 5
Total area of Blockages              : 378305.655
Number of Power Domains              : 1
Number of Voltage Areas              : 1
Number of Group Bounds               : 0
Number of Exclusive MoveBounds       : 0
Number of Hard or Soft MoveBounds    : 0
Number of Multibit Registers         : 0
Number of Multibit LS/ISO Cells      : 0
Number of Top Level RP Groups        : 0
Number of Tech Layers                : 21 (11 of them have unknown routing dir.)

Total wire length                    : 27725416.81 micron
Total number of wires                : 926287
Total number of contacts             : 2954444
1
icc2_shell>

```



### pg error reports

```
icc2_shell> check_pg_connectivity 
Information: The command 'check_pg_connectivity' cleared the undo history. (UNDO-016)
Checking secondary net through power switch is enabled. 
Secondary net will be checked together from primary net. They will be treated as the same net
Primary Net : VDD    Secondary Net:
Primary Net : VSS    Secondary Net:
Loading cell instances...
Number of Standard Cells: 1824976
Number of Macro Cells: 1
Number of IO Pad Cells: 45
Number of Blocks: 0
Loading P/G wires and vias...
Number of VDD Wires: 1819
Number of VDD Vias: 981859
Number of VDD Terminals: 0
**************Verify net VDD connectivity*****************
  Number of floating wires: 0
  Number of floating vias: 0
  Number of floating std cells: 0
  Number of floating hard macros: 0
  Number of floating I/O pads: 0
  Number of floating terminals: 0
  Number of floating hierarchical blocks: 0
************************************************************
Loading cell instances...
Loading P/G wires and vias...
Number of VSS Wires: 1942
Number of VSS Vias: 970568
Number of VSS Terminals: 0
**************Verify net VSS connectivity*****************
  Number of floating wires: 0
  Number of floating vias: 0
  Number of floating std cells: 0
  Number of floating hard macros: 0
  Number of floating I/O pads: 0
  Number of floating terminals: 0
  Number of floating hierarchical blocks: 0
************************************************************
Overall runtime: 12 seconds.
icc2_shell> check_pg_drc
Command check_pg_drc started  at Tue Dec 30 13:25:13 2025
Command check_pg_drc finished at Tue Dec 30 13:25:43 2025
CPU usage for check_pg_drc: 202.70 seconds ( 0.06 hours)
Elapsed time for check_pg_drc: 30.25 seconds ( 0.01 hours)
No errors found.
icc2_shell> 

```
### Timing Reports

> **📋 Critical Path Report:**

```
Information: The RC mode used is DR for design 'raven_wrapper'. (NEX-022)
Extracting design: raven_wrapper 
Information: coupling capacitance is lumped to ground. (NEX-030)
Information: 82495 nets are successfully extracted. (NEX-028)
Information: Update timing completed net estimation for all the timing graph nets (TIM-111)
****************************************
Report : timing
        -path_type full
        -delay_type max
        -max_paths 1
        -report_by design
Design : raven_wrapper
Version: U-2022.12-SP3
Date   : Tue Dec 30 13:26:50 2025
****************************************

  Startpoint: flash_io2 (input port clocked by ext_clk)
  Endpoint: _34495_ (rising edge-triggered flip-flop clocked by pll_clk)
  Mode: func1
  Corner: func1
  Scenario: func1
  Path Group: **in2reg_default**
  Path Type: max

  Point                                            Incr      Path  
  ------------------------------------------------------------------------
  clock ext_clk (rise edge)                        0.00      0.00
  clock network delay (propagated)                 3.44      3.44
  input external delay                             0.60      4.04 r
  flash_io2 (inout)                                0.00      4.04 r
  flash_io_buf_2/YPAD (PADINOUT)                   0.00      4.04 r
  flash_io_buf_2/DI (PADINOUT)                     5.33      9.37 r ~
  copt_gre_mt_inst_117492/Z (CLKBUF_X1)            1.07     10.44 r
  ZINV_692_inst_93527/ZN (INV_X2)                  0.09     10.54 f
  ZINV_427_inst_93526/ZN (INV_X8)                  0.13     10.67 r
  ZINV_212_inst_93525/ZN (INV_X1)                  0.25     10.92 f
  copt_gre_mt_inst_125765/Z (CLKBUF_X1)            0.16     11.07 f
  copt_gre_mt_inst_125764/Z (CLKBUF_X1)            0.19     11.26 f
  copt_gre_mt_inst_125763/Z (CLKBUF_X1)            0.22     11.49 f
  copt_gre_mt_inst_125762/Z (CLKBUF_X1)            0.24     11.73 f
  copt_gre_mt_inst_125761/Z (CLKBUF_X1)            0.23     11.96 f
  copt_gre_mt_inst_125760/Z (CLKBUF_X2)            0.16     12.12 f
  copt_gre_mt_inst_125759/Z (CLKBUF_X1)            0.22     12.33 f
  ZINV_76_inst_93524/ZN (INV_X1)                   0.19     12.52 r
  copt_gre_mt_inst_131748/Z (BUF_X16)              0.05     12.58 r
  _20145_/ZN (INV_X2)                              0.18     12.75 f
  _20147_/ZN (OAI21_X1)                            0.11     12.86 r
  _20150_/ZN (OAI221_X2)                           0.09     12.95 f
  _20152_/ZN (AOI21_X1)                            0.11     13.06 r
  _21483_/ZN (INV_X1)                              0.03     13.09 f
  _21485_/ZN (OAI211_X1)                           0.08     13.17 r
  _21489_/ZN (NAND3_X2)                            0.05     13.22 f
  ctmTdsLR_3_36291/ZN (AND3_X1)                    0.04     13.26 f
  ctmTdsLR_2_36290/ZN (NAND2_X1)                   0.03     13.29 r
  ctmTdsLR_1_36289/ZN (INV_X2)                     0.01     13.30 f
  _21635_/ZN (NAND3_X1)                            0.10     13.40 r
  _29672_/ZN (NOR2_X1)                             0.06     13.46 f
  ctmTdsLR_3_36124/ZN (INV_X1)                     0.04     13.50 r
  ctmTdsLR_2_36123/ZN (NAND3_X2)                   0.03     13.53 f
  ctmTdsLR_1_36122/ZN (OAI21_X1)                   0.03     13.56 r
  _29677_/Z (MUX2_X1)                              0.08     13.65 r
  ZINV_84_inst_32013/ZN (INV_X8)                   0.03     13.67 f
  copt_gre_mt_inst_123959/Z (CLKBUF_X1)            0.18     13.85 f
  copt_gre_mt_inst_131115/Z (CLKBUF_X1)            0.18     14.04 f
  copt_gre_mt_inst_131114/Z (CLKBUF_X1)            0.19     14.22 f
  copt_gre_mt_inst_131113/Z (CLKBUF_X1)            0.21     14.44 f
  copt_gre_mt_inst_131112/Z (CLKBUF_X1)            0.18     14.62 f
  ZBUF_59_inst_32012/Z (BUF_X4)                    0.08     14.70 f
  ZBUF_11_inst_62361/Z (CLKBUF_X2)                 0.11     14.82 f
  copt_gre_mt_inst_131646/Z (BUF_X4)               0.03     14.85 f
  copt_gre_mt_inst_131645/Z (CLKBUF_X3)            0.15     15.01 f
  copt_gre_mt_inst_131644/Z (CLKBUF_X2)            0.17     15.18 f
  ZINV_22_inst_32011/ZN (INV_X1)                   0.14     15.32 r
  copt_gre_mt_inst_129561/Z (CLKBUF_X1)            0.10     15.42 r
  copt_gre_mt_inst_135996/Z (CLKBUF_X1)            0.17     15.59 r
  copt_gre_mt_inst_129560/Z (CLKBUF_X1)            0.25     15.84 r
  copt_gre_mt_inst_129559/Z (CLKBUF_X1)            0.16     16.00 r
  copt_gre_mt_inst_129558/Z (CLKBUF_X1)            0.06     16.07 r
  copt_gre_mt_inst_136138/Z (CLKBUF_X1)            0.17     16.24 r
  copt_gre_mt_inst_129557/Z (CLKBUF_X1)            0.25     16.49 r
  copt_gre_mt_inst_129556/Z (CLKBUF_X1)            0.16     16.65 r
  copt_gre_mt_inst_129555/Z (CLKBUF_X1)            0.19     16.85 r
  _34495_/D (DFF_X1)                               0.02     16.87 r
  data arrival time                                         16.87

  clock pll_clk (rise edge)                       10.00     10.00
  clock network delay (propagated)                 5.39     15.39
  _34495_/CK (DFF_X1)                              0.00     15.39 r
  library setup time                              -0.04     15.35
  data required time                                        15.35
  ------------------------------------------------------------------------
  data required time                                        15.35
  data arrival time                                        -16.87
  ------------------------------------------------------------------------
  slack (VIOLATED)                                          -1.52


```
---

## How to Run

### Step 1: Setup Environment
```bash
csh
source ~/toolRC_iitgntapeout 

# Verify installation
which icc2_shell
```

### Step 2: Prepare Input Files
```bash
# Copy all required files to working directory
cp /path/to/raven_wrapper.synth.v .
cp /path/to/*.lef .
cp /path/to/*.db .
cp /path/to/*.tf .
```

### Step 3: Run Floorplanning
```bash
icc2_shell -f floorplan.tcl | tee floorplan.log
```

### Step 4: Run Power Planning
```bash
icc2_shell -f power_plan.tcl | tee power_plan.log
```

### Step 5: Run Place/CTS/Route
```bash
icc2_shell -f place_cts_route.tcl | tee place_cts_route.log
```
or run top.tcl

```
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

####################################
# Place, CTS, Route
####################################
eval create_placement $CMD_OPTIONS
report_placement    -physical_hierarchy_violations all    -wirelength all -hard_macro_overlap    -verbose high > $REPORTS_DIR_PLACEMENT/report_placement.rpt
set_host_options -max_cores 8
remove_corners [get_corners estimated_corner]
set_app_options -name place.coarse.continue_on_missing_scandef -value true
place_opt
clock_opt
route_auto -max_detail_route_iterations 5
set FILLER_CELLS [get_object_name [sort_collection -descending [get_lib_cells NangateOpenCellLibrary/FILL*] area]]
create_stdcell_fillers -lib_cells $FILLER_CELLS

save_block -hier -force   -label post_route
save_lib -all
```

### Step 6: Verify Results
```bash
# Check logs for errors
grep -i error logs_icc2/*.log

# Check timing
grep -i "slack" rpts_icc2/route/*.rpt

# Check DRC
grep -i "violation" rpts_icc2/route/*.rpt
```

---

## Key Takeaways

### Design Highlights
✅ **Timing:** All paths meet 100 MHz timing requirements  
✅ **Power:** Robust PDN with rings, straps, and mesh  
✅ **Routing:** 100% routed with zero DRC violations  
✅ **Utilization:** 68.3% core utilization  
✅ **Verification:** Clean DRC and LVS  

### Best Practices Applied
- Proper floorplanning with adequate spacing
- Multi-level power distribution network
- Timing-driven placement and routing
- Comprehensive design checks at each stage
- Detailed documentation and checkpointing

---

## Troubleshooting

### Common Issues

**Issue 1: Library not found**
```
Error: Cannot find reference library
```
**Solution:** Check REFERENCE_LIBRARY path in icc2_common_setup.tcl

**Issue 2: Timing violations**
```
Error: Setup violations exist
```
**Solution:** Adjust target density, enable more optimization

**Issue 3: Routing congestion**
```
Warning: High congestion in region
```
**Solution:** Reduce density, adjust macro placement

**Issue 4: PG DRC violations**
```
Error: PG spacing violation
```
**Solution:** Increase stripe spacing, check via rules

---

## References

- Synopsys IC Compiler II User Guide (Version P-2019.03-SP4)
- NangateOpenCellLibrary Documentation
- FreePDK45 Technology Design Manual
- IEEE Standard for Verilog (IEEE 1364-2005)

---

## License

This documentation is provided as-is for educational purposes.

---

**Last Updated:** December 2025  
**Tool Version:** Synopsys ICC2 P-2019.03-SP4  
**Design:** Raven Wrapper (FreePDK45)
