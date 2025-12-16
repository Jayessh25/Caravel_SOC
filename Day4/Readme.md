# RISC-V SoC Research Task - Synopsys VCS + DC_TOPO Flow (SCL180) without dummy_por.v module


# Functional simulation setup

## Prerequisites
Before using this repository, ensure you have the following dependencies installed:

- **SCL180 PDK** ( SCL180 PDK)
- **RiscV32-uknown-elf.gcc** (building functional simulation files)
- **Caravel User Project Framework** from vsd
- **Synopsys EDA tool Suite** for Synthesis

The primary objective of this task is to eliminate the behavioral on-chip Power-On Reset (POR) mechanism and migrate the SoC to a clean external reset–only architecture suitable for the SCL-180 technology.

In the original Caravel-based design, a non-synthesizable `dummy_por` module was used to generate multiple reset-related signals (`porb`, `porb_l`, `porb_h`) to model power-up sequencing behavior. These signals were distributed across the design and consumed purely as digital reset inputs by various blocks.

As part of this task, the following architectural changes were made:

- The `dummy_por` module has been **completely removed** from the RTL.
- All POR-related signals (`porb`, `porb_l`, `porb_h`, and variants) are no longer generated internally.
- A **single external active-low reset signal (`resetb`)**, driven directly from the testbench, is used as the sole reset source.
- The external reset signal is explicitly connected to all reset points that previously depended on POR signals.

This ensures that:
- Reset behavior is **explicit, deterministic, and visible** in the RTL.
- No internal reset generation, counters, or power-detection logic remains.
- All sequential logic is reset using a single, externally controlled reset input.

The external reset signal (`resetb`) functionally replaces all legacy POR outputs and provides equivalent reset coverage without relying on any behavioral or analog assumptions in RTL. This approach aligns with standard industry practices, where power-up sequencing is handled outside the digital design, and reset is treated as a system-level responsibility.

The correctness of this architectural change is validated through clean DC_TOPO synthesis and final VCS-based gate-level simulation using SCL-180 standard cell models.

To remove all POR signals and replace them with a single reset signal (such as resetb from your testbench), you can follow these guidelines:

Wherever dummy_por outputs are used (porb, porb_l, porb_h), replace them with direct assignments from resetb. For example, you can insert:

verilog
assign porb = resetb;
assign porb_l = resetb;
assign porb_h = resetb;
Remove the instantiation of the dummy_por module entirely since it's no longer needed.

Ensure that resetb is driven appropriately in your testbench, and it is the single asynchronous reset controlling all modules previously controlled by POR signals.

Confirm that the internal logic depending on POR signals can work correctly with this single reset input. If necessary, maintain active-low or active-high conventions by inverting resetb.

In your testbench, assert and deassert resetb as needed to initialize the design, just like a typical asynchronous reset.

This approach ensures that one global reset (resetb) controls the entire design's reset state, simplifying reset logic and allowing you to completely remove the dummy_por block.

**Note**
The changes to get the rtl verification without dummy_por.v,have already explained in Por_removal.md

---

## Test Instructions
1. source the synopsys tools
2. go to home
   ```
   csh
   source toolRC_iitgntapeout
   ```

### Functional Simulation Setup

3.Use this command to verify rtl in synopsys tool

```bash
vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+all +vpdfile+dump.vpd +incdir+../ +incdir+../../rtl +incdir+../../rtl/scl180_wrapper +incdir+/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/6M1L/verilog/tsl18cio250/zero +define+FUNCTIONAL +define+SIM hkspi_tb.v -o simv
```
<img width="776" height="914" alt="image" src="" />

before running the command clear previous output
```bash
rm -f *.vcd *.vpd
```

currently while running the vcs command it will generate vdp file but currently the tool which can access the vpd file is not installed so manually generating .vcd file so that we can see in gtkwave
we have to generate it using this command

```bash
./simv -no_save +define+DUMP_VCD=1 | tee sim_log.txt

```

<img width="776" height="914" alt="image" src="https://github.com/Jayessh25/Caravel_SOC/blob/main/Day4/Images/Command6.png" />

<img width="776" height="914" alt="image" src="https://github.com/Jayessh25/Caravel_SOC/blob/main/Day4/Images/Command7.png" />


## Key Changes Made

1. **Replaced `iverilog` with `vcs`** compilation
2. **Changed `-I` to `+incdir+`** for include directories
3. **Changed `+define+` syntax** for SIM_DEFINES (VCS standard)
4. **Added VCS-specific flags**: `-sverilog`, `+v2k`, `-full64`, `-debug_all`, `-lca`
5. **Removed all `.vvp` and `.vcd` targets** - replaced with `compile`, `sim`, `gui`, `vpd`, `fsdb`
6. **Updated clean target** to remove VCS-generated files: `simv.daidir`, `csrc`, `DVEfiles`, etc.
7. **Added separate targets** for batch simulation and GUI simulation
8. **Completely removed** any reference to `iverilog`, `vvp`, or `gtkwave`


## Errors you might encounter after changing follow the below solutions to clear those errors 

### Error 1: Variable TMPDIR (tmp) is selecting a non-existent directory.

Create the tmp directory in your current location

```
mkdir -p tmp
```
- rerun the make compile command

#### Why This Happens

VCS needs a temporary directory to store intermediate compilation files. The setup script set TMPDIR=tmp, which is a relative path referring to a tmp subdirectory in your current working directory. When you're in the hkspi directory, VCS looks for hkspi/tmp, which doesn't exist.

### Error 2: Error-[IND] Identifier not declared

Now there's an error in dummy_schmittbuf.v where signals are not declared. This happens because default_nettype none is set somewhere in your code, which requires explicit declaration of all signals.

#### Fix the dummy_schmittbuf.v file

Step 1: Open the file

```
gedit ../../rtl/dummy_schmittbuf.v
```
Step 2: Comment this line `default_nettype none

```
// default_nettype  none

module dummy_schmittbuf (
    output UDP_OUT,
    input UDP_IN,
    input VPWR,
    input VGND
);
    
    assign UDP_OUT = UDP_IN;
    
endmodule

```
Step 4: After all changes re-run the command 

---


# Synthesis Setup

    • Tool: Synopsys DC_TOPO
    • Synthesize vsdcaravel using SCL180 standard cell libraries
    • Constraints must be clean and reasonable
    • Output:
        ◦ Synthesized netlist
        ◦ Area, timing, and power reports
		
Important Constraint:

	1) POR and memory modules must remain as RTL modules
    2) Do not synthesize or replace them with macros yet
    3) Treat them as modules/blackboxes as appropriate

as per the task 2 we need to make modules like POR and memory modules such as RAM128 and RAM256 as blackbox and should not synthesize them. To do that we need to change synth.tcl with many changes. Follow the included run_dc_topo.tcl file in the repository to make the modules as blackbox and synthesis rest of the logic.

<img width="776" height="914" alt="image" src="https://github.com/Jayessh25/Caravel_SOC/blob/main/Day3/Images/Command7.png" />

```run_dc_topo.tcl
# ========================================================================
# Synopsys DC Synthesis Script for vsdcaravel
# Modified to keep POR and Memory modules as complete RTL blackboxes
# ========================================================================

# ========================================================================
# Load technology libraries
# ========================================================================
read_db "/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/4M1L/liberty/tsl18cio250_min.db"
read_db "/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/4M1IL/liberty/lib_flow_ff/tsl18fs120_scl_ff.db"

# ========================================================================
# Set library variables
# ========================================================================
set target_library "/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/4M1L/liberty/tsl18cio250_min.db /home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/4M1IL/liberty/lib_flow_ff/tsl18fs120_scl_ff.db"
set link_library "* /home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/4M1L/liberty/tsl18cio250_min.db /home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/4M1IL/liberty/lib_flow_ff/tsl18fs120_scl_ff.db"
set_app_var target_library $target_library
set_app_var link_library $link_library

# ========================================================================
# Define directory paths
# ========================================================================
set root_dir "/home/jaysk/vsdRiscvScl180"
set io_lib "/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/4M1L/verilog/tsl18cio250/zero"
set verilog_files  "$root_dir/rtl"
set top_module "vsdcaravel" ;
set output_file "$root_dir/synthesis/output/vsdcaravel_synthesis.v"
set report_dir "$root_dir/synthesis/report"

# ========================================================================
# Configure Blackbox Handling
# ========================================================================
# Prevent automatic memory inference and template saving
set_app_var hdlin_infer_multibit default_none
set_app_var hdlin_auto_save_templates false
set_app_var compile_ultra_ungroup_dw false

