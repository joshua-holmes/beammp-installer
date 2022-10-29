#define FMT_HEADER_ONLY
#include <fmt/core.h>
#include <iostream>
#include <filesystem>
#include <vector>
#include <algorithm>
#include <fstream>
#include <array>

using namespace std;

string exec(const char* cmd) {
    array<char, 128> buffer;
    string result;
    unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd, "r"), pclose);
    if (!pipe) {
        throw std::runtime_error("popen() failed!");
    }
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
        result += buffer.data();
    }
    return result;
}


int main(int argc, char** argv) {
    if (!(getenv("HOME") && getenv("USER"))) {
        cout << "Hold up cowboy! Please set your HOME and USER environment variables.\n";
        return 1;
    }
    string home = getenv("HOME");
    string user = getenv("USER");

    string steam = "", pfx, proton, beamng;
    bool init = false;
    if (!system("which steam")) steam = exec("which steam");
    else if (getenv("BEAMMP_LAUNCHER_STEAM")) steam = getenv("BEAMMP_LAUNCHER_STEAM");
    if (getenv("BEAMMP_LAUNCHER_PFX")) pfx = getenv("BEAMMP_LAUNCHER_PFX");
    else pfx = fmt::format("{}/.steam/steam/steamapps/compatdata/284160/pfx", home);
    if (getenv("BEAMMP_LAUNCHER_PROTON")) proton = getenv("BEAMMP_LAUNCHER_PROTON");
    else proton = fmt::format("{}/.steam/steam/steamapps/common/Proton\\ -\\ Experimental/proton", home);
    if (getenv("BEAMMP_LAUNCHER_BEAMNG")) beamng = getenv("BEAMMP_LAUNCHER_BEAMNG");
    else beamng = fmt::format("{}/.steam/steam/steamapps/common/BeamNG.drive/BeamNG.drive.exe", home);

    for (int i = 1; i < argc; i++) {
        string arg = argv[i];
        auto help = [arg, pfx, proton, beamng]() {
            int exitCode;
            if (arg == "--help") {
                cout << "Welcome to the BeamMP Laucher!\n";
                cout << "This program launches BeamMP using an already installed Proton, which is installed using Steam.\n";
                cout << "With a recent update to BeamNG, running the game without using Proton can result in black boxes appearing in the level, which is a texture caching issue.\n";
                cout << "By running BeamMP with Proton, the caching issue no longer occurs. This script makes running BeamMP with Proton easier.\n\n";

                cout << "Argument options are:\n";
                exitCode = 0;
            } else {
                cout << "Incorrect arguments! Options are:\n";
                exitCode = 1;
            }
            
            cout << "--steam <path-to-steam-executable>   default is result of `$ which steam` which finds Steam in PATH\n";
            cout << fmt::format("--pfx <directory-of-BeamNG's-proton/wine-prefix>   default is {}", pfx) << "\n";
            cout << fmt::format("--proton <path-of-proton-executable>   default is {}", proton) << "\n";
            cout << "--init   Vanilla BeamNG will start up on Proton prefix, initialize, close, then BeamMP will start. If BeamMP tells you that BeamNG is not running, try running the program with this flag just one time.\n";
            cout << fmt::format("--beamng <path-of-windows-beamng-executable>   arg only used if --init is used. Default is {}", beamng) << "\n";
            cout << "--help   this help menu" << "\n";
            return exitCode;
        };
        if (i + 1 < argc) {
            string nextArg = argv[i + 1];
            if (arg == "--steam") steam = nextArg;
            else if (arg == "--pfx") pfx = nextArg;
            else if (arg == "--proton") proton = nextArg;
            else if (arg == "--beamng") beamng  = nextArg;
            else return help();
            i++; // Skip next argument because it was already used.
        } else if (arg == "--init") init = true;
        else return help();
    }

    if (steam == "") {
        cout << "Locating Steam with `which steam` failed. Try one of these solutions:\n";
        cout << "1. Install Steam and add to PATH, or\n"; 
        cout << "2. Path to Steam executable needs to be specified as an argument `--steam <path-to-steam-executable>`, or\n";
        cout << "3. Path to Steam executable needs to be added as environment variable BEAMMP_LAUNCHER_STEAM.\n";
        cout << "See `$ beammp-launcher --help` for help.\n";
        return 1;
    }

    setenv("STEAM_COMPAT_DATA_PATH", pfx.c_str(), 1);
    setenv("STEAM_COMPAT_CLIENT_INSTALL_PATH", steam.c_str(), 1);

    string beammpDir = fmt::format("{}/drive_c/users/{}/AppData/Roaming/BeamMP-Launcher", pfx, user);
    string beammp = fmt::format("{}/BeamMP-Launcher.exe", beammpDir);
    

    cout << "Proton prefix directory: " << getenv("STEAM_COMPAT_DATA_PATH") << "\n";
    cout << "Steam executable directory: " << getenv("STEAM_COMPAT_CLIENT_INSTALL_PATH") << "\n";
    cout << "Proton executable file: " << proton << "\n";

    try {
        filesystem::current_path(beammpDir);
        string command;
        if (init) {
            cout << "BeamNG executable file: " << beamng << "\n\n";
            cout << "-----------------------------------------------------------\n";
            cout << "BeamNG is going to initialize before launching BeamMP. This only needs to be done the first time BeamMP is launched.\n";
            cout << "Please wait a couple minutes and avoid interrupting the process...\n";
            cout << "-----------------------------------------------------------\n";
            command = fmt::format("{} run {}", proton, beamng);
        } else {
            command = fmt::format("{} run {}", proton, beammp);
        }
        cout << "\nExecuting: " << command.c_str() << "\n";
        system(command.c_str());
        if (init) cout << "Initialization complete. Please close BeamNG and run this launch script again without --init.\n";
    } catch(std::exception& error) {
        cout << error.what() << "\n\n";
        cout << "Error likely occurred because of incorrect path. See `beammp-launcher --help` for help.\n";
        return 1;
    }
    
    return 0;
}