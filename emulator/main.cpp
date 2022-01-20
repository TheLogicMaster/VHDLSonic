#pragma ide diagnostic ignored "cert-err34-c" // Ignore sscanf warnings
#include <iostream>
#include <functional>
#include <set>

#include <SDL.h>
#include "imgui/imgui.h"
#include "imgui/backends/imgui_impl_sdl.h"
#include "imgui/backends/imgui_impl_opengl3.h"
#include <GL/glew.h>
#include <imgui_internal.h>
#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#include <emscripten/fetch.h>
#else
#include "ImGuiFileDialog.h"
#endif

#include "imgui_memory_editor.h"
#include "imgui_toggle_button.h"
#include "json.hpp"
#include "cxxopts.hpp"
#include "Disassembler.h"
#include "Emulator.h"
#include "DebugSymbols.h"
#include "Utilities.h"

// Macros from: https://github.com/drhelius/Gearboy/blob/master/platforms/desktop-shared/gui_debug.h
#define BYTE_TO_BINARY_PATTERN "%c%c%c%c%c%c%c%c"
#define BYTE_TO_BINARY(byte)  \
  (byte & 0x80 ? '1' : '0'), \
  (byte & 0x40 ? '1' : '0'), \
  (byte & 0x20 ? '1' : '0'), \
  (byte & 0x10 ? '1' : '0'), \
  (byte & 0x08 ? '1' : '0'), \
  (byte & 0x04 ? '1' : '0'), \
  (byte & 0x02 ? '1' : '0'), \
  (byte & 0x01 ? '1' : '0')

#define WINDOW_COUNT 15

struct WindowState {
    bool shown = false;
    float x = 10;
    float y = 10;
    float width = 100;
    float height = 100;
};

struct Layout {
    const char *name = nullptr;
    WindowState locations[WINDOW_COUNT]{};
    int displayScale = 3;
    int windowWidth = 1601;
    int windowHeight = 730;
};

#define LAYOUT_COUNT 3
static const Layout LAYOUTS[LAYOUT_COUNT]{
        {
                "Demo",
                {
                        {true, 5, 26}, // Display
                        {false, 5, 26, 164, 430}, // Processor
                        {true, 666, 200, 551, 192}, // Print log
                        {true, 665, 26, 552, 170}, // IO
                        {false, 5, 26, 1268, 75}, // GPIO
                        {false, 5, 26, 354, 430}, // Disassembly
                        {false, 5, 26, 354, 358}, // Functions
                        {false, 5, 26, 354, 135}, // Locals
                        {false, 5, 26, 354, 106}, // Calls
                        {false, 5, 26, 354, 107}, // Variables
                        {false, 5, 26, 133, 180}, // Breakpoints
                        {false, 5, 26, 217, 201}, // Timers
                        {false, 5, 26, 74, 168}, // PWM
                        {false, 5, 26, 0, 218}, // ROM
                        {false, 5, 26, 0, 218}, // RAM
                },
                4,
                1226,
                570
        },
        {
            "Assembly Development",
            {
                    {true, 5, 26}, // Display
                    {true, 1071, 25, 164, 430}, // Processor
                    {true, 5, 450, 496, 192}, // Print log
                    {true, 506, 472, 552, 170}, // IO
                    {true, 5, 648, 1268, 75}, // GPIO
                    {true, 1240, 25, 354, 430}, // Disassembly
                    {false, 5, 26, 354, 358}, // Functions
                    {false, 5, 26, 354, 135}, // Locals
                    {false, 5, 26, 354, 106}, // Calls
                    {false, 5, 26, 354, 107}, // Variables
                    {true, 1144, 460, 133, 180}, // Breakpoints
                    {true, 1282, 459, 217, 201}, // Timers
                    {true, 1064, 472, 74, 168}, // PWM
                    {true, 506, 25, 0, 218}, // ROM
                    {true, 506, 248, 0, 218}, // RAM
            },
            3
        },
        {
                "C Development",
                {
                        {true, 5, 26}, // Display
                        {false, 1275, 26, 164, 430}, // Processor
                        {true, 4, 451, 496, 281}, // Print log
                        {true, 505, 562, 552, 170}, // IO
                        {true, 5, 736, 1268, 75}, // GPIO
                        {false, 5, 26, 354, 430}, // Disassembly
                        {true, 505, 26, 654, 532}, // Functions
                        {true, 1163, 136, 329, 210}, // Locals
                        {true, 1163, 27, 329, 106}, // Calls
                        {true, 1163, 351, 329, 207}, // Variables
                        {true, 1139, 563, 133, 168}, // Breakpoints
                        {true, 1276, 563, 217, 201}, // Timers
                        {true, 1061, 563, 74, 168}, // PWM
                        {false, 5, 26, 0, 218}, // ROM
                        {false, 5, 26, 0, 218}, // RAM
                },
                3,
                1497,
                816
        },
};

static const char* WINDOW_DISPLAY = "Display";
static const char* WINDOW_PROCESSOR = "Processor";
static const char* WINDOW_PRINT_LOG = "Print Log";
static const char* WINDOW_IO = "IO Panel";
static const char* WINDOW_GPIO = "GPIO";
static const char* WINDOW_DISASSEMBLY = "Disassembly";
static const char* WINDOW_FUNCTIONS = "Functions";
static const char* WINDOW_LOCALS = "Local Variables";
static const char* WINDOW_CALLS = "Call Stack";
static const char* WINDOW_VARIABLES = "Global Variables";
static const char* WINDOW_BREAKPOINTS = "Breakpoints";
static const char* WINDOW_TIMERS = "Timers";
static const char* WINDOW_PWM = "PWM";
static const char* WINDOW_ROM = "ROM Viewer";
static const char* WINDOW_RAM = "RAM Editor";
static const char* WINDOWS[WINDOW_COUNT]{
    WINDOW_DISPLAY,
    WINDOW_PROCESSOR,
    WINDOW_PRINT_LOG,
    WINDOW_IO,
    WINDOW_GPIO,
    WINDOW_DISASSEMBLY,
    WINDOW_FUNCTIONS,
    WINDOW_LOCALS,
    WINDOW_CALLS,
    WINDOW_VARIABLES,
    WINDOW_BREAKPOINTS,
    WINDOW_TIMERS,
    WINDOW_PWM,
    WINDOW_ROM,
    WINDOW_RAM
};

static SDL_Window *window;
static SDL_GLContext glContext;
static SDL_AudioDeviceID audioDevice;
static ImGuiIO *imguiIO;
static GLuint displayTexture;
static bool exited = false;
static bool layoutLoaded = false;
static const Layout *layoutToLoad = nullptr;

static std::map<std::string, bool> windowStates;
static int displayScale = 3;
static bool controllerPeripheral = true;
static bool keypadPeripheral = false;
static int processorSpeeds[8]{0, 1, 2, 3, 4, 5, 9, 14};
static int processorSpeed = 0;

