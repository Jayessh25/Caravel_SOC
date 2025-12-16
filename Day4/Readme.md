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
