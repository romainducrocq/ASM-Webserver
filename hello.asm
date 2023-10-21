format ELF64 executable

SYS_WRITE = 1
SYS_EXIT  = 60

macro write fd, buf, count
{
    mov rax, SYS_WRITE
    mov rdi, fd
    mov rsi, buf
    mov rdx, count
    syscall
}

macro exit code
{
    mov rax, SYS_EXIT
    mov rdi, code
    syscall
}

segment readable executable
entry main
main:
    write 1, msg, msg_len
    exit 0

segment readable writeable
msg db "Hello from assembler!", 10
msg_len = $ - msg
