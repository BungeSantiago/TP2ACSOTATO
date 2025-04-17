#include "ej1.h"
#include <string.h>
// Manejo de error si no se pudo reservar memoria

string_proc_list* string_proc_list_create(void) {
    string_proc_list* list = malloc(sizeof(string_proc_list));
    if (list == NULL) {
        return NULL; 
    }
    list->first = NULL;
    list->last = NULL;
    return list;
}

string_proc_node* string_proc_node_create(uint8_t type, char* hash){
	string_proc_node* node = malloc(sizeof(string_proc_node));
	if (node == NULL) {
		return NULL; // Manejo de error si no se pudo reservar memoria
	}
	node->next = NULL;
	node->previous = NULL;
	node->type = type;
	node->hash = hash; // Copia el hash a la memoria del nodo
	return node;
}

void string_proc_list_add_node(string_proc_list* list, uint8_t type, char* hash){
    if (list == NULL) {
        return; // Manejo de error si la lista es NULL
    }
	string_proc_node* node = string_proc_node_create(type, hash);
	if (node == NULL) {
		return; // Manejo de error si no se pudo crear el nodo
	}

	if (list->first == NULL) {
		list->first = node;
		list->last = node;
	} else {
		list->last->next = node;
		node->previous = list->last;
		list->last = node;
	}
	// Si la lista no está vacía, enlazamos el nuevo nodo al final
}

char* string_proc_list_concat(string_proc_list* list, uint8_t type, char* hash) {
    if (list == NULL || hash == NULL) return NULL;

    char* resultado = malloc(strlen(hash) + 1);
    if (resultado == NULL) return NULL;

    strcpy(resultado, hash);

    string_proc_node* actual = list->first;
    while (actual != NULL) {
        if (actual->type == type && actual->hash != NULL) {
            char* resultado_nuevo = str_concat(resultado, actual->hash);
            free(resultado);
            if (resultado_nuevo == NULL) return NULL;
            resultado = resultado_nuevo;
        }
        actual = actual->next;
    }

    return resultado;
}



/** AUX FUNCTIONS **/

void string_proc_list_destroy(string_proc_list* list){

	/* borro los nodos: */
	string_proc_node* current_node	= list->first;
	string_proc_node* next_node		= NULL;
	while(current_node != NULL){
		next_node = current_node->next;
		string_proc_node_destroy(current_node);
		current_node	= next_node;
	}
	/*borro la lista:*/
	list->first = NULL;
	list->last  = NULL;
	free(list);
}
void string_proc_node_destroy(string_proc_node* node){
	node->next      = NULL;
	node->previous	= NULL;
	node->hash		= NULL;
	node->type      = 0;			
	free(node);
}


char* str_concat(char* a, char* b) {
	int len1 = strlen(a);
    int len2 = strlen(b);
	int totalLength = len1 + len2;
    char *result = (char *)malloc(totalLength + 1); 
    strcpy(result, a);
    strcat(result, b);
    return result;  
}

void string_proc_list_print(string_proc_list* list, FILE* file){
        uint32_t length = 0;
        string_proc_node* current_node  = list->first;
        while(current_node != NULL){
                length++;
                current_node = current_node->next;
        }
        fprintf( file, "List length: %d\n", length );
		current_node    = list->first;
        while(current_node != NULL){
                fprintf(file, "\tnode hash: %s | type: %d\n", current_node->hash, current_node->type);
                current_node = current_node->next;
        }
}

