import argparse
import os
import re

line_number = 0  # The current line number
label_num = 0  # The current label index
registers = 0  # The number of registers in use aside from r14/r15
output = ""  # The output buffer
variables = []  # Variables used by the program
depth = 0  # The number of blocks deep at the current line
while_stack = []  # The stack for WHILE loops
for_stack = []  # The stack for FOR loops
loop_stack = []  # The stack for DO-UNTIL/DO-WHILE loops
if_stack = []  # The IF-statement stack


# Prints error message and line number then exits
def error(message):
    print(f'Error at line {line_number}: {message}')
    exit(-1)


# Parse a single regex group
def parse_group(text, regex):
    match = regex.search(text)
    if not match:
        return None
    return match[1]


# Parse a program variable
def parse_variable(text):
    return parse_group(text.lower(), re.compile(r"^\s*(\w+)\s*$"))


# Parse a program string
def parse_string(text):
    return parse_group(text, re.compile(r"^\s*\"(.*)\"\s*$"))


# Parse a program label
def parse_label(text):
    return parse_group(text.lower(), re.compile(r"^\s*@(\w+)\s*$"))


# Parse a constant integer
def parse_constant(text):
    parsed = parse_group(text, re.compile(r"^\s*(-?[0-9]+)\s*$"))
    return None if parsed is None else int(parsed)


# Parses command integer arguments into first N registers
# Also clears allocated registers
def parse_arguments(text, count):
    global registers
    split = text.split(',')
    if len(split) != count:
        error('Invalid arguments')
    registers = 0
    for i in range(count):
        registers += 1
        evaluate_expression(split[i], i)
    registers = 0


# Output a command that writes to a specific memory array
def output_array_set_command(arguments, name):
    global output
    parse_arguments(arguments, 2)
    output += f'\tmul r0,4\n'
    output += f'\tstr r1,r0,{{{name}}}\n\n'


# Output a command that reads from a specific memory array
def output_array_get_command(arguments, name):
    global output
    split = arguments.split(',', 1)
    if len(split) != 2:
        error('Invalid arguments')
    parse_arguments(split[1], 1)
    variable = parse_variable(split[0])
    if not variable:
        error('Invalid variable')
    output += f'\tmul r0,4\n'
    output += f'\tldr r1,r0,{{{name}}}\n'
    output += f'\tstr r1,[_{variable}]\n\n'


# Output a command that writes to a specific memory address
def output_mem_set_command(arguments, name):
    global output
    parse_arguments(arguments, 1)
    output += f'\tstr r1,r0,{{{name}}}\n\n'


# Output a command that reads from a specific memory address
def output_mem_get_command(arguments, name):
    global output
    variable = parse_variable(arguments)
    if not variable:
        error('Invalid variable')
    output += f'\tldr r0,[{{{name}}}]\n'
    output += f'\tstr r0,[_{variable}]\n\n'


# Collect variable if not already collected
def collect_variable(variable):
    if variable not in variables:
        variables.append(variable)


# Find all top level groups of parentheses in an expression.
# Returns a list of tuples that contain the first and last indices of each group
def find_parentheses(expression):
    groups = []
    group_depth = 0
    group_start = 0
    for j in range(len(expression)):
        if expression[j] == '(':
            if group_depth == 0:
                group_start = j
            group_depth += 1
        elif expression[j] == ')':
            group_depth -= 1
            if group_depth == 0:
                groups.append((group_start, j))
    return groups


# Attempt to allocate N registers
def allocate_registers(count):
    global registers
    registers += count
    if registers > 14:
        error('Insufficient registers')


