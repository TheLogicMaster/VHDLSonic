/*  LM-8 backend for vbcc
    (c) Justin Marentette 2021

*/

#include "supp.h"

static char FILE_[] = __FILE__;

/*  Public data that MUST be there.                             */

/* Name and copyright. */
char cg_copyright[] = "vbcc VHDLSonic code-generator V0.1 (c) in 2021 by Justin Marentette";

/*  Commandline-flags the code-generator accepts:
    0: just a flag
    VALFLAG: a value must be specified
    STRINGFLAG: a string can be specified
    FUNCFLAG: a function will be called
    apart from FUNCFLAG, all other versions can only be specified once */
int g_flags[MAXGF] = {0};

/* the flag-name, do not use names beginning with l, L, I, D or U, because
   they collide with the frontend */
char *g_flags_name[MAXGF] = {""};

/* the results of parsing the command-line-flags will be stored here */
union ppi g_flags_val[MAXGF];

/*  Alignment-requirements for all types in bytes.              */
zmax align[MAX_TYPE + 1];

/*  Alignment that is sufficient for every object.              */
zmax maxalign;

/*  CHAR_BIT for the target machine.                            */
zmax char_bit;

/*  sizes of the basic types (in bytes) */
zmax sizetab[MAX_TYPE + 1];

/*  Minimum and Maximum values each type can have.              */
/*  Must be initialized in init_cg().                           */
zmax t_min[MAX_TYPE + 1];
zumax t_max[MAX_TYPE + 1];
zumax tu_max[MAX_TYPE + 1];

/*  Names of all registers. will be initialized in init_cg(),
    register number 0 is invalid, valid registers start at 1 */
char *regnames[MAXR + 1] = {
        "noreg", "r0", "r1", "r2", "r3", "r4", "r5", "r6", "r7",
        "r8", "r9", "r10", "r11", "r12", "r13", "fp", "sp"
};

/*  The Size of each register in bytes.                         */
zmax regsize[MAXR + 1];

/*  a type which can store each register. */
struct Typ *regtype[MAXR + 1];

/*  regsa[reg]!=0 if a certain register is allocated and should */
/*  not be used by the compiler pass.                           */
int regsa[MAXR + 1];

/*  Specifies which registers may be scratched by functions.    */
int regscratch[MAXR + 1];


/****************************************/
/*  Private data and functions.         */
/****************************************/

/* alignment of basic data-types, used to initialize align[] */
static long malign[MAX_TYPE + 1] = {
        1, 1, 2, 4, 4, 4, 1, 1, 1, 1, 4, 1, 1, 1, 4, 1, 1, 1
};

/* sizes of basic data-types, used to initialize sizetab[] */
zmax msizetab[MAX_TYPE + 1] = {
        0,    /* 0: unused */
        1,    /* 1: CHAR */
        2,    /* 2: SHORT */
        4,    /* 3: INT */
        4,    /* 4: LONG */
        8,  /* 5: LLONG */
        0,    /* 6: FLOAT */
        0,    /* 7: DOUBLE */
        0,  /* 8: LDOUBLE */
        0,    /* 9: VOID */
        4,    /* 10: POINTER */
        0,    /* 11: ARRAY */
        0,    /* 12: STRUCT */
        0,    /* 13: UNION */
        4,    /* 14: ENUM */
        0,    /* 15: FUNKT */
};

static struct Typ ityp = {INT};

// Suffixes for load and store instructions by byte count
static char memory_suffixes[5] = {'?', 'b', 'w', '?', 'r'};

// Interrupts
#define INTERRUPT_COUNT 8
static char *interrupt_names[INTERRUPT_COUNT] = {
        "reset", "exception", "vblank", "hblank", "timer", "interrupt5", "interrupt6", "interrupt7"
};
static int interrupts[8] = {};

// Boolean for genreating header once
static int headerGen;

// The current section, 1 for data
static int section;

// The last variable head generated
static struct Var *lastVarHeadVar;

// Whether the last variable head has been created
static int lastVarHeadCreated;

// Whether the last compare instruction was signed or not
static int lastCompareSigned;

// The last C line of code
static char *lastCodeFile;
static int lastCodeLine;

// Linked list for storing variable initialization data
static struct VariableInit {
    char *variable;
    int size;
    unsigned int value;
    struct VariableInit *next;
} *variableInit;

// Linked list for Assembly includes
static struct Include {
    char *path;
    struct Include *next;
} *includes;

// Linked list for local variables for the current function
static struct LocalVariable {
    Var *var;
    struct LocalVariable *next;
} *localVariables;

// The last function entered
static char *lastFunction;

#define ISCHAR(t) ((t&NQ)==CHAR)
#define ISSHORT(t) ((t&NQ)==SHORT)
#define ISLONG(t) ((t&NQ)==LONG||(t&NQ)==INT||(t&NQ)==POINTER)
#define ISLLONG(t) ((t&NQ)==LLONG)

// Emit a comment containing the IC
void emit_ic_comment(FILE *f, struct IC *ic) {
    emit_flush(f);
    fprintf(f, "; ");
    printic(f, ic);
}

// Get a byte particular byte from a zmax value
int get_byte(zmax val, int byte) {
    return (val >> (byte * 8)) & 0xFF;
}

// Switch code sections if not in the desired one
void ensure_section(FILE *f, int dataSection) {
    if (section != dataSection)
        emit(f, "\t%s\n", dataSection == 0 ? "rodata" : "data");
    section = dataSection;
}

// Returns the id of an interrupt if name is valid
unsigned int check_interrupts(char *name) {
    for (int i = 1; i < INTERRUPT_COUNT; i++)
        if (!strcmp(name, interrupt_names[i])) {
            interrupts[i] = 1;
            return i;
        }
    return 0;
}

