# 🚀 RISC-V SoC Tapeout Program – Phase 2  
## Caravel SoC Technology Migration & Integration Study (Sky130 → SCL180)

![RISC-V](https://img.shields.io/badge/RISC--V-SoC-blue?style=for-the-badge)
![Caravel](https://img.shields.io/badge/Caravel-Platform-orange?style=for-the-badge)
![Sky130](https://img.shields.io/badge/PDK-Sky130-lightgrey?style=for-the-badge)
![SCL180](https://img.shields.io/badge/PDK-SCL180-green?style=for-the-badge)
![Stage](https://img.shields.io/badge/Stage-Frontend%20Validated-yellow?style=for-the-badge)

---

## 📘 Introduction

This repository captures my **independent technical work during Phase 2 of the RISC-V SoC Tapeout Program**, focused on **analyzing, adapting, and validating the Caravel SoC for a new semiconductor technology node**.

Unlike a simple porting exercise, this phase concentrated on:
- Understanding **technology-coupled RTL assumptions**
- Stress-testing the SoC under a **non-native PDK**
- Identifying **hidden integration failures** that survive synthesis but fail silicon

The work culminated in a **functionally stable RTL baseline**, verified through synthesis and gate-level simulation, and ready for backend implementation under **SCL180 (180 nm)** constraints.

---

## 🔍 Scope of Work

The repository documents a **frontend-heavy SoC engineering effort**, covering:

- RTL integration validation  
- Technology-aware synthesis debugging  
- Firmware-to-hardware interface tracing  
- Early physical design feasibility checks  

Rather than optimizing performance, the primary objective was **correctness, portability, and verification rigor**.

---

## 🧰 Design & Verification Stack

**Languages & Design**
- Verilog / SystemVerilog
- RISC-V ISA-based soft processors

**Simulation & Verification**
- Synopsys VCS
- Icarus Verilog
- GTKWave

**Synthesis & Physical Design**
- Synopsys Design Compiler (DC)
- DC_TOPO
- Synopsys ICC2 (early PD only)

**SoC Components**
- Caravel SoC platform
- PicoRV32 and VexRiscv cores
- Wishbone interconnect

**Technology**
- Sky130 (reference PDK)
- SCL180 (migration target)

---

## 🧩 Key Engineering Contributions

| Area | Engineering Focus | Result |
|-----|------------------|--------|
| **Technology Migration** | Adapted Caravel RTL & synthesis flow for SCL180 | Multi-PDK compatible frontend |
| **RTL Robustness** | Fixed reset, hierarchy, and signal connectivity issues | Clean synthesis & GLS |
| **Core Evaluation** | Studied PicoRV32 vs VexRiscv integration complexity | Reduced integration risk |
| **Verification Depth** | RTL ↔ Gate-Level simulation correlation | Functional consistency ensured |
| **Padframe Analysis** | Audited I/O control and routing for SCL180 | Backend-ready I/O structure |
| **Firmware Alignment** | Cross-checked firmware expectations vs RTL behavior | Detected critical GPIO bug |

---

## 🔁 Technology Migration Insights (Sky130 → SCL180)

Moving Caravel away from its native Sky130 environment exposed **implicit design dependencies**, including:

- Timing and drive-strength assumptions
- Reset and initialization behavior
- Pad control signal expectations
- Library-driven synthesis side effects

### Adaptation Steps
- Rebuilt synthesis libraries for SCL180
- Tuned DC/DC_TOPO constraints
- Modified RTL blocks sensitive to PDK rules
- Reworked padframe logic for SCL180 cells
- Revalidated design using gate-level simulation

This reinforced a key lesson:  
> **PDK migration is an architectural validation problem, not a library swap.**

---

## 🧪 RTL Debug & Integration Validation

Multiple synthesis-blocking and silicon-risk issues were uncovered:

- Mismatched module interfaces
- Incomplete reset propagation
- Dangling or unused pad control signals
- Firmware-visible registers missing hardware backing

Each issue was debugged through:
1. Targeted RTL isolation  
2. Iterative synthesis  
3. Gate-level simulation correlation  

Result: a **stable and analyzable RTL system** suitable for backend handoff.

---

## 🚨 Critical GPIO Failure Identified

One of the most important findings of this phase:

- Firmware accessed GPIOs via **CSR-style registers**
- RTL exposed **legacy MMIO-style logic**
- Several GPIO control signals were **never physically connected**

This flaw passed synthesis and simulation but would have caused **dead GPIOs in silicon**.

✔ Issue detected  
✔ Root cause identified  
✔ Fix path clearly defined  

This underscores the importance of **firmware–RTL co-verification**, even in “working” designs.

---

## 🏗️ Backend Readiness Assessment

After frontend stabilization:

- Floorplanning experiments were performed in ICC2
- Area utilization and congestion trends were reviewed
- Timing feasibility was evaluated under SCL180 constraints

The design is **structurally capable of progressing to full P&R**, pending GPIO and register-map corrections.

---

## 👨‍🔧 What I Personally Implemented

All work in this repository reflects **hands-on engineering**, including:

- SCL180 PDK setup and library integration
- Synthesis flow modification and validation
- RTL debug of hierarchy, reset, and connectivity issues
- RTL and gate-level simulation using VCS & Icarus
- Padframe inspection and signal tracing
- Firmware-to-hardware register path analysis
- Early physical design exploration using ICC2
- Report analysis (area, timing, congestion)

> ⚙️ No steps were theoretical or delegated — all debugging and validation was performed directly.

---

## 📚 Technical Takeaways

- Passing synthesis does **not** guarantee silicon correctness  
- Firmware mismatches can silently break hardware  
- Auto-generated SoC platforms require aggressive verification  
- Technology migration exposes hidden RTL assumptions  
- Frontend quality determines backend success

---

## 📌 Current Status

- **Phase**: Pre-Tapeout (Frontend Validated)  
- **Technology Node**: SCL180 (180 nm)  
- **Flow Coverage**: RTL → Synthesis → GLS → Early PD  
- **Next Milestone**: GPIO fix + full Place & Route

---

> 🧠 *This repository documents real SoC engineering challenges encountered during technology migration and highlights the importance of deep verification beyond tool success indicators.*

<details>
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
</details>