# ========================================================================
# Create Blackbox Stub File for Memory and POR Modules
# ========================================================================
set blackbox_file "$root_dir/synthesis/memory_por_blackbox_stubs.v"
set fp [open $blackbox_file w]
puts $fp "// Blackbox definitions for memory and POR modules"
puts $fp "// Auto-generated by synthesis script"
puts $fp ""

# RAM128 blackbox
puts $fp "(* blackbox *)"
puts $fp "module RAM128(CLK, EN0, VGND, VPWR, A0, Di0, Do0, WE0);"
puts $fp "  input CLK, EN0, VGND, VPWR;"
puts $fp "  input \[6:0\] A0;"
puts $fp "  input \[31:0\] Di0;"
puts $fp "  input \[3:0\] WE0;"
puts $fp "  output \[31:0\] Do0;"
puts $fp "endmodule"
puts $fp ""

# RAM256 blackbox
puts $fp "(* blackbox *)"
puts $fp "module RAM256(VPWR, VGND, CLK, WE0, EN0, A0, Di0, Do0);"
puts $fp "  input CLK, EN0;"
puts $fp "  inout VPWR, VGND;"
puts $fp "  input \[7:0\] A0;"
puts $fp "  input \[31:0\] Di0;"
puts $fp "  input \[3:0\] WE0;"
puts $fp "  output \[31:0\] Do0;"
puts $fp "endmodule"
puts $fp ""

# dummy_por blackbox
puts $fp "(* blackbox *)"
puts $fp "module dummy_por(vdd3v3, vdd1v8, vss3v3, vss1v8, porb_h, porb_l, por_l);"
puts $fp "  inout vdd3v3, vdd1v8, vss3v3, vss1v8;"
puts $fp "  output porb_h, porb_l, por_l;"
puts $fp "endmodule"
puts $fp ""

close $fp
puts "INFO: Created blackbox stub file: $blackbox_file"

# ========================================================================
# Read RTL Files
# ========================================================================
# Read defines first
read_file $verilog_files/defines.v

# Read blackbox stubs FIRST (before actual RTL)
puts "INFO: Reading memory and POR blackbox stubs..."
read_file $blackbox_file -format verilog

# ========================================================================
# Read RTL files excluding memory and POR modules
# ========================================================================
puts "INFO: Building RTL file list (excluding RAM128.v, RAM256.v, and dummy_por.v)..."

# Get all verilog files
set all_rtl_files [glob -nocomplain ${verilog_files}/*.v]

# Define files to exclude
set exclude_files [list \
    "${verilog_files}/RAM128.v" \
    "${verilog_files}/RAM256.v" \
    "${verilog_files}/dummy_por.v" \
]

# Build list of files to read
set rtl_to_read [list]
foreach file $all_rtl_files {
    set excluded 0
    foreach excl_file $exclude_files {
        if {[string equal $file $excl_file]} {
            set excluded 1
            puts "INFO: Excluding $file (using blackbox instead)"
            break
        }
    }
    if {!$excluded} {
        lappend rtl_to_read $file
    }
}

puts "INFO: Reading [llength $rtl_to_read] RTL files..."

# Read all RTL files EXCEPT RAM128.v, RAM256.v, and dummy_por.v
read_file $rtl_to_read -define USE_POWER_PINS -format verilog

# ========================================================================
# Elaborate Design
# ========================================================================
puts "INFO: Elaborating design..."
elaborate $top_module

# ========================================================================
# Set Blackbox Attributes for Memory Modules
# ========================================================================
puts "INFO: Setting Blackbox Attributes for Memory Modules..."

# Mark RAM128 as blackbox
if {[sizeof_collection [get_designs -quiet RAM128]] > 0} {
    set_attribute [get_designs RAM128] is_black_box true -quiet
    set_dont_touch [get_designs RAM128]
    puts "INFO: RAM128 marked as blackbox"
}

# Mark RAM256 as blackbox
if {[sizeof_collection [get_designs -quiet RAM256]] > 0} {
    set_attribute [get_designs RAM256] is_black_box true -quiet
    set_dont_touch [get_designs RAM256]
    puts "INFO: RAM256 marked as blackbox"
}

# ========================================================================
# Set POR (Power-On-Reset) Module as Blackbox
# ========================================================================
puts "INFO: Setting POR module as blackbox..."

# Mark dummy_por as blackbox
if {[sizeof_collection [get_designs -quiet dummy_por]] > 0} {
    set_attribute [get_designs dummy_por] is_black_box true -quiet
    set_dont_touch [get_designs dummy_por]
    puts "INFO: dummy_por marked as blackbox"
}

# Handle any other POR-related modules (case insensitive)
foreach_in_collection por_design [get_designs -quiet "*por*"] {
    set design_name [get_object_name $por_design]
    if {![string equal $design_name "dummy_por"]} {
        set_dont_touch $por_design
        set_attribute $por_design is_black_box true -quiet
        puts "INFO: $design_name set as blackbox"
    }
}

# ========================================================================
# Protect blackbox instances from optimization
# ========================================================================
puts "INFO: Protecting blackbox instances from optimization..."

# Protect all instances of RAM128, RAM256, and dummy_por
foreach blackbox_ref {"RAM128" "RAM256" "dummy_por"} {
    set instances [get_cells -quiet -hierarchical -filter "ref_name == $blackbox_ref"]
    if {[sizeof_collection $instances] > 0} {
        set_dont_touch $instances
        set inst_count [sizeof_collection $instances]
        puts "INFO: Protected $inst_count instance(s) of $blackbox_ref"
    }
}

# ========================================================================
# Link Design
# ========================================================================
puts "INFO: Linking design..."
link

# ========================================================================
# Uniquify Design
# ========================================================================
puts "INFO: Uniquifying design..."
uniquify

# ========================================================================
# Read SDC constraints (if exists)
# ========================================================================
if {[file exists "$root_dir/synthesis/vsdcaravel.sdc"]} {
    puts "INFO: Reading timing constraints..."
    read_sdc "$root_dir/synthesis/vsdcaravel.sdc"
}

# ========================================================================
# Compile Design (Basic synthesis)
# ========================================================================
puts "INFO: Starting compilation..."
#compile_ultra -incremental
compile_ultra -topographical -effort high   ← KEEP THIS
compile -incremental -map_effort high
# ========================================================================
# Write Outputs
# ========================================================================
puts "INFO: Writing output files..."

# Write Verilog netlist
write -format verilog -hierarchy -output $output_file
puts "INFO: Netlist written to: $output_file"

# Write DDC format for place-and-route
write -format ddc -hierarchy -output "$root_dir/synthesis/output/vsdcaravel_synthesis.ddc"
puts "INFO: DDC written to: $root_dir/synthesis/output/vsdcaravel_synthesis.ddc"

# Write SDC with actual timing constraints
write_sdc "$root_dir/synthesis/output/vsdcaravel_synthesis.sdc"
puts "INFO: SDC written to: $root_dir/synthesis/output/vsdcaravel_synthesis.sdc"

# ========================================================================
# Generate Reports
# ========================================================================
puts "INFO: Generating reports..."

report_qor > "$report_dir/qor_post_synth.rpt"
report_area > "$report_dir/area_post_synth.rpt"
report_power > "$report_dir/power_post_synth.rpt"

# Report on blackbox modules
puts "INFO: Generating blackbox module report..."
set bb_report [open "$report_dir/blackbox_modules.rpt" w]
puts $bb_report "========================================"
puts $bb_report "Blackbox Modules Report"
puts $bb_report "========================================"
puts $bb_report ""

foreach bb_module {"RAM128" "RAM256" "dummy_por"} {
    puts $bb_report "Module: $bb_module"
    set instances [get_cells -quiet -hierarchical -filter "ref_name == $bb_module"]
    if {[sizeof_collection $instances] > 0} {
        puts $bb_report "  Status: PRESENT"
        puts $bb_report "  Instances: [sizeof_collection $instances]"
        foreach_in_collection inst $instances {
            puts $bb_report "    - [get_object_name $inst]"
        }
    } else {
        puts $bb_report "  Status: NOT FOUND"
    }
    puts $bb_report ""
}
close $bb_report
puts "INFO: Blackbox report written to: $report_dir/blackbox_modules.rpt"

# ========================================================================
# Summary
# ========================================================================
puts ""
puts "INFO: ========================================"
puts "INFO: Synthesis Complete!"
puts "INFO: ========================================"
puts "INFO: Output netlist: $output_file"
puts "INFO: DDC file: $root_dir/synthesis/output/vsdcaravel_synthesis.ddc"
puts "INFO: SDC file: $root_dir/synthesis/output/vsdcaravel_synthesis.sdc"
puts "INFO: Reports directory: $report_dir"
puts "INFO: Blackbox stub file: $blackbox_file"
puts "INFO: "
puts "INFO: NOTE: The following modules are preserved as blackboxes:"
puts "INFO:   - RAM128 (Memory macro)"
puts "INFO:   - RAM256 (Memory macro)"
puts "INFO:   - dummy_por (Power-On-Reset circuit)"
puts "INFO: These modules will need to be replaced with actual macros during P&R"
puts "INFO: ========================================"

# Exit dc_shell
# dc_shell> exit
```
## What the run_dc_topo.tcl script actually does?

Here's a comprehensive explanation of the complete synthesis TCL script, broken down block by block:

## 1. Load Technology Libraries
```tcl
read_db "/home/Synopsys/pdk/SCL_PDK_3/.../tsl18cio250_min.db"
read_db "/home/Synopsys/pdk/SCL_PDK_3/.../tsl18fs120_scl_ff.db"
```
**Purpose**: Load compiled Liberty (.db) files into DC memory
- **`read_db`**: Reads binary database files containing cell timing/power/area information
- **First file**: I/O pad library (cio250) for chip periphery
- **Second file**: Standard cell library (fs120) for core logic
- **`_min.db`**: Minimum timing corner (fast process, high voltage, low temp)
- **`_ff.db`**: Fast-fast corner for timing analysis

***

## 2. Set Library Variables
```tcl
set target_library "..."
set link_library "* ..."
set_app_var target_library $target_library
set_app_var link_library $link_library
```
**Purpose**: Configure which libraries DC will use for synthesis
- **`target_library`**: Libraries DC uses to map logic gates during synthesis (technology mapping)
- **`link_library`**: Libraries DC searches to resolve cell references (`*` = current design in memory)
- **`set_app_var`**: Sets Synopsys application variables (persistent across sessions)
- **Why both?**: `target_library` = synthesis destination, `link_library` = reference resolution

***

## 3. Define Directory Paths
```tcl
set root_dir "/home/jaysk/vsdRiscvScl180"
set io_lib "..."
set verilog_files "$root_dir/rtl"
set top_module "vsdcaravel"
set output_file "$root_dir/synthesis/output/vsdcaravel_synthesis.v"
set report_dir "$root_dir/synthesis/report"
```
**Purpose**: Create variables for file paths (easier maintenance)
- **`root_dir`**: Project root directory
- **`io_lib`**: I/O library Verilog models (not used in this script but defined)
- **`verilog_files`**: Source RTL directory
- **`top_module`**: Top-level design name for elaboration
- **`output_file`**: Where to write synthesized netlist
- **`report_dir`**: Where to write analysis reports

***

## 4. Configure Blackbox Handling
```tcl
set_app_var hdlin_infer_multibit default_none
set_app_var hdlin_auto_save_templates false
set_app_var compile_ultra_ungroup_dw false
```
**Purpose**: Control how DC handles HDL reading and memory inference
- **`hdlin_infer_multibit default_none`**: Prevents DC from automatically inferring arrays as memories (stops RAM synthesis)
- **`hdlin_auto_save_templates false`**: Disables automatic saving of memory templates
- **`compile_ultra_ungroup_dw false`**: Prevents ungrouping of DesignWare components (keeps hierarchy)

**Why needed**: Without these, DC would try to synthesize RAM128/RAM256 into flip-flops or SRAMs

***

## 5. Create Blackbox Stub File
```tcl
set blackbox_file "$root_dir/synthesis/memory_por_blackbox_stubs.v"
set fp [open $blackbox_file w]
puts $fp "// Blackbox definitions..."
puts $fp "(* blackbox *)"
puts $fp "module RAM128(...);"
# ... more module definitions
close $fp
```
**Purpose**: Dynamically create a Verilog file with empty module definitions
- **`open $blackbox_file w`**: Opens file for writing, returns file handle `$fp`
- **`puts $fp`**: Writes lines to file
- **`(* blackbox *)`**: Verilog attribute telling synthesis this is a blackbox
- **`close $fp`**: Closes file handle
- **Why?**: Provides module interfaces without implementation, preventing synthesis

**Key modules created**:
1. **RAM128**: 7-bit address (128 words), 32-bit data, 4-bit write enable
2. **RAM256**: 8-bit address (256 words), 32-bit data, 4-bit write enable  
3. **dummy_por**: Power-on-reset with power pins and reset outputs

***

## 6. Read RTL Files - Defines
```tcl
read_file $verilog_files/defines.v
```
**Purpose**: Read preprocessor defines first
- **`read_file`**: Reads Verilog source files
- **Why first?**: `defines.v` contains `define` macros used by other files (e.g., `USE_POWER_PINS`)

***

## 7. Read Blackbox Stubs
```tcl
read_file $blackbox_file -format verilog
```
**Purpose**: Read empty blackbox definitions BEFORE actual RTL
- **`-format verilog`**: Explicitly specify Verilog format
- **Why first?**: Ensures DC sees blackbox version before any actual implementation
- **Result**: DC knows RAM128, RAM256, dummy_por exist but won't synthesize them

***

## 8. Filter RTL Files
```tcl
set all_rtl_files [glob -nocomplain ${verilog_files}/*.v]
set exclude_files [list "${verilog_files}/RAM128.v" ...]
set rtl_to_read [list]
foreach file $all_rtl_files {
    set excluded 0
    foreach excl_file $exclude_files {
        if {[string equal $file $excl_file]} {
            set excluded 1
            break
        }
    }
    if {!$excluded} {
        lappend rtl_to_read $file
    }
}
```
**Purpose**: Build list of RTL files, excluding blackbox implementations
- **`glob -nocomplain`**: Get all `.v` files (no error if none found)
- **`list`**: Creates TCL list
- **`foreach`**: Loop through each file
- **`string equal`**: Compare file paths
- **`lappend`**: Append to list if not excluded
- **Why exclude?**: Prevents reading actual RAM/POR implementations that would override blackboxes

***

## 9. Read Filtered RTL
```tcl
read_file $rtl_to_read -define USE_POWER_PINS -format verilog
```
**Purpose**: Read all RTL except blackboxed modules
- **`-define USE_POWER_PINS`**: Sets Verilog preprocessor define (like `+define+USE_POWER_PINS`)
- **Reads**: All design files except RAM128.v, RAM256.v, dummy_por.v
- **Result**: DC has full design except blackbox internals

***

## 10. Elaborate Design
```tcl
elaborate $top_module
```
**Purpose**: Build design hierarchy and resolve module references
- **`elaborate`**: Processes RTL to create internal design database
- **What happens**:
  - Resolves module instantiations
  - Creates hierarchy tree
  - Infers sequential logic (registers)
  - Builds netlist connectivity
- **For blackboxes**: Uses stub definitions (port-only, no internals)

***

## 11. Set Blackbox Attributes - Memory
```tcl
if {[sizeof_collection [get_designs -quiet RAM128]] > 0} {
    set_attribute [get_designs RAM128] is_black_box true -quiet
    set_dont_touch [get_designs RAM128]
}
```
**Purpose**: Mark modules as blackboxes and protect from optimization
- **`get_designs -quiet RAM128`**: Query if RAM128 design exists (no error if missing)
- **`sizeof_collection`**: Returns number of objects in collection
- **`set_attribute ... is_black_box true`**: Tells DC this is a blackbox (don't optimize internals)
- **`set_dont_touch`**: Prevents DC from:
  - Optimizing/removing the module
  - Modifying its ports
  - Ungrouping its hierarchy
- **`-quiet`**: Suppresses warnings

**Same for RAM256 and dummy_por**

***

## 12. Protect POR Modules (Wildcard)
```tcl
foreach_in_collection por_design [get_designs -quiet "*por*"] {
    set design_name [get_object_name $por_design]
    if {![string equal $design_name "dummy_por"]} {
        set_dont_touch $por_design
        set_attribute $por_design is_black_box true -quiet
    }
}
```
**Purpose**: Find and protect any other POR-related modules
- **`get_designs "*por*"`**: Wildcard search for modules with "por" in name
- **`foreach_in_collection`**: Loop through collection
- **`get_object_name`**: Extract name from design object
- **Why skip dummy_por?**: Already handled above (avoid redundancy)
- **Safety net**: Catches any POR modules with different naming

***

## 13. Protect Blackbox Instances
```tcl
foreach blackbox_ref {"RAM128" "RAM256" "dummy_por"} {
    set instances [get_cells -quiet -hierarchical -filter "ref_name == $blackbox_ref"]
    if {[sizeof_collection $instances] > 0} {
        set_dont_touch $instances
    }
}
```
**Purpose**: Protect instances (not just module definitions)
- **`get_cells`**: Query cell instances in design
- **`-hierarchical`**: Search entire hierarchy (not just top level)
- **`-filter "ref_name == $blackbox_ref"`**: Find instances of specific module type
- **`set_dont_touch $instances`**: Protect instances from:
  - Being optimized away
  - Having logic pushed through them
  - Boundary optimization
- **Why needed?**: Module protection doesn't automatically protect instances

***

## 14. Link Design
```tcl
link
```
**Purpose**: Resolve all module/cell references and check for unlinked objects
- **What it does**:
  - Connects module instances to definitions
  - Resolves library cell references
  - Checks for missing definitions
- **Errors if**:
  - Referenced module not found
  - Required library cell missing
- **For blackboxes**: Links instances to blackbox definitions (not internals)

***

## 15. Uniquify Design
```tcl
uniquify
```
**Purpose**: Create unique copies of multiply-instantiated modules
- **Why needed**: If module is instantiated multiple times, DC creates unique copies for independent optimization
- **Example**: If `moduleA` is used twice:
  - Before: `moduleA`, `moduleA`
  - After: `moduleA_0`, `moduleA_1`
- **For blackboxes**: They remain unchanged (protected by `dont_touch`)

***

## 16. Read Timing Constraints
```tcl
if {[file exists "$root_dir/synthesis/vsdcaravel.sdc"]} {
    read_sdc "$root_dir/synthesis/vsdcaravel.sdc"
}
```
**Purpose**: Load timing constraints (clock definitions, I/O delays, false paths)
- **`file exists`**: Check if SDC file exists
- **`read_sdc`**: Parses Synopsys Design Constraints file
- **SDC contains**:
  - Clock definitions (`create_clock`)
  - Input/output delays (`set_input_delay`)
  - Timing exceptions (`set_false_path`)
  - Max/min delays
- **Why conditional?**: Script won't fail if SDC missing

***

## 17. Compile Design
```tcl
compile
```
**Purpose**: Perform logic synthesis (main synthesis step)
- **What happens**:
  1. **Logic optimization**: Simplifies Boolean equations
  2. **Technology mapping**: Maps gates to standard cells from `target_library`
  3. **Timing optimization**: Meets setup/hold timing
  4. **Area optimization**: Minimizes cell area
  5. **DFT insertion** (if configured): Adds scan chains
- **For blackboxes**: Instances treated as black boxes (no internal optimization)
- **Output**: Gate-level netlist using library cells

**Alternative**: `compile_ultra` (more aggressive, longer runtime)

***

## 18. Write Outputs - Verilog Netlist
```tcl
write -format verilog -hierarchy -output $output_file
```
**Purpose**: Save synthesized netlist as Verilog
- **`-format verilog`**: Output format (alternatives: `ddc`, `vhdl`)
- **`-hierarchy`**: Include full hierarchy (not flattened)
- **`-output`**: Destination file
- **Contains**:
  - Module definitions
  - Instantiated standard cells
  - Wire connections
  - Blackbox module definitions (port-only)

***

## 19. Write Outputs - DDC
```tcl
write -format ddc -hierarchy -output ".../vsdcaravel_synthesis.ddc"
```
**Purpose**: Save design in Synopsys binary format
- **`ddc`**: Synopsys proprietary binary format
- **Advantages**:
  - Preserves all DC internal information
  - Faster to read than Verilog
  - Used by ICC/ICC2 for place-and-route
- **Contains**: Complete design database (netlist, constraints, attributes)

***

## 20. Write Outputs - SDC
```tcl
write_sdc "$root_dir/synthesis/output/vsdcaravel_synthesis.sdc"
```
**Purpose**: Export timing constraints with actual netlist names
- **Difference from input SDC**:
  - Input: Uses RTL signal names
  - Output: Uses gate-level netlist names
- **Used by**: P&R tools for timing closure
- **Contains**: Clock definitions, I/O constraints mapped to synthesized netlist

***

## 21. Generate Reports
```tcl
report_area > "$report_dir/area.rpt"
report_power > "$report_dir/power.rpt"
report_timing -max_paths 10 > "$report_dir/timing.rpt"
report_constraint -all_violators > "$report_dir/constraints.rpt"
report_qor > "$report_dir/qor.rpt"
```
**Purpose**: Generate analysis reports for design evaluation

### Individual Reports:
- **`report_area`**: Cell area, combinational vs sequential breakdown
- **`report_power`**: Power consumption (dynamic, static, switching)
- **`report_timing -max_paths 10`**: 10 worst timing paths (setup/hold analysis)
- **`report_constraint -all_violators`**: Lists all violated timing constraints
- **`report_qor`**: Quality of Results summary (area, timing, power overview)

***

## 22. Generate Blackbox Report
```tcl
set bb_report [open "$report_dir/blackbox_modules.rpt" w]
foreach bb_module {"RAM128" "RAM256" "dummy_por"} {
    set instances [get_cells -quiet -hierarchical -filter "ref_name == $bb_module"]
    if {[sizeof_collection $instances] > 0} {
        puts $bb_report "  Status: PRESENT"
        puts $bb_report "  Instances: [sizeof_collection $instances]"
        foreach_in_collection inst $instances {
            puts $bb_report "    - [get_object_name $inst]"
        }
    }
}
close $bb_report
```
**Purpose**: Create custom report documenting blackbox modules
- **Opens file**: For writing
- **Loops through**: Each blackbox module
- **Queries**: Instance count and names
- **Reports**:
  - Whether module is present
  - How many instances
  - Instance hierarchical paths
- **Result**: Verification that blackboxes are preserved

***

## 23. Summary
```tcl
puts ""
puts "INFO: ========================================"
puts "INFO: Synthesis Complete!"
# ... prints summary information
```
**Purpose**: Display synthesis completion message and file locations
- **`puts`**: Print to console (stdout)
- **Shows**:
  - Output file locations
  - Blackbox modules preserved
  - Next steps (P&R)
- **User-friendly**: Clear summary of synthesis results

***
---

## Running tcl file

- To run the tcl file change to the synthesis directory and run the following command
  ```
	dc_shell -f run_dc_topo.tcl | tee dc_shell.log
  ```
- The above command will do synthesis using dc_shell tool and create a log file.

<img width="776" height="914" alt="image" src="https://github.com/Jayessh25/Caravel_SOC/blob/main/Day3/Images/Command8.png" />

- After synthesis go to output directory and check the `vsdcaravel_synthesis.v`. The POR and Memory modules will have only ports.

<img width="776" height="914" alt="image" src="https://github.com/Jayessh25/Caravel_SOC/blob/main/Day4/Images/Command8.png" />

**Note** see currently there is no dummy_por

---
<img width="776" height="914" alt="image" src="https://github.com/Jayessh25/Caravel_SOC/blob/main/Day4/Images/Command11.png" />


This script ensures RAM128, RAM256, and dummy_por remain as port-only blackboxes, ready for macro replacement during physical design!
---

## Reports

After synthesis report files will be generated in the report directory such as area, power, timing, constraints, qor and blackbox_modules reports.

### area report

``` bash
Warning: Design 'vsdcaravel' has '4' unresolved references. For more detailed information, use the "link" command. (UID-341)
 
****************************************
Report : area
Design : vsdcaravel
Version: T-2022.03-SP5
Date   : Tue Dec 16 18:09:41 2025
****************************************

Library(s) Used:

    tsl18fs120_scl_ff (File: /home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/4M1IL/liberty/lib_flow_ff/tsl18fs120_scl_ff.db)
    tsl18cio250_min (File: /home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/4M1L/liberty/tsl18cio250_min.db)

Number of ports:                        14246
Number of nets:                         38523
Number of cells:                        31047
Number of combinational cells:          18422
Number of sequential cells:              6888
Number of macros/black boxes:              17
Number of buf/inv:                       3532
Number of references:                       2

Combinational area:             341951.960055
Buf/Inv area:                    28798.119889
Noncombinational area:          431036.399128
Macro/Black Box area:             1395.760063
Net Interconnect area:           32654.899591

Total cell area:                774384.119246
Total area:                     807039.018838

Information: This design contains black box (unknown) components. (RPT-8)
1
```












### power report

```bash
Loading db file '/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/4M1IL/liberty/lib_flow_ff/tsl18fs120_scl_ff.db'
Loading db file '/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/4M1L/liberty/tsl18cio250_min.db'
Information: Propagating switching activity (low effort zero delay simulation). (PWR-6)
Warning: Design has unannotated primary inputs. (PWR-414)
Warning: Design has unannotated sequential cell outputs. (PWR-415)
Warning: Design has unannotated black box outputs. (PWR-428)
 
****************************************
Report : power
        -analysis_effort low
Design : vsdcaravel
Version: T-2022.03-SP5
Date   : Tue Dec 16 18:24:32 2025
****************************************


Library(s) Used:

    tsl18fs120_scl_ff (File: /home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/4M1IL/liberty/lib_flow_ff/tsl18fs120_scl_ff.db)
    tsl18cio250_min (File: /home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/4M1L/liberty/tsl18cio250_min.db)


Operating Conditions: tsl18cio250_min   Library: tsl18cio250_min
Wire Load Model Mode: enclosed

Design        Wire Load Model            Library
------------------------------------------------
vsdcaravel             1000000           tsl18cio250_min
chip_io                4000              tsl18cio250_min
caravel_core           1000000           tsl18cio250_min
constant_block_0       ForQA             tsl18cio250_min
mprj_io                ForQA             tsl18cio250_min
mgmt_core_wrapper      280000            tsl18cio250_min
mgmt_protect           8000              tsl18cio250_min
user_project_wrapper   16000             tsl18cio250_min
caravel_clocking       8000              tsl18cio250_min
digital_pll            16000             tsl18cio250_min
housekeeping           280000            tsl18cio250_min
mprj_io_buffer         4000              tsl18cio250_min
gpio_defaults_block_1803_1
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_34
                       ForQA             tsl18cio250_min
gpio_defaults_block_0801
                       ForQA             tsl18cio250_min
gpio_control_block_36  4000              tsl18cio250_min
user_id_programming_00000000
                       ForQA             tsl18cio250_min
xres_buf               ForQA             tsl18cio250_min
spare_logic_block_0    4000              tsl18cio250_min
dummy_scl180_conb_1_760
                       ForQA             tsl18cio250_min
mgmt_core              280000            tsl18cio250_min
mprj_logic_high        ForQA             tsl18cio250_min
mprj2_logic_high       ForQA             tsl18cio250_min
mgmt_protect_hv        ForQA             tsl18cio250_min
debug_regs             16000             tsl18cio250_min
clock_div_SIZE3_1      4000              tsl18cio250_min
ring_osc2x13           4000              tsl18cio250_min
digital_pll_controller 8000              tsl18cio250_min
housekeeping_spi       8000              tsl18cio250_min
gpio_logic_high_36     ForQA             tsl18cio250_min
scl180_marco_sparecell_36
                       ForQA             tsl18cio250_min
even_1                 4000              tsl18cio250_min
odd_1                  4000              tsl18cio250_min
delay_stage_11         4000              tsl18cio250_min
start_stage            4000              tsl18cio250_min
constant_block_6       ForQA             tsl18cio250_min
constant_block_5       ForQA             tsl18cio250_min
constant_block_4       ForQA             tsl18cio250_min
constant_block_3       ForQA             tsl18cio250_min
constant_block_2       ForQA             tsl18cio250_min
constant_block_1       ForQA             tsl18cio250_min
spare_logic_block_3    4000              tsl18cio250_min
spare_logic_block_2    4000              tsl18cio250_min
spare_logic_block_1    4000              tsl18cio250_min
gpio_defaults_block_1803_0
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_0
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_1
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_2
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_3
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_4
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_5
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_6
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_7
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_8
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_9
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_10
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_11
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_12
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_13
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_14
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_15
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_16
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_17
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_18
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_19
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_20
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_21
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_22
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_23
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_24
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_25
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_26
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_27
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_28
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_29
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_30
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_31
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_32
                       ForQA             tsl18cio250_min
gpio_defaults_block_0403_33
                       ForQA             tsl18cio250_min
gpio_control_block_15  4000              tsl18cio250_min
gpio_control_block_14  4000              tsl18cio250_min
gpio_control_block_13  4000              tsl18cio250_min
gpio_control_block_12  4000              tsl18cio250_min
gpio_control_block_11  4000              tsl18cio250_min
gpio_control_block_10  4000              tsl18cio250_min
gpio_control_block_9   4000              tsl18cio250_min
gpio_control_block_8   4000              tsl18cio250_min
gpio_control_block_7   4000              tsl18cio250_min
gpio_control_block_6   4000              tsl18cio250_min
gpio_control_block_5   4000              tsl18cio250_min
gpio_control_block_4   4000              tsl18cio250_min
gpio_control_block_3   4000              tsl18cio250_min
gpio_control_block_2   4000              tsl18cio250_min
gpio_control_block_1   4000              tsl18cio250_min
gpio_control_block_0   4000              tsl18cio250_min
gpio_control_block_18  4000              tsl18cio250_min
gpio_control_block_17  4000              tsl18cio250_min
gpio_control_block_16  4000              tsl18cio250_min
gpio_control_block_29  4000              tsl18cio250_min
gpio_control_block_28  4000              tsl18cio250_min
gpio_control_block_27  4000              tsl18cio250_min
gpio_control_block_26  4000              tsl18cio250_min
gpio_control_block_25  4000              tsl18cio250_min
gpio_control_block_24  4000              tsl18cio250_min
gpio_control_block_23  4000              tsl18cio250_min
gpio_control_block_22  4000              tsl18cio250_min
gpio_control_block_21  4000              tsl18cio250_min
gpio_control_block_20  4000              tsl18cio250_min
gpio_control_block_19  4000              tsl18cio250_min
gpio_control_block_35  4000              tsl18cio250_min
gpio_control_block_34  4000              tsl18cio250_min
gpio_control_block_33  4000              tsl18cio250_min
gpio_control_block_32  4000              tsl18cio250_min
gpio_control_block_31  4000              tsl18cio250_min
gpio_control_block_30  4000              tsl18cio250_min
gpio_control_block_37  4000              tsl18cio250_min
clock_div_SIZE3_0      4000              tsl18cio250_min
dummy_scl180_conb_1_103
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_57 ForQA             tsl18cio250_min
dummy_scl180_conb_1_58 ForQA             tsl18cio250_min
dummy_scl180_conb_1_55 ForQA             tsl18cio250_min
dummy_scl180_conb_1_56 ForQA             tsl18cio250_min
dummy_scl180_conb_1_53 ForQA             tsl18cio250_min
dummy_scl180_conb_1_54 ForQA             tsl18cio250_min
dummy_scl180_conb_1_51 ForQA             tsl18cio250_min
dummy_scl180_conb_1_52 ForQA             tsl18cio250_min
dummy_scl180_conb_1_49 ForQA             tsl18cio250_min
dummy_scl180_conb_1_50 ForQA             tsl18cio250_min
dummy_scl180_conb_1_47 ForQA             tsl18cio250_min
dummy_scl180_conb_1_48 ForQA             tsl18cio250_min
dummy_scl180_conb_1_45 ForQA             tsl18cio250_min
dummy_scl180_conb_1_46 ForQA             tsl18cio250_min
dummy_scl180_conb_1_43 ForQA             tsl18cio250_min
dummy_scl180_conb_1_44 ForQA             tsl18cio250_min
dummy_scl180_conb_1_41 ForQA             tsl18cio250_min
dummy_scl180_conb_1_42 ForQA             tsl18cio250_min
dummy_scl180_conb_1_39 ForQA             tsl18cio250_min
dummy_scl180_conb_1_40 ForQA             tsl18cio250_min
dummy_scl180_conb_1_37 ForQA             tsl18cio250_min
dummy_scl180_conb_1_38 ForQA             tsl18cio250_min
dummy_scl180_conb_1_35 ForQA             tsl18cio250_min
dummy_scl180_conb_1_36 ForQA             tsl18cio250_min
dummy_scl180_conb_1_33 ForQA             tsl18cio250_min
dummy_scl180_conb_1_34 ForQA             tsl18cio250_min
dummy_scl180_conb_1_31 ForQA             tsl18cio250_min
dummy_scl180_conb_1_32 ForQA             tsl18cio250_min
dummy_scl180_conb_1_29 ForQA             tsl18cio250_min
dummy_scl180_conb_1_30 ForQA             tsl18cio250_min
dummy_scl180_conb_1_27 ForQA             tsl18cio250_min
dummy_scl180_conb_1_28 ForQA             tsl18cio250_min
dummy_scl180_conb_1_63 ForQA             tsl18cio250_min
dummy_scl180_conb_1_64 ForQA             tsl18cio250_min
dummy_scl180_conb_1_61 ForQA             tsl18cio250_min
dummy_scl180_conb_1_62 ForQA             tsl18cio250_min
dummy_scl180_conb_1_59 ForQA             tsl18cio250_min
dummy_scl180_conb_1_60 ForQA             tsl18cio250_min
dummy_scl180_conb_1_85 ForQA             tsl18cio250_min
dummy_scl180_conb_1_86 ForQA             tsl18cio250_min
dummy_scl180_conb_1_83 ForQA             tsl18cio250_min
dummy_scl180_conb_1_84 ForQA             tsl18cio250_min
dummy_scl180_conb_1_81 ForQA             tsl18cio250_min
dummy_scl180_conb_1_82 ForQA             tsl18cio250_min
dummy_scl180_conb_1_79 ForQA             tsl18cio250_min
dummy_scl180_conb_1_80 ForQA             tsl18cio250_min
dummy_scl180_conb_1_77 ForQA             tsl18cio250_min
dummy_scl180_conb_1_78 ForQA             tsl18cio250_min
dummy_scl180_conb_1_75 ForQA             tsl18cio250_min
dummy_scl180_conb_1_76 ForQA             tsl18cio250_min
dummy_scl180_conb_1_73 ForQA             tsl18cio250_min
dummy_scl180_conb_1_74 ForQA             tsl18cio250_min
dummy_scl180_conb_1_71 ForQA             tsl18cio250_min
dummy_scl180_conb_1_72 ForQA             tsl18cio250_min
dummy_scl180_conb_1_69 ForQA             tsl18cio250_min
dummy_scl180_conb_1_70 ForQA             tsl18cio250_min
dummy_scl180_conb_1_67 ForQA             tsl18cio250_min
dummy_scl180_conb_1_68 ForQA             tsl18cio250_min
dummy_scl180_conb_1_65 ForQA             tsl18cio250_min
dummy_scl180_conb_1_66 ForQA             tsl18cio250_min
dummy_scl180_conb_1_97 ForQA             tsl18cio250_min
dummy_scl180_conb_1_98 ForQA             tsl18cio250_min
dummy_scl180_conb_1_95 ForQA             tsl18cio250_min
dummy_scl180_conb_1_96 ForQA             tsl18cio250_min
dummy_scl180_conb_1_93 ForQA             tsl18cio250_min
dummy_scl180_conb_1_94 ForQA             tsl18cio250_min
dummy_scl180_conb_1_91 ForQA             tsl18cio250_min
dummy_scl180_conb_1_92 ForQA             tsl18cio250_min
dummy_scl180_conb_1_89 ForQA             tsl18cio250_min
dummy_scl180_conb_1_90 ForQA             tsl18cio250_min
dummy_scl180_conb_1_87 ForQA             tsl18cio250_min
dummy_scl180_conb_1_88 ForQA             tsl18cio250_min
dummy_scl180_conb_1_101
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_102
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_99 ForQA             tsl18cio250_min
dummy_scl180_conb_1_100
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_757
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_758
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_759
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_566
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_565
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_564
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_563
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_562
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_561
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_560
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_559
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_558
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_557
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_556
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_555
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_554
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_553
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_552
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_551
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_550
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_549
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_548
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_547
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_546
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_545
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_544
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_543
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_542
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_541
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_540
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_539
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_538
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_537
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_536
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_535
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_534
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_533
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_532
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_531
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_530
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_529
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_528
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_527
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_526
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_525
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_524
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_523
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_522
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_521
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_520
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_519
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_518
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_517
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_516
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_515
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_514
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_513
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_512
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_511
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_510
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_509
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_508
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_507
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_506
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_505
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_504
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_503
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_502
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_501
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_500
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_499
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_498
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_497
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_496
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_495
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_494
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_493
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_492
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_491
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_490
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_489
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_488
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_487
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_486
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_485
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_484
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_483
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_482
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_481
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_480
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_479
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_478
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_477
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_476
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_475
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_474
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_473
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_472
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_471
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_470
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_469
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_468
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_467
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_466
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_465
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_464
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_463
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_462
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_461
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_460
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_459
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_458
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_457
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_456
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_455
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_454
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_453
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_452
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_451
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_450
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_449
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_448
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_447
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_446
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_445
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_444
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_443
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_442
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_441
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_440
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_439
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_438
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_437
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_436
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_435
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_434
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_433
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_432
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_431
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_430
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_429
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_428
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_427
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_426
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_425
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_424
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_423
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_422
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_421
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_420
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_419
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_418
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_417
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_416
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_415
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_414
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_413
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_412
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_411
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_410
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_409
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_408
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_407
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_406
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_405
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_404
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_403
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_402
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_401
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_400
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_399
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_398
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_397
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_396
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_395
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_394
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_393
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_392
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_391
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_390
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_389
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_388
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_387
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_386
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_385
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_384
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_383
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_382
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_381
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_380
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_379
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_378
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_377
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_376
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_375
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_374
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_373
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_372
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_371
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_370
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_369
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_368
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_367
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_366
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_365
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_364
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_363
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_362
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_361
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_360
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_359
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_358
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_357
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_356
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_355
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_354
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_353
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_352
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_351
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_350
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_349
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_348
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_347
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_346
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_345
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_344
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_343
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_342
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_341
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_340
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_339
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_338
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_337
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_336
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_335
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_334
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_333
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_332
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_331
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_330
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_329
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_328
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_327
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_326
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_325
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_324
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_323
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_322
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_321
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_320
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_319
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_318
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_317
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_316
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_315
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_314
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_313
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_312
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_311
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_310
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_309
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_308
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_307
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_306
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_305
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_304
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_303
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_302
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_301
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_300
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_299
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_298
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_297
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_296
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_295
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_294
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_293
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_292
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_291
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_290
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_289
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_288
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_287
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_286
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_285
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_284
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_283
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_282
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_281
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_280
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_279
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_278
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_277
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_276
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_275
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_274
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_273
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_272
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_271
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_270
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_269
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_268
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_267
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_266
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_265
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_264
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_263
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_262
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_261
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_260
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_259
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_258
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_257
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_256
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_255
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_254
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_253
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_252
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_251
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_250
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_249
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_248
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_247
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_246
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_245
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_244
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_243
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_242
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_241
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_240
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_239
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_238
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_237
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_236
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_235
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_234
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_233
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_232
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_231
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_230
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_229
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_228
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_227
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_226
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_225
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_224
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_223
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_222
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_221
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_220
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_219
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_218
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_217
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_216
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_215
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_214
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_213
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_212
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_211
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_210
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_209
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_208
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_207
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_206
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_205
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_204
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_203
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_202
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_201
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_200
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_199
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_198
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_197
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_196
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_195
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_194
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_193
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_192
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_191
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_190
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_189
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_188
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_187
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_186
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_185
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_184
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_183
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_182
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_181
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_180
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_179
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_178
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_177
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_176
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_175
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_174
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_173
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_172
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_171
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_170
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_169
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_168
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_167
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_166
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_165
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_164
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_163
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_162
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_161
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_160
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_159
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_158
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_157
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_156
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_155
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_154
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_153
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_152
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_151
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_150
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_149
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_148
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_147
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_146
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_145
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_144
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_143
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_142
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_141
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_140
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_139
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_138
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_137
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_136
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_135
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_134
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_133
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_132
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_131
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_130
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_129
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_128
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_127
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_126
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_125
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_124
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_123
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_122
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_121
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_120
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_119
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_118
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_117
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_116
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_115
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_114
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_113
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_112
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_111
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_110
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_109
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_108
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_107
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_106
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_105
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_104
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_26 ForQA             tsl18cio250_min
dummy_scl180_conb_1_25 ForQA             tsl18cio250_min
dummy_scl180_conb_1_24 ForQA             tsl18cio250_min
dummy_scl180_conb_1_23 ForQA             tsl18cio250_min
dummy_scl180_conb_1_22 ForQA             tsl18cio250_min
dummy_scl180_conb_1_21 ForQA             tsl18cio250_min
dummy_scl180_conb_1_20 ForQA             tsl18cio250_min
dummy_scl180_conb_1_19 ForQA             tsl18cio250_min
dummy_scl180_conb_1_18 ForQA             tsl18cio250_min
dummy_scl180_conb_1_17 ForQA             tsl18cio250_min
dummy_scl180_conb_1_16 ForQA             tsl18cio250_min
dummy_scl180_conb_1_15 ForQA             tsl18cio250_min
dummy_scl180_conb_1_14 ForQA             tsl18cio250_min
dummy_scl180_conb_1_13 ForQA             tsl18cio250_min
dummy_scl180_conb_1_12 ForQA             tsl18cio250_min
dummy_scl180_conb_1_11 ForQA             tsl18cio250_min
dummy_scl180_conb_1_10 ForQA             tsl18cio250_min
dummy_scl180_conb_1_9  ForQA             tsl18cio250_min
dummy_scl180_conb_1_8  ForQA             tsl18cio250_min
dummy_scl180_conb_1_7  ForQA             tsl18cio250_min
dummy_scl180_conb_1_6  ForQA             tsl18cio250_min
dummy_scl180_conb_1_5  ForQA             tsl18cio250_min
dummy_scl180_conb_1_4  ForQA             tsl18cio250_min
dummy_scl180_conb_1_3  ForQA             tsl18cio250_min
dummy_scl180_conb_1_2  ForQA             tsl18cio250_min
dummy_scl180_conb_1_1  ForQA             tsl18cio250_min
dummy_scl180_conb_1_0  ForQA             tsl18cio250_min
dummy_scl180_conb_1_647
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_646
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_645
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_644
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_643
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_642
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_641
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_640
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_639
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_638
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_637
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_636
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_635
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_634
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_633
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_632
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_631
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_630
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_629
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_628
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_627
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_626
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_625
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_624
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_623
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_622
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_621
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_620
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_619
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_618
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_617
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_616
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_615
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_614
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_613
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_612
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_611
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_610
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_609
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_608
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_607
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_606
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_605
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_604
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_603
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_602
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_601
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_600
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_599
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_598
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_597
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_596
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_595
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_594
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_593
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_592
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_591
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_590
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_589
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_588
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_587
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_586
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_585
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_584
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_583
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_582
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_581
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_580
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_579
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_578
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_577
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_576
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_575
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_574
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_573
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_572
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_571
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_570
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_569
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_568
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_567
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_679
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_678
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_677
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_676
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_675
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_674
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_673
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_672
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_671
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_670
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_669
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_668
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_667
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_666
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_665
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_664
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_663
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_662
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_661
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_660
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_659
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_658
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_657
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_656
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_655
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_654
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_653
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_652
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_651
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_650
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_649
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_648
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_695
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_694
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_693
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_692
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_691
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_690
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_689
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_688
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_687
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_686
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_685
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_684
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_683
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_682
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_681
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_680
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_698
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_697
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_696
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_709
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_708
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_707
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_706
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_705
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_704
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_703
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_702
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_701
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_700
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_699
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_715
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_714
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_713
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_712
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_711
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_710
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_717
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_716
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_779
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_778
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_777
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_776
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_775
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_774
                       ForQA             tsl18cio250_min
dummy_scl180_conb_1_773
Global Operating Voltage = 1.98 
Power-specific unit information :
    Voltage Units = 1V
    Capacitance Units = 1.000000pf
    Time Units = 1ns
    Dynamic Power Units = 1mW    (derived from V,C,T units)
    Leakage Power Units = 1pW


Attributes
----------
i - Including register clock pin internal power


  Cell Internal Power  =   2.5263 mW   (36%)
  Net Switching Power  =   4.5792 mW   (64%)
                         ---------
Total Dynamic Power    =   7.1056 mW  (100%)

Cell Leakage Power     = 819.1693 nW


                 Internal         Switching           Leakage            Total
Power Group      Power            Power               Power              Power   (   %    )  Attrs
--------------------------------------------------------------------------------------------------
io_pad         6.6131e-02        1.3503e-04        5.7237e+03        6.6272e-02  (   1.11%)
memory             0.0000            0.0000            0.0000            0.0000  (   0.00%)
black_box          0.0000        4.7322e-03           62.7200        4.7323e-03  (   0.08%)
clock_network      2.1774            2.5973        1.9833e+05            4.7749  (  80.23%)  i
register           0.1074        1.4864e-02        4.3284e+05            0.1227  (   2.06%)
sequential     2.2439e-03        6.9747e-06        9.0534e+03        2.2599e-03  (   0.04%)
combinational      0.1732            0.8070        1.7316e+05            0.9803  (  16.47%)
--------------------------------------------------------------------------------------------------
Total              2.5263 mW         3.4240 mW     8.1917e+05 pW         5.9511 mW
1
```

### qor report

```bash
Warning: Design 'vsdcaravel' has '5' unresolved references. For more detailed information, use the "link" command. (UID-341)
Information: Updating design information... (UID-85)
Information: Timing loop detected. (OPT-150)
	chip_core/housekeeping/U739/I chip_core/housekeeping/U739/ZN chip_core/housekeeping/U741/I chip_core/housekeeping/U741/ZN chip_core/housekeeping/wbbd_busy_reg/CP chip_core/housekeeping/wbbd_busy_reg/Q chip_core/housekeeping/U766/I chip_core/housekeeping/U766/ZN chip_core/housekeeping/U4136/A2 chip_core/housekeeping/U4136/ZN chip_core/housekeeping/U4135/A chip_core/housekeeping/U4135/ZN chip_core/housekeeping/U998/I chip_core/housekeeping/U998/Z chip_core/housekeeping/U994/I chip_core/housekeeping/U994/Z chip_core/housekeeping/U2769/I chip_core/housekeeping/U2769/Z chip_core/housekeeping/U1980/I chip_core/housekeeping/U1980/Z chip_core/housekeeping/U1017/I chip_core/housekeeping/U1017/Z chip_core/housekeeping/pll_trim_reg[5]/CP chip_core/housekeeping/pll_trim_reg[5]/Q chip_core/pll/U7/A1 chip_core/pll/U7/Z chip_core/pll/ringosc/dstage[5].id/delayenb0/EN chip_core/pll/ringosc/dstage[5].id/delayenb0/ZN chip_core/pll/ringosc/ibufp10/I chip_core/pll/ringosc/ibufp10/ZN chip_core/pll/ringosc/ibufp11/I chip_core/pll/ringosc/ibufp11/ZN chip_core/clock_ctrl/use_pll_second_reg/CP chip_core/clock_ctrl/use_pll_second_reg/Q chip_core/clock_ctrl/U8/A1 chip_core/clock_ctrl/U8/ZN 
Information: Timing loop detected. (OPT-150)
	chip_core/housekeeping/U995/I chip_core/housekeeping/U995/Z chip_core/housekeeping/U3977/I chip_core/housekeeping/U3977/Z chip_core/housekeeping/U1384/I chip_core/housekeeping/U1384/Z chip_core/housekeeping/U1059/I chip_core/housekeeping/U1059/Z chip_core/housekeeping/gpio_configure_reg[3][3]/CP chip_core/housekeeping/gpio_configure_reg[3][3]/Q chip_core/housekeeping/U4142/A1 chip_core/housekeeping/U4142/ZN chip_core/housekeeping/U4138/A1 chip_core/housekeeping/U4138/ZN chip_core/housekeeping/U4137/I chip_core/housekeeping/U4137/ZN chip_core/housekeeping/U4136/A3 chip_core/housekeeping/U4136/ZN chip_core/housekeeping/U4135/A chip_core/housekeeping/U4135/ZN chip_core/housekeeping/U998/I chip_core/housekeeping/U998/Z 
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/housekeeping/wbbd_busy_reg'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/housekeeping/gpio_configure_reg[3][3]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/pll/pll_control/tval_reg[6]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/pll/pll_control/tval_reg[4]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/pll/pll_control/tval_reg[3]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/pll/pll_control/tval_reg[2]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/pll/pll_control/tval_reg[5]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'I' and 'ZN' on cell 'chip_core/pll/ringosc/dstage[6].id/delayenb0'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/clock_ctrl/divider/syncN_reg[1]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'QN' on cell 'chip_core/clock_ctrl/divider/syncN_reg[1]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/clock_ctrl/divider/syncN_reg[2]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/clock_ctrl/divider/syncN_reg[0]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/housekeeping/hkspi_disable_reg'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'QN' on cell 'chip_core/housekeeping/wbbd_sck_reg'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'I' and 'ZN' on cell 'chip_core/pll/ringosc/dstage[0].id/delayenb0'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'I' and 'ZN' on cell 'chip_core/pll/ringosc/dstage[6].id/delayenb1'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'I' and 'ZN' on cell 'chip_core/pll/ringosc/dstage[6].id/delayen1'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/clock_ctrl/divider2/syncN_reg[1]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'QN' on cell 'chip_core/clock_ctrl/divider2/syncN_reg[1]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/clock_ctrl/divider2/syncN_reg[2]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/clock_ctrl/divider2/syncN_reg[0]'
         to break a timing loop. (OPT-314)
Information: Input delay ('fall') on clock port 'clk' will be added to the clock's propagated skew. (TIM-112)
Information: Input delay ('rise') on clock port 'clk' will be added to the clock's propagated skew. (TIM-112)
Information: Input delay ('fall') on clock port 'hk_serial_clk' will be added to the clock's propagated skew. (TIM-112)
Information: Input delay ('rise') on clock port 'hk_serial_clk' will be added to the clock's propagated skew. (TIM-112)
Information: Input delay ('fall') on clock port 'hk_serial_load' will be added to the clock's propagated skew. (TIM-112)
Information: Input delay ('rise') on clock port 'hk_serial_load' will be added to the clock's propagated skew. (TIM-112)
Information: Input delay ('fall') on clock port 'hkspi_clk' will be added to the clock's propagated skew. (TIM-112)
Information: Input delay ('rise') on clock port 'hkspi_clk' will be added to the clock's propagated skew. (TIM-112)
 
****************************************
Report : qor
Design : vsdcaravel
Version: T-2022.03-SP5
Date   : Tue Dec 16 18:24:31 2025
****************************************


  Timing Path Group 'hk_serial_clk'
  -----------------------------------
  Levels of Logic:               0.00
  Critical Path Length:          0.18
  Critical Path Slack:          49.03
  Critical Path Clk Period:    100.00
  Total Negative Slack:          0.00
  No. of Violating Paths:        0.00
  Worst Hold Violation:         -0.14
  Total Hold Violation:        -24.64
  No. of Hold Violations:      336.00
  -----------------------------------


  Cell Count
  -----------------------------------
  Hierarchical Cell Count:       1446
  Hierarchical Port Count:      13054
  Leaf Cell Count:              20464
  Buf/Inv Cell Count:            4771
  Buf Cell Count:                 573
  Inv Cell Count:                4201
  CT Buf/Inv Cell Count:           84
  Combinational Cell Count:     16303
  Sequential Cell Count:         4161
  Macro Count:                      0
  -----------------------------------


  Area
  -----------------------------------
  Combinational Area:   287186.920916
  Noncombinational Area:
                        272951.804337
  Buf/Inv Area:          66065.790697
  Total Buffer Area:         29696.52
  Total Inverter Area:       36566.85
  Macro/Black Box Area:   1395.760063
  Net Area:              20905.057385
  -----------------------------------
  Cell Area:            561534.485316
  Design Area:          582439.542701


  Design Rules
  -----------------------------------
  Total Number of Nets:         25883
  Nets With Violations:            17
  Max Trans Violations:             0
  Max Cap Violations:              16
  Max Fanout Violations:            1
  -----------------------------------


  Hostname: nanodc.iitgn.ac.in

  Compile CPU Statistics
  -----------------------------------------
  Resource Sharing:                    9.06
  Logic Optimization:                  6.99
  Mapping Optimization:               11.85
  -----------------------------------------
  Overall Compile Time:               31.49
  Overall Compile Wall Clock Time:    32.28

  --------------------------------------------------------------------

  Design  WNS: 0.00  TNS: 0.00  Number of Violating Paths: 0


  Design (Hold)  WNS: 0.14  TNS: 24.64  Number of Violating Paths: 336

  --------------------------------------------------------------------


1

  --------------------------------------------------------------------

...


### Blackbox_modules.rpt

```bash
========================================
Blackbox Modules Report
========================================

Module: RAM128
  Status: PRESENT
  Instances: 1
    - chip_core/soc/core/RAM128

Module: RAM256
  Status: PRESENT
  Instances: 1
    - chip_core/soc/core/RAM256

Module: dummy_por
  Status: NOT FOUND

```
---

# GLS Setup

- Copy all rtl files into gl directory, then edit the Makefile as per below.

```Makefile
scl_io_PATH = "/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/4M1L/verilog/tsl18cio250/zero"
scl_io_wrapper_PATH = ../rtl/scl180_wrapper
VERILOG_PATH = ../
RTL_PATH = $(VERILOG_PATH)/rtl
GL_PATH = $(VERILOG_PATH)/gl
BEHAVIOURAL_MODELS = ../gls
RISCV_TYPE ?= rv32imc
PDK_PATH = /home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/4M1IL/verilog/vcs_sim_model 
FIRMWARE_PATH = ../gls
GCC_PATH?=/home/jaysk/riscv
GCC_PREFIX?=riscv32-unknown-elf
SIM_DEFINES = +define+FUNCTIONAL +define+SIM
SIM?=gl

.SUFFIXES:

PATTERN = hkspi

all: ${PATTERN:=.vcd}
hex: ${PATTERN:=.hex}
vcd: ${PATTERN:=.vcd}

# VCS compilation target
simv: ${PATTERN}_tb.v ${PATTERN}.hex
	 vcs -full64 -debug_access+all \
	 $(SIM_DEFINES) +define+GL \
	 -timescale=1ns/1ps \
	 +v2k -sverilog \
	 -lca -kdb \
	 +incdir+$(VERILOG_PATH) \
	 +incdir+$(VERILOG_PATH)/synthesis/output \
	 +incdir+$(BEHAVIOURAL_MODELS) \
	 +incdir+$(RTL_PATH) \
	 +incdir+$(GL_PATH) \
	 +incdir+$(scl_io_wrapper_PATH) \
	 +incdir+$(scl_io_PATH) \
	 +incdir+$(PDK_PATH) \
	 -y $(scl_io_wrapper_PATH) +libext+.v+.sv \
	 -y $(RTL_PATH) +libext+.v+.sv \
	 -y $(GL_PATH) +libext+.v+.sv \
	 -y $(scl_io_PATH) +libext+.v+.sv \
	 -y $(PDK_PATH) +libext+.v+.sv \
	 $(GL_PATH)/defines.v \
	 $< \
	 -l vcs_compile.log \
	 -o simv

# Run simulation and generate VCD
%.vcd: simv
	 ./simv +vcs+dumpvars+${PATTERN}.vcd \
	 -l simulation.log

# Alternative: Generate FSDB waveform (if Verdi is available)
%.fsdb: simv
	 ./simv -ucli -do "dump -file ${PATTERN}.fsdb -type fsdb -add {*}" \
	 -l simulation.log

%.elf: %.c $(FIRMWARE_PATH)/sections.lds $(FIRMWARE_PATH)/start.s
	 ${GCC_PATH}/${GCC_PREFIX}-gcc -march=$(RISCV_TYPE) -mabi=ilp32 -Wl,-Bstatic,-T,$(FIRMWARE_PATH)/sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ $(FIRMWARE_PATH)/start.s $<

%.hex: %.elf
	 ${GCC_PATH}/${GCC_PREFIX}-objcopy -O verilog $< $@ 
 # to fix flash base address
	 sed -i 's/@10000000/@00000000/g' $@

%.bin: %.elf
	 ${GCC_PATH}/${GCC_PREFIX}-objcopy -O binary $< /dev/stdout | tail -c +1048577 > $@

# Interactive debug with DVE
debug: simv
	 ./simv -gui -l simulation.log

# Coverage report generation (optional)
coverage: simv
	 ./simv -cm line+cond+fsm+tgl -cm_dir coverage.vdb
	 urg -dir coverage.vdb -report urgReport

check-env:
ifeq (,$(wildcard $(GCC_PATH)/$(GCC_PREFIX)-gcc ))
	 $(error $(GCC_PATH)/$(GCC_PREFIX)-gcc is not found, please export GCC_PATH and GCC_PREFIX before running make)
endif

clean:
	 rm -f *.elf *.hex *.bin *.vcd *.fsdb *.log simv
	 rm -rf csrc simv.daidir DVEfiles ucli.key *.vpd urgReport coverage.vdb AN.DB

.PHONY: clean hex vcd fsdb all debug coverage check-env# SPDX-FileCopyrightText: 2020 Efabless Corporation

```
then run the following commands

- make simv 
```
error will come 
Error-[IND] Identifier not declared
hkspi_tb.v, 92
  Identifier 'i' has not been declared yet. If this error is not expected, 
  please check if you have set `default_nettype to none.
  

3 warnings
1 error
[SCL] 12/14/2025 18:22:33 PID:9989 Client:nanodc.iitgn.ac.in checkin (null) 
CPU time: .220 seconds to compile
make: *** [simv] Error 255
[jaysk@nanodc gls]$ 

```
To correct the error u have to go to thr hkspi_tb.v and define integer i in the module and remove the integer already defined inside the module
again run "make simv" output will come 

<img width="776" height="914" alt="image" src="https://github.com/Jayessh25/Caravel_SOC/blob/main/Day3/Images/Command11.png" />
- now run "make hkspi.vcd"  u will get output  of gls passed
<img width="776" height="914" alt="image" src="https://github.com/Jayessh25/Caravel_SOC/blob/main/Day4/Images/Command9.png" />
- gtkwave hkspi.vcd u will see the waveform of gls 
- To view the waveform use vcd file and open it using gtkwave
<img width="776" height="914" alt="image" src="https://github.com/Jayessh25/Caravel_SOC/blob/main/Day4/Images/Command10.png" />