// Create the assembler file header code if not created already
void header(FILE *f) {
    if (headerGen)
        return;

    emit(f, "; Generated VHDLSonic Assembly Program\n\n");
    emit(f, "; Interrupt vector jump table\n");
    emit(f, "\tjmp _initialize\n");
    for (int i = 1; i < INTERRUPT_COUNT; i++)
        emit(f, "\tjmp %s\n", interrupt_names[i]);
    emit(f, "\n");

    emit(f, "\tinclude \"libraries/Sonic.asm\"\n");
    emit(f, "\tinclude \"libraries/Math.asm\"\n\n");

    headerGen = 1;
}

void emit_var_info(FILE *f, Var *v) {
    if (v->storage_class == STATIC)
        emit(f, "label%d:", v->offset);
    else
        emit(f, "%s:", v->identifier);
            
    typfl t = v->vtyp->next ? v->vtyp->next->flags : v->vtyp->flags;
    
    switch (t & NQ) {
        case CHAR:
        case SHORT:
        case INT:
        case LONG:
            emit(f, "%c%u", t & UNSIGNED ? 'u' : 'i', sizetab[t & NQ]);
            break;
        default:
            emit(f, "?");
            // printf("Unsupported debug symbol variable type: %i\n", t & NQ);
            break;
    }

    switch (v->vtyp->flags & NQ) {
        case ARRAY:
            emit(f, "[%i]", v->vtyp->size);
            break;
        case POINTER:
            emit(f, "*");
            break;
        default:
            break;
    }

    emit(f, ":L%i@%s\n", v->line, v->filename);
}

// Emit comment for local variable if not recorded yet
void record_local_variable(FILE *f, int size, Var *var) {
    if (!var || !var->identifier || strlen(var->identifier) == 0)
        return;
    struct LocalVariable *variable = mymalloc(sizeof(struct LocalVariable));
    variable->next = NULL;
    variable->var = var;
    if (localVariables) {
        struct LocalVariable *last = localVariables;
        while(last) {
            if (!strcmp(last->var->identifier, var->identifier) && last->var->line == var->line)
                return;
            last = last->next;
        }
        last = localVariables;
        while(last->next)
            last = last->next;
        last->next = variable;
    } else
        localVariables = variable;
    emit(f, "; #LOCAL:%s:%i:", lastFunction, var->offset - (var->offset < 0 ? 8 - 2 * (4 - size) : 0));
    emit_var_info(f, var);
}

// Load address of object into register
void load_address(FILE *f, int size, int reg, obj o) {
    if (o.flags & KONST) {
        emit(f, "\tldr r%i,$%x\n", reg, o.val.vint);
        return;
    }
    if (o.v->storage_class == AUTO || o.v->storage_class == REGISTER) {
        emit(f, "\ttfr r%i,fp\n", reg);
        emit(f, "\tadd r%i,%i\n", reg, o.v->offset - (o.v->offset < 0 ? 8 - 2 * (4 - size) : 0) + o.val.vmax);
        record_local_variable(f, size, o.v);
    } else {
        if (o.v->storage_class == STATIC)
            emit(f, "\tldr r%i,label%i\n", reg, o.v->offset);
        else
            emit(f, "\tldr r%i,%s\n", reg, o.v->identifier);
        if (o.val.vmax)
            emit(f, "\tadd r%i,%i\n", reg, o.val.vint);
    }
}

// Get the register with the parameter
// Loads the value into a temp register if needed
int get_param_reg(FILE *f, int size, int tempReg, obj q) {
    if (q.flags & REG && !(q.flags & DREFOBJ))
        return q.reg - 1;
    if (q.flags & KONST) {
        if (q.flags & DREFOBJ)
            emit(f, "\tld%c r%i,[$%x]\n", memory_suffixes[size], tempReg, q.val.vuint);
        else
            emit(f, "\tldr r%i,$%x\n", tempReg, q.val.vuint);
    } else if (q.flags & VARADR)
        load_address(f, size, tempReg, q);
    else if (q.flags & DREFOBJ || q.val.vmax) {
        if (q.flags & REG) {
            emit(f, "\ttfr r%i,r%i\n", tempReg, q.reg - 1);
            if (q.val.vmax)
                emit(f, "\tadd r%i,%i\n", tempReg, q.val.vint);
        } else
            load_address(f, 4, tempReg, q);
        if (q.flags & DREFOBJ && !(q.flags & REG))
            emit(f, "\tldr r%i,r%i,0\n", tempReg, tempReg);
        emit(f, "\tld%c r%i,r%i,0\n", memory_suffixes[size], tempReg, tempReg);
    } else {
        if (q.v->storage_class == AUTO || q.v->storage_class == REGISTER) {
            emit(f, "\tld%c r%i,fp,%i\n", memory_suffixes[size], tempReg,
                 q.v->offset - (q.v->offset < 0 ? 8 - 2 * (4 - size) : 0) + q.val.vmax);
            record_local_variable(f, size, q.v);
        } else if (q.v->storage_class == STATIC)
            emit(f, "\tld%c r%i,[label%i]\n", memory_suffixes[size], tempReg, q.v->offset);
        else
            emit(f, "\tld%c r%i,[%s]\n", memory_suffixes[size], tempReg, q.v->identifier);
    }
    return tempReg;
}

