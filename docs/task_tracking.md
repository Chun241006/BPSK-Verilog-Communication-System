# BPSK Communication System - Task Tracking


## 1. Project Information
| Item              | Information                                      |
|------             |-------------                                     |
| Project           | BPSK Modulator and Demodulator using Verilog HDL |
| Course            | Communication System                             |
| Team Size         | 4 members                                        |
| Project Start     | 28/09/2026                                       |
| Planned Duration  | 3 weeks                                          |
| Main Tools        | Verilog HDL, ModelSim, GitHub                    |
| Repository        | BPSK-Verilog-Communication-System                |


# 2. Team Responsibilities
| Member   | Role                                              | Main Responsibility                        |
|--------  |------                                             |---------------------                       |
| Leader   | System Integration & Project Management           | System specification,architecture,Channel,BER,integration, progress tracking                                                                                           |
| Member 1 | BPSK Modulator                                    | Design and implement BPSK Modulator RTL |
| Member 2 | BPSK Demodulator                                  | Design and implement correlation-based BPSK Demodulator RTL |
| Member 3 | Verification Engineer                             | Testbench, simulation, waveform analysis, verification |


# 3. Week 4 - System Design and Preparation
## Period

**28/09/2026 - 04/10/2026**
## Objective
Complete the system-level design and prepare all team members for RTL implementation.

## Leader

### Responsibilities

- Define the overall system architecture.
- Create the project block diagram.
- Define system parameters.
- Define module interfaces.
- Design the Channel model.
- Design the BER calculation method.
- Create and maintain the GitHub repository structure.
- Coordinate work between team members.
- Review technical decisions made by team members.
- Track project progress.

### Deliverables

- `docs/block_diagram.md`
- `docs/system_specification.md`
- `docs/interface_specification.md`
- `docs/channel_design.md`
- `docs/ber_design.md`
- `docs/task_tracking.md`

### Status

**Completed**

---

## Member 1 - BPSK Modulator

### Responsibilities

- Study the BPSK modulation principle.
- Understand the selected BPSK mapping:
  - `0 → +Carrier`
  - `1 → -Carrier`
- Understand the 8-sample carrier LUT.
- Design the Modulator architecture.
- Define the Modulator timing behavior.
- Prepare the `bpsk_modulator.v` RTL structure.

### Deliverables

- Modulator block concept.
- Carrier LUT definition.
- Modulator timing description.
- Initial `bpsk_modulator.v` skeleton.

### Status

**In Progress**

---

## Member 2 - BPSK Demodulator

### Responsibilities

- Study the BPSK demodulation principle.
- Understand correlation-based detection.
- Understand signed arithmetic.
- Design the correlation accumulator.
- Define the 8-sample symbol processing.
- Define the decision rule:
  - Positive correlation → `0`
  - Negative correlation → `1`
- Prepare the `bpsk_demodulator.v` RTL structure.

### Deliverables

- Demodulator block concept.
- Correlation calculation description.
- Decision rule.
- Timing description.
- Initial `bpsk_demodulator.v` skeleton.

### Status

**In Progress**

---

## Member 3 - Verification

### Responsibilities

- Define the verification strategy.
- Study the ModelSim simulation flow.
- Prepare clock and reset generation.
- Define test input sequences.
- Define expected outputs.
- Prepare PASS/FAIL checking.
- Prepare the testbench structure.

### Initial Test Cases

| Test Case | Input |
|-----------|-------|
| Test 1 | `00000000` |
| Test 2 | `11111111` |
| Test 3 | `10101010` |
| Test 4 | `10110010` |
| Test 5 | Random sequence |

### Deliverables

- Verification plan.
- Test case table.
- Testbench skeleton.
- Initial waveform signal list.

### Status

**In Progress**

---

# 4. Week 5 - RTL Implementation and Unit Testing

## Period

**05/10/2026 - 11/10/2026**

## Objective

Implement the main RTL modules and perform individual module testing.

---

## Leader

### Tasks

- Review Modulator implementation.
- Review Demodulator implementation.
- Implement or finalize `channel.v`.
- Implement or finalize `ber_counter.v`.
- Check interface compatibility.
- Review GitHub commits.
- Resolve integration issues between members.

### Deliverables

- `rtl/channel.v`
- `rtl/ber_counter.v`
- Reviewed interfaces.
- Initial integration structure.

### Status

**Planned**

---

## Member 1

### Tasks

- Implement `bpsk_modulator.v`.
- Implement the carrier LUT.
- Implement sample counter.
- Implement bit-to-phase mapping.
- Generate `sample_valid`.
- Perform unit simulation.
- Verify output for bit `0`.
- Verify output for bit `1`.

### Deliverables

- Functional `bpsk_modulator.v`.
- Unit test results.
- Waveform screenshots.

### Status

**Planned**

---

## Member 2

### Tasks

- Implement `bpsk_demodulator.v`.
- Implement sample counter.
- Implement correlation accumulator.
- Implement signed multiplication.
- Implement decision logic.
- Generate `bit_valid`.
- Perform unit simulation.

### Deliverables

- Functional `bpsk_demodulator.v`.
- Unit test results.
- Waveform screenshots.

### Status

**Planned**

---

## Member 3

### Tasks

- Complete `tb_bpsk_system.v`.
- Generate clock and reset.
- Generate test input sequences.
- Create expected results.
- Check Modulator output.
- Check Demodulator output.
- Prepare automatic PASS/FAIL messages.

### Deliverables

- Functional testbench.
- Initial simulation results.
- Waveform screenshots.

### Status

