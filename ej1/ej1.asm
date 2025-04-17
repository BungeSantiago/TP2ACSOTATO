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
extern strlen
extern memcpy





string_proc_list_create_asm:
    push    rbp
    mov     rbp, rsp

    sub     rsp, 16                      ; reservo espacio en el stack
    mov     edi, 16                      ; tamaño de la lista
    call    malloc                       ; malloc(16) retorna rax que es la dirección
    mov     qword [rbp-8], rax           

    cmp     qword [rbp-8], 0             ; chequeo si malloc==NULL
    jne     .init_list                   ; si no es NULL

    mov     eax, 0                       ; si malloc falló, retorno NULL (rax = 0)
    jmp     .return

.init_list:
    mov     rax, qword [rbp-8]           ; rax = puntero a la lista
    mov     qword [rax], 0               ; first
    mov     rax, qword [rbp-8]           
    mov     qword [rax+8], 0             ; last
    mov     rax, qword [rbp-8]           ; puntero a la lista

.return:
    leave                                ; restauro rbp y rsp
    ret                                  




string_proc_node_create_asm:
    push    rbp
    mov     rbp, rsp

    sub     rsp, 32

    mov     eax, edi                      ; guardo type (edi) en al
    mov     qword [rbp-32], rsi           ; guardo hash (rsi)
    mov     byte [rbp-20], al             ; guardo type como byte

    cmp     qword [rbp-32], 0             ; si hash == NULL
    jne     .alloc_node
    mov     eax, 0                        ; retorno NULL
    jmp     .return

.alloc_node:
    mov     edi, 32                       ; tamaño del nodo
    call    malloc                        
    mov     qword [rbp-8], rax            ; guardo puntero a nodo

    cmp     qword [rbp-8], 0              ; si malloc falla
    jne     .init_node
    mov     eax, 0                        ; retorno NULL
    jmp     .return

.init_node:
    mov     rax, qword [rbp-8]
    movzx   edx, byte [rbp-20]            ; edx = type
    mov     byte [rax+16], dl             ; nodo->type = type

    mov     rax, qword [rbp-8]
    mov     rdx, qword [rbp-32]           ; rdx = hash
    mov     qword [rax+24], rdx           ; nodo->hash = hash

    mov     rax, qword [rbp-8]
    mov     qword [rax], 0                ; nodo->next = NULL

    mov     rax, qword [rbp-8]
    mov     qword [rax+8], 0              ; nodo->prev = NULL

    mov     rax, qword [rbp-8]            ; devuelvo nodo

.return:
    leave
    ret




string_proc_list_add_node_asm:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 48

    ; guardo parametros en variables locales
    mov     qword [rbp-24], rdi         ; lista
    mov     eax, esi                    ; type (en AL)
    mov     qword [rbp-40], rdx         ; hash
    mov     byte [rbp-28], al           ; type como byte

    ; chequeo si lista o hash son NULL
    cmp     qword [rbp-24], 0
    je      .return
    cmp     qword [rbp-40], 0
    je      .return

    ; creo nodo
    movzx   eax, byte [rbp-28]          ; cargo type
    mov     rdx, qword [rbp-40]         ; rdx = hash
    mov     rsi, rdx                    ; rsi = hash
    mov     edi, eax                    ; edi = type
    call    string_proc_node_create_asm
    mov     qword [rbp-8], rax          ; guardo nuevo nodo

    ; chequeo si el nodo se creo bien
    cmp     qword [rbp-8], 0
    je      .return

    ; if (list->first == NULL)
    mov     rax, qword [rbp-24]         ; rax = lista
    mov     rax, qword [rax]            ; rax = lista->first
    test    rax, rax
    jne     .append_to_end              ; si no es NULL, agrego al final

    ; lista vacía: first = last = new_node
    mov     rax, qword [rbp-24]         ; rax = lista
    mov     rdx, qword [rbp-8]          ; rdx = new_node
    mov     qword [rax], rdx            ; lista->first = new_node

    mov     rax, qword [rbp-24]
    mov     rdx, qword [rbp-8]
    mov     qword [rax+8], rdx          ; lista->last = new_node
    jmp     .return

.append_to_end:
    ; inserto al final de la lista
    mov     rax, qword [rbp-24]
    mov     rax, qword [rax+8]          ; rax = lista->last
    mov     rdx, qword [rbp-8]          ; rdx = new_node
    mov     qword [rax], rdx            ; last->next = new_node

    mov     rax, qword [rbp-24]
    mov     rdx, qword [rax+8]          ; rdx = lista->last
    mov     rax, qword [rbp-8]          ; rax = new_node
    mov     qword [rax+8], rdx          ; new_node->prev = last

    mov     rax, qword [rbp-24]
    mov     rdx, qword [rbp-8]
    mov     qword [rax+8], rdx          ; lista->last = new_node

.return:
    leave
    ret




