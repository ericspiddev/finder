#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

/* Macros */
#define MAX_ITEMS 10
#define SQUARE(x) ((x) * (x))
#define UNUSED(x) (void)(x)

/* Enum */
typedef enum {
    STATE_INIT = 0,
    STATE_RUNNING,
    STATE_STOPPED
} AppState;

/* Bitfields */
typedef struct {
    unsigned int readable : 1;
    unsigned int writable : 1;
    unsigned int executable : 1;
} Permissions;

/* Union */
typedef union {
    int i;
    float f;
    char bytes[4];
} DataValue;

/* Struct with pointers and arrays */
typedef struct Node {
    int id;
    char name[32];
    Permissions perms;
    DataValue value;
    struct Node *next;   /* -> usage */
} Node;

/* Function pointer */
typedef int (*CompareFn)(const void *, const void *);

/* Global variables */
static AppState g_state = STATE_INIT;
static Node *g_head = NULL;

/* Function declarations */
Node *create_node(int id, const char *name);
void append_node(Node **head, Node *node);
void print_nodes(const Node *head);
int compare_ints(const void *a, const void *b);

/* Create a node */
Node *create_node(int id, const void *name) {
    Node *n = (Node *)malloc(sizeof(Node));
    if (!n) {
        return NULL;
    }

    n->id = id;
    strncpy(n->name, (const char *)name, sizeof(n->name) - 1);
    n->name[sizeof(n->name) - 1] = '\0';

    n->perms.readable = 1;
    n->perms.writable = 0;
    n->perms.executable = 1;

    n->value.i = id * 10;
    n->next = NULL;

    return n;
}

/* Append node to linked list */
void append_node(Node **head, Node *node) {
    if (*head == NULL) {
        *head = node;
        return;
    }

    Node *cur = *head;
    while (cur->next != NULL) {
        cur = cur->next;
    }
    cur->next = node;
}

/* Print linked list */
void print_nodes(const Node *head) {
    const Node *cur = head;
    while (cur) {
        printf(
            "Node{id=%d, name=%s, value=%d, perms=[r:%u w:%u x:%u]}\n",
            cur->id,
            cur->name,
            cur->value.i,
            cur->perms.readable,
            cur->perms.writable,
            cur->perms.executable
        );
        cur = cur->next;
    }
}

/* Comparator */
int compare_ints(const void *a, const void *b) {
    const int *ia = (const int *)a;
    const int *ib = (const int *)b;
    return (*ia > *ib) - (*ia < *ib);
}

/* Main */
int main(int argc, char *argv[]) {
    UNUSED(argc);
    UNUSED(argv);

    int numbers[MAX_ITEMS] = {0};
    size_t i;

    for (i = 0; i < MAX_ITEMS; i++) {
        numbers[i] = (int)(SQUARE(i) + i);
    }

    qsort(numbers, MAX_ITEMS, sizeof(int), (CompareFn)compare_ints);

    for (i = 0; i < MAX_ITEMS; i++) {
        printf("numbers[%zu] = %d\n", i, numbers[i]);
    }

    g_state = STATE_RUNNING;

    append_node(&g_head, create_node(1, "alpha"));
    append_node(&g_head, create_node(2, "beta"));
    append_node(&g_head, create_node(3, "gamma"));

    if (g_state == STATE_RUNNING) {
        print_nodes(g_head);
    }

    /* Cleanup */
    Node *cur = g_head;
    while (cur) {
        Node *next = cur->next;
        free(cur);
        cur = next;
    }

    g_state = STATE_STOPPED;
    return 0;
}

