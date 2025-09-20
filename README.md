# AMBA APB Protocol Implementation  

This repository contains a **complete Verilog implementation of the AMBA APB (Advanced Peripheral Bus) protocol**. The design includes:  

- An **APB Master** (bus controller)  
- Three **APB-compliant Slave Peripherals**:  
  1. **Memory Slave** (RAM-like storage for read/write)  
  2. **GPIO Slave** (programmable I/O with direction control)  
  3. **UART Slave** (full-duplex UART Tx/Rx interface with APB register mapping)  
- A **Top-Level APB Interconnect** with address decoding and bus multiplexing  
- **Testbenches** for each peripheral and integrated verification for the complete system  

This project demonstrates **protocol-level design, hardware-software interfacing, and peripheral integration** using AMBA’s lightweight APB standard.  

---

## 🔹 Why APB?  
The **Advanced Peripheral Bus (APB)** is a subset of the ARM AMBA protocol family, designed for **low-bandwidth, low-power peripherals**. Unlike AHB or AXI, APB is **non-pipelined**, making it simpler yet powerful for control-register-mapped devices such as GPIO, UART, timers, and memory-mapped I/O.  

This project pushes APB to its limits by integrating **multiple real-world peripherals** under one common bus master, ensuring:  
- Proper **handshake sequencing** (SETUP, ENABLE, ACCESS)  
- **PREADY/PSLVERR signaling** for synchronization and error detection  
- **Address decoding** for multiple slaves  
- **Synchronous and asynchronous peripheral support**  

---
<img width="897" height="585" alt="image" src="https://github.com/user-attachments/assets/514f3e0e-9d08-43d7-b9fd-6a6770eca37e" />

## 🔹 System Overview  

- **APB Master**: Issues read/write transactions, controls bus signals, manages state machine.  
- **Memory Slave**: Implements addressable storage with APB-compliant access cycles.  
- **GPIO Slave**: Provides input/output port registers, programmable direction, real-time pin sampling.  
- **UART Slave**: Bridges parallel APB bus to serial Tx/Rx with proper baud-rate timing and APB register-mapped interface.  

---

## 🔹 Peripheral Descriptions  

### 1️⃣ APB Master  
- Implements **three-phase APB protocol**:  
  - **IDLE → SETUP → ENABLE**  
- Generates:  
  - `PADDR` → address bus  
  - `PWDATA` → write data bus  
  - `PWRITE` → read/write control  
  - `PSELx` → one-hot slave select  
  - `PENABLE` → transfer enable  
- Monitors:  
  - `PRDATA` (read data)  
  - `PREADY` (slave ready)  
  - `PSLVERR` (error signaling)  

The master is implemented as a **Moore FSM** ensuring strict adherence to AMBA timing diagrams.  

---

### 2️⃣ Memory Slave  
- **8-bit memory array** with APB interface.  
- Decodes addresses from master and maps them into local memory space.  
- Supports both **read and write transfers**.  
- Implements `PREADY` to signal access completion.  
- Optionally asserts `PSLVERR` on invalid accesses.  

---

### 3️⃣ GPIO Slave  
- Implements three memory-mapped registers:  
  - **Direction Register (DIR)** → configures pins as input or output.  
  - **Input Register (IN)** → samples and stores real-time external inputs.  
  - **Output Register (OUT)** → drives external pins.  
- APB transactions dynamically update or read from these registers.  
- Supports bidirectional pin interfacing, modeled in Verilog.  

---

### 4️⃣ UART Slave  
- **Full APB-mapped UART peripheral** with transmit (Tx) and receive (Rx) support.  
- Memory-mapped registers:  
  - **TX Data Register (TXD)**  
  - **RX Data Register (RXD)**  
  - **Status Register** (Tx busy, Rx complete flags)  
- UART core includes:  
  - **Baud Rate Generator** (parameterizable)  
  - **UART Transmitter** (start, data, parity, stop framing)  
  - **UART Receiver** (synchronization, sampling, stop detection)  
- Integrates handshake between APB FSM and slower baud-rate domain.  

---

## 🔹 Verification Strategy  
Each slave and the integrated system are verified with **self-checking testbenches**.  

- **Waveform analysis** using GTKWave (`$dumpfile`, `$dumpvars`).  
- **Directed stimulus**:  
  - Write data to memory → Read back.  
  - Configure GPIO pins → Write outputs → Read inputs.  
  - Send UART TX data → Verify RX data loopback.  
- **Error handling tests**: invalid addresses, invalid data.  

---

## 🔹 Key Challenges & Complexity  
1. **Bridging clock domains** between APB (system clock) and UART (baud-rate driven).  
2. **One-cycle APB pulses** (e.g., TX_START) not aligning with baud tick → solved using synchronization logic.  
3. **Protocol correctness** – strict sequencing of PSEL, PENABLE, and state transitions.  
4. **Multi-slave address decoding** and avoiding bus contention.  
5. **Error signaling** via PSLVERR for robustness.  

These aspects make this implementation **far more than a toy design** – it closely models how real SoCs integrate low-speed peripherals into an AMBA-compliant environment.  

---

## 🔹 Tools Used  
- **Language**: Verilog HDL  
- **Simulator**: Icarus Verilog (`iverilog`, `vvp`)  
- **Waveform Viewer**: GTKWave  
- **Platform**: Linux-based environment  

---

## 🔹 Future Work  
- Add more APB-compliant peripherals (Timers, SPI, I2C).  
- Integrate with higher-level AMBA interconnect (AHB/AXI bridge).  
- Add UVM/SystemVerilog testbenches for protocol compliance verification.  

---

🚀 This project demonstrates **SoC-level bus design skills**: protocol implementation, peripheral design, verification, and debug.  
