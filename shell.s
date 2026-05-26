.global main

    .section .data
prompt:     .asciz "shell> "

cmd_hello:  .asciz "hello"
cmd_help:   .asciz "help"
cmd_exit:   .asciz "exit"
cmd_clear:  .asciz "clear"
cmd_hex:    .asciz "hex "
cmd_sum:    .asciz "sum "

hello_msg:  .asciz "Hello World!\n"
help_msg:   .asciz "Available commands:\n - hello\n - help\n - exit\n - clear\n - hex <num>\n - sum <num1> <num2>\n"
unknown_msg:.asciz "Unknown command.\n"
clear_seq:  .asciz "\033[2J\033[H"
hex_prefix: .asciz "0x"
newline:    .asciz "\n"

    .section .bss
    .lcomm buffer, 128

    .section .text

main:
shell_loop:
    ldr r0, =prompt
    bl print_string

    ldr r0, =buffer
    mov r2, #128
    bl read_input

    ldr r0, =buffer
    bl remove_newline

    bl handle_command

    b shell_loop

// -------------------------

remove_newline:
    push {r1, r2, lr}
    mov r1, r0
remove_loop:
    ldrb r2, [r1]
    cmp r2, #0
    beq remove_done
    cmp r2, #10
    beq set_zero
    add r1, r1, #1
    b remove_loop
set_zero:
    mov r2, #0
    strb r2, [r1]
remove_done:
    pop {r1, r2, lr}
    bx lr

// -------------------------

strcmp:
    push {r2, r3, lr}
strcmp_loop:
    ldrb r2, [r0], #1
    ldrb r3, [r1], #1
    cmp r2, r3
    bne strings_not_equal
    cmp r2, #0
    bne strcmp_loop
    mov r0, #0
    b strcmp_done
strings_not_equal:
    mov r0, #1
strcmp_done:
    pop {r2, r3, lr}
    bx lr

// -------------------------

handle_command:
    push {lr}

    ldr r0, =buffer
    ldr r1, =cmd_hello
    bl strcmp
    cmp r0, #0
    beq call_hello

    ldr r0, =buffer
    ldr r1, =cmd_help
    bl strcmp
    cmp r0, #0
    beq call_help

    ldr r0, =buffer
    ldr r1, =cmd_exit
    bl strcmp
    cmp r0, #0
    beq call_exit

    ldr r0, =buffer
    ldr r1, =cmd_clear
    bl strcmp
    cmp r0, #0
    beq call_clear

    ldr r0, =buffer
    ldr r1, =cmd_hex
    bl starts_with
    cmp r0, #0
    beq call_hex

    ldr r0, =buffer
    ldr r1, =cmd_sum
    bl starts_with
    cmp r0, #0
    beq call_sum

    ldr r0, =unknown_msg
    bl print_string
    b handle_done

call_hello:
    bl hello_command
    b handle_done

call_help:
    bl help_command
    b handle_done

call_exit:
    bl exit_command

call_clear:
    bl clear_command
    b handle_done

call_hex:
    ldr r0, =buffer
    add r0, r0, #4
    bl hex_command
    b handle_done

call_sum:
    ldr r0, =buffer
    add r0, r0, #4
    bl sum_command
    b handle_done

handle_done:
    pop {lr}
    bx lr

// -------------------------

starts_with:
    push {r2, r3, lr}
    mov r2, r0      @ input ptr
    mov r3, r1      @ prefix ptr

check_loop:
    ldrb r0, [r2], #1
    ldrb r1, [r3], #1
    cmp r1, #0
    beq starts_match
    cmp r0, r1
    bne starts_fail
    b check_loop

starts_match:
    mov r0, #0
    b starts_done

starts_fail:
    mov r0, #1

starts_done:
    pop {r2, r3, lr}
    bx lr

// -------------------------

hello_command:
    push {lr}
    ldr r0, =hello_msg
    bl print_string
    pop {lr}
    bx lr

help_command:
    push {lr}
    ldr r0, =help_msg
    bl print_string
    pop {lr}
    bx lr

exit_command:
    mov r7, #1      @ sys_exit
    mov r0, #0      @ exit code
    swi 0

clear_command:
    push {lr}
    ldr r0, =clear_seq
    bl print_string
    pop {lr}
    bx lr

// -------------------------

print_string:
    push {r1, r2, lr}
    mov r1, r0
    bl strlen
    mov r2, r0
    mov r0, #1      @ stdout
    mov r7, #4      @ sys_write
    swi 0
    pop {r1, r2, lr}
    bx lr

