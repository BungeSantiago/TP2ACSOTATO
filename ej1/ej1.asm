; /** defines bool y puntero **/
%define NULL 0
%define TRUE 1
%define FALSE 0

section .data

section .text

global string_proc_list_create_asm
global string_proc_node_create_asm
global string_proc_list_add_node_asm
global string_proc_list_concat_asm

; FUNCIONES auxiliares que pueden llegar a necesitar:
extern malloc
extern free
extern str_concat


string_proc_list_create_asm:
    mov rdi, 16            ; sizeof(string_proc_list) = 2 punteros = 16 bytes
    call malloc
    test rax, rax
    je .return_null_list

    ; inicializar list->first = NULL y list->last = NULL
    mov qword [rax], NULL
    mov qword [rax + 8], NULL
    ret

.return_null_list:
    xor rax, rax
    ret

string_proc_node_create_asm:
    ; Entrada:
    ;   rdi = type (uint8_t)
    ;   rsi = hash (char*)

    mov rdx, rdi           ; guardar 'type' en rdx
    mov rdi, 32            ; tamaño del nodo
    call malloc
    test rax, rax
    je .return_null_node

    ; rax = puntero a nodo
    mov qword [rax], NULL          ; next
    mov qword [rax + 8], NULL      ; previous
    mov byte  [rax + 16], dl       ; type

    ; strdup(hash)
    mov rdi, rsi                   ; strdup(hash)
    call strdup
    mov [rax + 24], rax            ; hash

    ; devolver nodo
    mov rax, rax
    ret

.return_null_node:
    xor rax, rax
    ret

string_proc_list_add_node_asm:
    ; Entrada:
    ;   rdi = list
    ;   sil = type
    ;   rdx = hash

    ; Guardar argumentos
    push rdi            ; list
    push rdx            ; hash
    movzx rsi, sil      ; pasar type como 64-bit limpio
    mov rdi, rsi        ; rdi = type
    pop rsi             ; rsi = hash
    call string_proc_node_create_asm
    test rax, rax
    je .ret_void        ; si no se pudo crear, salir

    ; rax = nuevo nodo
    pop rdi             ; recuperar list

    mov rcx, [rdi]      ; rcx = list->first
    test rcx, rcx
    je .lista_vacia

    ; lista no vacía
    mov rdx, [rdi + 8]      ; rdx = list->last
    mov [rdx], rax          ; last->next = nodo
    mov [rax + 8], rdx      ; nodo->previous = last
    mov [rdi + 8], rax      ; list->last = nodo
    ret

.lista_vacia:
    mov [rdi], rax          ; list->first = nodo
    mov [rdi + 8], rax      ; list->last = nodo
    ret

.ret_void:
    add rsp, 8              ; limpiar stack si hicimos push sin pop
    ret

; char* string_proc_list_concat_asm(string_proc_list* list, uint8_t type, char* hash)
; Entradas:
;   rdi = list
;   sil = type
;   rdx = hash
; Salida:
;   rax = puntero a string concatenado

global string_proc_list_concat_asm
extern malloc
extern free
extern strdup
extern str_concat

section .text

string_proc_list_concat_asm:
    push rbx              ; salvamos rbx porque lo vamos a usar
    push r12              ; r12 = result
    push r13              ; r13 = current
    push r14              ; r14 = type

    ; Guardamos los argumentos
    mov r14b, sil         ; type en r14b
    mov r13, rdi          ; r13 = list
    mov rsi, rdx          ; rsi = hash (para strdup o malloc)

    ; === Inicializar result ===
    test rsi, rsi         ; ¿hash == NULL?
    je .malloc_empty

    ; result = strdup(hash)
    mov rdi, rsi
    call strdup
    jmp .store_result

.malloc_empty:
    mov rdi, 1
    call malloc
    test rax, rax
    je .done              ; malloc falló
    mov byte [rax], 0     ; result[0] = '\0'

.store_result:
    mov r12, rax          ; r12 = result

    ; === if (list != NULL) ===
    test r13, r13
    je .done

    mov r13, [r13]        ; r13 = list->first (current)

.loop:
    test r13, r13
    je .done

    movzx rbx, byte [r13 + 16] ; rbx = current->type
    cmp bl, r14b               ; ¿type coincide?
    jne .next_node

    ; temp = str_concat(result, current->hash)
    mov rdi, r12               ; rdi = result
    mov rsi, [r13 + 24]        ; rsi = current->hash
    call str_concat            ; devuelve rax
    mov rdi, r12               ; rdi = old result
    call free                  ; free(result)
    mov r12, rax               ; result = temp

.next_node:
    mov r13, [r13]             ; current = current->next
    jmp .loop

.done:
    mov rax, r12               ; return result

    pop r14
    pop r13
    pop r12
    pop rbx
    ret

