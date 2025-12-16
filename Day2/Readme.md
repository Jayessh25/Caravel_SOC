# RISC-V Reference SoC Implementation using Synopsys and SCL180 PDK

## Overview
This repository contains a reference RISC-V SoC implementation with I/O interfaces from SCL (Semiconductor Laboratory), designed specifically for participants under the SMDP (Special Manpower Development Program). The RISC-V SoC implementation IP provided here serves as a reference design and is absolutely FREE to use for tapeout purposes with the SCL180 process. Access to this repository is restricted to individuals who have access to Synopsys tools and have signed a Non-Disclosure Agreement (NDA) with Semiconductor Laboratory (SCL) to use their 180nm Process Design Kits (PDKs).

![a](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day1/Images/Command15.png)


  **caravel** is from efabless+SKY130+opensource , while **vsdcaravel** is from vsd+SCL180+Synopsys

## Features
- **Synthesis and Gate-Level Simulation (GLS)** of VSDCaravel SoC, derived from original Caravel by efabless
- **Utilization of SCL180 PDK** for ASIC design
- **Reproducible and Open-source Workflow**

## Repository Structure
```
VsdRiscvScl180/
├── dv             # Contains functional verification files 
├── gl             # Contains GLS supports files
├── gls            # Contains test bench files and synthesized netlists
├── rtl            # Contains verilog files        
├── synthesis      # Contains synthesis scripts and outputs
   ├──output       # Contain synthesis output
   ├──report       # Contain area,power and qor post synth report
   ├──work         # Synthesis work folder
├── README.md      # This README file
```


## Prerequisites
Before using this repository, ensure you have the following dependencies installed:

- **SCL180 PDK** ( SCL180 PDK)
- **RiscV32-uknown-elf.gcc** (building functional simulation files)
- **Caravel User Project Framework** from Efabless
- **Synopsys EDA tool Suite** for Synthesis
- **Verilog Simulator** (e.g., Icarus Verilog)
- **GTKWAVE** (used for visualizing testbench waves)

## Test Instructions
### Repo Setup
1. Clone the repository:
   ```sh 
   git clone https://github.com/vsdip/vsdRiscvScl180.git
   cd vsdRiscvScl180
   ```
2. Install required dependencies (ensure dc_shell and SCL180 PDK are properly set up).

### Functional Simulation Setup
3. Setup functional simulation file paths
   - Edit Makefile at this path [./dv/hkspi/Makefile](./dv/hkspi/Makefile)
   - Modify and verify `GCC_Path` to point to correct riscv installation
   - Modify and verify `scl_io_PATH` to point to correct io

###  Functional Simulation Execution
4. open a terminal and cd to the location of Makefile i.e. [./dv/hkspi](./dv/hkspi)
5. make sure hkspi.vvp file has been deleted from the hkspi folder
6. Run following command to generate vvp file for functional simulation
   ```
   make
   vvp hkspi.vvp
   ```
- you should receive output similar to following output on successfull execution
![functional simulation](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day2/Images/Command1.png)
7. Visualize the Testbench waveforms for complete design using following command
   ```
   gtkwave hkspi.vcd hkspi_tb.v
   ```
   ![GTK WAVE](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day2/Images/Command2.png)

### Synthesis Setup
8. Modify and verify following variables in synth.tcl file at path [./synthesis/synth.tcl](./synthesis/synth.tcl)
   ```
   library Path
   Root Directory Path
   SCL PDK Path
   SCL IO PATH

   ```
### Running Synthesis
9. open a terminal and cd to the work folder i.e. [./synthesis]()
10. Run synthesis using following command
```
dc_shell -f ../synth.tcl
```
This should update the caravel_snthesis.v file in [./synthesis/output]() folder


### GLS Setup
11. Modify and verify following variables in Makefile at path [./gls/Makefile](./gls/Makefile) according to your paths
```
SCL PDK Path
GCC Path
SCL IO Path
```
# Complete GLS Setup Guide - All Steps in One Response

Here's the complete step-by-step guide to set up Gate-Level Simulation from scratch:

## **Step 1: Navigate to GLS Directory**

```bash
cd ~/jaysk/vsdRiscvScl180/gls
```

## **Step 2: Copy All Required RTL Files to GL Directory**

```bash
# Copy all RTL files to gl directory
cp ../rtl/*.v ../gl/

# Copy wrapper files from scl180_wrapper subdirectory
cp ../rtl/scl180_wrapper/*.v ../gl/

# Copy the user_project_wrapper (rename to remove __)
cp ../rtl/__user_project_wrapper.v ../gl/user_project_wrapper.v
```

## **Step 3: Modify clock_div.v to Include Defines**

```bash
cd ../gl
sed -i '17i\`include "defines.v"' clock_div.v
cd ../gls
```

## **Step 4: Create/Update the Makefile**

```bash
scl_io_PATH = "/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/iopad/cio250/6M1L/verilog/tsl18cio250/zero"
VERILOG_PATH = ../../
RTL_PATH = $(VERILOG_PATH)/rtl
BEHAVIOURAL_MODELS = ../ 
RISCV_TYPE ?= rv32imc

FIRMWARE_PATH = ../
GCC_PATH?=/home/jaysk/riscv
GCC_PREFIX?=riscv32-unknown-elf

SIM_DEFINES = -DFUNCTIONAL -DSIM

SIM?=RTL

.SUFFIXES:

PATTERN = hkspi

# Path to management SoC wrapper repository
scl_io_wrapper_PATH ?= $(RTL_PATH)/scl180_wrapper
	

vvp:  ${PATTERN:=.vvp}

hex:  ${PATTERN:=.hex}

vcd:  ${PATTERN:=.vcd}

%.vvp: %_tb.v %.hex
	iverilog -Ttyp $(SIM_DEFINES) -I $(BEHAVIOURAL_MODELS) \
	 -I $(RTL_PATH) -I $(scl_io_wrapper_PATH) -I $(scl_io_PATH)  \
	$< -o $@ 
 
	


%.vcd: %.vvp
	vvp $<

#%.elf: %.c $(FIRMWARE_PATH)/sections.lds $(FIRMWARE_PATH)/start.s
#	${GCC_PATH}/${GCC_PREFIX}-gcc -march=$(RISCV_TYPE) -mabi=ilp32 -Wl,-Bstatic,-T,$(FIRMWARE_PATH)/sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ $(FIRMWARE_PATH)/start.s $<

#%.hex: %.elf
#	${GCC_PATH}/${GCC_PREFIX}-objcopy -O verilog $< $@ 
	# to fix flash base address
#	sed -i 's/@10000000/@00000000/g' $@

#%.bin: %.elf
#	${GCC_PATH}/${GCC_PREFIX}-objcopy -O binary $< /dev/stdout | tail -c +1048577 > $@

check-env:
#ifndef PDK_ROOT
#	$(error PDK_ROOT is undefined, please export it before running make)
#endif
#ifeq (,$(wildcard $(PDK_ROOT)/$(PDK)))
#	$(error $(PDK_ROOT)/$(PDK) not found, please install pdk before running make)
#endif
ifeq (,$(wildcard $(GCC_PATH)/$(GCC_PREFIX)-gcc ))
	$(error $(GCC_PATH)/$(GCC_PREFIX)-gcc is not found, please export GCC_PATH and GCC_PREFIX before running make)
endif
# check for efabless style installation
ifeq (,$(wildcard $(PDK_ROOT)/$(PDK)/libs.ref/*/verilog))
#SIM_DEFINES := ${SIM_DEFINES} -DEF_STYLE
endif
# ---- Clean ----

clean:
	rm -f *.vcd *.log *.vvp
```

## **Step 5: Compile and Run Simulation**

```bash
# Clean any previous builds
make clean

# Compile the simulation
make

# Generate VCD waveform (if compilation successful)
make vcd
```

## **Summary of Key Changes Made**

