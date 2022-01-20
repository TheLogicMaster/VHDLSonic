#ifndef EMULATOR_DEBUGSYMBOLS_H
#define EMULATOR_DEBUGSYMBOLS_H

struct DebugLineOfCode {
    int line;
    std::string source;
    uint32_t address;
    uint32_t end;
};

struct DebugVariable {
    int line;
    std::string source;
    uint32_t address;
    std::string type;
    int type_size;
    bool pointer;
    int array;
};

struct DebugLocal : DebugVariable {
    int start;
    int end;
    std::string name;
};

struct DebugFunction {
    int line;
    std::string source;
    uint32_t address;
    int frame;
    uint32_t end_code;
    uint32_t start_code;
    std::vector<DebugLineOfCode> code;
    std::vector<DebugLocal> locals;
};

NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE(DebugLineOfCode, line, source, address, end)
NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE(DebugVariable, line, source, address, type, type_size, pointer, array)
NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE(DebugLocal, line, source, address, type, type_size, pointer, array, start, end, name)
NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE(DebugFunction, line, source, address, frame, end_code, start_code, code, locals)

#endif //EMULATOR_DEBUGSYMBOLS_H