**Planned**

---

# 5. Week 6 - System Integration and BER Testing

## Period

**12/10/2026 - 18/10/2026**

## Objective

Connect all modules and verify the complete BPSK communication system.

---

## Leader

### Tasks

- Integrate all RTL modules.
- Finalize `bpsk_top.v`.
- Check signal connections.
- Run complete system simulation.
- Verify Channel error injection.
- Verify BER calculation.
- Coordinate debugging between members.
- Review final results.

### Deliverables

- Functional `bpsk_top.v`.
- Integrated simulation.
- BER results.
- Final technical review.

### Status

**Planned**

---

## Member 1

### Tasks

- Support Modulator integration.
- Fix Modulator issues discovered during system simulation.
- Verify timing compatibility with the Channel.
- Support debugging.

### Deliverables

- Stable Modulator implementation.
- Integration fixes.

### Status

**Planned**

---

## Member 2

### Tasks

- Support Demodulator integration.
- Verify correlation results.
- Debug incorrect recovered bits.
- Verify behavior when the Channel introduces symbol inversion.

### Deliverables

- Stable Demodulator implementation.
- Integration fixes.

### Status

**Planned**

---

## Member 3

### Tasks

- Run complete system testbench.
- Test no-error condition.
- Test one-error condition.
- Test multiple-error condition.
- Collect waveform results.
- Collect BER results.
- Record PASS/FAIL results.

### Deliverables

- Final testbench.
- Simulation waveforms.
- BER test results.
- Verification summary.

### Status

**Planned**

---

# 6. Week 7 - Finalization

## Period

**19/10/2026 - 25/10/2026**

## Objective

Finalize the project documentation, presentation, and GitHub repository.

---

## Leader

- Final code review.
- Check repository structure.
- Check README.
- Review documentation.
- Coordinate final report.
- Prepare presentation.
- Prepare project explanation.
- Final GitHub review.

---

## Member 1

- Provide Modulator explanation.
- Provide Modulator waveform.
- Support presentation preparation.

---

## Member 2

- Provide Demodulator explanation.
- Provide correlation waveform.
- Support presentation preparation.

---

## Member 3

- Provide verification results.
- Provide BER results.
- Prepare simulation screenshots.
- Support presentation preparation.

---

# 7. Project Milestones

| Milestone | Target Date | Description | Status |
|-----------|-------------|-------------|--------|
| M0 | 29/09/2026 | System specification agreed | Completed |
| M1 | 04/10/2026 | Week 4 design completed | In Progress |
| M2 | 11/10/2026 | Main RTL modules implemented | Planned |
| M3 | 14/10/2026 | System integration completed | Planned |
| M4 | 16/10/2026 | BER testing completed | Planned |
| M5 | 18/10/2026 | Project V1.0 code freeze | Planned |
| M6 | 25/10/2026 | Documentation and presentation finalized | Planned |

---

# 8. Definition of Done

## Week 4

Week 4 is considered complete when:

- [x] Project block diagram completed.
- [x] System specification completed.
- [x] Interface specification completed.
- [x] Channel design completed.
- [x] BER design completed.
- [x] GitHub folder structure created.
- [x] Team responsibilities defined.

---

## Week 5

Week 5 is considered complete when:

- [ ] BPSK Modulator implemented.
- [ ] BPSK Demodulator implemented.
- [ ] Channel implemented.
- [ ] BER Counter implemented.
- [ ] Individual module tests completed.
- [ ] Initial waveforms obtained.

---

## Week 6

Week 6 is considered complete when:

- [ ] All modules integrated.
- [ ] Top-level module works.
- [ ] No-error test passes.
- [ ] One-error test passes.
- [ ] Multiple-error test passes.
- [ ] BER results are verified.
- [ ] Main simulation results are collected.

---

## Week 7

Week 7 is considered complete when:

- [ ] Final RTL code reviewed.
- [ ] Testbench finalized.
- [ ] README completed.
- [ ] Documentation completed.
- [ ] Report completed.
- [ ] Presentation completed.
- [ ] GitHub repository organized.
- [ ] Final project version pushed to GitHub.

---

# 9. GitHub Workflow

Each team member should work using Git.

The recommended workflow is:

```text
Clone Repository
       |
       v
Create / Modify Files
       |
       v
git status
       |
       v
git add
       |
       v
git commit
       |
       v
git push
       |
       v
GitHub Repository

Each commit should clearly describe the change.
Examples:
docs: add system specification
docs: add interface specification
docs: add channel design
docs: add BER design
docs: update task tracking
feat: implement BPSK modulator
feat: implement BPSK demodulator
test: add BPSK testbench
fix: correct demodulator correlation


# 10. Repository Rules
The team should follow these rules:
Do not commit generated simulation files unless required.
Do not commit temporary editor files.
Do not modify another member's RTL without discussion.
Keep module interfaces consistent with interface_specification.md.
Commit related changes together.
Use meaningful commit messages.
Push work regularly.
Pull the latest changes before starting work.
Resolve merge conflicts carefully.
The Leader reviews the repository before major milestones.


# 11. Current Project Status
As of the end of Week 4:

Project Design
       |
       +-- Block Diagram .............. COMPLETED
       |
       +-- System Specification ....... COMPLETED
       |
       +-- Interface Specification .... COMPLETED
       |
       +-- Channel Design ............. COMPLETED
       |
       +-- BER Design ................. COMPLETED
       |
       +-- Task Tracking .............. COMPLETED
       |
       v
Week 5: RTL Implementation

The project is ready to move from system-level design to RTL implementation.

