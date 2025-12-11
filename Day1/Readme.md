# Caravel SoC Overview & Housekeeping SPI (HKSPI)

## What is Caravel?

Caravel is a pre-designed, open-source SoC wrapper developed to simplify ASIC development within the Google/Efabless OpenMPW shuttle program.
It provides a ready-to-use infrastructure so designers can focus entirely on their custom logic without reinventing basic system components such as clocking, GPIO control, memory map, and debug features.

Caravel includes an integrated RISC-V management SoC, a complete GPIO subsystem, and a well-structured user project area.
This combination makes it easier for developers to design, test, verify, and tape-out their ASIC designs with lower risk and faster development cycles.

![a](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day1/Images/Command15.png)


### Caravel divides the chip into two main regions:

## 1. Management Area

- Contains the 32-bit RISC-V management core (RV32IMC).
- Responsible for powering up the system, configuring GPIO, managing reset, and initializing the user project area.
- Acts as the “operating system” of the chip, handling boot flow and internal housekeeping.
- Provides firmware-driven peripherals such as UART, SPI, timers, and logic analyzers for debugging.
- Ensures safe communication between the user project and external interfaces.
- Includes the housekeeping SPI, system clock modules, PLL/DCO control, and interrupt logic.
- Offers memory-mapped registers for configuration, monitoring, and debugging.
- Manages the Wishbone bus that connects peripherals and the user project wrapper.

## 2. User Project Area

 - A dedicated region where developers can integrate their own RTL logic or custom digital design.
 - Isolated from the management core to protect the system from accidental faults in user-defined logic.
 - Communicates with the outside world through carefully controlled GPIO routing and Wishbone interfaces.
 - Supports custom modules such as CPUs, accelerators, controllers, IP blocks, or any synthesized logic.
 - Provides optional access to power-gated analog pins and clocking signals.
 - Includes the user project wrapper, which defines interface signals, interrupt lines, clock connections, and GPIO arrangements.
 - Enables fully independent operation once configured by the management core.
 - Allows logic analyzer probes and additional debug signals to aid verification and testbench development.

---
### 2. Housekeeping SPI

The Housekeeping SPI (HK-SPI) is a built-in SPI responder/slave inside the Caravel SoC.
It allows an external device (like a microcontroller, FPGA, or Raspberry Pi) to communicate with the chip using a standard 4-pin SPI interface:

- SCK – Clock
- SDI – Serial Data In (MOSI)
- SDO – Serial Data Out (MISO)
- CSB – Chip Select (active low)

This interface gives the external host access to management functions, such as:

- Reading/writing housekeeping registers
- Accessing configuration/status information
- Indirectly controlling the user project (based on settings)
  
---

### SPI Mode 0 Operation (CPOL=0, CPHA=0)

The HK-SPI operates in SPI Mode 0, which means:

Timing Rules

| **Signal Event**      | **Meaning**                                  |
|-----------------------|----------------------------------------------|
| SCK idle low          | Clock rests at 0 when inactive               |
| Rising edge of SCK    | HK-SPI **samples SDI** (captures input data) |
| Falling edge of SCK   | HK-SPI **updates SDO** (outputs next bit)    |

So the external master must:
- Put data on MOSI (SDI) before the rising edge
- Sample data on MISO (SDO) on the next rising edge

This ensures reliable data transfer without race conditions.

---

### Pin Sharing with User GPIO

The SPI pins are multiplexed with the user project GPIO pins.
This means:

- By default, on power-up/reset, these pins belong to the management core for SPI access.
- After configuration, the user project can take control of these pins if needed.

👉 But the user project must not interfere with SPI activity while the management core still uses the pins.

Hardware logic inside Caravel handles this sharing by allowing:

- Management core to override the pins when housekeeping SPI is active
- User area to access GPIO when authorized via control registers

🌐 How Communication Flow Works