// Todo: See if r0 can be trashed sometimes?
// Stores a register into the object destination
// Can't store from r0
void store_reg(FILE *f, int size, int reg, obj z) {
    if (z.flags & KONST) {
        emit(f, "\tst%c r%i,[$%x]\n", memory_suffixes[size], reg, z.val.vuint);
        return;
    }
    if (z.flags & REG && !(z.flags & DREFOBJ)) {
        if (z.reg - 1 != reg)
            emit(f, "\ttfr r%i,r%i\n", z.reg - 1, reg);
        return;
    }
    if (z.flags & DREFOBJ || z.val.vmax) {
        emit(f, "\tpush r0\n");
        if (z.flags & REG) {
            emit(f, "\ttfr r0,r%i\n", z.reg - 1);
            if (z.val.vmax)
                emit(f, "\tadd r0,%i\n", z.val.vint);
        } else
            load_address(f, 4, 0, z);
        if (z.flags & DREFOBJ && !(z.flags & REG))
            emit(f, "\tldr r0,r0,0\n");
        emit(f, "\tst%c r%i,r0,0\n", memory_suffixes[size], reg);
        emit(f, "\tpop r0\n");
    } else {
        if (z.v->storage_class == AUTO || z.v->storage_class == REGISTER) {
            emit(f, "\tst%c r%i,fp,%i\n", memory_suffixes[size], reg,
                 z.v->offset - (z.v->offset < 0 ? 8 - 2 * (4 - size) : 0) + z.val.vmax);
            record_local_variable(f, size, z.v);
        } else if (z.v->storage_class == STATIC)
            emit(f, "\tst%c r%i,[label%i]\n", memory_suffixes[size], reg, z.v->offset);
        else
            emit(f, "\tst%c r%i,[%s]\n", memory_suffixes[size], reg, z.v->identifier);
    }
}

// Copies "size" bytes from sourceReg address to destReg address
// Trashes r0 and r1
void output_memcpy(FILE *f, int sourceReg, int destReg, unsigned int size) {
    if (sourceReg != 12)
        emit(f, "\ttfr x,r%i\n", sourceReg);
    if (destReg != 13)
        emit(f, "\ttfr y,r%i\n", destReg);
    emit(f, "\tldr r0,$%x\n", size);
    int loop = ++label;
    int done = ++label;
    emit(f, "label%i:\n", loop);
    emit(f, "\tbeq label%i\n", done);
    emit(f, "\tldb r1,X++\n");
    emit(f, "\tstb r1,Y++\n");
    emit(f, "\tdec r0\n");
    emit(f, "\tbra label%i\n", loop);
    emit(f, "label%i:\n\n", done);
}

// Find the next Call IC after the current ic
struct IC *get_next_call(struct IC *ic) {
    while (ic = ic->next)
        if (ic->code == CALL)
            return ic;
    return NULL;
}

// Returns true if the next Call IC after the current ic has a return value
int next_call_has_return(struct IC *ic) {
    ic = get_next_call(ic);
    return ic->next && ic->next->code == GETRETURN;
}

// Returns true if this push IC is the last push IC before a call
int is_last_push(struct IC *ic) {
    while (ic = ic->next) {
        if (ic->code == CALL)
            return 1;
        if (ic->code == PUSH)
            return 0;
    }
    printf("Invalid push");
    ierror(0);
    return 0;
}

/****************************************/
/*  End of private data and functions.  */
/****************************************/

/*  Does necessary initializations for the code-generator. Gets called  */
/*  once at the beginning and should return 0 in case of problems.      */
int init_cg(void) {
    maxalign = l2zm(4L);
    char_bit = l2zm(8L);
    stackalign = l2zm(4L);

    for (int i = 0; i <= MAX_TYPE; i++) {
        sizetab[i] = l2zm(msizetab[i]);
        align[i] = l2zm(malign[i]);
    }

    for (int i = 0; i < MAXR; i++) {
        regsa[i + 1] = i <= 1 || i >= 12; // Reserve r0, r1, fp, and sp
        regscratch[i + 1] = i > 1 && i < 12; // Allow scratching
        if (i > 0) {
            regsize[i] = l2zm(4L);
            regtype[i] = &ityp;
        }
    }

            /*  Initialize the min/max-settings. Note that the types of the     */
            /*  host system may be different from the target system and you may */
            /*  only use the smallest maximum values ANSI guarantees if you     */
            /*  want to be portable.                                            */
            /*  That's the reason for the subtraction in t_min[INT]. Long could */
            /*  be unable to represent -2147483648 on the host system.          */
    t_min[CHAR] = l2zm(-128L);
    t_min[SHORT] = l2zm(-32768L);
    t_min[INT] = zmsub(l2zm(-2147483647L), l2zm(1L));
    t_min[LONG] = t_min(INT);
    t_min[LLONG] = zmlshift(l2zm(1L), l2zm(63L));
    t_min[MAXINT] = t_min(LLONG);
    t_max[CHAR] = ul2zum(127L);
    t_max[SHORT] = ul2zum(32767UL);
    t_max[INT] = ul2zum(2147483647UL);
    t_max[LONG] = t_max(INT);
    t_max[LLONG] = zumrshift(zumkompl(ul2zum(0UL)), ul2zum(1UL));
    t_max[MAXINT] = t_max(LLONG);
    tu_max[CHAR] = ul2zum(255UL);
    tu_max[SHORT] = ul2zum(65535UL);
    tu_max[INT] = ul2zum(4294967295UL);
    tu_max[LONG] = t_max(UNSIGNED | INT);
    tu_max[LLONG] = zumkompl(ul2zum(0UL));
    tu_max[MAXINT] = t_max(UNSIGNED | LLONG);

    variableInit = NULL;
    lastFunction = NULL;
    includes = NULL;
    section = 0;
    headerGen = 0;
    lastCompareSigned = 0;
    lastCodeLine = 0;
    lastCodeFile = NULL;

    return 1;
}

