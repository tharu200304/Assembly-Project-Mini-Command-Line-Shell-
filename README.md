# 🐚 Mini Command-Line Shell — ARM32 Assembly

> **CO1020 – Computer System Programming | Assembly Project**  
> Department of Computer Engineering, University of Peradeniya  
> **Group 58** | E/22/154 – Inuwara S.A.T | E/23/167 – Karunarathna A.V.P.J.P

---

## 📖 Overview

A minimal interactive command-line shell written entirely in **ARM32 assembly language**, running on Linux via QEMU user-mode emulation. The shell demonstrates low-level concepts including Linux syscalls, stack management, string processing, and arithmetic — all without any C runtime support beyond `__aeabi_uidiv`.

---

## ✨ Features

| Command | Description |
|---|---|
| `hello` | Prints `Hello World!` |
| `help` | Lists all available commands |
| `clear` | Clears the terminal using ANSI escape codes |
| `hex <num>` | Converts a decimal integer to hexadecimal (e.g. `hex 255` → `0xff`) |
| `sum <num1> <num2>` | Adds two integers and prints the result (e.g. `sum 100 147` → `247`) |
| `exit` | Exits the shell |

Unknown commands produce an `Unknown command.` message.

---

## 🗂️ Project Structure

```
.
├── shell.s        # Full ARM32 assembly source
└── README.md
```

### Source Sections

| Section | Purpose |
|---|---|
| `.data` | Constant strings — prompt, command keywords, messages, ANSI sequences |
| `.bss` | 128-byte uninitialized input buffer |
| `.text` | All executable code starting from `main` / `shell_loop` |

---

## 🔧 How It Works

### Shell Loop (`shell_loop`)
The core infinite loop that:
1. Prints the `shell> ` prompt via `sys_write`
2. Reads user input into the buffer via `sys_read`
3. Strips the trailing newline (`remove_newline`)
4. Dispatches to `handle_command`
5. Repeats

### Command Dispatch (`handle_command`)
Uses a custom `strcmp` for exact-match commands (`hello`, `help`, `exit`, `clear`) and a `starts_with` check for prefix-based commands (`hex `, `sum `). Each matched command branches to its own handler function.

### Custom Commands

**`hex <number>`**
- Parses the decimal string digit-by-digit (ASCII → int, multiply-accumulate)
- Prints `0x` prefix then calls recursive `print_hex` to emit hex digits

**`sum <num1> <num2>`**
- Skips spaces with `skip_spaces`, parses both numbers with `parse_number`
- Adds via `add r4, r2, r3` and prints with recursive `print_decimal`
- Uses `__aeabi_uidiv` (ARM runtime) for decimal digit extraction

### Key Helper Functions

| Function | Role |
|---|---|
| `print_string` | `sys_write` to stdout using computed `strlen` |
| `read_input` | `sys_read` from stdin into buffer |
| `strlen` | Counts bytes until null terminator |
| `remove_newline` | Replaces `\n` (ASCII 10) with `\0` |
| `strcmp` | Byte-by-byte string comparison, returns 0 if equal |
| `starts_with` | Checks if input begins with a given prefix |
| `putchar` | Writes a single byte to stdout via the stack |
| `print_hex` | Recursive hex digit printer |
| `print_decimal` | Recursive decimal digit printer |

---

## 🚀 Build & Run

### Prerequisites

```bash
sudo apt install gcc-arm-linux-gnueabi qemu-user
```

### Compile

```bash
arm-linux-gnueabi-gcc -Wall shell.s -o shell
```

### Run

```bash
qemu-arm -L /usr/arm-linux-gnueabi shell
```

### Example Session

```
shell> help
Available commands:
 - hello
 - help
 - exit
 - clear
 - hex <num>
 - sum <num1> <num2>
shell> hello
Hello World!
shell> hex 255
0xff
shell> sum 100 147
247
shell> exit
```

---

## 🏗️ ARM32 Concepts Demonstrated

- **`swi 0`** — Linux syscall interface (read, write, exit)
- **`push` / `pop`** — Callee-saved register preservation across function calls
- **`bl` / `bx lr`** — Branch-with-link function calls and returns
- **`ldrb` / `strb`** — Byte-level memory access for string processing
- **ANSI escape codes** — `\033[2J\033[H` for terminal clear
- **`.extern __aeabi_uidiv`** — ARM runtime soft-division for decimal printing
- **Recursive functions** — `print_hex` and `print_decimal` use stack-based recursion

---

## 👥 Team Contributions

- **E/22/154 – Inuwara S.A.T** — Task 1: Shell loop, input handling, helper functions
- **E/23/167 – Karunarathna A.V.P.J.P** — Task 2: Command handling logic, built-in commands
- **Both** — Task 3: Custom `hex` and `sum` commands, debugging, integration, report

---

## 📄 License

Academic project — University of Peradeniya, Department of Computer Engineering.