# Evaluates and expression and puts the result in the specified register
def evaluate_expression(expression, register):
    global output
    global registers
    global label_num

    # Remove outer whitespace from expression
    expression = expression.strip()

    # Remove outer parentheses
    groups = find_parentheses(expression)
    if len(groups) == 1 and groups[0] == (0, len(expression) - 1):
        expression = expression[1:-1]

    # Handle constant expressions
    if (constant := parse_constant(expression)) is not None:
        output += f'\tldr r{register},{constant}\n'
        return

    # Handle variable expressions
    if variable := parse_variable(expression):
        collect_variable(variable)
        output += f'\tldr r{register},[_{variable}]\n'
        return

    # Expression comment
    output += f'; Evaluate: {expression}\n'

    # Extract parenthesized groups
    groups = find_parentheses(expression)
    groups.reverse()
    replaced = []
    for group in groups:
        replaced.append(expression[group[0]:group[1] + 1])
    parenthesized = expression
    for i in range(len(groups)):
        parenthesized = parenthesized.replace(replaced[i], f"[{i}]", 1)

    # Determine two-operand operation with respect to operator precedence
    for op in [r'\|\|', '&&', 'or', 'xor', 'and', '==|!=', '>=|<=|<|>', '<<|>>', r'-|\+', r'\*|/|mod']:
        if match := re.search(rf"(?i)^\s*(.+)(?:\s|\b)+({op})(?:\s|\b)+(.+?)\s*$", parenthesized):
            break
    if match and match[1] != 'not':
        # Allocate registers to hold expression values
        allocate_registers(1)

        # Replace parenthesized groups
        expression_1 = match[1]
        expression_2 = match[3]
        for i in range(len(replaced)):
            expression_1 = expression_1.replace(f'[{i}]', replaced[i], 1)
            expression_2 = expression_2.replace(f'[{i}]', replaced[i], 1)

        # Evaluate operand expressions
        evaluate_expression(expression_1, register)
        evaluate_expression(expression_2, registers - 1)

        # Perform operation
        operation = match[2].lower()
        if operation == '==' or operation == '!=' or operation == '>' \
                or operation == '>=' or operation == '<' or operation == '<=':
            output += f'\tcmp r{register},r{registers - 1}\n'
            output += '\t'
            if operation == '==':
                output += 'beq'
            elif operation == '!=':
                output += 'bne'
            elif operation == '>':
                output += 'bgt'
            elif operation == '>=':
                output += 'bge'
            elif operation == '<':
                output += 'blt'
            elif operation == '<=':
                output += 'ble'
            else:
                error('Invalid operation')
            label = (label_num := label_num + 1)
            output += f' _{label}_true\n'
            output += f'\tldr r{register},0\n'
            output += f'\tbra _{label}_done\n'
            output += f'_{label}_true:\n'
            output += f'\tldr r{register},1\n'
            output += f'_{label}_done:\n'
        elif operation == '+' or operation == '-' or operation == '*' or operation == 'and' or operation == 'or' \
                or operation == 'xor' or operation == '>>' or operation == '<<':
            output += '\t'
            if operation == '+':
                output += 'add'
            elif operation == '-':
                output += 'sub'
            elif operation == '*':
                output += 'mul'
            elif operation == 'and':
                output += 'and'
            elif operation == 'or':
                output += 'or'
            elif operation == 'xor':
                output += 'xor'
            elif operation == '>>':
                output += 'asr'
            elif operation == '<<':
                output += 'lsl'
            else:
                error('Invalid operations')
            output += f' r{register},r{registers - 1}\n'
        elif operation == '/' or operation == 'mod':
            output += '\tpush r0\n'
            output += '\tpush r1\n'
            output += f'\ttfr r0,r{register}\n'
            output += f'\ttfr r1,r{registers - 1}\n'
            output += '\tjsr '
            if operation == '/':
                output += 'div'
            elif operation == 'mod':
                output += 'mod'
            else:
                error('Invalid operations')
            output += '\n'
            output += f'\tstr r0,[temp]\n'
            output += '\tpop r1\n'
            output += '\tpop r0\n'
            output += f'\tldr r{register},[temp]\n'
        elif operation == '||' or operation == '&&':
            label = (label_num := label_num + 1)
            output += f'\tcmp r{register},0\n'
            output += f'\t{"bne" if operation == "||" else "beq"} _{label}_branch\n'
            output += f'\tcmp r{registers - 1},0\n'
            output += f'\t{"bne" if operation == "||" else "beq"} _{label}_branch\n'
            output += f'\tldr r{register},{int(operation != "||")}\n'
            output += f'\tbra _{label}_done\n'
            output += f'_{label}_branch:\n'
            output += f'\tldr r{register},{int(operation == "||")}\n'
            output += f'_{label}_done:\n'
        else:
            error('Invalid operation')

        # Deallocate registers
        registers -= 1

        return

    # Handle single operand expressions
    if match := re.search(r"(?i)^\s*(not|!)(?:\s|\b)+(.+?)\s*$", parenthesized):
        operation = match[1]
        expression = match[2]

        # Replace parenthesized groups
        for i in range(len(replaced)):
            expression = expression.replace(f'[{i}]', replaced[i], 1)

        # Evaluate operand expression
        evaluate_expression(expression, register)

        # Perform operation
        if operation == 'not':
            output += f'\txor r{register},$FFFFFFFF\n\n'
        elif operation == '!':
            label = (label_num := label_num + 1)
            output += f'\tcmp r{register},0\n'
            output += f'\tbeq _{label}_zero\n'
            output += f'\tldr r{register},0\n'
            output += f'\tbra _{label}_done\n'
            output += f'_{label}_zero:\n'
            output += f'\tldr r{register},1\n'
            output += f'_{label}_done:\n\n'
        return

    error('Invalid expression')


