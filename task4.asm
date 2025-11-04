%define MAX_NUM_LENGTH 7 ; Такая длина задана для корректной работы с числами от -32768 до 32767(с учётом вводимого символа переноса строки)

global _start 

section .data
    letter_error_string db 'Do not use letters in numbers!', 10
    letter_error_string_length equ $ - letter_error_string

section .bss
    first_num_str resb MAX_NUM_LENGTH
    second_num_str resb MAX_NUM_LENGTH
    result_str resb MAX_NUM_LENGTH

section .text
_start:
    ; Читаем первое число
    xor rax, rax ; Системный вызов read
    xor rdi, rdi ; Файловый дескриптор stdin
    mov rsi, first_num_str
    mov rdx, MAX_NUM_LENGTH
    syscall

    test rax, rax
    js exit_error ; Если RAX < 0, произошла ошибка

    ; Преобразуем первое число и сохраняем результат преобразования в rax
    call str_to_int ; На входе rsi - указатель на буфер
    mov rbx, rax ; Сохраняем первое число в rbx, чтобы потом сложить со вторым

    ; Читаем второе число
    xor rax, rax ; Системный вызов read
    xor rdi, rdi ; Файловый дескриптор stdin
    mov rsi, second_num_str
    mov rdx, MAX_NUM_LENGTH
    syscall

    test rax, rax
    js exit_error ; Если RAX < 0, произошла ошибка

    ; Преобразуем второе число и сохраняем результат преобразования в rax
    call str_to_int ; На входе rsi - указатель на буфер

    ; Складываем числа
    call sum ; На входе rbx - первое число, rax - второе число, возвращаем в rax сумму

    ; Преобразуем результат в строку
    mov rdi, result_str
    call int_to_str ; На входе rax - число(сумма) и rdi - указатель на буфер

    ; Добавляем символ переноса строки в конец
    mov [result_str + rdx], byte 10 ; rdx содержит длину result_str после вызова int_to_str
    inc rdx

    ; Выводим результат
    mov rax, 1 ; Системный вызов write
    mov rdi, 1 ; Файловый дескриптор stdout
    mov rsi, result_str
    ; rdx содержит длину result_str
    syscall

    test rax, rax
    js exit_error ; Если RAX < 0, произошла ошибка

    ; Если записано не все, то тоже вернём ошибку
    cmp rax, rdx
    jne exit_error ; Переход выполняется, если операнды не равны, результат не ноль(флаг нуля не установлен -> ZF = 0)
    
    ; Выход из программы
    mov rax, 60
    xor rdi, rdi ; 0 - успешное завершение
    syscall

; Функция для преобразования строки в число
; Вход: rsi - указатель на строку
; Выход: rax - число
str_to_int:
    xor rax, rax ; rax = 0 (результат)
    xor rcx, rcx ; rcx = 0 (индекс)
    xor r8, r8   ; r8 = 0 ("флаг" знака: 0 - плюс, 1 - минус)
    
    ; Проверяем первый символ на знак минус
    movzx rdx, byte [rsi]
    cmp dl, '-'
    jne .loop ; Если не минус, начинаем обработку
    
    mov r8, 1 ; Устанавливаем "флаг" отрицательного числа
    inc rcx   ; Пропускаем символ минуса

; Обрабатываем циклически цифры
.loop:
    movzx rdx, byte [rsi + rcx] ; Читаем один символ

    ; Проверяем достигли ли конца строки
    cmp dl, 10  ; '\n'
    je .check_sign
    test dl, dl   ; '\0'
    jz .check_sign
    cmp dl, ' ' ; пробел
    je .check_sign
    
    ; Проверяем ввод букв(вычитаем '9', т.е. 57 - крайний код, на котором заканчиваются цифры в ASCII)
    cmp dl, '9'
    jg letter_error

    ; Преобразуем символ в цифру(вычитаем '0', т.е. 48 - крайний код, с которого начинаются цифры в ASCII)
    sub dl, '0'
    
    ; rax = rax * 10 + новая цифра(таким образом устанавливаем цифру в свой разряд)
    shl rax, 1
    lea rax, [rax + rax*4]
    add rax, rdx
    
    inc rcx ; Смещаем индекс дальше
    jmp .loop ; Продолжаем цикл
    
.check_sign:
    ; Если число отрицательное, меняем знак
    test r8, r8 ; Побитовое И(единица даст единицу)
    jz .done
    neg rax ; Делаем число отрицательным

.done:
    ret ; Возврат из функции

; Функция для преобразования числа в строку
; Вход: rax - число, rdi - указатель на буфер
; Выход: rdx - длина строки
int_to_str:
    xor rcx, rcx ; rcx = 0 (индекс)
    xor r8, r8   ; r8 = 0 ("флаг" знака: 0 - плюс, 1 - минус)
    
    ; Проверяем, отрицательное ли число(первый бит - единица)
    test rax, rax
    jns .convert ; Если положительное, переходим к конвертации
    
    ; Число отрицательное
    mov r8, 1 ; Устанавливаем "флаг"
    neg rax ; Делаем число положительным для обработки
    
.convert:
    mov rbx, 10 ; Делитель
    
; Обрабатываем циклически цифры
.loop:
    xor rdx, rdx        ; Обнуляем rdx перед делением
    div rbx             ; rax = rax / 10, rdx = остаток(путём деления на 10 получаем самый первый разряд в рассматриваемой в данный момент целой части)
    add dl, '0'         ; Преобразуем цифру в символ(теперь добавляя 48)
    mov [rdi + rcx], dl ; Сохраняем символ
    inc rcx 
    
    test rax, rax ; Проверяем, все ли цифры обработаны(целая часть должна быть нулём)
    jnz .loop ; Если нет, то продолжаем цикл
    
    ; Если число было отрицательным, добавляем минус
    test r8, r8
    jz .reverse
    ; rcx после финальной итерации цикла показывает на байт за последним символом
    mov [rdi + rcx], byte '-'
    inc rcx ; Теперь rcx содержит длину строки
    
.reverse:
    ; Переворачиваем строку(т.к. первые разряды теперь стоят последними(т.е. в начале строки))
    mov rdx, rcx ; Сохраняем длину
    ; Задаём "указатели" для свопов
    dec rcx      ; rcx = последний индекс
    xor rbx, rbx ; rbx = первый индекс
    
.reverse_loop:
    ; Меняем местами символы(своп)
    mov r9b, [rdi + rbx]
    mov r10b, [rdi + rcx]
    mov [rdi + rbx], r10b
    mov [rdi + rcx], r9b
    
    ; Смещаем указатели
    inc rbx
    dec rcx

    ; Пока левый "указатель" меньше правого продолжаем цикл
    cmp rbx, rcx
    jl .reverse_loop

.done:
    ret ; Возврат из функции

; Функция для суммирования двух чисел
; Вход: rax - первое число, rbx - второе число
; Выход: rax - сумма
sum:
    ; Складываем числа
    add rax, rbx ; rax = rax + rbx
    ret

; Выход с ошибкой
exit_error:    
    mov rax, 60
    mov rdi, 1 ; Код возврата 1 (ошибка)
    syscall

; Выход с ошибкой из-за ввода буквы
letter_error:
    mov rax, 1 ; Системный вызов write
    mov rdi, 2 ; Файловый дескриптор stderr
    mov rsi, letter_error_string
    mov rdx, letter_error_string_length
    syscall

    mov rax, 60
    mov rdi, 1 ; Код возврата 1 (ошибка)
    syscall