static Emulator *emulator;
static Disassembler* disassembler;
static MemoryEditor *ramEditor;
static MemoryEditor *romViewer;
static uint8_t *rom;
static std::map<std::string, DebugFunction> debugFunctions;
static std::map<std::string, DebugVariable> debugVariables;
static std::map<std::string, uint32_t> debugProgramLabels;
static std::map<std::string, uint32_t> debugDataLabels;
static std::map<std::string, uint32_t> debugMappedLabels;
static std::map<std::string, std::vector<std::string>> debugFiles;
static bool halted = false;
static bool paused = false;
static bool disassemblerJumpToPC = true;
static bool functionsJumpToPC = true;
static bool stepBreakpoint = false;
static bool stepBreakpointC = false;
static bool enableBreakpoints = false;
static bool showAllLocals = false;
static std::set<uint32_t> breakpoints{};
static char breakpointText[6]{};
static char uartText[255]{};
static bool showFramerate = false;

// Todo: Give colors better names
static ImFont *font7Segment;
static ImVec4 *windowColor;
static ImVec4 *flagColor;
static ImVec4 *registerColor;
static ImVec4 *breakpointColor;
static ImVec4 *outputColor;
static ImVec4 *disabledColor;

static void loadLayout(const Layout &layout) {
    SDL_SetWindowSize(window, layout.windowWidth, layout.windowHeight);
    displayScale = layout.displayScale;
    for (int i = 0; i < WINDOW_COUNT; i++) {
        ImGui::SetWindowPos(WINDOWS[i], ImVec2(layout.locations[i].x, layout.locations[i].y));
        ImGui::SetWindowSize(WINDOWS[i], ImVec2(layout.locations[i].width, layout.locations[i].height));
        windowStates[WINDOWS[i]] = layout.locations[i].shown;
    }
}

static void setupPersistenceHandler(ImGuiContext *context) {
    ImGuiContext& g = *context;
    ImGuiSettingsHandler ini_handler;
    ini_handler.TypeName = "Emulator";
    ini_handler.TypeHash = ImHashStr("Emulator");
    ini_handler.ClearAllFn = [](ImGuiContext* ctx, ImGuiSettingsHandler* handler) {

    };
    ini_handler.ReadOpenFn = [](ImGuiContext* ctx, ImGuiSettingsHandler* handler, const char* name) -> void* {
        return (void*)1; // Return anything except nullptr or ReadLineFn won't be called
    };
    ini_handler.ReadLineFn = [](ImGuiContext* ctx, ImGuiSettingsHandler* handler, void* entry, const char* line) {
        int value, value2, n;
        for (const auto & name : WINDOWS) {
            char buffer[40];
            snprintf(buffer, 40, "Show%s=%%d%%n", name);
            if (sscanf(line, buffer, &value, &n) == 1) {
                windowStates[name] = value;
                return;
            }
        }
        if (sscanf(line, "DisplayScale=%d%n", &value, &n) == 1)
            displayScale = value;
        if (sscanf(line, "ProcessorSpeed=%d%n", &value, &n) == 1)
            processorSpeed = value;
        else if (sscanf(line, "WindowSize=%d,%d%n", &value, &value2, &n) == 2)
            SDL_SetWindowSize(window, value, value2);
        else if (sscanf(line, "Controller=%d%n", &value, &n) == 1)
            controllerPeripheral = value;
        else if (sscanf(line, "Keypad=%d%n", &value, &n) == 1)
            keypadPeripheral = value;
    };
    ini_handler.ApplyAllFn = [](ImGuiContext* ctx, ImGuiSettingsHandler* handler) {
        ramEditor->Open = windowStates[WINDOW_RAM];
        romViewer->Open = windowStates[WINDOW_ROM];
        layoutLoaded = true;
    };
    ini_handler.WriteAllFn = [](ImGuiContext* ctx, ImGuiSettingsHandler* handler, ImGuiTextBuffer* buf) {
        buf->append("[Emulator][Data]\n");
        buf->appendf("DisplayScale=%d\n", displayScale);
        buf->appendf("ProcessorSpeed=%d\n", processorSpeed);
        for (const auto & name : WINDOWS)
            buf->appendf("Show%s=%d\n", name, windowStates[name]);
        int w, h;
        SDL_GetWindowSize(window, &w, &h);
        buf->appendf("WindowSize=%d,%d\n", w, h);
        buf->appendf("Controller=%d\n", controllerPeripheral);
        buf->appendf("Keypad=%d\n", keypadPeripheral);
    };
    g.SettingsHandlers.push_back(ini_handler);
}

static bool loadDebugSymbols(const std::string &path) {
#ifndef __EMSCRIPTEN__
    std::ifstream debug(path);
    if (!debug.good()) {
        std::cout << "Failed to open debug symbols: '" << path << "'" << std::endl;
        return false;
    }
    nlohmann::json json;
    debug >> json;
    json["functions"].get_to(debugFunctions);
    json["variables"].get_to(debugVariables);
    json["program_labels"].get_to(debugProgramLabels);
    json["data_labels"].get_to(debugDataLabels);
    json["mapped_labels"].get_to(debugMappedLabels);

    std::set<std::string> files;
    for (const auto &function: debugFunctions)
        files.emplace(function.second.source);
    for (const auto &variable: debugVariables)
        files.emplace(variable.second.source);
    for (const auto &file: files) {
        std::filesystem::path filePath(path);
        filePath = filePath.parent_path();
        filePath /= file;
        std::ifstream source(filePath);
        if (!source.good()) {
            std::cout << "Failed to open: \"" << filePath << "\"" << std::endl;
            return false;
        }
        std::vector<std::string> sourceLines;
        std::string line;
        while (std::getline(source, line))
            sourceLines.emplace_back(line);
        debugFiles[file] = sourceLines;
    }
#endif
    return true;
}

static bool loadRom(const std::string &path) {
#ifndef __EMSCRIPTEN__
    std::ifstream input(path, std::ios::binary);
    if (!input.good()) {
        std::cout << "Failed to open ROM: '" << path << "'" << std::endl;
        return false;
    }
    input.seekg(0, std::ios::end);
    long len = input.tellg();
    rom = new uint8_t[len];
    input.seekg(0, std::ios::beg);
    input.read(reinterpret_cast<char *>(rom), len);
    input.close();
    emulator->load(rom, len);
    delete disassembler;
    disassembler = new Disassembler(emulator->getMemory());

    debugFunctions.clear();
    debugVariables.clear();
    debugProgramLabels.clear();
    debugDataLabels.clear();
    debugMappedLabels.clear();
    debugFiles.clear();
#else
    emscripten_fetch_attr_t attr;
    emscripten_fetch_attr_init(&attr);
    strcpy(attr.requestMethod, "GET");
    attr.attributes = EMSCRIPTEN_FETCH_LOAD_TO_MEMORY;
    attr.onsuccess = [](auto fetch) {
        auto len = fetch->numBytes;
        rom = new uint8_t[len];
        memcpy(rom, fetch->data, len);
        emscripten_fetch_close(fetch);
        emulator->load(rom, len);
        delete disassembler;
        disassembler = new Disassembler(emulator->getMemory());
        halted = false;
        breakpoints.clear();
        enableBreakpoints = false;
        emulator->reset();
    };
    emscripten_fetch(&attr, path.c_str());
#endif
    return true;
}

static void displayMainMenuBar() {
    if (ImGui::BeginMainMenuBar()) {
        if (ImGui::BeginMenu("File")) {
#ifndef __EMSCRIPTEN__
            if (ImGui::MenuItem("Open ROM", "ctrl+O"))
                ImGuiFileDialog::Instance()->OpenDialog("ChooseROM", "Choose ROM", ".bin", ".");
            if (ImGui::MenuItem("Load Debug Symbols"))
                ImGuiFileDialog::Instance()->OpenDialog("LoadSymbols", "Load Debug Symbols", ".debug", ".");
            if (ImGui::MenuItem("Exit"))
                exited = true;
#else
            static const char *roms[] {"C Snake", "Tetris", "Hello World", "Demo", "Dice", "Parrot", "Blink", "Number Game"};
            for (auto &memory: roms)
                if (ImGui::MenuItem(memory))
                    loadRom(memory + std::string(".bin"));
#endif
            ImGui::EndMenu();
        }
        if (ImGui::BeginMenu("Emulation")) {
            if (ImGui::MenuItem("Reset", "ctrl+R")) {
                halted = false;
                emulator->reset();
            }
            ImGui::MenuItem("Pause", "ctrl+P", &paused);
            ImGui::MenuItem("Enable Breakpoints", "ctrl+B", &enableBreakpoints);
            if (ImGui::MenuItem("Step CPU", "ctrl+Z") and !halted and paused)
                stepBreakpoint = true;
            if (ImGui::MenuItem("Step C Code", "ctrl+X") and !halted and paused and !debugFunctions.empty())
                stepBreakpointC = true;
            ImGui::Combo("Processor Speed", &processorSpeed, " 1 MHz\0 512 KHz\0 256 KHz\0 128 KHz\0 64 KHz\0 32 KHz\0 2 Khz\0 64 Hz\0", 8);
            ImGui::EndMenu();
        }
        if (ImGui::BeginMenu("Peripherals")) {
            ImGui::MenuItem("Controller", nullptr, &controllerPeripheral);
            ImGui::MenuItem("Keypad", nullptr, &keypadPeripheral);
            ImGui::EndMenu();
        }
        if (ImGui::BeginMenu("View")) {
            ImGui::MenuItem("Show Display", nullptr, &windowStates[WINDOW_DISPLAY]);
            ImGui::MenuItem("Show Print Log", nullptr, &windowStates[WINDOW_PRINT_LOG]);
            ImGui::MenuItem("Show I/O Panel", nullptr, &windowStates[WINDOW_IO]);
            ImGui::MenuItem("Show GPIO", nullptr, &windowStates[WINDOW_GPIO]);
            ImGui::Separator();
            ImGui::MenuItem("Show ROM Viewer", nullptr, &windowStates[WINDOW_ROM]);
            ImGui::MenuItem("Show RAM Editor", nullptr, &windowStates[WINDOW_RAM]);
            ImGui::MenuItem("Show Processor", nullptr, &windowStates[WINDOW_PROCESSOR]);
            ImGui::MenuItem("Show Disassembly", nullptr, &windowStates[WINDOW_DISASSEMBLY]);
            ImGui::MenuItem("Show Breakpoints", nullptr, &windowStates[WINDOW_BREAKPOINTS]);
            ImGui::MenuItem("Show Timers", nullptr, &windowStates[WINDOW_TIMERS]);
            ImGui::MenuItem("Show PWM", nullptr, &windowStates[WINDOW_PWM]);
            ImGui::Separator();
            ImGui::MenuItem("Show Functions", nullptr, &windowStates[WINDOW_FUNCTIONS]);
            ImGui::MenuItem("Show Locals", nullptr, &windowStates[WINDOW_LOCALS]);
            ImGui::MenuItem("Show Calls", nullptr, &windowStates[WINDOW_CALLS]);
            ImGui::MenuItem("Show Variables", nullptr, &windowStates[WINDOW_VARIABLES]);
            ImGui::EndMenu();
        }
        if (ImGui::BeginMenu("Layout")) {
            for (const auto &layout : LAYOUTS)
                if (ImGui::MenuItem(layout.name)) {
                    loadLayout(layout);
                    layoutToLoad = &layout;
                }
            ImGui::EndMenu();
        }
        ImGui::EndMainMenuBar();
    }
}

static void displayRomBrowser() {
#ifndef __EMSCRIPTEN__
    if (ImGuiFileDialog::Instance()->Display("ChooseROM", ImGuiWindowFlags_NoCollapse, ImVec2(400, 250))) {
        if (ImGuiFileDialog::Instance()->IsOk()) {
            halted = false;
            breakpoints.clear();
            enableBreakpoints = false;
            loadRom(ImGuiFileDialog::Instance()->GetCurrentPath() + "/" + ImGuiFileDialog::Instance()->GetCurrentFileName());
            emulator->reset();
        }
        ImGuiFileDialog::Instance()->Close();
    }
#endif
}

static void displayDebugSymbolBrowser() {
#ifndef __EMSCRIPTEN__
    if (ImGuiFileDialog::Instance()->Display("LoadSymbols", ImGuiWindowFlags_NoCollapse, ImVec2(400, 250))) {
        if (ImGuiFileDialog::Instance()->IsOk())
            loadDebugSymbols(ImGuiFileDialog::Instance()->GetCurrentPath() + "/" + ImGuiFileDialog::Instance()->GetCurrentFileName());
        ImGuiFileDialog::Instance()->Close();
    }
#endif
}

static void displayScreen() {
    if (!windowStates[WINDOW_DISPLAY])
        return;

    ImGui::Begin(WINDOW_DISPLAY, &windowStates[WINDOW_DISPLAY], ImGuiWindowFlags_AlwaysAutoResize);

    // Right click context menu
    if (ImGui::IsWindowHovered(ImGuiHoveredFlags_RootAndChildWindows) && ImGui::IsMouseReleased(ImGuiMouseButton_Right))
        ImGui::OpenPopup("context");

    // Options menu
    if (ImGui::BeginPopup("context")) {
        ImGui::SetNextItemWidth(100);
        if (ImGui::DragInt("##scale", &displayScale, 0.2f, 1, 6, "Scale: %dx")) {
            if (displayScale < 1)
                displayScale = 1;
        }
        ImGui::Checkbox("Show Framerate", &showFramerate);
        ImGui::EndPopup();
    }

    ImGui::Image((ImTextureID)(intptr_t)displayTexture, ImVec2(DISPLAY_WIDTH * displayScale / 2., DISPLAY_HEIGHT * displayScale / 2.));

    // Options button
    if (ImGui::Button("Options"))
        ImGui::OpenPopup("context");

    if (showFramerate)
        ImGui::Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate);

    ImGui::End();
}

static void displayMemoryViewers() {
    romViewer->Open = windowStates[WINDOW_ROM];
    ramEditor->Open = windowStates[WINDOW_RAM];
    if (romViewer->Open)
        romViewer->DrawWindow(WINDOW_ROM, emulator->getROM(), 0x18000);
    if (ramEditor->Open)
        ramEditor->DrawWindow(WINDOW_RAM, emulator->getRAM(), 0x8000, 0x18000);
    windowStates[WINDOW_ROM] = romViewer->Open;
    windowStates[WINDOW_RAM] = ramEditor->Open;
}

// Todo: Use ImGui::PushTextWrapPos
static void displayPrintLog() {
    if (!windowStates[WINDOW_PRINT_LOG])
        return;

    ImGui::Begin(WINDOW_PRINT_LOG, &windowStates[WINDOW_PRINT_LOG]);
    ImGui::BeginChild("PrintLog", ImVec2(ImGui::GetWindowWidth() - 10, ImGui::GetWindowHeight() - 60), true);
    ImGui::PushTextWrapPos(ImGui::GetWindowWidth() - 30);
    ImGui::TextUnformatted(emulator->getPrintBuffer().data());
    ImGui::PopTextWrapPos();
    ImGui::EndChild();
    if (ImGui::Button("Clear"))
        emulator->getPrintBuffer().clear();
    ImGui::SameLine();

    ImGui::SetNextItemWidth(ImGui::GetWindowWidth() - 120);
    ImGui::InputText("", uartText, 255);
    ImGui::SameLine();
    if (ImGui::Button("Send")) {
        emulator->uartReceive(uartText, strlen(uartText));
        uartText[0] = 0;
    }
    ImGui::End();
}

static void displayPanelIO() {
    if (!windowStates[WINDOW_IO])
        return;

    ImGui::Begin(WINDOW_IO, &windowStates[WINDOW_IO], ImGuiWindowFlags_NoResize);
    ImGui::BeginColumns("I/O Columns", 10, ImGuiOldColumnFlags_NoResize);

    // Switches
    for (int i = 0; i < 10; i++) {
        ImGui::BeginGroup();
        ImGui::Dummy(ImVec2(1, 0));
        ImGui::SameLine();
        ToggleButton(("SW" + std::to_string(i)).c_str(), &emulator->getSwitch(i));
        ImGui::EndGroup();
        ImGui::NextColumn();
    }
    for (int i = 0; i < 10; i++) {
        ImGui::Text("  SW%d", i);
        ImGui::NextColumn();
    }
    ImGui::Separator();

    // LEDs
    for (int i = 0; i < 10; i++) {
        ImVec2 p = ImGui::GetCursorScreenPos();
        ImDrawList* draw_list = ImGui::GetWindowDrawList();
        draw_list->AddCircleFilled(ImVec2(p.x + 20, p.y + 15), 8, emulator->getLight(i) ?
                                                                  IM_COL32(255, 50, 50, 255) : IM_COL32(50, 50, 50, 255));
        ImGui::Dummy(ImVec2(20, 22));
        ImGui::NextColumn();
    }
    for (int i = 0; i < 10; i++) {
        ImGui::Text(" LED%d", i);
        ImGui::NextColumn();
    }
    ImGui::Separator();

    // Buttons
    for (int i = 0; i < 2; i++) {
        ImGui::Button(("BTN" + std::to_string(i)).c_str(), ImVec2(42, 42));
        emulator->getButton(i) = ImGui::IsItemActive();
        ImGui::NextColumn();
    }

    // Seven segment displays
    for (int i = 5; i >= 0; i--) {
        ImGui::PushFont(font7Segment);
        ImGui::BeginGroup();
        ImGui::Dummy(ImVec2(2, 0));
        ImGui::SameLine();
        ImGui::Text("%x", emulator->getSevenSegmentDisplay(i) & 0xF);
        ImGui::EndGroup();
        ImGui::PopFont();
        ImGui::NextColumn();
    }

    ImGui::End();
}

static void displayPanelGPIO() {
    if (!windowStates[WINDOW_GPIO])
        return;

    ImGui::Begin(WINDOW_GPIO, &windowStates[WINDOW_GPIO], ImGuiWindowFlags_NoResize);
    if (ImGui::BeginTable("GPIO Table", 3)) {
        ImGui::TableSetupColumn("GPIO", ImGuiTableColumnFlags_WidthFixed, 725);
        ImGui::TableSetupColumn("Arduino Header I/O", ImGuiTableColumnFlags_WidthFixed, 325);
        ImGui::TableSetupColumn("ADCs", ImGuiTableColumnFlags_WidthFixed, 180);
        ImGui::TableHeadersRow();
        char buf[3];

        ImGuiTextFlags ioFlags = ImGuiInputTextFlags_NoHorizontalScroll | ImGuiInputTextFlags_CharsHexadecimal
                | ImGuiInputTextFlags_AlwaysOverwrite | ImGuiInputTextFlags_AutoSelectAll;

        // GPIO
        ImGui::TableNextColumn();
        for (int i = 0; i < 36; i++) {
            ImGui::PushID(i);
            sprintf(buf, "%d", emulator->getGPIO(i));
            ImGui::SetNextItemWidth(12);
            bool output = emulator->getGpioOutput(i);
            if (output)
                ImGui::PushStyleColor(ImGuiCol_Text, emulator->getGPIO(i) ? *outputColor : *breakpointColor);
            if (ImGui::InputText("##", buf, 2, ioFlags | (output ? ImGuiInputTextFlags_ReadOnly : 0)))
                emulator->getGPIO(i) = buf[0] != '0';
            if (output)
                ImGui::PopStyleColor();
            if (ImGui::IsItemHovered())
                ImGui::SetTooltip("GPIO %d", i);
            ImGui::SameLine();
            ImGui::PopID();
        }

        // Arduino I/O
        ImGui::TableNextColumn();
        for (int i = 0; i < 16; i++) {
            ImGui::PushID(i + 36);
            sprintf(buf, "%d", emulator->getArduinoIO(i));
            ImGui::SetNextItemWidth(12);
            bool output = emulator->getArduinoOutput(i);
            if (output)
                ImGui::PushStyleColor(ImGuiCol_Text, emulator->getArduinoIO(i) ? *outputColor : *breakpointColor);
            if (ImGui::InputText("##", buf, 2, ioFlags | (output ? ImGuiInputTextFlags_ReadOnly : 0)))
                emulator->getArduinoIO(i) = buf[0] != '0';
            if (output)
                ImGui::PopStyleColor();
            if (ImGui::IsItemHovered())
                ImGui::SetTooltip("Arduino I/O %d", i);
            ImGui::SameLine();
            ImGui::PopID();
        }

        // ADCs
        ImGui::TableNextColumn();
        for (int i = 0; i < 6; i++) {
            ImGui::PushID(i + 52);
            sprintf(buf, "%x", emulator->getADC(i));
            ImGui::SetNextItemWidth(24);
            if (ImGui::InputText("##", buf, 3, ImGuiInputTextFlags_NoHorizontalScroll
                                               | ImGuiInputTextFlags_CharsHexadecimal | ImGuiInputTextFlags_AlwaysOverwrite | ImGuiInputTextFlags_AutoSelectAll))
                emulator->getADC(i) = strtol(buf, nullptr, 16);
            if (ImGui::IsItemHovered())
                ImGui::SetTooltip("ADC %d", i);
            ImGui::SameLine();
            ImGui::PopID();
        }
        ImGui::EndTable();
    }
    ImGui::End();
}

static void displayProcessor() {
    if (!windowStates[WINDOW_PROCESSOR])
        return;

    ImGui::Begin(WINDOW_PROCESSOR, &windowStates[WINDOW_PROCESSOR]/*, ImGuiWindowFlags_NoResize*/);

    // CPU Flags
    ImGui::TextColored(*flagColor, "   Z");
    ImGui::SameLine();
    ImGui::Text("= %d", (bool)(emulator->getStatus() & FLAG_Z));
    ImGui::SameLine();
    ImGui::TextColored(*flagColor, "  C");
    ImGui::SameLine();
    ImGui::Text("= %d", (bool)(emulator->getStatus() & FLAG_C));
    ImGui::TextColored(*flagColor, "   N");
    ImGui::SameLine();
    ImGui::Text("= %d", (bool)(emulator->getStatus() & FLAG_N));
    ImGui::SameLine();
    ImGui::TextColored(*flagColor, "  V");
    ImGui::SameLine();
    ImGui::Text("= %d", (bool)(emulator->getStatus() & FLAG_V));
    ImGui::Text("Interrupts:");
    ImGui::SameLine();
    if ((emulator->getStatus() & FLAG_I))
        ImGui::TextColored(*outputColor, "enabled");
    else
        ImGui::TextColored(*breakpointColor, "disabled");

    // Halted or not
    ImGui::NextColumn();
    ImGui::Text("    Halted:");
    ImGui::SameLine();
    ImGui::TextColored(halted ? *outputColor : *breakpointColor, halted ? "true" : "false");

    // CPU Registers
    ImGui::Columns(2, "registers");

    ImGui::NextColumn();
    ImGui::Columns(1);
    ImGui::Separator();

    // PC
    ImGui::TextColored(*flagColor, "    PC: ");
    ImGui::SameLine();
    ImGui::Text("$%08X", emulator->getPC());

    // IE
    ImGui::TextColored(*flagColor, "    IE: ");
    ImGui::SameLine();
    ImGui::Text(BYTE_TO_BINARY_PATTERN, BYTE_TO_BINARY(emulator->getIE()));

    // IF
    ImGui::TextColored(*flagColor, "    IF: ");
    ImGui::SameLine();
    ImGui::Text(BYTE_TO_BINARY_PATTERN, BYTE_TO_BINARY(emulator->getIF()));

    ImGui::Separator();

    for (int i = 0; i <= 13; i++) {
        ImGui::TextColored(*registerColor, i >= 10 ? "    R%d:" : "    R%d: ", i);
        ImGui::SameLine();
        ImGui::Text("$%08X", emulator->getReg(i));
    }

    // FP
    ImGui::TextColored(*flagColor, "    FP: ");
    ImGui::SameLine();
    ImGui::Text("$%08X", emulator->getFP());

    // SP
    ImGui::TextColored(*flagColor, "    SP: ");
    ImGui::SameLine();
    ImGui::Text("$%08X", emulator->getSP());

    ImGui::End();
}

static void displayDisassembly() {
    if (!windowStates[WINDOW_DISASSEMBLY])
        return;

    ImGui::Begin(WINDOW_DISASSEMBLY, &windowStates[WINDOW_DISASSEMBLY]);
    ImGui::BeginChild("DisassemblyView", ImVec2(ImGui::GetWindowWidth() - 10, ImGui::GetWindowHeight() - 60), true);
    if (disassembler) {
        long previousEnd = -1;
        for (const auto &instruction: disassembler->getDisassembled()) {
            if (previousEnd != -1 and previousEnd < instruction.address)
                ImGui::TextUnformatted("----------------------------------");
            for (auto const &entry: debugProgramLabels)
                if (entry.second == instruction.address)
                    ImGui::Text("%s:", entry.first.c_str());
            ImGui::PushStyleColor(ImGuiCol_Text, emulator->getPC() == instruction.address ? *flagColor : *windowColor);
            ImGui::TextUnformatted(instruction.assembly.c_str());
            ImGui::PopStyleColor();
            if (emulator->getPC() == instruction.address and disassemblerJumpToPC)
                ImGui::SetScrollHereY();
            previousEnd = instruction.address + instruction.size;
        }
    }
    ImGui::EndChild();
    ImGui::Checkbox("Follow PC", &disassemblerJumpToPC);
    ImGui::End();
}

static std::string getVarType(const DebugVariable &variable) {
    std::string string{};
    switch(variable.type[0]) {
        case 'u':
            string += "u";
        case 'i':
            string += stringFormat("int%i_t", variable.type_size * 8);
            break;
        default:
            string += "?";
    }
    if (variable.pointer)
        string += "*";
    if (variable.array)
        string += stringFormat("[%i]", variable.array);
    return string;
}

static std::string getVarValue(const DebugVariable &variable, uint32_t address) {
    std::string string{};
    switch (variable.type[0]) {
        case 'i':
            switch (variable.type_size) {
                case 1:
                    string += stringFormat("%i", *(int8_t *) &emulator->getMemory()[address]);
                    break;
                case 2: {
                    uint16_t result = reverseHalfWordBytes(*(uint16_t *) &emulator->getMemory()[address]);
                    string += stringFormat("%i", *(int16_t *) &result);
                    break;
                }
                default:
                case 4: {
                    uint32_t result = reverseWordBytes(*(int32_t *) &emulator->getMemory()[address]);
                    string += stringFormat("%i", *(int32_t *) &result);
                    break;
                }
            }
            break;
        case 'u':
            switch (variable.type_size) {
                case 1:
                    string += stringFormat("%u", *(uint8_t *) &emulator->getMemory()[address]);
                    break;
                case 2:
                    string += stringFormat("%u", reverseHalfWordBytes(*(uint16_t *) &emulator->getMemory()[address]));
                    break;
                default:
                case 4:
                    string += stringFormat("%u", reverseWordBytes(*(uint32_t *) &emulator->getMemory()[address]));
                    break;
            }
            break;
        default:
            string += "?";
            break;
    }
    return string;
}

static void insertTableVariable(const std::string &name, const DebugVariable &variable, uint32_t fp, bool local = false) {
    ImGui::TableNextRow();
    ImGui::TableNextColumn();
    ImGui::TextUnformatted(name.c_str());
    ImGui::TableNextColumn();
    ImGui::TextUnformatted(getVarType(variable).c_str());
    ImGui::TableNextColumn();

    uint32_t address = local ? fp + variable.address : variable.address;

    if (variable.pointer) {
        uint32_t value = reverseWordBytes(*(uint32_t *) &emulator->getMemory()[address]);
        ImGui::Text("0x%x (%s)", value, getVarValue(variable, value).c_str());
        if (variable.type_size == 1 and variable.type[0] == 'i' and value < 0x20000 and ImGui::IsItemHovered()) {
            ImGui::BeginTooltip();
            ImGui::Text("%.100s", emulator->getMemory() + value);
            ImGui::EndTooltip();
        }
    } else if (variable.array) {
        bool shown = ImGui::TreeNodeEx(&variable, ImGuiTreeNodeFlags_SpanFullWidth, "Array");
        if (variable.type_size == 1 and variable.type[0] == 'i' and ImGui::IsItemHovered()) {
            ImGui::BeginTooltip();
            ImGui::PushTextWrapPos(ImGui::GetFontSize() * 100.0f);
            ImGui::Text("%.*s", variable.array, emulator->getMemory() + address);
            ImGui::PopTextWrapPos();
            ImGui::EndTooltip();
        }
        if (shown) {
            if (variable.type_size)
                for (int i = 0; i < variable.array; i++)
                    ImGui::Text("%i: %s", i, getVarValue(variable, address + i * variable.type_size).c_str());
            ImGui::TreePop();
        }
    } else
        ImGui::TextUnformatted(getVarValue(variable, address).c_str());
}

int getCurrentLine(uint32_t pc, std::string &currentSource) {
    int currentLine = 0;
    for (const auto &function : debugFunctions) {
        if (pc < function.second.code[0].address)
            continue;
        for (int i = 0; i < function.second.code.size(); i++) {
            if (i < function.second.code.size() - 1) {
                if (pc >= function.second.code[i + 1].address)
                    continue;
            } else if (pc >= function.second.end_code)
                break;
            const auto &statement = function.second.code[i];
            currentSource = statement.source;
            currentLine = statement.line;
            break;
        }
        if (!currentSource.empty())
            break;
    }
    return currentLine;
}

static void displayFunctions() {
    uint32_t pc = emulator->getPC();
    uint32_t fp = emulator->getFP();

    if (windowStates[WINDOW_CALLS]) {
        if (ImGui::Begin(WINDOW_CALLS, &windowStates[WINDOW_CALLS])) {
            uint32_t frame = emulator->getFP();
            uint32_t address = emulator->getPC();
            int watchdog = 0;
            if (debugDataLabels.count("_stack") > 0) {
                static uint32_t previousPC = 0;
                static int selected = 0;
                int count = 0;
                if (previousPC != emulator->getPC())
                    selected = 0;
                while (frame >= debugDataLabels["_stack"] and frame <= 0x20000 and address <= 0x20000 and watchdog++ < 1000) {
                    bool found = false;
                    for (const auto &func: debugFunctions)
                        if (func.second.start_code <= address and address <= func.second.end_code) {
                            ImGui::PushID(count);
                            if (ImGui::Selectable(func.first.c_str(), selected == count))
                                selected = count;
                            ImGui::PopID();
                            if (selected == count) {
                                fp = frame;
                                pc = address;
                            }
                            count++;
                            found = true;
                            break;
                        }
                    if (!found)
                        break;
                    address = reverseWordBytes(*(uint32_t *) &emulator->getMemory()[frame - 8]) - 8;
                    frame = reverseWordBytes(*(uint32_t *) &emulator->getMemory()[frame - 4]);
                }
                previousPC = emulator->getPC();
            }
        }
        ImGui::End();
    }

    std::string currentSource;
    int currentLine = getCurrentLine(pc, currentSource);

    if (windowStates[WINDOW_FUNCTIONS]) {
        ImGui::Begin(WINDOW_FUNCTIONS, &windowStates[WINDOW_FUNCTIONS]);

        ImGui::BeginChild("FunctionView", ImVec2(ImGui::GetWindowWidth() - 10,ImGui::GetWindowHeight() - 60), true,ImGuiWindowFlags_HorizontalScrollbar);
        if (!debugFiles.empty() and ImGui::BeginTabBar("FunctionTabView")) {
            for (const auto &file: debugFiles) {
                int flags = ImGuiTabItemFlags_None;
                if (functionsJumpToPC and currentSource == file.first)
                    flags |= ImGuiTabItemFlags_SetSelected;
                if (ImGui::BeginTabItem(file.first.c_str(), nullptr, flags)) {
                    int lineNumber = 1;
                    for (const auto &line: file.second) {
                        bool isStatement = false;

                        for (const auto &function: debugFunctions) {
                            for (const auto &statement: function.second.code)
                                if (statement.source == file.first and statement.line == lineNumber) {
                                    auto draw_list = ImGui::GetWindowDrawList();
                                    ImGui::PushID(statement.line);
                                    bool pressed = ImGui::InvisibleButton("", ImVec2(10, 10));
                                    ImGui::PopID();
                                    auto center = ImVec2((ImGui::GetItemRectMax().x + ImGui::GetItemRectMin().x) / 2,
                                                         (ImGui::GetItemRectMax().y + ImGui::GetItemRectMin().y) / 2);
                                    if (breakpoints.count(statement.address)) {
                                        if (pressed)
                                            breakpoints.erase(statement.address);
                                        draw_list->AddCircleFilled(center, 5, ImColor(*breakpointColor));
                                    } else {
                                        if (pressed)
                                            breakpoints.emplace(statement.address);
                                        draw_list->AddCircle(center, 5, ImColor(*flagColor));
                                    }
                                    isStatement = true;
                                    break;
                                }
                            if (isStatement)
                                break;
                        }

                        if (isStatement)
                            ImGui::SameLine(18);
                        else
                            ImGui::Indent(10);

                        bool isCurrentStatement = currentSource == file.first and currentLine == lineNumber;
                        if (isCurrentStatement and functionsJumpToPC)
                            ImGui::SetScrollHereY();
                        ImGui::PushStyleColor(ImGuiCol_Text, isCurrentStatement ? *flagColor : *windowColor);
                        ImGui::Text("% 3i: %s", lineNumber, line.c_str());
                        ImGui::PopStyleColor();

                        if (!isStatement)
                            ImGui::Unindent(10);

                        lineNumber++;
                    }
                    ImGui::EndTabItem();
                }
            }
            ImGui::EndTabBar();
        }
        ImGui::EndChild();

        ImGui::Checkbox("Follow PC", &functionsJumpToPC);
        ImGui::End();
    }

    if (windowStates[WINDOW_LOCALS]) {
        if (ImGui::Begin(WINDOW_LOCALS, &windowStates[WINDOW_LOCALS])) {
            ImGui::BeginChild("FunctionView", ImVec2(ImGui::GetWindowWidth() - 10, ImGui::GetWindowHeight() - 60),
                              true,ImGuiWindowFlags_HorizontalScrollbar);
            if (ImGui::BeginTable("LocalsTable", 3, ImGuiTableFlags_BordersInnerV | ImGuiTableFlags_SizingFixedFit)) {
                ImGui::TableSetupColumn("Name", ImGuiTableColumnFlags_NoHide);
                ImGui::TableSetupColumn("Type", ImGuiTableColumnFlags_NoHide);
                ImGui::TableSetupColumn("Value", ImGuiTableColumnFlags_NoHide);
                ImGui::TableHeadersRow();
                for (auto const &func: debugFunctions) {
                    if (func.second.start_code <= pc and pc <= func.second.end_code) {
                        for (auto const &var: func.second.locals)
                            if (showAllLocals or (currentLine >= var.line and var.start <= currentLine and currentLine <= var.end))
                                insertTableVariable(var.name, var, fp, true);
                        break;
                    }
                }
                ImGui::EndTable();
            }
            ImGui::EndChild();
            ImGui::Checkbox("Show All", &showAllLocals);
        }
        ImGui::End();
    }
}

static void displayVariables() {
    if (!windowStates[WINDOW_VARIABLES])
        return;

    ImGui::Begin(WINDOW_VARIABLES, &windowStates[WINDOW_VARIABLES]);

    if (ImGui::BeginTable("VariableTable", 3, ImGuiTableFlags_BordersInnerV | ImGuiTableFlags_SizingFixedFit)) {
        ImGui::TableSetupColumn("Name", ImGuiTableColumnFlags_NoHide);
        ImGui::TableSetupColumn("Type", ImGuiTableColumnFlags_NoHide);
        ImGui::TableSetupColumn("Value", ImGuiTableColumnFlags_NoHide);
        ImGui::TableHeadersRow();
        for (const auto &variable: debugVariables) {
            if (variable.second.address >= 0x20000)
                continue;
            insertTableVariable(variable.first, variable.second, emulator->getFP());
        }
        ImGui::EndTable();
    }

    ImGui::End();
}

static void displayBreakpoints() {
    if (!windowStates[WINDOW_BREAKPOINTS])
        return;

    ImGui::Begin(WINDOW_BREAKPOINTS, &windowStates[WINDOW_BREAKPOINTS]);
    ImGui::BeginChild("BreakpointList", ImVec2(ImGui::GetWindowWidth() - 10, ImGui::GetWindowHeight() - 82), true);
    for (auto breakpoint: breakpoints) {
        ImGui::PushID((int)breakpoint);
        if (ImGui::Button("X")) {
            breakpoints.erase(breakpoint);
            ImGui::PopID();
            break;
        }
        ImGui::PopID();
        ImGui::SameLine();
        ImGui::TextColored(*breakpointColor, "$%05x", breakpoint);
    }
    ImGui::EndChild();
    ImGui::SetNextItemWidth(50);
    ImGui::InputText("##", breakpointText, 6, ImGuiInputTextFlags_NoHorizontalScroll
                                              | ImGuiInputTextFlags_CharsHexadecimal | ImGuiInputTextFlags_AlwaysOverwrite | ImGuiInputTextFlags_AutoSelectAll);

    ImGui::SameLine();
    if (ImGui::Button("Add") and breakpointText[0] != 0) {
        breakpoints.insert(strtol(breakpointText, nullptr, 16));
        breakpointText[0] = 0; // Set first character to null to clear string
    }

    if (ImGui::Button("Clear"))
        breakpoints.clear();
    ImGui::SameLine();
    ImGui::Checkbox("Enable", &enableBreakpoints);
    ImGui::End();
}

static void displayTimers() {
    if (!windowStates[WINDOW_TIMERS])
        return;

    ImGui::Begin(WINDOW_TIMERS, &windowStates[WINDOW_TIMERS]);

    ImGui::TextColored(*flagColor, "IE:");
    ImGui::SameLine();
    ImGui::Text(BYTE_TO_BINARY_PATTERN, BYTE_TO_BINARY(emulator->getTimerIE()));

    ImGui::TextColored(*flagColor, "IF:");
    ImGui::SameLine();
    ImGui::Text(BYTE_TO_BINARY_PATTERN, BYTE_TO_BINARY(emulator->getTimerIF()));

    for (int i = 0; i < 8; i++) {
        auto &timer = emulator->getTimer(i);
        ImGui::TextColored(timer.enabled ? *outputColor : *breakpointColor, "Timer%d:", i);
        ImGui::SameLine();
        ImGui::Text("%s/%u/%u (%u)", timer.repeat ? "(R) " : "", timer.divider, timer.compare, (uint32_t)timer.count);
    }

    ImGui::End();
}

static void displayPWM() {
    if (!windowStates[WINDOW_PWM])
        return;

    ImGui::Begin(WINDOW_PWM, &windowStates[WINDOW_PWM]);

    for (int i = 0; i < 8; i++) {
        ImGui::TextColored(emulator->getPWMEnabled(i) ? *outputColor : *breakpointColor, "Ch%d:", i);
        ImGui::SameLine();
        ImGui::Text("%d", emulator->getPWMDuty(i));
    }

    ImGui::End();
}

static void handleShortcuts() {
    if (ImGui::IsKeyDown(SDL_SCANCODE_LCTRL)) {
        if (ImGui::IsKeyPressed(SDL_SCANCODE_P, false))
            paused ^= 1;
#ifndef __EMSCRIPTEN__
        if (ImGui::IsKeyPressed(SDL_SCANCODE_O, false))
            ImGuiFileDialog::Instance()->OpenDialog("ChooseROM", "Choose ROM", ".bin", ".");
#endif
        if (ImGui::IsKeyPressed(SDL_SCANCODE_B, false))
            enableBreakpoints ^= 1;
        if (ImGui::IsKeyPressed(SDL_SCANCODE_Z, true) and !halted and paused)
            stepBreakpoint = true;
        if (ImGui::IsKeyPressed(SDL_SCANCODE_X, true) and !halted and paused and !debugFunctions.empty())
            stepBreakpointC = true;
        if (ImGui::IsKeyPressed(SDL_SCANCODE_R, false)) {
            halted = false;
            emulator->reset();
        }
    }
}

static void runEmulator() {
    if (!halted and (!paused or stepBreakpoint or stepBreakpointC)) {
        for (int i = 0; i < 16667 / (1 << processorSpeeds[processorSpeed]); i++) {
            if (controllerPeripheral) {
                if (!emulator->getGpioOutput(0))
                    emulator->getGPIO(0) = ImGui::IsKeyDown(SDL_SCANCODE_W) or ImGui::IsKeyDown(SDL_SCANCODE_UP);
                if (!emulator->getGpioOutput(1))
                    emulator->getGPIO(1) = ImGui::IsKeyDown(SDL_SCANCODE_S) or ImGui::IsKeyDown(SDL_SCANCODE_DOWN);
                if (!emulator->getGpioOutput(2))
                    emulator->getGPIO(2) = ImGui::IsKeyDown(SDL_SCANCODE_A) or ImGui::IsKeyDown(SDL_SCANCODE_LEFT);
                if (!emulator->getGpioOutput(3))
                    emulator->getGPIO(3) = ImGui::IsKeyDown(SDL_SCANCODE_D) or ImGui::IsKeyDown(SDL_SCANCODE_RIGHT);
            }

            if (keypadPeripheral) {
                static const SDL_Scancode KEYPAD_KEYS[]{
                    SDL_SCANCODE_X, SDL_SCANCODE_1, SDL_SCANCODE_2, SDL_SCANCODE_3,
                    SDL_SCANCODE_Q, SDL_SCANCODE_W, SDL_SCANCODE_E, SDL_SCANCODE_A,
                    SDL_SCANCODE_S, SDL_SCANCODE_D, SDL_SCANCODE_C, SDL_SCANCODE_Z,
                    SDL_SCANCODE_4, SDL_SCANCODE_R, SDL_SCANCODE_F, SDL_SCANCODE_V
                };
                for (int j = 0; j < 16; j++)
                    if (!emulator->getGpioOutput(j))
                        emulator->getGPIO(j) = ImGui::IsKeyDown(KEYPAD_KEYS[j]);
            }

            emulator->fixedUpdate(1 << processorSpeeds[processorSpeed]);

            if (emulator->run()) {
                halted = true;
                break;
            }

            bool broken = false;
            if (enableBreakpoints)
                for (auto breakpoint: breakpoints)
                    if (emulator->getPC() == breakpoint) {
                        broken = true;
                        break;
                    }
            if (broken) {
                paused = true;
                break;
            }

            if (stepBreakpoint) {
                stepBreakpointC = false;
                break;
            }

            if (stepBreakpointC) {
                static int previousLine;
                static std::string previousSource;
                static uint32_t previousFP;
                std::string newSource;
                int newLine = getCurrentLine(emulator->getPC(), newSource);
                if ((previousLine != newLine or previousSource != newSource or previousFP != emulator->getFP()) and newLine != 0 and !newSource.empty()) {
                    previousSource = newSource;
                    previousLine = newLine;
                    previousFP = emulator->getFP();
                    stepBreakpointC = false;
                    break;
                }
            }
        }
        stepBreakpoint = false;
    }
}