1.External master pulls CSB = 0
2.Sends command byte(s) on SDI
3.HK-SPI decodes the instruction
4.Read/write operations happen on internal housekeeping registers
5.HK-SPI shifts out response data on SDO on the next falling edge
6.When CSB = 1, transaction ends

---
##  Standard 4-Pin SPI Interface

| Signal | Description | Caravel Pin |
|--------|-------------|-------------|
| **SDI (MOSI)** | Slave Data In | F9 |
| **SCK** | Clock | F8 |
| **CSB** | Chip Select (active low) | E8 |
| **SDO (MISO)** | Slave Data Out | E9 |

---
### SPI protocol definition

All input is in groups of 8 bits. Each byte is input most-significant-bit first.

Every command sequence requires one command word (8 bits), followed by one address word (8 bits), followed by one or more data words (8 bits each), according to the data transfer modes described in Housekeeping SPI modes.

![a](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day1/Images/Command16.png)
Addresses are read in sequence from lower values to higher values.

Therefore groups of bits larger than 8 should be grouped such that the lowest bits are at the highest address. Any bits additional to an 8-bit boundary should be at the lowest address.

Data is captured from the register map in bytes on the falling edge of the last SCK before a data byte transfer. Multi-byte transfers should ensure that data do not change between byte reads.

CSB pin must be low to enable an SPI transmission. Data are clocked by pin SCK, with data valid on the rising edge of SCK. Output data is received on the SDO line. SDO is held high-impedance when CSB is high and at all times other than the transfer of data bits on a read command. SDO outputs become active on the falling edge of SCK, such that data are written and read on the same SCK rising edge.

After CSB is set low, the SPI is always in the “command” state, awaiting a new command.

The first transferred byte is the command word, interpreted according to the Housekeeping SPI command word definition.

### Table 10 — Housekeeping SPI Command Word Definition

| **Word**     | **Meaning**                                              |
|--------------|-----------------------------------------------------------|
| `00000000`   | No operation                                              |
| `10000000`   | Write in streaming mode                                   |
| `01000000`   | Read in streaming mode                                    |
| `11000000`   | Simultaneous Read/Write in streaming mode                 |
| `11000100`   | Pass-through (management) Read/Write in streaming mode    |
| `11000110`   | Pass-through (user) Read/Write in streaming mode          |
| `10nnn000`   | Write in **n-byte mode** (up to 7 bytes)                  |
| `01nnn000`   | Read in **n-byte mode** (up to 7 bytes)                   |
| `11nnn000`   | Simultaneous Read/Write in **n-byte mode** (up to 7 bytes)|

#### Note
 - All other words are reserved and act as no-operation if not defined by the SPI responder module.

---
### Housekeeping SPI modes
The two basic modes of operation are streaming mode and n-byte mode.

In streaming mode operation, the data is sent or received continuously, one byte at a time, with the internal address incrementing for each byte. Streaming mode operation continues until CSB is raised to end the transfer.

In n-byte mode operation, the number of bytes to be read and/or written is encoded in the command word, and may have a value from 1 to 7 (note that a value of zero implies streaming mode). After n bytes have been read and/or written, the SPI returns to waiting for the next command. No toggling of CSB is required to end the command or to initiate the following command.

---

Housekeeping SPI registers
The purpose of the housekeeping SPI is to give access to certain system values and controls independently of the CPU. The housekeeping SPI can be accessed even when the CPU is in full reset. Some control registers in the housekeeping SPI affect the behaviour of the CPU in a way that can be potentially detrimental to the CPU operation, such as adjusting the trim value of the digital frequency-locked loop generating the CPU core clock.

Under normal working conditions, the SPI should not need to be accessed unless it is to adjust the clock speed of the CPU. All other functions are purely for test and debug.

The housekeeping SPI can be accessed by the CPU from a running program by enabling the SPI controller, and enabling the bit that connects the internal SPI controller directly to the housekeeping SPI. This configuration then allows a program to read, for example, the user project ID of the chip. See the SPI controller description for details.

![a](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day1/Images/Command14.png)

### Housekeeping SPI Registers

