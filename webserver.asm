format ELF64 executable

;; syscall
SYS_WRITE  equ 1
SYS_CLOSE  equ 3
SYS_SOCKET equ 41
SYS_ACCEPT equ 43
SYS_BIND   equ 49
SYS_LISTEN equ 50
SYS_EXIT   equ 60

;; write
STDOUT_FILENO equ 1
STDERR_FILENO equ 2

;; socket
IPPROTO_IP  equ 0
SOCK_STREAM equ 1
AF_INET     equ 2

;; bind
INADDR_ANY equ 0

;; listen
MAX_CONN equ 8

;; exit
EXIT_SUCCESS equ 0
EXIT_FAILURE equ 1

;; string
NIL equ 0
LF  equ 10
CR  equ 13

;; rax - syscall n
;; rdi - arg 1
;; rsi - arg 2
;; rdx - arg 3
;; ...
;;
;; see https://chromium.googlesource.com/chromiumos/docs/+/HEAD/constants/syscalls.md

macro syscall1 n, a
{
    mov rax, n
    mov rdi, a
    syscall
}

macro syscall2 n, a, b
{
    mov rax, n
    mov rdi, a
    mov rsi, b
    syscall
}

macro syscall3 n, a, b, c
{
    mov rax, n
    mov rdi, a
    mov rsi, b
    mov rdx, c
    syscall
}

macro write fd, buf, count
{
    syscall3 SYS_WRITE, fd, buf, count
}

macro close fd
{
    syscall1 SYS_CLOSE, fd
}

macro socket domain, type, protocol
{
    syscall3 SYS_SOCKET, domain, type, protocol
}

macro bind sockfd, addr, addrlen
{
    syscall3 SYS_BIND, sockfd, addr, addrlen
}

macro listen sockfd, backlog
{
    syscall2 SYS_LISTEN, sockfd, backlog
}

macro accept sockfd, addr, addrlen
{
    syscall3 SYS_ACCEPT, sockfd, addr, addrlen
}

macro exit code
{
    syscall1 SYS_EXIT, code
}

macro assert
{
    cmp rax, EXIT_SUCCESS
    jl error
    ;; write STDOUT_FILENO, str_success, str_success.len
}

segment readable executable

;; eax, r... - 32 bit registers
;; rax, r... - 64 bit registers

;; word  - write 2 bytes
;; dword - write 4 bytes
;; qword - write 8 bytes

;; mov loc, data - copy data to loc
;; jl label      - conditional jump to label
;; jmp label     - unconditional jump to label

;; $     - current memory
;; [var] - dereference var

entry main
main:
    write STDOUT_FILENO, str_start, str_start.len
    
    ;; func socket
    ;; see https://man7.org/linux/man-pages/man2/socket.2.html
    write STDOUT_FILENO, str_socket, str_socket.len
    socket AF_INET, SOCK_STREAM, IPPROTO_IP
    assert
    
    mov qword [sockfd], rax ;; allocate sockfd
    write STDOUT_FILENO, str_success, str_success.len

    ;; func bind
    ;; see https://man7.org/linux/man-pages/man2/bind.2.html
    write STDOUT_FILENO, str_bind, str_bind.len
    bind [sockfd], servaddr.sin_family, servaddr.size
    assert

    write STDOUT_FILENO, str_success, str_success.len

    ;; func listen
    ;; see https://man7.org/linux/man-pages/man2/listen.2.html
    write STDOUT_FILENO, str_listen, str_listen.len
    listen [sockfd], MAX_CONN
    assert
    
    write STDOUT_FILENO, str_success, str_success.len

request:
    ;; func accept
    ;; see https://man7.org/linux/man-pages/man2/accept.2.html
    write STDOUT_FILENO, str_accept, str_accept.len
    accept [sockfd], cliaddr.sin_family, ptr_cliaddr_size
    assert

    ;; get http response
    mov qword [connfd], rax ;; allocate connfd
    write [connfd], http_response, http_response.len ;; response to fd
    write STDOUT_FILENO, str_success, str_success.len
    jmp request ;; next request

    close [connfd] ;; deallocate connfd
    close [sockfd] ;; deallocate sockfd
    exit EXIT_SUCCESS

error:
    write STDERR_FILENO, str_error, str_error.len
    
    close [connfd] ;; deallocate connfd
    close [sockfd] ;; deallocate sockfd
    exit EXIT_FAILURE

;; db - type 1 byte
;; dw - type 2 byte
;; dd - type 4 byte
;; dq - type 8 byte

segment readable writeable

;; fd
sockfd dq -1
connfd dq -1

;; struct sockaddr_in
;; see https://www.gta.ufrj.br/ensino/eel878/sockets/sockaddr_inman.html
struc servaddr_in sin_family, sin_port, sin_addr
{
    .sin_family dw sin_family
    .sin_port   dw sin_port
    .sin_addr   dd sin_addr
    .sin_zero   dq 0
    .size = $ - .sin_family ;; current memory (-) struct addr 0
}

servaddr servaddr_in AF_INET, 36895, INADDR_ANY  ;; server sockaddr_in ;; 36895 = htons(8080)
cliaddr  servaddr_in 0, 0, 0 ;; client sockaddr_in
ptr_cliaddr_size dd cliaddr.size ;; pointer to size

;; http
struc http msg
{
    .content db "HTTP/1.1 200 OK", CR, LF
             db "Content-Type: text/html; charset=utf-8", CR, LF
             db "Connection: close", CR, LF
             db CR, LF
             db "<h1>", msg, "</h1>", LF
    .len = $ - .content
}
http_response http "Hello from assembler!"

;; string
struc string data, a
{
    .str db data, a
    .len = $ - .str
}

str_start string "Starting Web Server", LF

str_socket string "Creating socket... ", NIL
str_bind   string "Binding socket... ", NIL
str_listen string "Listening socket... ", NIL
str_accept string "Waiting for client connection... ", NIL

str_success string "OK", LF
str_error   string "ERROR", LF