read_input:
    push {r1, lr}
    mov r1, r0
    mov r0, #0      @ stdin
    mov r7, #3      @ sys_read
    swi 0
    pop {r1, lr}
    bx lr

strlen:
    push {r1, r2, lr}
    mov r1, r0
    mov r2, #0
strlen_loop:
    ldrb r3, [r1, r2]
    cmp r3, #0
    beq strlen_done
    add r2, r2, #1
    b strlen_loop
strlen_done:
    mov r0, r2
    pop {r1, r2, lr}
    bx lr

// -------------------------

hex_command:
    push {r1, r2, r3, lr}
    mov r1, r0          @ decimal string ptr

    mov r2, #0          @ accumulator
    mov r3, #10         @ multiplier

hex_conv_loop:
    ldrb r0, [r1], #1
    cmp r0, #0
    beq hex_conv_done
    cmp r0, #'0'
    blt hex_conv_done
    cmp r0, #'9'
    bgt hex_conv_done
    sub r0, r0, #'0'
    mul r2, r2, r3      @ r2 = r2 * 10 (r2 != r3)
    add r2, r2, r0
    b hex_conv_loop

hex_conv_done:
    ldr r0, =hex_prefix
    bl print_string

    mov r0, r2
    bl print_hex

    ldr r0, =newline
    bl print_string

    pop {r1, r2, r3, lr}
    bx lr

// -------------------------

sum_command:
    push {r1, r2, r3, r4, lr}
    mov r1, r0          @ pointer to input string

    bl skip_spaces      @ skip leading spaces
    mov r0, r1
    bl parse_number     @ parse num1, returns in r0
    mov r2, r0          @ save num1

    bl skip_spaces
    mov r0, r1
    bl parse_number     @ parse num2, returns in r0
    mov r3, r0          @ save num2

    add r4, r2, r3      @ sum

    mov r0, r4
    bl print_decimal

    ldr r0, =newline
    bl print_string

    pop {r1, r2, r3, r4, lr}
    bx lr

// -------------------------

skip_spaces:
    push {r0, lr}
skip_loop:
    ldrb r0, [r1]
    cmp r0, #' '
    bne skip_done
    add r1, r1, #1
    b skip_loop
skip_done:
    pop {r0, lr}
    bx lr

// -------------------------

parse_number:
    push {r2, r3, lr}
    mov r1, r0          @ local string ptr
    mov r0, #0          @ accumulator

parse_loop_num:
    ldrb r2, [r1]
    cmp r2, #'0'
    blt parse_done_num
    cmp r2, #'9'
    bgt parse_done_num
    sub r2, r2, #'0'
    mov r3, #10
    mul r0, r0, r3      @ r0 = r0 * 10 (r0 != r3)
    add r0, r0, r2
    add r1, r1, #1
    b parse_loop_num

parse_done_num:
    mov r1, r1          @ update string pointer
    pop {r2, r3, lr}
    bx lr

// -------------------------

print_hex:
    push {r1, lr}
    mov r1, r0
    cmp r1, #16
    blt print_hex_digit

    mov r0, r1
    lsr r0, r0, #4
    bl print_hex

    and r0, r1, #0xF

print_hex_digit:
    cmp r0, #10
    blt print_hex_digit_num

    add r0, r0, #'a' - 10
    bl putchar
    b print_hex_done

print_hex_digit_num:
    add r0, r0, #'0'
    bl putchar

print_hex_done:
    pop {r1, lr}
    bx lr

// -------------------------

print_decimal:
    push {r1, lr}
    mov r1, r0
    cmp r1, #10
    blt print_decimal_digit

    mov r0, r1
    mov r1, #10
    bl udiv

    mov r0, r0
    bl print_decimal

    mov r0, r1

print_decimal_digit:
    add r0, r0, #'0'
    bl putchar
    pop {r1, lr}
    bx lr

// -------------------------

udiv:
    push {r1, lr}
    bl __aeabi_uidiv
    pop {r1, lr}
    bx lr

// -------------------------

putchar:
    push {r1, lr}
    sub sp, sp, #4
    strb r0, [sp]
    mov r0, #1      @ stdout
    mov r1, sp
    mov r2, #1      @ write 1 byte
    mov r7, #4      @ sys_write
    swi 0
    add sp, sp, #4
    pop {r1, lr}
    bx lr