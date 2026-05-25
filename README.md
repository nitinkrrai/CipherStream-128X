# CipherStream-128X

The CipherStream-128X is a fully unrolled, 10-stage pipelined AES-128 hardware accelerator designed for high-throughput, deterministic encryption in hostile environments. It integrates with a custom AXI4-Lite memory-mapped interface to ensure seamless SoC compatibility and strict protocol adherence.

## Architecture & Datapath

* The core encryption engine features a fully unrolled, 10-stage synchronous pipeline designed to output a new 128-bit ciphertext block every valid clock cycle.
* Stage 0 executes the initial AddRoundKey transformation by XORing the plaintext with the initial key.
* Stages 1 through 9 execute SubBytes, ShiftRows, MixColumns, and AddRoundKey transformations sequentially.
* Stage 10 omits the MixColumns step to comply with the AES-128 specification.
* The SubBytes transformation utilizes Distributed Combinational Logic (LUTs) rather than Block RAM (BRAM) to guarantee single-cycle combinational evaluation.
* Each round instantiates 16 parallel 8-bit S-boxes to process the entire 128-bit state matrix simultaneously.
* The design utilizes separate reset inputs rather than global asynchronous resets for precise domain initialization and control.

## Key Schedule & Dynamic Updates

* The architecture implements On-the-Fly Key Expansion to dynamically generate the 1408-bit expanded key bus.
* Flip-flops are inserted between each key expansion round to minimize critical path delay and achieve high-frequency operation.
* A Shadow Register isolates the active cryptographic datapath from the AXI interface to prevent data corruption during dynamic key updates.
* An 11-bit shift register tracks valid data flowing through the pipeline, executing an atomic key swap only when the pipeline is entirely empty.

## AXI4-Lite Interface & Buffering

* A specialized buffering state machine handles 32-to-128-bit data packing, triggering a single-cycle injection into the AES pipeline upon writing to the 4th word address.
* The 128-to-32-bit unpacking logic automatically clears the hardware Done bit upon reading the final 32-bit ciphertext word.
* The pipeline features a zero-data-loss global stall mechanism that instantly freezes all 1,408 datapath flip-flops by pulling the clock enable signal low during AXI backpressure.

## Performance Metrics

* **Maximum Operating Frequency:** 215.89 MHz.
* **Effective System Throughput:** 6.9 Gbps.
* **Total Latency:** 19 clock cycles or 88.0 nanoseconds.

## Resource Utilization

Targeting the Xilinx Zynq-7000 series architecture (xc7z020clg484-1).

| Resource Type | Utilized Count | Available | Utilization |
| :--- | :--- | :--- | :--- |
| Slice LUTs | 9,686 | 53,200 | 18.21% |
| Slice Registers (FFs) | 3,381 | 106,400 | 3.18% |
| Block RAM (BRAM) | 0 | 140 | 0.00% |