# Parses and outputs a statement
def output_statement(statement):
    global output, depth
    global label_num
    global registers

    # Add comment for statement
    output += f'; {statement.rstrip()}\n'

    # Check for assignment
    assign = re.search(r"^\s*(\w+)\s*=(.*)$", statement)
    if assign:
        variable = assign[1]
        evaluate_expression(assign[2], 14)
        collect_variable(variable)
        output += f'\tstr r14,[_{variable}]\n\n'
        return

    # Determine command
    match = re.search(r"^\s*(\w+)\s*", statement)
    if not match:
        error('Invalid command')
    command = match[1].lower()
    remaining = statement[len(match[0]):]

    # Output command
    if command == 'if':
        match = re.search(r"(?i)^\s*(.+)\s*then\s*(.+)\s*else\s*(.+)\s*$", remaining)
        if_else = (label_num := label_num + 1)
        if not match:
            match = re.search(r"(?i)^\s*(.+)\s*then\s*(.*)\s*$", remaining)
            if_else = False
        if not match:
            error('Invalid if statement')
        label = (label_num := label_num + 1)
        evaluate_expression(match[1], 14)
        output += '\tcmp r14,0\n'
        if match[2].isspace() or len(match[2]) == 0:
            if_stack.append({'label': label, 'depth': depth, 'count': 0})
            depth += 1
            output += f'\tbeq _{label}_0\n'
        else:
            output += f'\tbeq _{label}\n'
            output += '; Then\n'
            output_statement(match[2])
            if if_else:
                output += f'\tbra _{if_else}\n'
            output += f'_{label}:\n'
            if if_else:
                output += '; Else\n'
                output_statement(match[3])
                output += f'_{if_else}:\n'
            output += f'; End if\n\n'

    elif command == 'elseif':
        if len(if_stack) == 0:
            error(f'ELSEIF without IF')
        match = re.search(r"(?i)^\s*(.+)\s*then\s*$", remaining)
        if not match:
            error('Invalid ELSEIF')
        output += f'\tbra {if_stack[-1]["label"]}_end\n'
        output += f'_{if_stack[-1]["label"]}_{if_stack[-1]["count"]}:\n'
        if_stack[-1]["count"] += 1
        evaluate_expression(match[1], 14)
        output += '\tcmp r14,0\n'
        output += f'\tbeq _{if_stack[-1]["label"]}_{if_stack[-1]["count"]}\n'

    elif command == 'else':
        if len(if_stack) == 0:
            error(f'ELSE without IF')
        output += f'\tbra {if_stack[-1]["label"]}_end\n'
        output += f'_{if_stack[-1]["label"]}_{if_stack[-1]["count"]}:\n'
        if_stack[-1]["count"] = -1

    elif command == 'endif':
        if len(if_stack) == 0:
            error(f'ENDIF without IF')
        depth -= 1
        if depth != if_stack[-1]['depth']:
            error('Inconsistent IF-statement depth')
        if if_stack[-1]["count"] != -1:
            output += f'_{if_stack[-1]["label"]}_{if_stack[-1]["count"]}:\n'
        output += f'{if_stack[-1]["label"]}_end:\n\n'
        if_stack.pop(-1)

    elif command == 'goto':
        label = parse_label(remaining)
        if not label:
            error('Invalid label')
        output += f'\tbra _{label}\n\n'

    elif command == 'input':
        variable = parse_variable(remaining)
        if not variable:
            error('Invalid variable')
        output += '\tjsr input_int\n'
        output += f'\tstr r0,[_{variable}]\n\n'

    elif command == 'while':
        label = (label_num := label_num + 1)
        while_stack.append({'label': label, 'depth': depth})
        output += f'_{label}:\n'
        evaluate_expression(remaining, 14)
        output += '\tcmp r14,0\n'
        output += f'\tbeq _{label}_end\n\n'
        depth += 1

    elif command == 'for':
        match = re.search(r"(?i)^\s*(\w+)\s*=\s*(.+)\s*to\s*(.+)\s*step\s*(-?\d+)\s*$", remaining)
        if match:
            step = parse_constant(match[4])
        else:
            match = re.search(r"(?i)^\s*(\w+)\s*=\s*(.+)\s*to\s*(.+)\s*$", remaining)
            step = 1
        if not match:
            error('Invalid for loop')
        variable = parse_variable(match[1])
        label = (label_num := label_num + 1)
        for_stack.append({'label': label, 'depth': depth})
        depth += 1
        evaluate_expression(match[2], 14)
        output += f'\tstr r14,[_{variable}]\n'
        output += f'\tbra _{label}_start\n'
        output += f'_{label}:\n'
        output += f'\tldr r0,[_{variable}]\n'
        output += f'\tadd r0,{step}\n'
        output += f'\tstr r0,[_{variable}]\n'
        output += f'_{label}_start:\n'
        evaluate_expression(match[3], 14)
        output += f'\tldr r0,[_{variable}]\n'
        output += f'\tcmp r14,r0\n'
        output += f'\t{"bgt" if step < 0 else "blt"} _{label}_end\n\n'

    elif command == 'next' or command == 'wend':
        stack = for_stack if command == 'next' else while_stack
        if len(stack) == 0:
            error(f'Orphaned {command}')
        label = stack[-1]['label']
        output += f'\tbra _{label}\n'
        output += f'_{label}_end:\n\n'
        depth -= 1
        if depth != stack[-1]['depth']:
            error('Inconsistent loop depth')
        stack.pop(-1)

    elif command == 'do':
        label = (label_num := label_num + 1)
        loop_stack.append({'label': label, 'depth': depth})
        depth += 1
        output += f'_{label}:\n\n'

    elif command == 'loop':
        match = re.search(r"(?i)^\s*(while|until)\s*(.+)\s*$", remaining)
        if not match:
            error('Invalid loop')
        evaluate_expression(match[2], 14)
        output += '\tcmp r14,0\n'
        output += f'\t{"bne" if match[1] == "while" else "beq"} _{loop_stack[-1]["label"]}\n\n'
        depth -= 1
        if depth != loop_stack[-1]['depth']:
            error('Inconsistent loop depth')
        loop_stack.pop(-1)

    elif command == 'end':
        output += '\thalt\n\n'

    elif command == 'inc' or command == 'dec':
        variable = parse_variable(remaining)
        if not variable:
            error('Invalid variable')
        output += f'\tldr r0,[_{variable}]\n'
        output += f'\t{command} r0\n'
        output += f'\tstr r0,[_{variable}]\n\n'

    elif command == 'print':
        string = parse_string(remaining)
        if string:
            string_label = (label_num := label_num + 1)
            branch = (label_num := label_num + 1)
            output += f'\tldr r0,_{string_label}\n'
            output += '\tjsr print_string\n'
            output += f'\tbra _{branch}\n'
            output += f'_{string_label}: db "{string}", 0\n'
            output += '\talign 4\n'
            output += f'_{branch}:\n\n'
        else:
            registers = 1
            evaluate_expression(remaining, 0)
            registers = 0
            output += f'\tjsr print_int\n\n'

    elif command == 'gosub':
        label = parse_label(remaining)
        if not label:
            error('Invalid label')
        output += f'\tjsr _{label}\n\n'

    elif command == 'return':
        output += f'\tret\n\n'

    elif command == 'setled':
        output_array_set_command(remaining, 'leds')
    elif command == 'setsevenseg':
        output_array_set_command(remaining, 'seven_segment')
    elif command == 'setgpio':
        output_array_set_command(remaining, 'gpio')
    elif command == 'setgpiomode':
        output_array_set_command(remaining, 'gpio_mode')
    elif command == 'setardu':
        output_array_set_command(remaining, 'arduino')
    elif command == 'setardumode':
        output_array_set_command(remaining, 'arduino_mode')
    elif command == 'getled':
        output_array_get_command(remaining, 'leds')
    elif command == 'getbtn':
        output_array_get_command(remaining, 'buttons')
    elif command == 'getswitch':
        output_array_get_command(remaining, 'switches')
    elif command == 'getadc':
        output_array_get_command(remaining, 'adc')
    elif command == 'getsevenseg':
        output_array_get_command(remaining, 'seven_segment')
    elif command == 'getgpio':
        output_array_get_command(remaining, 'gpio')
    elif command == 'getgpiomode':
        output_array_get_command(remaining, 'gpio_mode')
    elif command == 'getarduino':
        output_array_get_command(remaining, 'arduino')
    elif command == 'getarduinomode':
        output_array_get_command(remaining, 'arduino_mode')
    elif command == 'seedrng':
        output_mem_set_command(remaining, 'random')
    elif command == 'random':
        output_mem_get_command(remaining, 'random')

    else:
        error('Invalid command')


