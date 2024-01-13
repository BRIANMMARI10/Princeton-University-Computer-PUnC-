# Princeton-University-Computer-PUnC-

## Purpose
  Build a Princeton University Computer (PUnC), a 16-bit processor with a simple but versatile instruction set. This 
  processor is Turing complete and is a full-fledged stored program computer.In PUnC, all data and instructions are aligned 16-bit     words, and both programs and data reside in the same memory unit.

## Hardware Modules
Memory
  PUnC memory addresses are 16 bits long, and each unique address points to a full 16-bit data word

Register File
  PUnC has eight general-purpose 16-bit registers, addressed from 0x0 to 0x7. These registers are used as scratch space for 
  arithmetic operations and are used in nearly every instruction

Condition Codes
  PUnC also has three 1-bit condition code registers: N (Negative), Z (Zero), and P (Positive). These condition codes are set by         arithmetic and load operations based on the value of the data being saved to the register file.

Program Counter
  A 16-bit program counter (PC) register  that is used to address memory. PC increments by 1 immediately after fetching and              decoding an instruction, so the program counter actually points to the next instruction to be fetched while the current instruction    executes
  
Instruction Register
  Stores the currently-executing instruction.   
   
## Instruction Stages
1. Fetch – An instruction is loaded from memory into the IR (IR <= Mem[PC]). This phase takes one cycle.
2. Decode – The instruction is now in the IR. In this stage, we simply increment the PC. On a pipelined processor, we would also prepare the control signals for executing the instruction, but since PUnC is unpipelined, we’ll actually do that in the execute
phase. This phase takes one cycle.
4. Execute – The control unit sets control signals to manipulate the datapath into executing the decoded instruction. This could involve reading from memory, executing an arithmetic operation, or even modifying the PC. 
