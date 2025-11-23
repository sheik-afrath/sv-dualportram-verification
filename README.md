# Dual-Port RAM Verification Environment

## 📌 Overview

This project focuses on the pre-silicon verification of a **Dual-Port RAM Controller** using **SystemVerilog**. The goal was to validate the design's correctness under concurrent access scenarios, ensuring data integrity and proper handling of priority logic during address collisions.

The verification environment employs a **random test-based methodology** with an automated self-checking mechanism (shadow memory) to verify a 1 KB synchronous memory design.

## ⚙️ Design Under Test (DUT) Specifications

The DUT is a **Simple Dual-Port RAM** with the following characteristics:

  * **Memory Size:** 1 KB ($1024 \times 8$-bit)
  * **Ports:** Two independent ports (Port A & Port B)
  * **Clocking:** Synchronous read/write operations
  * **Priority Scheme:** Port A has higher priority. If both ports access the same address simultaneously, Port A proceeds, and Port B is blocked.
  * **Collision Handling:** A `busy_B` signal is asserted when a collision occurs, indicating Port B's operation was ignored.

## 📂 Project Structure

All files are located in the main root directory:

```bash
├── dual_ram.v        # Design Under Test (DUT) source code
├── dual_ram_tb.sv    # SystemVerilog Testbench (contains Interface & Test Program)
└── README.md         # Project documentation
```

## 🧪 Verification Strategy

The testbench is built using a **Program-Block Architecture** in SystemVerilog. It validates the design through 2000 randomized iterations of concurrent operations.

### Key Components

  * **Generator:** Produces random 10-bit addresses and 8-bit data using `$urandom_range`.
  * **Driver:** Drives signals to the DUT via the interface.
  * **Shadow Memory (Scoreboard):** Maintains a "golden" copy of the memory (`MEM_WR` and `MEM_RD` arrays) to predict expected behavior.
  * **Checker:** Automatically compares DUT output against shadow memory at the end of simulation to detect data mismatches.
  * **Coverage Collector:** Functional coverage groups track execution of concurrent Read/Write scenarios and Address Collisions.

### Test Scenarios

The environment cycles through four primary concurrent scenarios:

1.  **Concurrent Write/Write:** Simultaneous writes to random addresses on both ports.
2.  **Concurrent Read/Read:** Simultaneous reads from random addresses on both ports.
3.  **Concurrent Read/Write:** Port A reads while Port B writes.
4.  **Concurrent Write/Read:** Port A writes while Port B reads.

## 📊 Verification Results

The project successfully verified the DUT with **zero data mismatches** across 2000 test vectors.

| Metric | Result |
| :--- | :--- |
| **Status** | ✅ Passed (2000/2000 tests) |
| **Functional Coverage** | 91.66% |
| **Code Coverage (Statement)** | 82.35% |
| **Code Coverage (Branch)** | 80.00% |

## 🚀 How to Run

This project is designed to be run with **Siemens EDA QuestaSim** (or ModelSim).

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/yourusername/dual-port-ram-verification.git
    cd dual-port-ram-verification
    ```

2.  **Compile and Run:**
    Open your terminal in the project directory and run the following commands:

    ```bash
    vlib work
    vlog dual_ram.v dual_ram_tb.sv
    vsim -c -do "run -all; exit" dual_ram_tb
    ```

## 👤 Author

  * **Sheik Afrath**

-----
