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

    ; FUNCIONES auxiliares
    extern malloc
    extern free
    extern strlen
    extern strcpy
    extern str_concat

; -------------------------------------------------------------------------
; string_proc_list_create_asm
;   string_proc_list* string_proc_list_create_asm(void)
; -------------------------------------------------------------------------
string_proc_list_create_asm:
    ; malloc(sizeof(string_proc_list))  → 2 punteros = 16 bytes
    mov     edi, 16
    call    malloc
    test    rax, rax
    je      .return_null_list

    ; inicializar campos: first = NULL, last = NULL
    mov     qword [rax + 0], 0
    mov     qword [rax + 8], 0
    ret

.return_null_list:
    xor     rax, rax
    ret

; -------------------------------------------------------------------------
; string_proc_node_create_asm
;   string_proc_node* string_proc_node_create_asm(uint8_t type, char* hash)
; -------------------------------------------------------------------------
string_proc_node_create_asm:
    ; guardar args
    mov     edx, edi        ; DL = type
    mov     rcx, rsi        ; RCX = hash pointer

    ; malloc(sizeof(string_proc_node)) = 32 bytes
    mov     edi, 32
    call    malloc
    test    rax, rax
    je      .return_null_node

    ; node->next     = NULL
    mov     qword [rax + 0], 0
    ; node->previous = NULL
    mov     qword [rax + 8], 0
    ; node->type     = type
    mov     byte  [rax + 16], dl
    ; node->hash     = hash
    mov     qword [rax + 24], rcx
    ret

.return_null_node:
    xor     rax, rax
    ret

; -------------------------------------------------------------------------
; string_proc_list_add_node_asm
;   void string_proc_list_add_node_asm(string_proc_list* list, uint8_t type, char* hash)
; -------------------------------------------------------------------------
string_proc_list_add_node_asm:
    push    rbx
    mov     rbx, rdi        ; RBX = list*

    ; if (list == NULL) return
    test    rbx, rbx
    je      .done_add

    ; llamar a string_proc_node_create_asm(type, hash)
    mov     edi, esi        ; edi = type
    mov     rsi, rdx        ; rsi = hash
    call    string_proc_node_create_asm
    test    rax, rax
    je      .done_add

    ; RAX = new node, RBX = list*
    ; si list->first == NULL
    mov     rcx, [rbx + 0]
    test    rcx, rcx
    je      .add_first

.non_empty_add:
    ; list->last->next = node
    mov     rcx, [rbx + 8]
    mov     [rcx + 0], rax
    ; node->previous = list->last
    mov     [rax + 8], rcx
    ; list->last = node
    mov     [rbx + 8], rax
    jmp     .done_add

.add_first:
    ; list->first = node
    mov     [rbx + 0], rax
    ; list->last = node
    mov     [rbx + 8], rax

.done_add:
    pop     rbx
    ret

; -------------------------------------------------------------------------
; string_proc_list_concat_asm
;   char* string_proc_list_concat_asm(string_proc_list* list, uint8_t type, char* hash)
; -------------------------------------------------------------------------
string_proc_list_concat_asm:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     rbx, rdi        ; list*
    mov     r12b, sil       ; type
    mov     r13, rdx        ; hash

    ; if (list == NULL || hash == NULL) return NULL
    test    rbx, rbx
    je      .return_null_concat
    test    r13, r13
    je      .return_null_concat

    ; resultado = malloc(strlen(hash) + 1)
    mov     rdi, r13
    call    strlen
    add     rax, 1
    mov     edi, eax
    call    malloc
    test    rax, rax
    je      .return_null_concat
    mov     r14, rax        ; r14 = resultado

    ; strcpy(resultado, hash)
    mov     rdi, r14
    mov     rsi, r13
    call    strcpy

    ; actual = list->first
    mov     r15, [rbx + 0]

.loop_concat:
    test    r15, r15
    je      .end_concat

    ; if (actual->type == type)
    mov     al, [r15 + 16]
    cmp     al, r12b
    jne     .next_node

    ; if (actual->hash != NULL)
    mov     rdx, [r15 + 24]
    test    rdx, rdx
    je      .next_node

    ; resultado_nuevo = str_concat(resultado, actual->hash)
    mov     rdi, r14
    mov     rsi, rdx
    call    str_concat
    test    rax, rax
    je      .return_null_concat
    ; free(old resultado)
    mov     rdx, r14
    mov     rdi, rdx
    call    free
    mov     r14, rax        ; r14 = nuevo resultado

.next_node:
    ; actual = actual->next
    mov     r15, [r15 + 0]
    jmp     .loop_concat

.end_concat:
    mov     rax, r14
    jmp     .epilogue

.return_null_concat:
    xor     rax, rax

.epilogue:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
