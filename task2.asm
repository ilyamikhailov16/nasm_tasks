%define OPEN  2
%define WRITE 1
%define CLOSE 3
%define EXIT  60
%define O_WRONLY  1
%define O_CREAT 0o100
%define O_MODE 0o644 ; Права rw-r--r--(владелец - читать/писать, группа - читать, остальные - читать)

global _start

section .data
    filename db "task2_output.txt", 0 ; open ожидает нуль-терминированную строку
    message db "Hello world!", 10
    length  equ $ - message

section .text
_start:
    ; Открываем файл 
    mov rax, OPEN ; Вызов open
    mov rdi, filename
    mov rsi, O_CREAT | O_WRONLY ; Флаги(создать если нет, только запись)
    mov rdx, O_MODE ; Права доступа(для создания)
    syscall
    
    ; Проверка на ошибку открытия
    cmp rax, 0
    jl open_error

    ; сохраняем файловый дескриптор в rbx
    mov rbx, rax
    
    ; Записываем в файл 
    mov rax, WRITE ; Вызов write
    mov rdi, rbx ; файловый дескриптор
    mov rsi, message
    mov rdx, length
    syscall

    ; Проверка результата записи
    cmp rax, 0
    jl write_error
    cmp rax, length
    jne write_error

    ; Закрываем файл
    mov rax, CLOSE ; Вызов close
    mov rdi, rbx ; файловый дескриптор
    syscall

    ; Проверка результата закрытия
    cmp rax, 0
    jl close_error

    ; Успешный выход
    mov rax, EXIT
    mov rdi, 0 ; Код возврата 0 (успех)
    syscall

open_error:
    jmp exit_error

write_error:
    ; Закрываем файл
    mov rax, 3 ; Вызов close
    mov rdi, rbx ; файловый дескриптор
    syscall
    jmp exit_error

close_error:
    jmp exit_error

exit_error:
    mov rax, EXIT ; Вызов exit
    mov rdi, 1 ; Код возврата 1 (ошибка)
    syscall
