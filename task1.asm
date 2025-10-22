global _start

section .data
    message db "Hello world!", 10
    length  equ $ - message

section .text
_start:
    mov rax, 1 ; Вызов sys_write
    mov rdi, 1 ; Файловый дескриптор stdout
    mov rsi, message
    mov rdx, length
    syscall
    
    ; Проверка результата
    ; RAX содержит количество записанных байт или код ошибки (отрицательное число)
    ; cmp выполнит сравнение через вычитание rax - 0, но не сохранит результат, но обновит флаги во флаговом регистре
    ; jl проверяет SF и OF, если они не равны, то выполнится переход, т.к.
    ; для операции rax - 0 всегда OF = 0(не будет знакового переполнения), а SF принимает бит знака(Если rax < 0, то 1)
    cmp rax, 0
    jl write_error ; Если RAX < 0, произошла ошибка
    
    ; Если записано не все, то тоже вернём ошибку
    cmp rax, length
    jne write_error ; Переход выполняется, если операнды не равны, результат не ноль(флаг нуля не установлен -> ZF = 0)
    
    ; Успешный выход
    mov rax, 60
    mov rdi, 0 ; Код возврата 0 (успех)
    syscall

write_error:    
    mov rax, 60
    mov rdi, 1 ; Код возврата 1 (ошибка)
    syscall