/* If debug-information is requested, this functions is called after init_cg(), but
 * before any code is generated.*/
void init_db(FILE *f) {
}

int handle_pragma(const char *s) {
    char *path = mymalloc(strlen(s));
    if (sscanf(s, "include \"%[^\"]\"", path)) {
        struct Include *include = mymalloc(sizeof(struct Include));
        include->next = NULL;
        include->path = path;
        if (includes) {
            struct Include *last = includes;
            while(last) {
                if (!strcmp(last->path, path))
                    return 0;
                last = last->next;
            }
            last = includes;
            while(last->next)
                last = last->next;
            last->next = include;
        } else
            includes = include;
        return 1;
    }
    return 0;
}

/*  Returns the register in which variables of type t are returned. */
/*  If the value cannot be returned in a register returns 0.        */
/*  A pointer MUST be returned in a register. The code-generator    */
/*  has to simulate a pseudo register if necessary.                 */
int freturn(struct Typ *t) {
    return 0;
}

/* Returns 0 if the register is no register pair. If r  */
/* is a register pair non-zero will be returned and the */
/* structure pointed to p will be filled with the two   */
/* elements.                                            */
int reg_pair(int r, struct rpair *p) {
    return 0;
}

/*  Returns 0 if register r cannot store variables of   */
/*  type t. If t==POINTER and mode!=0 then it returns   */
/*  non-zero only if the register can store a pointer   */
/*  and dereference a pointer to mode.                  */
int regok(int r, int t, int mode) {
    if (t == POINTER) {
        if (mode)
            return r > 2 && r < 13 && mode >= CHAR && mode <= LONG;
        else
            return 1;
    }
    return r > 2 && r < 13 && t >= CHAR && t <= LONG;
}

/*  Returns zero if the IC p can be safely executed     */
/*  without danger of exceptions or similar things.     */
/*  vbcc may generate code in which non-dangerous ICs   */
/*  are sometimes executed although control-flow may    */
/*  never reach them (mainly when moving computations   */
/*  out of loops).                                      */
/*  Typical ICs that generate exceptions on some        */
/*  machines are:                                       */
/*      - accesses via pointers                         */
/*      - division/modulo                               */
/*      - overflow on signed integer/floats             */
int dangerous_IC(struct IC *p) {
    return 0;
}

/*  Returns zero if code for converting np to type t    */
/*  can be omitted.                                     */
/*  On the PowerPC cpu pointers and 32bit               */
/*  integers have the same representation and can use   */
/*  the same registers.                                 */
int must_convert(int o, int t, int const_expr) {
    return 1;
}

/*  This function has to create <size> bytes of storage */
/*  initialized with zero.                              */
void gen_ds(FILE *f, zmax size, struct Typ *t) {
    header(f);

    if (section == 0) {
        emit(f, "\tdb ");
        for (int i = 0; i < size; i++) {
            if (i > 0)
                emit(f, ", ");
            emit(f, "$0");
        }
        emit(f, "\n");
    } else
        emit(f, " var[%d]\n\n", size);
}

/*  This function has to make sure the next data is     */
/*  aligned to multiples of <align> bytes.              */
void gen_align(FILE *f, zmax align) {
    header(f);
    if (align > 1)
        emit(f, "\talign %i\n", zm2l(align));
}

/*  This function has to create the head of a variable  */
/*  definition, i.e. the label and information for      */
/*  linkage etc.                                        */
void gen_var_head(FILE *f, struct Var *v) {
    header(f);

    if (ISFUNC(v->vtyp->flags) || (v->storage_class == EXTERN && !(v->flags & (DEFINED | TENTATIVE)))) {
        lastVarHeadVar = NULL;
        return;
    }

    lastVarHeadVar = v;
    lastVarHeadCreated = 0;

    ensure_section(f, !(v->clist && is_const(v->vtyp)));

    gen_align(f, falign(v->vtyp));

    if (!is_const(v->vtyp)) {
        emit(f, "; #VAR:");
        emit_var_info(f, v);
    }

    if (v->storage_class == STATIC)
        emit(f, "label%d:", v->offset);
    else if (v->storage_class == EXTERN)
        emit(f, "%s:", v->identifier);

    if (v->clist && is_const(v->vtyp))
        emit(f, "\n");
}

/*  This function has to create static storage          */
/*  initialized with const-list p.                      */
void gen_dc(FILE *f, int typf, struct const_list *p) {
    header(f);

    if (!lastVarHeadVar)
        return;

    if (!lastVarHeadCreated && !is_const(lastVarHeadVar->vtyp)) {
        struct const_list *last = lastVarHeadVar->clist;
        while (last->next)
            last = last->next;
        emit(f, " var[%d]\n\n", (last->idx + 1) * sizetab[typf & NQ]);
        lastVarHeadCreated = 1;
    }

    struct VariableInit *init;
    if (section == 1) {
        init = mymalloc(sizeof(struct VariableInit));
        init->next = NULL;
        char *variable = mymalloc(65);
        if (lastVarHeadVar->storage_class == STATIC)
            snprintf(variable, 65, "label%d", zm2zi(lastVarHeadVar->offset));
        else if (lastVarHeadVar->storage_class == EXTERN)
            snprintf(variable, 65, "%s", lastVarHeadVar->identifier);
        init->variable = variable;
        if (variableInit) {
            struct VariableInit *last = variableInit;
            while (last->next)
                last = last->next;
            last->next = init;
        } else
            variableInit = init;
    }

    switch (typf & NQ) {
        case CHAR:
            if (section == 0)
                emit(f, "\tdb $%x\n", p->val.vuchar);
            else {
                init->size = 1;
                init->value = p->val.vuchar;
            }
            break;

        case SHORT:
            if (section == 0)
                emit(f, "\tdw $%x\n", p->val.vushort);
            else {
                init->size = 2;
                init->value = p->val.vushort;
            }
            break;

        case INT:
        reallyanint:
            if (section == 0)
                emit(f, "\tdd $%x\n", p->val.vuint);
            else {
                init->size = 4;
                init->value = p->val.vuint;
            }
            break;

            // case LONG:
            // 	emit(f, "\tdb $%x, $%x, $%x, $%x\n", p->val.vlong >> 24, (p->val.vlong >> 16) & 0xFF, (p->val.vlong >> 8) & 0xFF, p->val.vlong & 0xFF);
            // 	break;

        case POINTER:
            if (!p->tree)
                goto reallyanint;

            // Todo: Support for initializing static pointers such as: static char *message = "Hello World";
            // Would require storing more data in the VariableInit struct to store labels or names

            // {
            //     struct obj *obj = &p->tree->o;

            //     switch (obj->v->storage_class) {
            //         case EXTERN:

            //             break;

            //         case STATIC:

            //             break;

            //         default:
            //             ierror(0);
            //     }

            // }
            // break;

        default:
            printf("Unimplemented gen_dc type %d\n", typf);
            ierror(0);
    }
}


/* The code generator itself.
 * This big, complicated, hairy and scary function does the work to actually
 * produce the code.  f is the output stream, ic the beginning of the ic
 * chain, func is a pointer to the actual function and stackframe is the size
 * of the function's stack frame.
 */
void gen_code(FILE *f, struct IC *firstIC, struct Var *func, zmax stackframe) {
    localVariables = NULL;
    lastFunction = func->identifier;
    
    header(f);
    ensure_section(f, 0);

    stackframe += (4 - stackframe % 4) % 4; // Align stackframe

    gen_align(f, 4);

    emit(f, "; Function \"%s\"\n", func->identifier);
    int interrupt = check_interrupts(func->identifier);
    emit(f, "; #FUNC:%s:%i:L%i@%s\n", func->identifier, stackframe, func->dline, func->dfilename);
    if (interrupt)
        emit(f, "_int%i:\n", interrupt);
    emit(f, "%s:\n", func->identifier);

    // printf("%s\n", func->identifier);
    // printiclist(stdout, firstIC);
    // printf("\n");

    emit(f, "; Save FP\n");
    emit(f, "\tpush fp\n\n");

    struct IC *ic = firstIC;

    int interruptRegisters[16] = {1, 1};
    if (interrupt) {
        emit(f, "; Save registers modified in this interrupt\n");
        for (; ic; ic = ic->next) {
            if (ic->code == ALLOCREG)
                interruptRegisters[ic->q1.reg - 1] = 1;
            else if (ic->code == ASSIGN 
                && ((ic->typf & NQ) == STRUCT || (ic->typf & NQ) == VOID || (ic->typf & NQ) == ARRAY || ((ic->typf & NQ) == CHAR && ic->q2.val.vmax != 1))) {
                interruptRegisters[12] = 1;
                interruptRegisters[13] = 1;
            } else if (ic->code == CALL && (ic->q1.flags & VAR) && ic->q1.v->fi && ic->q1.v->fi->inline_asm) {
                // Todo: Only save used registers using an annotation or something
                for (int i = 0; i < 16; i++)
                    interruptRegisters[i] = 1;
            }
        }
        for (int i = 0; i < 16; i++)
            if (interruptRegisters[i])
                emit(f, "\tpush r%i\n", i);
        emit(f, "\n");
    }

    emit(f, "; Load Stack Frame\n");
    emit(f, "\ttfr fp,sp\n");
    emit(f, "\tadd sp,%i\n\n", zm2l(stackframe));

    emit(f, "; #STARTCODE:%s\n", func->identifier);

    int pushed = 0, hasPushed = 0;

    ic = firstIC;
    for (; ic; ic = ic->next) {
        ensure_section(f, 0);

        if ((ic->line != lastCodeLine || !lastCodeFile || strcmp(lastCodeFile, ic->file)) && ic->code != LABEL) {
            emit(f, "; #CODE:%s:L%i@%s\n", func->identifier, ic->line, ic->file);
            lastCodeFile = ic->file;
            lastCodeLine = ic->line;
        }

        int code = ic->code;
        int typf = ic->typf;

        // Pointer arithmetic is the same as integer arithmetic
        switch (code) {
            case SUBPFP:
            case SUBIFP:
                code = SUB;
                break;

            case ADDI2P:
                code = ADD;
                break;
        }

        switch (code) {
            case NOP: /* No operation */
                break;

            case LABEL: /* Emit jump target */
                emit(f, "label%i:\n", iclabel(ic));
                break;

            case BRA: /* Unconditional jump */
                emit(f, "\tbra label%i\n", iclabel(ic));
                break;

            case GETRETURN: /* Read the last function call's return parameter */
            case SETRETURN: /* Set this function's return parameter */
                // Uses pushed pointer instead
                break;

                // Needed for anything?
            case ALLOCREG:
                //regs[ic->q1.reg] = 1;
                break;
            case FREEREG:
                //regs[ic->q1.reg] = 0;
                break;

            case ASSIGN:
                // Todo: Handle array initialization and possibly memcpy
                emit_ic_comment(f, ic);
                switch (typf & NQ) {
                    case CHAR:
                        if (ic->q2.val.vmax != 1)
                            goto assign_copy_array;
                    case SHORT:
                    case INT:
                    case POINTER:
                        store_reg(f, sizetab[ztyp(ic) & NQ], get_param_reg(f, sizetab[q1typ(ic) & NQ], 1, ic->q1), ic->z);
                        break;

                    case STRUCT:
                    case VOID:
                    case ARRAY: {
                        assign_copy_array:
                        load_address(f, sizetab[q1typ(ic) & NQ], 12, ic->q1);
                        load_address(f, sizetab[ztyp(ic) & NQ], 13, ic->z);
                        output_memcpy(f, 12, 13, ic->q2.val.vuint);
                        break;
                    }

                    default:
                        printf("Unsupported assign type:");
                        printic(stdout, ic);
                        ierror(0);
                        break;
                }
                emit(f, "\n");
                break;

            case ADDRESS: /* Fetch the address of something, always AUTO or STATIC */
                emit_ic_comment(f, ic);
                load_address(f, sizetab[q1typ(ic) & NQ], 1, ic->q1);
                store_reg(f, sizetab[ztyp(ic) & NQ], 1, ic->z);
                emit(f, "\n");
                break;

            case PUSH: /* Push a value onto the stack */
                if (opsize(ic) > 4) {
                    printf("Unsupported type: ");
                    printic(stdout, ic);
                    ierror(0);
                } else {
                    emit_ic_comment(f, ic);

                    if (!hasPushed)
                        emit(f, "\tadd sp,%i\n", pushedargsize(get_next_call(ic)));
                    hasPushed = 1;

                    int offset;
                    if (next_call_has_return(ic))
                        offset = is_last_push(ic) ? -1 : -2 - pushed++;
                    else
                        offset = -1 - pushed++;

                    emit(f, "\tstr r%i,sp,%i\n\n", get_param_reg(f, sizetab[q1typ(ic) & NQ], 0, ic->q1), offset * 4);
                }
                break;

            case MINUS: /* Unary minus */
            {
                emit_ic_comment(f, ic);
                int reg = get_param_reg(f, sizetab[q1typ(ic) & NQ], 0, ic->q1);
                emit(f, "\txor r%i,$FFFFFFFF\n", reg);
                emit(f, "\tinc r%i\n", reg);
                store_reg(f, sizetab[ztyp(ic) & NQ], reg, ic->z);
                emit(f, "\n");
                break;
            }

            case KOMPLEMENT: /* Unary komplement */
            {
                emit_ic_comment(f, ic);
                int reg = get_param_reg(f, sizetab[q1typ(ic) & NQ], 0, ic->q1);
                emit(f, "\txor r%i,$FFFFFFFF\n", reg);
                store_reg(f, sizetab[ztyp(ic) & NQ], reg, ic->z);
                emit(f, "\n");
                break;
            }

            case DIV: /* Divide two numbers */
            case MOD: /* Modulo two numbers */
            {
                emit_ic_comment(f, ic);
                int reg1 = get_param_reg(f, sizetab[q1typ(ic) & NQ], 0, ic->q1);
                if (reg1 != 0)
                    emit(f, "\ttfr r0,r%i\n", reg1);
                int reg2 = get_param_reg(f, sizetab[q1typ(ic) & NQ], 1, ic->q2);
                if (reg2 != 1)
                    emit(f, "\ttfr r1,r%i\n", reg2);
                emit(f, "\tjsr %s%s\n", q1typ(ic) & UNSIGNED ? "u" : "", code == DIV ? "div" : "mod");
                emit(f, "\ttfr r1,r0\n");
                store_reg(f, sizetab[ztyp(ic) & NQ], 1, ic->z);
                emit(f, "\n");
                break;
            }

            case ADD: /* Add two numbers */
            case SUB: /* Subtract two numbers */
            case MULT: /* Multiply two numbers */
            case OR: /* Bitwise or */
            case XOR: /* Bitwise xor */
            case AND: /* Bitwise and */
            case LSHIFT: /* Shift left */
            case RSHIFT: /* Shift right */
            {
                emit_ic_comment(f, ic);

                int source = get_param_reg(f, sizetab[q1typ(ic) & NQ], 0, ic->q1);

                // Todo: Don't push register if next IC is FREEREG

                // Push source register to stack if not temp and not destination
                int pushSource = source > 1 && !(ic->z.flags & REG && ic->z.reg - 1 == source);
                if (pushSource)
                    emit(f, "\tpush r%i\n", source);

                int paramReg;
                if (!(ic->q2.flags & KONST))
                    paramReg = get_param_reg(f, sizetab[q2typ(ic) & NQ], 1, ic->q2);

                switch (code) {
                    case SUB:
                        emit(f, "\tsub");
                        break;
                    case ADD:
                        emit(f, "\tadd");
                        break;
                    case MULT:
                        emit(f, "\tmul");
                        break;
                    case OR:
                        emit(f, "\tor");
                        break;
                    case XOR:
                        emit(f, "\txor");
                        break;
                    case AND:
                        emit(f, "\tand");
                        break;
                    case LSHIFT:
                        emit(f, "\tlsl");
                        break;
                    case RSHIFT:
                        emit(f, q1typ(ic) & UNSIGNED ? "\tlsr" : "\tasr");
                        break;
                }

                emit(f, " r%i,", source);

                if (ic->q2.flags & KONST)
                    emit(f, "$%x\n", ic->q2.val.vuint);
                else
                    emit(f, "r%i\n", paramReg);

                if (source == 0)
                    emit(f, "\ttfr r1,r0\n");
                store_reg(f, sizetab[ztyp(ic) & NQ], source == 0 ? 1 : source, ic->z);

                if (pushSource)
                    emit(f, "\tpop r%i\n", source);

                emit(f, "\n");
                break;
            }

            case CONVERT: /* Convert between types */
                emit_ic_comment(f, ic);

                // Todo: Treat long the same as int using ISLshortONG()

                if ((q1typ(ic) & UNSIGNED && (q1typ(ic) & NQ) < INT &&
                     ((ztyp(ic) & NU) == (UNSIGNED | INT) ||
                      (ztyp(ic) & NU) == (UNSIGNED | CHAR))) // unsigned (char or short) -> unsigned (int or short)
                    || ((q1typ(ic) & NU) == (UNSIGNED | INT) && (ztyp(ic) & NU) == INT) // unsigned int -> signed int
                    || (q1typ(ic) & UNSIGNED && (q1typ(ic) & NQ) < INT && (ztyp(ic) & NU) == INT)
                        ) {
                    // Just transfter
                    // Todo: Skip if source and dest are the same
                    store_reg(f, sizetab[ztyp(ic) & NQ], get_param_reg(f, sizetab[q1typ(ic) & NQ], 1, ic->q1), ic->z);
                } else if ((q1typ(ic) & NU) == INT &&
                           (ztyp(ic) & NU) == (UNSIGNED | INT)) { // signed int -> unsigned int
                    int reg = get_param_reg(f, sizetab[q1typ(ic) & NQ], 1, ic->q1);
                    int l = ++label;
                    emit(f, "\tcmp r%i,0\n", reg);
                    emit(f, "\tbpl label%i\n", l);
                    emit(f, "\txor r%i,$FFFFFFFF\n", reg);
                    emit(f, "\tinc r%i\n", reg);
                    emit(f, "label%i:\n", l);
                    store_reg(f, sizetab[ztyp(ic) & NQ], reg, ic->z);
                } else if ((q1typ(ic) & NQ) <= INT &&
                           (ztyp(ic) & NQ) == CHAR) { // (any sign) (int or short) -> (any sign) char
                    int reg = get_param_reg(f, sizetab[q1typ(ic) & NQ], 1, ic->q1);
                    emit(f, "\tand r%i,$000000FF\n", reg);
                    store_reg(f, sizetab[ztyp(ic) & NQ], reg, ic->z);
                } else if ((q1typ(ic) & NQ) == INT && (ztyp(ic) & NQ) == SHORT) { // (any sign) int -> (any sign) short
                    int reg = get_param_reg(f, sizetab[q1typ(ic) & NQ], 1, ic->q1);
                    emit(f, "\tand r%i,$0000FFFF\n", reg);
                    store_reg(f, sizetab[ztyp(ic) & NQ], reg, ic->z);
                } else if ((!(q1typ(ic) & UNSIGNED) && (q1typ(ic) & NQ) < INT) &&
                           ((ztyp(ic) & NU) == INT ||
                            (ztyp(ic) & NU) == SHORT)) { // signed (char or short) -> signed (int or short)
                    int reg = get_param_reg(f, sizetab[q1typ(ic) & NQ], 1, ic->q1);
                    int l = ++label;
                    emit(f, "\tpush r%i\n", reg);
                    emit(f, "\tand r%i,%s\n", reg, (q1typ(ic) & NQ) == CHAR ? "$80" : "$8000");
                    emit(f, "\tpop r%i\n", reg);
                    emit(f, "\tbeq label%i\n", l);
                    if ((ztyp(ic) & NU) == INT)
                        emit(f, "\tor r%i,%s\n", reg, (q1typ(ic) & NQ) == CHAR ? "$FFFFFF00" : "$FFFF0000");
                    else
                        emit(f, "\tor r%i,%s\n", reg, "$FF00");
                    emit(f, "label%i:\n", l);
                    store_reg(f, sizetab[ztyp(ic) & NQ], reg, ic->z);
                } else {
                    printf("Unsupported conversion: ");
                    printic(stdout, ic);
                    ierror(0);
                }

                emit(f, "\n");
                break;

            case COMPARE: /* Compare */
            {
                emit_ic_comment(f, ic);
                lastCompareSigned = !(UNSIGNED & q1typ(ic));
                int reg = get_param_reg(f, sizetab[q1typ(ic) & NQ], 0, ic->q1);
                if (ic->q2.flags & KONST)
                    emit(f, "\tcmp r%i,$%x\n\n", reg, ic->q2.val.vuint);
                else
                    emit(f, "\tcmp r%i,r%i\n\n", reg, get_param_reg(f, sizetab[q1typ(ic) & NQ], 1, ic->q2));
                break;
            }

            case TEST: /* Compare against zero */
                emit_ic_comment(f, ic);
                lastCompareSigned = 0;
                emit(f, "\tcmp r%i,0\n\n", get_param_reg(f, sizetab[q1typ(ic) & NQ], 0, ic->q1));
                break;

            case BEQ: /* Branch if equal */
                emit(f, "\tbeq label%d\n\n", iclabel(ic));
                break;

            case BNE: /* Branch if not equal */
                emit(f, "\tbne label%d\n\n", iclabel(ic));
                break;

            case BLT: /* Branch if less */
                if (lastCompareSigned)
                    emit(f, "\tblt label%d\n\n", iclabel(ic));
                else
                    emit(f, "\tblo label%d\n\n", iclabel(ic));
                break;

            case BGE: /* Branch if greater or equal */
                if (lastCompareSigned)
                    emit(f, "\tbge label%d\n\n", iclabel(ic));
                else
                    emit(f, "\tbhs label%d\n\n", iclabel(ic));
                break;

            case BLE: /* Branch if less or equal */
                if (lastCompareSigned)
                    emit(f, "\tble label%d\n\n", iclabel(ic));
                else
                    emit(f, "\tbls label%d\n\n", iclabel(ic));
                break;

            case BGT: /* Branch if greater */
                if (lastCompareSigned)
                    emit(f, "\tbgt label%d\n\n", iclabel(ic));
                else
                    emit(f, "\tbhi label%d\n\n", iclabel(ic));
                break;

            case CALL: /* Call function */
                {
                    int inlineASM = (ic->q1.flags & VAR) && ic->q1.v->fi && ic->q1.v->fi->inline_asm;
                    
                    if (inlineASM)
                        emit(f, "; Inline ASM:\n");
                    else
                        emit_ic_comment(f, ic);
                    
                    pushed = 0;
                    hasPushed = 0;
                    if (inlineASM)
                        emit_inline_asm(f, ic->q1.v->fi->inline_asm);
                    else {
                        if (ic->q1.flags & DREFOBJ) {
                            ic->q1.flags &= ~DREFOBJ; // Hack to support function pointers
                            int newLabel = ++label;
                            emit(f, "\tldr r0,label%d\n", newLabel);
                            emit(f, "\tpush r0\n");
                            emit(f, "\tjmp r%d\n", get_param_reg(f, 4, 0, ic->q1));
                            emit(f, "label%d:\n", newLabel);
                        } else
                            emit(f, "\tjsr %s\n", ic->q1.v->identifier);
                    }

                    if (pushedargsize(ic))
                        emit(f, "\tsub sp,%i\n\n", pushedargsize(ic));
                    else
                        emit(f, "\n");
                }
                break;

            default:
                printf("Unsupported operation:");
                printic(stdout, ic);
                //ierror(0);
                break;
        }
    }

    emit(f, "; Return from function \"%s\"\n", func->identifier);
    emit(f, "; #ENDCODE:%s\n", func->identifier);

    emit(f, "\tsub sp,%i\n", zm2l(stackframe));

    if (interrupt) {
        emit(f, "; Restore registers modified in this interrupt\n");
        for (int i = 15; i >= 0; i--)
            if (interruptRegisters[i])
                emit(f, "\tpop r%i\n", i);
        emit(f, "\n");
    }

    emit(f, "; Restore FP\n");
    emit(f, "\tpop fp\n");
    
    emit(f, "; #RETURN:%s\n", func->identifier);

    if (!strcmp(func->identifier, "main"))
        emit(f, "\thalt\n\n");
    else
        emit(f, "\t%s\n\n", interrupt ? "rti" : "ret");
}

