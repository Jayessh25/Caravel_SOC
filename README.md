# 🏗️ RISC-V SoC Tapeout Journey – Phase 2  
### Caravel SoC Migration from Sky130 to SCL180

![RISC-V](https://img.shields.io/badge/RISC--V-SoC-blue?style=for-the-badge)
![Caravel](https://img.shields.io/badge/Caravel-SoC-orange?style=for-the-badge)
![Sky130](https://img.shields.io/badge/Source-Sky130-lightgrey?style=for-the-badge)
![SCL180](https://img.shields.io/badge/Target-SCL180-green?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Pre--Tapeout-yellow?style=for-the-badge)

---

## 📖 Project Overview

This repository documents my advanced work in **Phase 2 of the RISC-V SoC Tapeout Program**, with a primary focus on adapting the open-source **Caravel SoC** from the **Sky130** technology node to the **SCL180 (180 nm) PDK**.

The project involved:
- Frontend RTL debugging  
- Processor integration analysis  
- Synthesis using industry-standard EDA tools  
- Preparation for physical design handoff  

A major emphasis of this phase was identifying and resolving **RTL integration and PDK-dependent issues** observed during synthesis and gate-level verification. The outcome was a stable RTL baseline suitable for backend implementation, along with the identification of critical design gaps that must be resolved prior to tapeout.

This repository serves as both a **technical record** and a **methodological reference** for multi-PDK SoC migration.

---
## 🛠️ Tools & Technologies Used

- **RTL Design & Debug**: Verilog, SystemVerilog
- **Synthesis**: Synopsys Design Compiler (DC), DC_TOPO
- **Simulation**: Synopsys VCS, Icarus Verilog, GTKWave
- **Physical Design (Early Stage)**: Synopsys ICC2
- **Processor Cores**: PicoRV32, VexRiscv
- **Bus Architecture**: Wishbone
- **PDKs**: Sky130 (baseline), SCL180 (target)

---
## 🎯 Core Contributions

| Domain | Contribution | Outcome |
|------|-------------|---------|
| **PDK Migration** | Migrated Caravel SoC from Sky130 to SCL180, including library setup and synthesis flow adaptation | Established repeatable multi-PDK SoC flow |
| **RTL Integration Debug** | Resolved synthesis-blocking RTL issues (hierarchy mismatches, reset logic, connectivity errors) | Enabled clean synthesis and GLS |
| **Processor Analysis** | Compared PicoRV32 and VexRiscv architectures for maintainability and integration risk | Informed processor selection trade-offs |
| **RTL–GLS Verification** | Performed RTL vs Gate-Level Simulation correlation using VCS and Icarus | Ensured functional equivalence |
| **Padframe Architecture** | Designed and validated SCL180-compatible padframe and I/O routing | Enabled backend readiness |
| **Firmware–RTL Analysis** | Traced firmware-to-pad signal flow and identified register-mapping mismatches | Prevented silent silicon failures |

---

## 🔄 Sky130 → SCL180 Migration

The original Caravel SoC targets the **Sky130 PDK**, whereas this work adapts the design to **SCL180**, requiring non-trivial changes beyond simple library replacement.

### Migration Activities
- Replaced Sky130 standard-cell libraries with SCL180 timing corners  
- Modified synthesis scripts for **DC** and **DC_TOPO**  
- Adapted RTL constructs incompatible with SCL180 constraints  
- Reworked padframe architecture for SCL180 I/O cells  
- Validated behavior through **RTL–GLS equivalence checking**

This process demonstrated that **technology migration is a system-level effort**, impacting RTL assumptions, timing closure, reset strategy, and peripheral behavior.

---

## 🧪 RTL Integration & Debug

During synthesis, several **integration-level RTL issues** were identified:

- Module interface mismatches  
- Reset sequencing incompatibilities  
- Unconnected pad control signals  
- Technology-dependent behavioral constructs  

Problematic RTL blocks were isolated, corrected, and re-verified through **iterative synthesis and gate-level simulation**. These fixes enabled a clean handoff to the backend physical design flow while maintaining functional correctness.

---

## 🔴 Critical GPIO Discovery

A major outcome of this phase was identifying a **latent GPIO subsystem failure**:

- Firmware expected **CSR-style register access**
- RTL implemented **legacy MMIO addressing**
- **Eight pad control signals were never connected**

Although synthesis and simulation completed successfully, this mismatch would have resulted in **non-functional GPIOs in silicon**. This finding highlights the importance of **firmware–RTL co-verification** prior to tapeout.

---

## 🏗️ Physical Design Readiness

Following RTL stabilization:
- Floorplanning and initial physical setup were completed in **ICC2**
- Area, congestion, and timing feasibility were analyzed
- Backend constraints were validated for **SCL180 technology**

The design is **structurally ready for RTL-to-GDS flow**, pending GPIO and firmware interface corrections.

---
## 👨‍💻 Hands-on Work Performed (What I Did)

During this phase of the project, I personally carried out the following technical tasks:

 - Set up the SCL180 PDK environment, including standard-cell libraries and timing corners
 - Modified and validated synthesis scripts for Sky130 → SCL180 migration using DC and DC_TOPO
 - Debugged RTL integration errors such as hierarchy mismatches, reset logic issues, and unconnected signals
 - Performed RTL simulation and Gate-Level Simulation (GLS) using Icarus Verilog and Synopsys VCS
 - Designed and reviewed SCL180-compatible padframe routing, identifying missing pad control connections
 - Traced firmware-to-hardware signal flow (C code → Wishbone bus → RTL registers → I/O pads)
 - Identified critical GPIO subsystem failures caused by register-mapping mismatches and disconnected pad signals
 - Performed floorplanning and early physical design analysis using ICC2
 - Generated and analyzed area, timing, and congestion reports to assess backend feasibility

Note:> 🔧 All debugging, migration, verification, and analysis tasks described above were performed directly as part of my contribution to Phase 2 of the tapeout program.

---

## 🎓 Key Learnings

- Clean RTL synthesis ≠ silicon correctness  
- Firmware–hardware interface verification is mandatory  
- Auto-generated cores increase verification complexity  
- PDK migration impacts architecture, not just libraries  
- Frontend quality determines backend success  

---

## 🏁 Project Status

- **Design Stage**: Pre-Tapeout Validation  
- **Technology**: SCL180 (180 nm)  
- **Flow Coverage**: RTL → Synthesis → GLS → Floorplanning  
- **Next Step**: GPIO redesign and full Place & Route (P&R)

---

> 📌 *This project reflects real-world SoC integration challenges and emphasizes rigorous verification before silicon tapeout.*