# Compile a basic program
def compile_basic(lines):
    global line_number, label_num, registers, output, variables
    global depth, while_stack, for_stack, loop_stack

    # Reset global variables
    line_number = 0
    label_num = 0
    registers = 0
    output = ""
    variables = []
    depth = 0
    while_stack = []
    for_stack = []
    loop_stack = []

    # Generate header comment
    output += '; Compiled Basic program\n\n'

    # Generate jump table
    output += '\tbra main\n'
    for i in range(7):
        output += '\tbra -8\n'

    # Output program includes
    output += '\n\tinclude "libraries/Sonic.asm"\n'
    output += '\n\tinclude "libraries/Math.asm"\n'
    output += '\tinclude "libraries/Serial.asm"\n\n'

    # Program entry point
    output += 'main:\n'
    output += '\tldr sp,stack\n\n'

    # Process program line by line
    for line in lines:
        line_number += 1

        # Remove comments
        line = re.split(r"'(?=(?:[^\"]*[\"][^\"]*[\"])*[^\"]*$)", line)[0]

        # Check for blank lines
        if len(line) == 0 or line.isspace():
            continue

        # Check for label
        label = parse_label(line)
        if label:
            output += f'_{label}:\n\n'
            continue

        # Evaluate line
        output_statement(line)

    # Check flow control stacks
    if len(while_stack) != 0:
        error('WHILE loop without WEND')
    if len(for_stack) != 0:
        error('FOR loop without NEXT')
    if len(loop_stack) != 0:
        error('DO statement without LOOP')

    # Halt at the end of the program
    output += '\thalt\n'

    # Output variable and stack definitions
    output += '\tdata\n'
    output += '\talign 4\n'
    for variable in variables:
        output += f'_{variable}: var[4]\n'
    output += 'temp: var[4]\n'
    output += 'stack:\n'

    # Return generated Assembly
    return output


# Command line interface
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Compile a Basic program')
    parser.add_argument('program', help='The program to compile')
    args = parser.parse_args()
    compiled = compile_basic(open(args.program).readlines())
    open(os.path.splitext(args.program)[0] + ".asm", 'w').write(compiled)
