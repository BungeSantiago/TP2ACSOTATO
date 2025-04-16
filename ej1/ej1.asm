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
    endbr64                  ; instrucción CET (opcional)
    push    rbp
    mov     rbp, rsp

    ; --- malloc(sizeof(string_proc_list)) ---
    mov     edi, 16          ; tamaño: 2 punteros = 16 bytes
    call    malloc
    test    rax, rax
    je      .L_null          ; si RAX==0, reserva falló

    ; --- list->first = NULL ---
    mov     QWORD [rax], 0

    ; --- list->last = NULL ---
    mov     QWORD [rax + 8], 0

    jmp     .L_end

.L_null:
    xor     rax, rax         ; devuelve NULL

.L_end:
    pop     rbp
    ret

    
string_proc_list_add_node:
    endbr64                  ; instrucción CET (opcional)
    push    rbp
    mov     rbp, rsp

    ; 1) if (list == NULL) return;
    test    rdi, rdi
    je      .L_return

    ; 2) node = string_proc_node_create(type, hash);
    ;    argumentos para la llamada:
    ;      edi = (uint32_t) type  ← viene en sil (RSI low byte)
    ;      rsi = hash pointer    ← viene en rdx
    movzx   edi, sil          ; edi = zero-extend(type)
    mov     rsi, rdx          ; rsi = hash
    call    string_proc_node_create
    test    rax, rax
    je      .L_return         ; si node == NULL, salimos

    ; 3) if (list->first == NULL) { … } else { … }
    mov     rcx, [rdi]        ; rcx = list->first
    test    rcx, rcx
    jne     .L_append         ; si no está vacío, ir a enlazar al final

    ; 3a) lista vacía:
    ;     list->first = node;
    ;     list->last  = node;
    mov     [rdi], rax        ; list->first = node
    mov     [rdi + 8], rax    ; list->last  = node
    jmp     .L_return

.L_append:
    ; 3b) lista no vacía: enlazamos al final
    ;    list->last->next     = node;
    ;    node->previous       = list->last;
    ;    list->last           = node;
    mov     rcx, [rdi + 8]    ; rcx = list->last
    mov     [rcx], rax        ; rcx->next = node
    mov     [rax + 8], rcx    ; node->previous = rcx
    mov     [rdi + 8], rax    ; list->last = node

.L_return:
    pop     rbp
    ret

string_proc_list_add_node:
    endbr64                    ; CET entry (omit if you don't use CET)
    push    rbp
    mov     rbp, rsp
    push    rbx                ; salvamos RBX (callee‑saved), lo usaremos para “list”

    ; ——————————————————————————————
    ; 1) if (list == NULL) return;
    ;    list está en RDI
    mov     rbx, rdi           ; rbx ← list
    test    rbx, rbx
    je      .L_return

    ; ——————————————————————————————
    ; 2) node = string_proc_node_create(type, hash);
    ;    preparar argumentos para la llamada:
    ;      edi ← type  (desde RSI)
    ;      rsi ← hash  (desde RDX)
    mov     edi, esi           ; edi ← (uint32_t) type
    mov     rsi, rdx           ; rsi ← hash (char*)
    call    string_proc_node_create
    test    rax, rax           ; ¿node == NULL?
    je      .L_return

    ; ——————————————————————————————
    ; 3) if (list->first == NULL) { … } else { … }
    ;    list->first está en [rbx + 0]
    mov     rcx, [rbx]         ; rcx ← list->first
    test    rcx, rcx
    jne     .L_append

    ; 3a) lista VACÍA:
    ;     list->first = node;
    ;     list->last  = node;
    mov     [rbx], rax         ; list->first = node
    mov     [rbx + 8], rax     ; list->last  = node
    jmp     .L_return

.L_append:
    ; 3b) lista NO vacía:
    ;     list->last->next = node;
    ;     node->previous   = list->last;
    ;     list->last       = node;
    mov     rcx, [rbx + 8]     ; rcx ← list->last
    mov     [rcx], rax         ; rcx->next = node
    mov     [rax + 8], rcx     ; node->previous = rcx
    mov     [rbx + 8], rax     ; list->last = node

.L_return:
    pop     rbx
    pop     rbp
    ret
    
string_proc_list_concat:
    endbr64
    push    rbp
    mov     rbp, rsp
    push    rbx            ; callee‑saved para 'list'
    push    r12            ; callee‑saved para 'type'
    push    r13            ; callee‑saved para 'resultado'

    ; 1) if (list==NULL || hash==NULL) return NULL;
    mov     rbx, rdi       ; rbx = list
    test    rbx, rbx
    je      .L_ret_null
    test    rdx, rdx       ; rdx = hash
    je      .L_ret_null

    ; 2) guardamos type en r12
    movzx   r12, sil       ; r12 = (uint32_t) type

    ; 3) malloc(strlen(hash)+1)
    mov     rdi, rdx       ; arg strlen = hash
    call    strlen
    add     rax, 1
    mov     rdi, rax       ; arg malloc = tamaño
    call    malloc
    test    rax, rax
    je      .L_ret_null
    mov     r13, rax       ; r13 = resultado

    ; 4) strcpy(resultado, hash)
    mov     rdi, r13
    mov     rsi, rdx
    call    strcpy

    ; 5) actual = list->first
    mov     rcx, [rbx]     ; offset 0 = first

.L_loop:
    test    rcx, rcx
    je      .L_done

    ; if (actual->type == type)
    mov     dl, [rcx + 24] ; offset 24 = type
    cmp     dl, r12b
    jne     .L_next

    ; if (actual->hash != NULL)
    mov     rsi, [rcx + 16] ; offset 16 = hash pointer
    test    rsi, rsi
    je      .L_next

    ; nuevo = str_concat(resultado, actual->hash)
    mov     rdi, r13        ; primer arg = resultado
    ; rsi ya = actual->hash
    call    str_concat

    ; free(old resultado)
    mov     rdi, r13
    call    free

    ; si falló la concatenación
    test    rax, rax
    je      .L_ret_null

    ; resultado = nuevo
    mov     r13, rax

.L_next:
    mov     rcx, [rcx]      ; actual = actual->next (offset 0)
    jmp     .L_loop

.L_done:
    mov     rax, r13        ; devolver resultado
    jmp     .L_epilogue

.L_ret_null:
    xor     rax, rax        ; devolver NULL

.L_epilogue:
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret
