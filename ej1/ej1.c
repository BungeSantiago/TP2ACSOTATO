#include "ej1.h"

string_proc_list* string_proc_list_create(void) {
    string_proc_list* list = malloc(sizeof(string_proc_list));
    if (list == NULL) {
        return NULL; // Manejo de error si no se pudo reservar memoria
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
	node->hash = strdup(hash); // Copia el hash a la memoria del nodo
	return node;
}

void string_proc_list_add_node(string_proc_list* list, uint8_t type, char* hash){
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
    // Inicializamos la cadena resultado:
    // Si hash no es NULL, se utiliza strdup para copiar su contenido.
    // Si es NULL, se reserva un espacio para una cadena vacía.
    char* result;
    if (hash != NULL) {
        result = strdup(hash);
    } else {
        result = malloc(1);
        if (result) {
            result[0] = '\0';
        }
    }
    
    // Si la lista es válida, recorremos cada nodo
    if (list != NULL) {
        string_proc_node* current = list->first;
        while (current != NULL) {
            // Solo procesamos los nodos que tengan el tipo especificado.
            if (current->type == type) {
                // Concatenamos la cadena acumulada con la cadena del nodo.
                char* temp = str_concat(result, current->hash);
                // Liberamos la memoria de la cadena previa para evitar fugas.
                free(result);
                result = temp;
            }
            current = current->next;
        }
    }
    
    // Retornamos la cadena resultado, que deberá ser liberada por el usuario.
    return result;
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