void audioCallback(void *userdata, uint8_t *buffer, int len) {
    if (halted or paused)
        memset(buffer, 0, len);
    else
        emulator->sampleAudio((float *) buffer, len / 4);
}

static void mainLoop(void *arg) {
    imguiIO = &ImGui::GetIO();
    IM_UNUSED(arg);

    // Poll events
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        ImGui_ImplSDL2_ProcessEvent(&event);
        if (event.type == SDL_QUIT or (event.type == SDL_WINDOWEVENT && event.window.event == SDL_WINDOWEVENT_CLOSE && event.window.windowID == SDL_GetWindowID(window)))
            exited = true;
    }

    // Start frame
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplSDL2_NewFrame(window);
    ImGui::NewFrame();

    handleShortcuts();

    runEmulator();

    // Update display texture from buffer
    glBindTexture(GL_TEXTURE_2D, displayTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, DISPLAY_WIDTH, DISPLAY_HEIGHT, 0, GL_RGB, GL_UNSIGNED_BYTE, emulator->getDisplayBuffer());
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);

    // Ensure windows are all registered
    {
        static bool init;
        if (!init) {
            for (const auto &name: WINDOWS) {
                ImGui::Begin(name);
                ImGui::End();
            }
            init = true;
        }
    }

    // Load default layout for first run
    if (!layoutLoaded) {
#ifdef __EMSCRIPTEN__
        loadLayout(LAYOUTS[0]);
#else
        loadLayout(LAYOUTS[1]);
#endif
        layoutLoaded = true;
    }

    if (layoutToLoad) {
        loadLayout(*layoutToLoad);
        layoutToLoad = nullptr;
    }

    // Draw windows
    displayMainMenuBar();
    displayRomBrowser();
    displayDebugSymbolBrowser();
    displayScreen();
    displayMemoryViewers();
    displayPrintLog();
    displayPanelIO();
    displayPanelGPIO();
    displayProcessor();
    displayDisassembly();
    displayFunctions();
    displayVariables();
    displayBreakpoints();
    displayTimers();
    displayPWM();

//    ImGui::ShowDemoWindow(); // Uncomment for IMGUI examples

    // Render
    ImGui::Render();
    glViewport(0, 0, (int)imguiIO->DisplaySize.x, (int)imguiIO->DisplaySize.y);
    glClearColor(windowColor->x * windowColor->w, windowColor->y * windowColor->w, windowColor->z * windowColor->w, windowColor->w);
    glClear(GL_COLOR_BUFFER_BIT);
    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
    SDL_GL_SwapWindow(window);
}

int main(int argc, char* argv[]) {
    emulator = new Emulator();

#ifdef __EMSCRIPTEN__
    controllerPeripheral = true;
    loadRom("Tetris.bin");
#else
    // Parse command line arguments
    cxxopts::Options options("emulator", "VBCCSonic emulator");
    options.add_options()
        ("r,rom", "Program ROM", cxxopts::value<std::string>())
        ("d,debug", "Debug symbols file", cxxopts::value<std::string>())
        ("h,help", "Print usage")
    ;
    auto result = options.parse(argc, argv);
    if (result.count("help")) {
        std::cout << options.help() << std::endl;
        return 0;
    }
    if (!result.count("rom"))
        paused = true;
    else if (!loadRom(result["rom"].as<std::string>()))
        return -1;
    if (result.count("debug"))
        loadDebugSymbols(result["debug"].as<std::string>());
#endif

    // Initialize SDL and OpenGL
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_TIMER)) {
        std::cout << "Failed to initialize SDL: " << SDL_GetError() << std::endl;
        return -1;
    }
#ifdef __EMSCRIPTEN__
    const char* glslVersion = "#version 100";
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
#else
    const char* glslVersion = "#version 130";
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
#endif
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, 0);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
    SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
    auto window_flags = (SDL_WindowFlags)(SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI);
    window = SDL_CreateWindow("Emulator", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 1601, 816, window_flags);
    glContext = SDL_GL_CreateContext(window);
    SDL_GL_MakeCurrent(window, glContext);
    SDL_GL_SetSwapInterval(1); // Enable vsync
#ifndef __EMSCRIPTEN__
    auto glewState = glewInit();
    if (glewState != GLEW_OK) {
        std::cout << "Failed to initialize OpenGL loader: " << glewState << std::endl;
        return -1;
    }
#endif

    // Setup ImGui
    IMGUI_CHECKVERSION();
    auto context = ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
#ifdef __EMSCRIPTEN__
    IM_UNUSED(context);
    io.IniFilename = NULL;
#endif
    io.WantCaptureKeyboard = true;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;
    ImGui::StyleColorsDark(); // Setup Dear ImGui style
    ImGui_ImplSDL2_InitForOpenGL(window, glContext);
    ImGui_ImplOpenGL3_Init(glslVersion);
    io.Fonts->AddFontDefault(); // Load default font before others

    // Create display texture
    glGenTextures(1, &displayTexture);

    // Initialize Audio
    SDL_AudioSpec want, have;
    want.freq = 44100;
    want.format = AUDIO_F32;
    want.channels = 1;
    want.samples = 1024;
    want.callback = audioCallback;
    audioDevice = SDL_OpenAudioDevice(nullptr, 0, &want, &have, 0);
    if (!audioDevice) {
        std::cout << "Failed to initialize audio: " << SDL_GetError() << std::endl;
        return -1;
    }
    SDL_PauseAudioDevice(audioDevice, 0);

    // Create ImGui windows
    ramEditor = new MemoryEditor();
    ramEditor->Open = true;
    romViewer = new MemoryEditor();
    romViewer->Open = true;
    romViewer->ReadOnly = true;

    // 7-segment display font
    ImFontConfig config;
    config.SizePixels = 40;
    font7Segment = io.Fonts->AddFontDefault(&config);

    // Colors
    windowColor = new ImVec4(0.45f, 0.55f, 0.60f, 1.00f);
    flagColor = new ImVec4(0.0f,1.0f,1.0f,1.0f);
    registerColor = new ImVec4(1.0f,1.0f,0.0f,1.0f);
    breakpointColor = new ImVec4(1.0f,0.1f,0.1f,1.0f);
    outputColor = new ImVec4(0.0f,1.0f,0.0f,1.0f);
    disabledColor = new ImVec4(0.7f,0.7f,0.7f,1.0f);

#ifdef __EMSCRIPTEN__
    emscripten_set_main_loop_arg(mainLoop, nullptr, 0, true);
    IM_UNUSED(setupPersistenceHandler);
#else
    setupPersistenceHandler(context);

    while (true) {
        mainLoop(nullptr);
        if (exited)
            break;
    }

    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplSDL2_Shutdown();
    ImGui::DestroyContext();
    SDL_GL_DeleteContext(glContext);
    SDL_DestroyWindow(window);
    SDL_CloseAudioDevice(audioDevice);
    SDL_Quit();

    // Must be deleted after ImGui shutdown for INI saving
    delete ramEditor;
    delete romViewer;

    delete windowColor;
    delete registerColor;
    delete flagColor;
    delete breakpointColor;
    delete outputColor;
    delete disabledColor;

    delete disassembler;
    delete[] rom;
#endif

    return 0;
}