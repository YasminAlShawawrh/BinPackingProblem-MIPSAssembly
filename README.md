# Bin Packing Problem — MIPS Assembly

A MIPS assembly implementation of the Bin Packing Problem using two heuristic algorithms: First Fit (FF) and Best Fit (BF). The program reads item sizes from a text file, runs the selected heuristic, and writes bin assignment results to an output file.

---

## Table of contents

- [Problem definition](#problem-definition)
- [Algorithms](#algorithms)
- [Program flow](#program-flow)
- [Memory layout](#memory-layout)
- [Input / output format](#input--output-format)
- [Sample run](#sample-run)
- [File structure](#file-structure)
- [How to run](#how-to-run)
---

## Problem definition

Given `n` items with sizes `S1, S2, … Sn` where each size is a floating-point number between 0 and 1, pack all items into the **minimum number of bins**, each with unit capacity (capacity = 1.0).

---

## Algorithms

### First Fit (FF)
Items are packed in order `I1, I2, … In`. Each item is placed into the **lowest-indexed bin** that still has enough remaining capacity.

```
For each item Ii:
  Find smallest index j such that bin[j].remaining >= size(Ii)
  Place Ii into bin[j]
  If no such bin exists, open a new bin
```

### Best Fit (BF)
Same as First Fit, except each item is placed into the **fullest bin** that still fits it — minimizing wasted space.

```
For each item Ii:
  Find bin j with minimum remaining capacity such that bin[j].remaining >= size(Ii)
  Place Ii into bin[j]
  If no such bin exists, open a new bin
```

---

## Program flow

```
START
  ↓
Display menu (infinite loop until Q/q)
  ├── Option 1: Prompt for input filename → open file → read into buffer → validate floats
  ├── Option 2: Prompt for heuristic (FF or BF, case-insensitive)
  ├── Option 3: Prompt for output filename → run selected algorithm → write results
  └── Q/q: Exit
```

### Key subroutines

| Label | Description |
|---|---|
| `validate_floats` | Scans input buffer byte-by-byte, confirms all values are valid floats in (0, 1] |
| `parse_items` | Parses floating-point values from buffer into the `items` array using FPU registers |
| `first_fit` | FF algorithm — scans bins left-to-right, places item in first fitting bin |
| `best_fit` | BF algorithm — scans all bins, places item in tightest fitting bin |
| `run_and_save` | Dispatches to FF or BF based on stored heuristic, writes results to output file |

### Input handling details
- Filename read into 100-byte buffer; trailing newline stripped before `open` syscall
- File opened read-only (`syscall 13`); failure prints `"Error: File does not exist."`
- Buffer validated before parsing — invalid values trigger `"Error: File contains invalid data."`
- Heuristic input is case-insensitive: `f/F` → First Fit · `b/B` → Best Fit
- Menu loops infinitely; exits only on `q` or `Q`

---

## Memory layout

```
.data section:
  items         [.space 1024]  # Float array — parsed item sizes (up to 256 items × 4 bytes)
  bins          [.space 1024]  # Float array — remaining capacity per bin
  bin_map       [.space 400]   # Int array   — bin assignment per item
  buffer        [.space 256]   # Raw file read buffer
  output_buffer [.space 1024]  # Output text formatting buffer
```

Floating-point arithmetic uses MIPS FPU coprocessor 1 (`$f` registers). Constants `1.0` and `0.0` are stored as `.float` literals and loaded for capacity threshold comparisons.

---

## Input / output format

### Input file (`items.txt`)
One floating-point value per line, each strictly between 0 and 1:

```
0.5
0.7
0.2
0.4
0.6
0.3
```

### Output file
```
Total bins used: <N>

item 1 in bin<X>
item 2 in bin<X>
...
```

---

## Sample run

**Input (`items.txt`):** `0.5, 0.7, 0.2, 0.4, 0.6, 0.3`

**First Fit (`ff_output.txt`):**
```
Total bins used: 3

item 1 in bin1     ← 0.5
item 2 in bin2     ← 0.7
item 3 in bin1     ← 0.5 + 0.2 = 0.7  (first bin with space)
item 4 in bin3     ← 0.4
item 5 in bin3     ← 0.4 + 0.6 = 1.0
item 6 in bin1     ← 0.7 + 0.3 = 1.0
```

**Best Fit (`bf_output.txt`):**
```
Total bins used: 3

item 1 in bin1     ← 0.5
item 2 in bin2     ← 0.7
item 3 in bin2     ← 0.7 + 0.2 = 0.9  (tighter fit than bin1 at 0.5)
item 4 in bin1     ← 0.5 + 0.4 = 0.9
item 5 in bin3     ← 0.6
item 6 in bin3     ← 0.6 + 0.3 = 0.9
```

Both heuristics achieve the optimal solution of **3 bins** for this input.

---

## File structure

```
bin-packing-mips/
├── binPackingProblem.asm   # Full MIPS assembly source
├── items.txt               # Sample input (6 items)
├── ff_output.txt           # Sample First Fit output
└── bf_output.txt           # Sample Best Fit output
```

---

## How to run

1. Open **MARS** (MIPS Assembler and Runtime Simulator)
2. Load `binPackingProblem.asm`: File → Open
3. Assemble: Run → Assemble (`F3`)
4. Run: Run → Go (`F5`)
5. Follow the interactive menu:

```
Bin Packing Solver
1. Enter input file name
2. Choose heuristic (FF or BF)
3. Run algorithm and save output to file
Q. Quit
Enter your choice:
```

**Typical session:**
```
Enter your choice: 1
Enter the input file name: items.txt
File read successfully!

Enter your choice: 2
Choose heuristic (FF or BF): BF

Enter your choice: 3
Enter the output file name: bf_output.txt
Output written to file successfully.

Enter your choice: Q
```

> If the input file is not in MARS's working directory, provide the full path (e.g. `C:\files\items.txt`).

---