| **Name**               | **Register Address**                    | **Description** |
|------------------------|------------------------------------------|-----------------|
| **manufacturer_ID**    | `0x01` (low 4 bits) and `0x02`          | The 12-bit manufacturer ID for efabless is **0x456**. |
| **product_ID**         | `0x03`                                  | The product ID for the Caravel harness chip is **0x10**. |
| **user_project_ID**    | `0x04` to `0x07`                         | 4-byte (32-bit) user project ID, metal-mask programmed uniquely for each project. |
| **PLL enable**         | `0x08` bit 0                             | Enables the digital FLL/PLL clock multiplier. Enable before disabling bypass so the PLL stabilizes. |
| **PLL DCO enable**     | `0x08` bit 1                             | Runs PLL in **DCO mode** (open-loop). Frequency tunable 90–200 MHz using trim bits. |
| **PLL bypass**         | `0x09` bit 0                             | When `1`, CPU clock uses external CMOS clock (default). When `0`, uses PLL output. |
| **CPU IRQ**            | `0x0A` bit 0                             | Manual CPU interrupt on IRQ channel 6. Not self-resetting; must be cleared manually. |
| **CPU reset**          | `0x0B` bit 0                             | Puts CPU into reset state. Not self-resetting; must be cleared manually. |
| **CPU trap**           | `0x0C` bit 0                             | Indicates CPU trap/error state. Can be read reliably via housekeeping SPI. |
| **PLL trim**           | `0x0D` (all bits) to `0x10` (lower 2 bits) | 26-bit trim controlling DCO frequency. Default `0x3FF EFFF`. Thermometer-code delays tune 90–215 MHz range. |
| **PLL output divider** | `0x11` bits 2–0                          | Divides PLL output for core clock (÷2 to ÷7). Values 0 and 1 pass undivided clock (not recommended). |
| **PLL output divider (2)** | `0x11` bits 5–3                      | Divides 90° PLL phase output for user project clock (÷2 to ÷7). Values 0 and 1 = undivided. |
| **PLL feedback divider** | `0x12` bits 4–0                       | PLL feedback divider. Must yield PLL frequency between 90–214 MHz. Example: 8 MHz input × 19 = 152 MHz. |

---

# SKY130 Installation, Caravel Setup & HKSPI Testbench 


## Installing SKY130 PDK Using Volare

---

    ###  Create a Python Virtual Environment
        python3 -m venv ~/myenv

    ### Activate the Virtual Environment
        source ~/myenv/bin/activate

    ### Upgrade pip
        pip install --upgrade pip

    ### Install Volare
        pip install volare

    ### Set the PDK Installation Path
        export PDK_ROOT="directory to install sky130"

    ### List Available SKY130 Versions
        volare ls --pdk sky130

    ### choose the version from the previous list :
        volare enable --pdk sky130 <version_number>

## Clone the Caravel Repository & and also several things like iverilog,vvp,verilator

    git clone https://github.com/efabless/caravel.git

![a](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day1/Images/Command1.png)
![a](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day1/Images/Command2.png)
![a](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day1/Images/Command3.png)
![a](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day1/Images/Command4.png)

---

## Testbench Tasks

The testbench defines three primary tasks used to interact with the HKSPI interface.

### 1. write_byte
- Sends a byte to the SDI pin.
- Input: `odata[7:0]`
- Used for write operations over SPI.

### 2. read_byte
- Receives a byte from the SDO pin.
- Output: `idata[7:0]`
- Used for reading data from HKSPI registers.

### 3. read_write_byte
- Performs simultaneous SPI read and write operations.
- Useful for full-duplex behavior during SPI transfers.

---

## Timing Information

- Each of the tasks (write, read, or read-write) requires a total of **200 ns** to complete.
- The SPI clock toggles every **100 ns**:
  - Clock transitions from 0 to 1 after 100 ns.
  - Clock transitions from 1 to 0 after the next 100 ns.

---

## Test Scenarios

The testbench performs the following functional checks:

### 1. Reading Product ID (Address `8'h03`)
- The testbench reads from register address `0x03`.
- This register holds the Product ID.
- Expected read value: `0x11`.

### 2. Writing to External Reset Register (Address `8'h0B`)
- The testbench writes value `1` to address `0x0B` to assert an external reset.
- Then it writes value `0` to deassert the external reset.
- Confirms correct write behavior and register functionality.

### 3. Streaming Mode Register Read
- The testbench enables HKSPI streaming mode.
- In streaming mode, the register address auto-increments after each byte read.
- The testbench reads 18 consecutive registers.
- Each read value is compared against the default values defined in the HKSPI specification.
- Validates streaming mode functionality and sequential register access.

---
# Simulation of HKSPI


Inside the HKSPI testbench folder (`caravel/verilog/dv/caravel/mgmt_soc/hkspi`) there is a Makefile to run the testbench.

## Simulation Command

      make RTL=SIM

![a](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day1/Images/Command6.png)

gtkwave hkspi.vcd

![a](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day1/Images/Command9.png)


# Gate-Level Simulation (GLS) of Housekeeping SPI

This portion explains the complete flow used to perform Gate-Level Simulation (GLS) of the Housekeeping SPI module. It includes synthesizing the RTL using Yosys, generating the gate-level netlist, integrating it with Caravel, and validating the GLS waveform against the RTL simulation. Additional notes are included to make the process clearer and more complete.

The goal of this GLS exercise is to ensure that the synthesized hardware implementation behaves the same as the RTL model.


## Synthesizing Housekeeping SPI Using Yosys

TheYosys synthesis tool is used to convert the RTL (`housekeeping_spi.v`) into a gate-level representation using the SKY130 standard cell library. Yosys must be launched first:

```
yosys
```

Inside the Yosys shell, the technology library is loaded:

```
read_liberty -lib ./lib/sky130_fd_sc_hd__tt_025C_1v80.lib
```

Then the RTL file is read:

```
read_verilog housekeeping_spi.v
```

The synthesis process begins by specifying the top module:

```
synth -top housekeeping_spi
```


![a](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day1/Images/Command10.png)

![a](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day1/Images/Command11.png)

After synthesis, technology mapping is performed using `abc` and `dfflibmap`:

```
abc -liberty ../lib/sky130_fd_sc_hd__tt_025C_1v80.lib
dfflibmap -liberty ../lib/sky130_fd_sc_hd__tt_025C_1v80.lib
```

The synthesized schematic can be viewed using:

```
show housekeeping_spi
```
![a](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day1/Images/Command12.png)

## Writing the Gate-Level Netlist

The synthesized netlist is written to a Verilog file:

```
write_verilog -noattr housekeeping_spi_netlist.v
```

![a](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day1/Images/Command13.png)


The netlist is now ready. For GLS, this gate-level netlist must be connected into the Caravel design structure so that it is simulated in the same environment as the RTL.


# Gate-Level Simulation (GLS) of Housekeeping SPI

This section explains the complete flow, results, and debugging insights gathered while running the Gate-Level Simulation (GLS) of the Housekeeping SPI module inside Caravel. GLS is an essential step in verifying that the synthesized netlist behaves consistently with the RTL model, ensuring functional correctness after technology mapping.

## Running the GLS

The GLS was executed using the command:

```
make SIM=GLS
```

This triggers the simulation using the synthesized netlist instead of the RTL.

![a](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day1/Images/Command7.png)



## Viewing GLS Waveform in GTKWave

Once the GLS VCD was generated, it was opened in GTKWave:

![a](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day1/Images/Command9.png)


The GLS matches the RTL in functionality, except for register 12, which did not produce the expected value during RTL simulation as well. That issue is related to the CPU trap flag and has been explored separately.

![a](https://github.com/Jayessh25/Caravel_SOC/blob/main/Day1/Images/Command17.png)

## RTL vs GLS Comparison

The outputs match confirming functional equivalence between RTL and synthesized netlist.