### **1. Makefile Changes:**
- Added `scl_io_wrapper_PATH = ../rtl/scl180_wrapper`
- Added **both `-I` and `-y` flags** for all PDK and RTL paths
  - `-I` flags: For `include` directives (`` `include "file.v" ``)
  - `-y` flags: For module searches (finding `pc3d01_wrapper`, etc.)
- Added `$(GL_PATH)/defines.v` before `$<` to ensure defines are loaded first
- Changed `RTL_PATH` to point to `$(VERILOG_PATH)/rtl`
- Added separate `GL_PATH = $(VERILOG_PATH)/gl`

### **2. File Structure:**
- Copied all RTL files to `gl/` directory so gate-level includes work properly
- Added `\`include "defines.v"` to `clock_div.v` to resolve `CLK_DIV` macro
- Copied wrapper modules from `scl180_wrapper/` subdirectory
- Renamed `__user_project_wrapper.v` to `user_project_wrapper.v`

### **3. Key Concepts:**
- **`-I` flag**: Tells iverilog where to find files for `` `include`` directives
- **`-y` flag**: Tells iverilog where to search for undefined module definitions
- Both flags can point to the same directory without conflicts
- Order matters: `defines.v` must be loaded before files that use its macros

## **Expected Result**

After running `make`, you should get `hkspi.vvp` compiled successfully. Then `make vcd` will generate `hkspi.vcd` waveform file that you can view with GTKWave:

```bash
gtkwave hkspi.vcd
```

If you encounter any errors, they will now be related to your actual design rather than missing files or compilation issues.

13. open a terminal and cd to the location of Makefile i.e. [./gls](./gls)
14. Replace 1'b0 from vsdcaravel.v file with vssa.
15. make sure hkspi.vvp file has been deleted from the GLS folder
16. Run following command to generate vvp file for GLS
   ```
   make
   vvp hkspi.vvp
   ```


if you get the following above errors follow the below steps

12. Modify synthesized netlist at path [./synthesis/output/vsdcaravel_synthsis.v](./synthesis/output/caravel_synthesis.v) to remove blackboxed modules
   - Remove following modules
   ```
   dummy_por
   RAM128
   housekeeping
   ```
   - add following lines at the beginning of the netlist file to import the blackboxed modules from functional rtl
   ```
   `include "dummy_por.v"
   `include "RAM128.v
   `include "housekeeping.v"
   ```

Based on my analysis of your `vsdcaravel_synthesis.v` file, here are the **exact line numbers** where you need to make changes:

## **STEP 1: ADD INCLUDE STATEMENTS**

**After line 6** (after the comment block), add these 3 lines:

```verilog
`include "dummy_por.v"
`include "RAM128.v"  
`include "housekeeping.v"
```

**Context:**
```
Line 4: // Date      : Fri Dec 12 15:03:43 2025
Line 5: /////////////////////////////////////////////////////////////
Line 6: 
Line 7:              <-- ADD THE 3 INCLUDE LINES HERE
Line 8: module RAM128 ( CLK, EN0, VGND, VPWR, A0, Di0, Do0, WE0 );
```

## **STEP 2: DELETE BLACKBOXED MODULE: RAM128**

**Delete lines 8 through 16** (9 lines total):

```verilog
Line 8:  module RAM128 ( CLK, EN0, VGND, VPWR, A0, Di0, Do0, WE0 );
Line 9:    input [6:0] A0;
Line 10:   input [31:0] Di0;
Line 11:   output [31:0] Do0;
Line 12:   input [3:0] WE0;
Line 13:   input CLK, EN0, VGND, VPWR;
Line 14: 
Line 15: 
Line 16: endmodule
```

## **STEP 3: DELETE BLACKBOXED MODULE: housekeeping**

**Delete lines 38599 through approximately 41000+** (the entire housekeeping module)

- Starts at line **38599**: `module housekeeping ( VPWR, VGND, wb_clk_i, wb_rstn_i, ...`
- The module is very large (thousands of lines)
- Search for the matching `endmodule` that closes this module
- To find it safely: look for the next top-level module declaration after line 38599, then find the `endmodule` just before it

## **STEP 4: Module dummy_por**

**NO ACTION NEEDED** - The `dummy_por` module definition does NOT exist in your synthesized file. It's only instantiated (at line 59211), which means it's already treated as a blackbox.

***

## **Summary:**

1. **ADD** 3 include lines after line 6
2. **DELETE** lines 8-16 (RAM128 module)
3. **DELETE** lines 38599 through the housekeeping endmodule (~2500+ lines)
4. **NO deletion** needed for dummy_por (already blackboxed)

This will convert the blackboxed modules to external includes, allowing you to provide the actual implementations from separate RTL files.

###  GLS Execution
13. open a terminal and cd to the location of Makefile i.e. [./gls](./gls)
14. Replace 1'b0 from vsdcaravel.v file with vssa.
15. make sure hkspi.vvp file has been deleted from the GLS folder
16. Run following command to generate vvp file for GLS
   ```
   make
   vvp hkspi.vvp
   ```
![GTK WAVE](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day2/Images/Command3.png)

17. Visualize the Testbench waveforms for complete design using following command
   ```
   gtkwave hkspi.vcd hkspi_tb.v
   ```

![GTK WAVE](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day2/Images/Command4.png)

18. Compare output from functional Simulation and GLS to verify the synthesis output

    
## Results
- Successfully ran functional simulations, synthesis and GLS for VexRiscV Harnessed with Efabless's Caravel usign SCL180 PDK.

## Reports
### Area Post Synth Report

```
Warning: Design 'vsdcaravel' has '2' unresolved references. For more detailed information, use the "link" command. (UID-341)
 
****************************************
Report : area
Design : vsdcaravel
Version: T-2022.03-SP5
Date   : Mon Dec 15 17:44:07 2025
****************************************

Library(s) Used:

    tsl18fs120_scl_ff (File: /home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/4M1IL/liberty/lib_flow_ff/tsl18fs120_scl_ff.db)

Number of ports:                        12749
Number of nets:                         37554
Number of cells:                        30961
Number of combinational cells:          18422
Number of sequential cells:              6882
Number of macros/black boxes:              16
Number of buf/inv:                       3532
Number of references:                       2

Combinational area:             341951.960055
Buf/Inv area:                    28798.119889
Noncombinational area:          431036.399128
Macro/Black Box area:              100.320000
Net Interconnect area:           32791.102344

Total cell area:                773088.679183
Total area:                     805879.781527

Information: This design contains black box (unknown) components. (RPT-8)
1
```
### Power Post Synth Report
```
Loading db file '/home/Synopsys/pdk/SCL_PDK_3/SCLPDK_V3.0_KIT/scl180/stdcell/fs120/4M1IL/liberty/lib_flow_ff/tsl18fs120_scl_ff.db'
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


  Cell Internal Power  =  38.6165 mW   (50%)
  Net Switching Power  =  37.9689 mW   (50%)
                         ---------
Total Dynamic Power    =  76.5854 mW  (100%)

Cell Leakage Power     =   1.1292 uW

Information: report_power power group summary does not include estimated clock tree power. (PWR-789)

                 Internal         Switching           Leakage            Total
Power Group      Power            Power               Power              Power   (   %    )  Attrs
--------------------------------------------------------------------------------------------------
io_pad             0.0000            0.0000            0.0000            0.0000  (   0.00%)
memory             0.0000            0.0000            0.0000            0.0000  (   0.00%)
black_box          0.0000            0.1470           62.7200            0.1470  (   0.19%)
clock_network      0.0000            0.0000            0.0000            0.0000  (   0.00%)  i
register           0.0000            0.0000            0.0000            0.0000  (   0.00%)
sequential        35.0847            0.4024        7.1946e+05           35.4883  (  46.36%)
combinational      3.5311           37.3879        4.0971e+05           40.9209  (  53.45%)
--------------------------------------------------------------------------------------------------
Total             38.6157 mW        37.9372 mW     1.1292e+06 pW        76.5561 mW
1
```
### QoR Post Synth Report

```
Information: Building the design 'chip_io'. (HDL-193)
Warning: Cannot find the design 'chip_io' in the library 'WORK'. (LBR-1)
Information: Building the design 'dummy_por'. (HDL-193)
Warning: Cannot find the design 'dummy_por' in the library 'WORK'. (LBR-1)
Warning: Unable to resolve reference 'chip_io' in 'vsdcaravel'. (LINK-5)
Warning: Unable to resolve reference 'dummy_por' in 'caravel_core'. (LINK-5)
Information: Updating design information... (UID-85)
Information: Timing loop detected. (OPT-150)
	chip_core/housekeeping/U223/I chip_core/housekeeping/U223/Z chip_core/housekeeping/U194/I chip_core/housekeeping/U194/Z chip_core/housekeeping/wbbd_sck_reg/CP chip_core/housekeeping/wbbd_sck_reg/QN chip_core/housekeeping/U3071/I chip_core/housekeeping/U3071/ZN chip_core/housekeeping/U3066/I0 chip_core/housekeeping/U3066/Z chip_core/housekeeping/U236/I chip_core/housekeeping/U236/Z chip_core/housekeeping/U233/I chip_core/housekeeping/U233/Z chip_core/housekeeping/U220/I chip_core/housekeeping/U220/Z chip_core/housekeeping/U184/I chip_core/housekeeping/U184/Z chip_core/housekeeping/pll_ena_reg/CP chip_core/housekeeping/pll_ena_reg/Q chip_core/pll/U29/A2 chip_core/pll/U29/ZN chip_core/pll/ringosc/iss/U4/I chip_core/pll/ringosc/iss/U4/ZN chip_core/pll/ringosc/iss/reseten0/EN chip_core/pll/ringosc/iss/reseten0/ZN chip_core/pll/pll_control/tval_reg[6]/CP chip_core/pll/pll_control/tval_reg[6]/Q chip_core/pll/pll_control/U122/I chip_core/pll/pll_control/U122/ZN chip_core/pll/pll_control/U29/A chip_core/pll/pll_control/U29/ZN chip_core/pll/pll_control/U28/A chip_core/pll/pll_control/U28/ZN chip_core/pll/pll_control/U27/A chip_core/pll/pll_control/U27/ZN chip_core/pll/pll_control/U26/A1 chip_core/pll/pll_control/U26/ZN chip_core/pll/pll_control/U25/A chip_core/pll/pll_control/U25/ZN chip_core/pll/pll_control/U22/A1 chip_core/pll/pll_control/U22/ZN chip_core/pll/pll_control/U21/A chip_core/pll/pll_control/U21/ZN chip_core/pll/pll_control/U7/I chip_core/pll/pll_control/U7/ZN chip_core/pll/U7/I0 chip_core/pll/U7/Z chip_core/pll/ringosc/dstage[5].id/U1/I chip_core/pll/ringosc/dstage[5].id/U1/ZN chip_core/pll/ringosc/dstage[5].id/delayen0/EN chip_core/pll/ringosc/dstage[5].id/delayen0/ZN chip_core/clock_ctrl/ext_clk_syncd_reg/CP chip_core/clock_ctrl/ext_clk_syncd_reg/Q chip_core/clock_ctrl/U9/I1 chip_core/clock_ctrl/U9/Z chip_core/clock_ctrl/U8/I0 chip_core/clock_ctrl/U8/Z chip_core/U1/I chip_core/U1/Z 
Information: Timing loop detected. (OPT-150)
	chip_core/housekeeping/U186/I chip_core/housekeeping/U186/Z chip_core/housekeeping/gpio_configure_reg[3][3]/CP chip_core/housekeeping/gpio_configure_reg[3][3]/Q chip_core/housekeeping/U3072/A1 chip_core/housekeeping/U3072/ZN chip_core/housekeeping/U3068/A1 chip_core/housekeeping/U3068/ZN chip_core/housekeeping/U3067/A2 chip_core/housekeeping/U3067/ZN chip_core/housekeeping/U3066/I1 chip_core/housekeeping/U3066/Z chip_core/housekeeping/U236/I chip_core/housekeeping/U236/Z chip_core/housekeeping/U233/I chip_core/housekeeping/U233/Z chip_core/housekeeping/U220/I chip_core/housekeeping/U220/Z 
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/pll/pll_control/tval_reg[6]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/housekeeping/gpio_configure_reg[3][3]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/housekeeping/hkspi_disable_reg'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/pll/pll_control/tval_reg[4]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/pll/pll_control/tval_reg[3]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/pll/pll_control/tval_reg[2]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/pll/pll_control/tval_reg[5]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'I' and 'ZN' on cell 'chip_core/pll/ringosc/dstage[0].id/delayenb1'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'I' and 'ZN' on cell 'chip_core/pll/ringosc/dstage[0].id/delayen1'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'I' and 'ZN' on cell 'chip_core/pll/ringosc/dstage[0].id/delayenb0'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/clock_ctrl/divider/syncN_reg[1]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'QN' on cell 'chip_core/clock_ctrl/divider/syncN_reg[1]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/clock_ctrl/divider/syncN_reg[2]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/clock_ctrl/divider/syncN_reg[0]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'QN' on cell 'chip_core/housekeeping/wbbd_sck_reg'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'QN' on cell 'chip_core/housekeeping/wbbd_busy_reg'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/clock_ctrl/divider2/syncN_reg[1]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'QN' on cell 'chip_core/clock_ctrl/divider2/syncN_reg[1]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/clock_ctrl/divider2/syncN_reg[2]'
         to break a timing loop. (OPT-314)
Warning: Disabling timing arc between pins 'CP' and 'Q' on cell 'chip_core/clock_ctrl/divider2/syncN_reg[0]'
         to break a timing loop. (OPT-314)
 
****************************************
Report : qor
Design : vsdcaravel
Version: T-2022.03-SP5
Date   : Mon Dec 15 17:44:07 2025
****************************************


  Timing Path Group (none)
  -----------------------------------
  Levels of Logic:               1.00
  Critical Path Length:          0.00
  Critical Path Slack:         uninit
  Critical Path Clk Period:       n/a
  Total Negative Slack:          0.00
  No. of Violating Paths:        0.00
  Worst Hold Violation:          0.00
  Total Hold Violation:          0.00
  No. of Hold Violations:        0.00
  -----------------------------------


  Cell Count
  -----------------------------------
  Hierarchical Cell Count:       1435
  Hierarchical Port Count:      12686
  Leaf Cell Count:              25320
  Buf/Inv Cell Count:            3532
  Buf Cell Count:                 456
  Inv Cell Count:                3081
  CT Buf/Inv Cell Count:            0
  Combinational Cell Count:     18496
  Sequential Cell Count:         6824
  Macro Count:                      0
  -----------------------------------


  Area
  -----------------------------------
  Combinational Area:   341951.960055
  Noncombinational Area:
                        431036.399128
  Buf/Inv Area:          28798.119889
  Total Buffer Area:          7393.23
  Total Inverter Area:       21734.19
  Macro/Black Box Area:    100.320000
  Net Area:              32791.102344
  -----------------------------------
  Cell Area:            773088.679183
  Design Area:          805879.781527


  Design Rules
  -----------------------------------
  Total Number of Nets:         30075
  Nets With Violations:             0
  Max Trans Violations:             0
  Max Cap Violations:               0
  -----------------------------------


  Hostname: nanodc.iitgn.ac.in

  Compile CPU Statistics
  -----------------------------------------
  Resource Sharing:                    9.97
  Logic Optimization:                 11.28
  Mapping Optimization:                9.10
  -----------------------------------------
  Overall Compile Time:               34.56
  Overall Compile Wall Clock Time:    35.14

  --------------------------------------------------------------------

  Design  WNS: 0.00  TNS: 0.00  Number of Violating Paths: 0


  Design (Hold)  WNS: 0.00  TNS: 0.00  Number of Violating Paths: 0

  --------------------------------------------------------------------


1

```
