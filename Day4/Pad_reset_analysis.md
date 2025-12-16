# Reset Pad Behavior and Power-Up Safety in SCL-180 I/O Libraries

## 1. Introduction
Removal of an on-chip Power-On Reset (POR) is only safe if the I/O pad library guarantees that reset pins are usable immediately after power-up and do not rely on internal POR-controlled enable paths.  
This document studies the SCL-180 I/O pad behavior with respect to reset handling and explains why an external reset-only strategy is architecturally safe in this technology. A comparison with SKY130 is provided to justify why POR was previously required there but not in SCL-180.

---

## 2. SCL-180 Reset Pad Characteristics

### 2.1 Internal Enable Requirement
Review of the SCL-180 I/O pad documentation and PDK comments indicates:

- Input pads do **not** require:
  - Internal digital enable sequencing
  - POR-driven gating logic
- Input buffers become functional once:
  - VDD and VSS are within valid operating range

> **Inference:**  
> The reset pad is not dependent on any internal POR signal to become active.

---

### 2.2 POR-Driven Gating
No evidence is found in the SCL-180 pad library indicating:

- Reset pin gating using POR
- Power-aware masking of reset during ramp-up
- Conditional input isolation tied to POR

Pad symbols and behavioral models treat reset as a standard digital input.

> **Conclusion:**  
> The reset pad is **electrically independent of POR logic**.

---

### 2.3 Asynchronous Nature of Reset Pin
The SCL-180 reset pad supports:

- Fully asynchronous assertion
- Glitch-free input buffering
- Immediate propagation into core logic

The reset pin does not depend on:
- Clock availability
- Internal enable signals
- Sequencing state machines

This allows reset to be asserted safely at any time after power is applied.

---

### 2.4 Availability After VDD Ramp
PDK documentation does not specify any delay or qualification requirement for reset pin usability after VDD rises.

Key observations:
- Input buffers are powered directly from VDD
- No internal “reset-valid” window is defined
- No mandatory stabilization time before reset assertion

> **Inference:**  
> Once VDD reaches valid logic levels, the reset pin is immediately usable.

---

## 3. Power-Up Sequencing Constraints in SCL-180

The SCL-180 documentation does **not** mandate:
- A digital POR for functional correctness
- Specific VDD ramp shapes
- Reset sequencing dependent on power detection

Instead, it assumes:
- Proper board-level power integrity
- External reset control when required

> **Key Insight:**  
> Reset responsibility is intentionally pushed to the system level, not the silicon.

---

## 4. Comparison with SKY130 (Why POR Was Mandatory There)

### 4.1 SKY130 Pad Behavior
In SKY130:
- Some pads rely on:
  - Internal enable logic
  - Power-good detection
- Reset inputs may remain undefined until:
  - POR logic stabilizes
- Certain I/O paths are masked during power-up

As a result:
- Internal digital logic cannot rely on reset alone
- A POR macro or equivalent is required to guarantee deterministic startup

---

### 4.2 Why SCL-180 Is Different
| Aspect | SKY130 | SCL-180 |
|------|-------|--------|
| Reset pad availability | After POR | After VDD |
| Internal enable needed | Yes | No |
| POR dependency | Mandatory | Not required |
| Pad input gating | Present | Absent |
| External reset sufficiency | ❌ No | ✅ Yes |

> **Design Consequence:**  
> What is unsafe in SKY130 becomes safe in SCL-180 due to fundamentally different pad assumptions.

---

## 5. Risk Assessment and Mitigation

### Identified Risks
- Reset asserted before VDD stabilizes
- External reset not properly driven

### Mitigations
- Board-level reset control
- Reset held low until power is stable
- Explicit asynchronous reset in RTL

These mitigations align with standard SoC integration practices.

---
1. **Does the reset pad require internal enable?**  
No, the reset pad in the SCL-180 I/O pad library does not require an internal enable signal. The pad is designed to directly accept an external reset input. As an active-low reset input, the signal propagates through internal logic without gating, ensuring immediate response on assertion.

2. **Does the reset pad require POR-driven gating?**  
No, reset pad signals are not gated by any POR-driven signals in SCL-180. The design relies on a deterministic external reset input that is always available and not conditioned by an internal Power-On Reset block.

3. **Is the reset pin asynchronous?**  
Yes, the reset pin is asynchronous relative to the core clock domain. It is intended to asynchronously clear internal states to bring the core into a known reset state. However, internally, synchronization to the clock domain happens after reset release to avoid metastability.

4. **Is the reset pin available immediately after VDD?**  
Yes, the reset pin input pad is available immediately after the power supply (VDD) reaches a valid level. It is meant to be driven externally and does not rely on any internal power-up sequencing or delay. The external circuitry controls reset assertion and de-assertion timing.

5. **Are there documented power-up sequencing constraints that mandate a POR?**  
No such constraints exist in the SCL-180 documentation for requiring a POR. The pad and SoC operate correctly using a conventional external reset signal, without internal POR sequencing. This reduces complexity and improves testability.

---

## Contrast with SKY130

| Feature                | SKY130                                              | SCL-180                                              |
|------------------------|----------------------------------------------------|-----------------------------------------------------|
| POR implementation     | On-chip analog and behavioral POR models mandatory for stable startup sequencing. | No silicon or behavioral POR implemented; external reset used. |
| Reset pad gating requirement | Reset signals gated by POR behavior for power sequencing. | No gating by POR; direct reset pad input used.       |
| Power sequencing constraints | Strict power-up sequencing enforced via POR module to avoid metastability and damage. | Relies on external reset timing; no internal power sequencing required. |
| Reset availability after power-up | Delayed by POR logic modeling power ramp.             | Immediately available; governed by external reset timing. |

---

## Why POR was mandatory in SKY130 and not in SCL-180

SKY130 uses aggressive power gating and complex power domains requiring careful on-chip power sequencing to avoid transient or undefined states during power-up. The on-chip POR ensures all domains power up in a correct sequence and the resets are asserted reliably. This requires analog and behavioral POR blocks tightly integrated into the silicon.

By contrast, SCL-180 uses a simpler power architecture without complex multi-domain sequencing requirements. Designs are intended to be driven with external reset signals rather than relying on an internal POR. This simplifies chip design and reduces analog complexity and silicon area.

---

## References

- SCL-180: Extracted from available documentation on CIO150 pad cells and reset handling procedures in the SCL PDK and I/O ring design templates.  
- SKY130 POR requirements: Industry typical POR implementation with analog power sensing and reset distribution for stable multi-power-domain start-up (general knowledge, contrasted with SCL-180).  
- Reset pin asynchronous behavior and availability noted from typical pad datasheets and user manuals in comparable 180nm technology nodes.

---

## 6. Conclusion
The SCL-180 I/O pad library provides reset pins that are:
- Asynchronous
- Available immediately after VDD
- Independent of POR-driven enable logic

No documented power-up sequencing constraints mandate the use of an on-chip POR.  
Therefore, a POR-free SoC relying solely on an external reset pin is architecturally correct and safe in SCL-180.

This stands in contrast to SKY130, where pad behavior necessitates POR for deterministic startup.

---