/* In C no operations are done with chars and shorts because of integral promotion.
However sometimes vbcc might see that an operation could be performed with
the short types yielding the same result.
Before generating such an instruction with short types vbcc will ask the code
generator by calling shortcut() to find out whether it should do so. Return
true iff it is a win to perform the operation code with type t rather than
promoting the operands and using e.g. int. */
int shortcut(int code, int typ) {
    return 0;
}

void cleanup_cg(FILE *f) {
    header(f);

    ensure_section(f, 0);

    emit(f, "; C includes\n");
    struct Include *include = includes;
    while (include) {
        emit(f, "\tinclude \"%s\"\n", include->path);
        include = include->next;
    }
    emit(f, "\n");

    emit(f, "_initialize:\n");

//     emit(f, "; Clear memory\n");
//     emit(f, "\tldr x,$18000\n");
//     emit(f, "\tldr r0,0\n");
//     emit(f, "_clear_mem_loop:\n");
//     emit(f, "\tstr r0,x++\n");
//     emit(f, "\tcmp x,$20000\n");
//     emit(f, "\tbne _clear_mem_loop\n\n");

    emit(f, "; Static variable initialization\n");
    char *previousVariable = NULL;
    struct VariableInit *init = variableInit;
    while (init) {
        if (!previousVariable || strcmp(previousVariable, init->variable)) {
            int size = 0;
            for (struct VariableInit *iter = init; iter; iter = iter->next) {
                if (strcmp(init->variable, iter->variable))
                    break;
                size++;
            }
            if (size == 1) {
                emit(f, "\tld%c r0,%s_init\n", memory_suffixes[init->size], init->variable);
                emit(f, "\tst%c r0,%s\n", memory_suffixes[init->size], init->variable);
            } else {
                emit(f, "\tldr x,%s_init\n", init->variable);
                emit(f, "\tldr y,%s\n", init->variable);
                output_memcpy(f, 12, 13, size);
            }
        }
        previousVariable = init->variable;
        init = init->next;
    }

    emit(f, "; Run main function\n");
    emit(f, "\tldr sp,_stack\n");
    emit(f, "\tjmp main\n\n");

    emit(f, "; Static variable initialization data\n");
    previousVariable = NULL;
    init = variableInit;
    while (init) {
        if (!previousVariable || strcmp(previousVariable, init->variable)) {
            if (previousVariable)
                emit(f, "\n");
            gen_align(f, init->size);
            emit(f, "%s_init:\n", init->variable);
        }
        emit(f, "\td%c $%x\n", init->size == 1 ? 'b' : (init->size == 2 ? 'w' : 'd'), init->value);
        previousVariable = init->variable;
        init = init->next;
    }
    emit(f, "\n");

    emit(f, "; Unused interrupt vectors\n");
    for (int i = 1; i < INTERRUPT_COUNT; i++)
        if (!interrupts[i])
            emit(f, "%s:\n", interrupt_names[i]);
    emit(f, "\tbra -8\n\n");

    ensure_section(f, 1);
    emit(f, "\talign 4\n");
    emit(f, "_stack:\n");
}

void cleanup_db(FILE *f) {
}