string_proc_list_concat_asm:
; rdi = list, rsi = type, rdx = hash
    push    rbp
    mov     rbp, rsp
    sub     rsp, 96                     ; reservo espacio en el stack

    ; Guardar argumentos
    mov     qword [rbp-72], rdi         ; list
    mov     eax, esi                    ; type en al
    mov     qword [rbp-88], rdx         ; hash
    mov     byte [rbp-76], al           ; guardo type

    ; if( list == NULL || hash == NULL )
    cmp     qword [rbp-72], 0
    je      .null_or_error
    cmp     qword [rbp-88], 0
    jne     .not_null

.null_or_error:
    mov     eax, 0
    jmp     .return

.not_null:
    ; detecto si hay ciclos en la lista
    mov     rax, qword [rbp-72]
    mov     rax, qword [rax]            ; rax = list->first
    mov     qword [rbp-8], rax          ; slow = first
    mov     qword [rbp-16], rax         ; fast = first

.loop_detect_start:
    cmp     qword [rbp-16], 0
    je      .no_loop

    mov     rax, qword [rbp-16]
    mov     rax, qword [rax]            ; avanza fast una vez
    test    rax, rax
    je      .no_loop

    mov     qword [rbp-16], rax
    mov     rax, qword [rbp-16]
    mov     rax, qword [rax]            ; avanza fast otra vez
    mov     qword [rbp-16], rax

    ; avanza slow una vez
    mov     rax, qword [rbp-8]
    mov     rax, qword [rax]
    mov     qword [rbp-8], rax

    ; comparo punteros
    mov     rax, qword [rbp-8]
    cmp     rax, qword [rbp-16]
    jne     .loop_detect_start

    ; si son iguales entonces tengo un ciclo
    mov     eax, 0
    jmp     .return

.no_loop:
    ; copio el hash
    mov     rax, qword [rbp-88]
    mov     rdi, rax
    call    strlen
    mov     qword [rbp-48], rax         ; len = strlen(hash)
    mov     rax, qword [rbp-48]
    add     rax, 1                      ; espacio para '\0'
    mov     rdi, rax
    call    malloc
    mov     qword [rbp-24], rax         ; nueva copia

    cmp     qword [rbp-24], 0
    jne     .copy_hash

    mov     eax, 0                      ; malloc falla
    jmp     .return

.copy_hash:
    mov     rax, qword [rbp-48]
    lea     rdx, [rax+1]
    mov     rcx, qword [rbp-88]         ; src = hash
    mov     rax, qword [rbp-24]
    mov     rsi, rcx
    mov     rdi, rax
    call    memcpy

    ; chequeo la copia
    cmp     qword [rbp-24], 0
    jne     .start_concat

    mov     eax, 0
    jmp     .return

.start_concat:
    ; obtengo el largo actual
    mov     rax, qword [rbp-24]
    mov     rdi, rax
    call    strlen
    mov     qword [rbp-32], rax         ; len acumulado

    ; itero la lista
    mov     rax, qword [rbp-72]
    mov     rax, qword [rax]            ; nodo actual = list->first
    mov     qword [rbp-40], rax

.iterate_nodes:
    cmp     qword [rbp-40], 0
    je      .done_iteration

    ; comparo tipos
    mov     rax, qword [rbp-40]
    movzx   eax, byte [rax+16]          ; node->type
    cmp     byte [rbp-76], al
    jne     .next_node

    ; if( node->hash != NULL )
    mov     rax, qword [rbp-40]
    mov     rax, qword [rax+24]
    test    rax, rax
    je      .next_node

    ; largo del hash del nodo
    mov     rdi, rax
    call    strlen
    mov     qword [rbp-56], rax

    ; chequeo que concatenar no supere 1MB
    mov     rdx, qword [rbp-32]         ; largo actual
    mov     rax, qword [rbp-56]         ; largo nuevo
    add     rax, rdx
    cmp     rax, 1048576
    jbe     .safe_to_concat

    ; si se pasa, libero y salgo
    mov     rax, qword [rbp-24]
    mov     rdi, rax
    call    free
    mov     eax, 0
    jmp     .return

.safe_to_concat:
    mov     rax, qword [rbp-40]
    mov     rdx, qword [rax+24]         ; hash del nodo
    mov     rax, qword [rbp-24]         ; string acumulada
    mov     rsi, rdx
    mov     rdi, rax
    call    str_concat
    mov     qword [rbp-64], rax

    cmp     qword [rbp-64], 0
    jne     .concat_success

    ; si falla, libero y salgo
    mov     rax, qword [rbp-24]
    mov     rdi, rax
    call    free
    mov     eax, 0
    jmp     .return

.concat_success:
    ; libero string viejo y actualizo el puntero
    mov     rax, qword [rbp-24]
    mov     rdi, rax
    call    free
    mov     rax, qword [rbp-64]
    mov     qword [rbp-24], rax

    ; actualizo el largo acumulado
    mov     rax, qword [rbp-56]
    add     qword [rbp-32], rax

.next_node:
    mov     rax, qword [rbp-40]
    mov     rax, qword [rax]
    mov     qword [rbp-40], rax
    jmp     .iterate_nodes

.done_iteration:
    mov     rax, qword [rbp-24]         ; devuelvo el string concatenado

.return:
    leave
    ret