# Legacy POR Dependency Analysis in Caravel-Based RISC-V SoC

## 1. Introduction
Early versions of the VSD Caravel-based SoC integrated a behavioral on-chip Power-On Reset (POR) module (`dummy_por`) to model reset sequencing during power-up. This POR was introduced purely for simulation convenience and does not represent a synthesizable or silicon-realizable implementation.  
This document analyzes how the POR was used in the existing RTL, identifies which blocks truly depend on it, and establishes whether it is functionally required.

---

## 2. Location and Usage of `dummy_por`

### 2.1 `vsdcaravel.v`
The `dummy_por` module is instantiated at the top level of the SoC in `vsdcaravel.v`.

- Inputs:
  - `vdd` (modeled supply)
  - `vss` (ground reference)
- Outputs:
  - `porb_h`
  - `porb_l`
  - `por_l`

The module generates power-up reset signals based on assumed supply behavior. These outputs are then routed into the reset distribution network.

> **Observation:**  
> The POR behavior is entirely behavioral and not tied to any physical analog macro.

---

### 2.2 Housekeeping Logic
The housekeeping (HK) block receives POR-derived signals primarily to initialize configuration registers and control logic.

- POR signals are logically combined with external reset inputs.
- No analog dependency exists within housekeeping logic.
- Registers use POR only as a reset qualifier.

> **Observation:**  
> Housekeeping logic requires a deterministic reset, but not a power-aware POR.

---

### 2.3 Reset Distribution Paths
The POR outputs are distributed through reset trees and gating logic to different SoC domains.

- `porb_h` is typically used for active-low reset paths in high-voltage or always-on domains.
- `porb_l` is used for active-low reset in core logic.
- `por_l` is an active-high reset used in limited legacy blocks.

> **Observation:**  
> These signals are functionally equivalent to standard reset signals and do not perform any power sequencing role.

---

## 3. POR Signal Definitions and Consumers

### 3.1 `porb_h`
- Active-low reset signal
- Intended for “high-domain” or top-level logic
- Drives:
  - Reset inputs of top-level control registers
  - Housekeeping reset logic

### 3.2 `porb_l`
- Active-low reset signal
- Used within core digital logic
- Drives:
  - CPU reset
  - Peripheral reset paths

### 3.3 `por_l`
- Active-high reset signal
- Used by legacy or wrapper logic
- Drives:
  - Select control or status registers

> **Key Point:**  
> All POR signals are ultimately consumed as **simple reset inputs**.

---

## 4. Blocks Dependent on POR vs Generic Reset

### 4.1 Blocks Using POR Signals
| Block | Usage Type | True POR Dependency |
|------|-----------|--------------------|
| CPU Core | Reset only | ❌ No |
| Housekeeping | Reset only | ❌ No |
| Peripheral Logic | Reset only | ❌ No |
| Control Registers | Initialization | ❌ No |

### 4.2 Blocks Requiring Deterministic Reset
All sequential blocks require a clean reset but **do not require power-aware behavior**.

- No block:
  - Detects VDD ramp
  - Uses POR for sequencing
  - Has analog dependencies

---

## 5. Key Findings

- `dummy_por` is a **behavioral model**, not a silicon-representable POR.
- All POR signals act as **generic reset signals**.
- No block functionally depends on analog power-up sequencing.
- Reset requirements can be fully satisfied by a single external reset pin.

---

## 6. Conclusion
The analysis confirms that the existing POR implementation does not provide any functional benefit beyond a standard reset. Since all dependent logic only requires deterministic reset assertion and de-assertion, the on-chip POR can be safely removed and replaced with a single external reset signal without impacting functionality.

This conclusion forms the basis for migrating to a **POR-free external reset-only architecture** in the SCL-180 technology.

---

