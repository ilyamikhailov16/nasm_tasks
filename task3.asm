%define STRING_MAX_SIZE 100

global _start

section .bss
    input_string resb STRING_MAX_SIZE  ; Резервируем память под строку пользователя
    output_string resb STRING_MAX_SIZE ; Резервируем память под строку для вывода

section .text
_start:
    ; Читаем строку от пользователя
    xor rax, rax ; Системный вызов read(0)
    xor rdi, rdi ; Файловый дескриптор stdin(0)
    mov rsi, input_string
    mov rdx, STRING_MAX_SIZE
    syscall
    
    test rax, rax
    js exit_error ; Если RAX < 0, произошла ошибка

    ; rax содержит количество прочитанных байтов
    mov rdx, rax 

    cmp byte [input_string + rdx - 1], 10 ; Проверяем является ли последний символ переносом строки
    jne skip_dec
  
    dec rdx ; Уменьшаем длину, чтобы не учитывать '\n'
    
skip_dec:
    ; Вызов функции для записи в output_string перевёрнутой строки(кладём на стек адрес возврата) 
    mov rdi, output_string
    call reverse ; rdx - длина строки, rsi - адрес исходной строки, rdi - адрес буфера для записи
    
    ; Добавляем символ переноса строки в конец
    mov [output_string + rdx], byte 10
    inc rdx
    
    ; Выводим результат
    mov rax, 1 ; Системный вызов write
    mov rdi, 1 ; Файловый дескриптор stdout
    mov rsi, output_string
    ; rdx уже содержит длину строки(с учётом '\n')
    syscall

    test rax, rax
    js exit_error ; Если RAX < 0, произошла ошибка

    ; Если записано не все, то тоже вернём ошибку
    cmp rax, rdx
    jne exit_error ; Переход выполняется, если операнды не равны, результат не ноль(флаг нуля не установлен -> ZF = 0)
    
    ; Завершение программы без ошибок
    mov rax, 60 ; Системный вызов exit
    xor rdi, rdi  ; Корректное завершение(0)
    syscall

; Выход с ошибкой
exit_error:    
    mov rax, 60
    mov rdi, 1 ; Код возврата 1 (ошибка)
    syscall

; Функция для разворота строки
; Вход: rdx - длина строки, rsi - адрес исходной строки, rdi - адрес буфера для записи
; Выход: перевернутая строка, записанная в буфер output_string
reverse:
    mov r8, rdx
    xor rdx, rdx ; Индекс для записи в начало output_string 
    dec r8 ; Индекс последнего элемента из input_string(rdx - 1)

; Цикл для записи значений из input_string в output_string
.loop:
    ; Копируем байт из input_string в output_string
    mov r10, [rsi + r8]  ; Читаем байт
    mov [rdi + rdx], r10 ; Записываем байт
    
    ; Переходим к следующим позициям
    inc rdx
    dec r8
    jns .loop; Продолжаем цикл пока не все элементы обработаны
    
; Завершение цикла(и возврат из функции)
.end_loop:
    ret ; Снимаем адрес возврата со стека и добавляем его в счётчик команд