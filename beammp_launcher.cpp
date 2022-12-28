#include <iostream>
#include <vector>
#include <fstream>
#include <pwd.h>
#include <filesystem>

std::vector<std::string> split(std::string str, char del) {
    std::vector<std::string> result;
    size_t resultInd = 0;
    for (size_t i = 0; i < str.size(); i++) {
        if (str[i] == del) {
            resultInd += 1;
        } else {
            if (result.size() < resultInd + 1) {
                result.push_back(std::string(1, str[i]));
            } else {
                result[resultInd] += str[i];
            }
        }
    }
    return result;
}

void loadConfig(std::string directory) {
    std::ifstream myFile;
    std::string line;
    myFile.open(directory);
    if (myFile.is_open()) {
        while (std::getline(myFile, line)) {
            std::vector<std::string> lineVec = split(line, '#');
            std::string uncommentedLine = lineVec[0];
            std::vector<std::string> newLineVec = split(uncommentedLine, '=');
            if (newLineVec.size() == 2) {
                std::string varName = newLineVec[0], varValue = newLineVec[1];
                setenv(varName.c_str(), varValue.c_str(), 0);
            }
        }
        myFile.close();
    }
}

int main(int argc, char** argv) {
    if (!(std::getenv("HOME") && std::getenv("USER"))) {
        std::cout << "Hold up cowboy! Please set your HOME and USER environment variables.\n";
        return 1;
    }
    std::string home = std::getenv("HOME");
    std::string user = std::getenv("USER");
    if (user == "root") {
        const char* sudoUser = std::getenv("SUDO_USER") ? std::getenv("SUDO_USER") : "";
        struct passwd* userInfo;
        userInfo = getpwnam(sudoUser);
        user = userInfo->pw_name;
        home = userInfo->pw_dir;
    }
    
    std::string configDir = home;
    configDir += "/.config/BeamMP.conf";
    loadConfig(configDir.c_str());

    std::string steam, pfx, proton, beammp;
    steam = std::getenv("BMP_STEAM") ? std::getenv("BMP_STEAM") : "";
    pfx = std::getenv("BMP_PROTON_PREFIX") ? std::getenv("BMP_PROTON_PREFIX") : "";
    proton = std::getenv("BMP_PROTON") ? std::getenv("BMP_PROTON") : "";
    beammp = std::getenv("BMP_BEAMMP") ? std::getenv("BMP_BEAMMP") : "";

    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];
        auto help = [arg]() {
            int exitCode;
            if (arg == "--help") {
                std::cout << "Welcome to the BeamMP Laucher!\n";
                std::cout << "This program launches BeamMP using an already installed Proton, which is installed using Steam.\n";
                std::cout << "With a recent update to BeamNG, running the game without using Proton Experimental can result in black boxes appearing in the level, which is a texture caching issue.\n";
                std::cout << "By running BeamMP with Proton, the caching issue no longer occurs. This script makes running BeamMP with Proton easier.\n\n";

                std::cout << "Argument options are:\n";
                exitCode = 0;
            } else {
                std::cout << "Incorrect arguments! Options are:\n";
                exitCode = 1;
            }
            
            std::cout << "--steam <path-to-steam-executable>\n";
            std::cout << "--pfx <directory-of-beamng's-proton-prefix>\n";
            std::cout << "--proton <path-of-proton-executable>\n";
            std::cout << "--beammp <path-of-windows-beammp-executable>\n";
            std::cout << "--help   this help menu" << "\n";
            return exitCode;
        };
        if (i + 1 < argc) {
            std::string nextArg = argv[i + 1];
            if (arg == "--steam") steam = nextArg;
            else if (arg == "--pfx") pfx = nextArg;
            else if (arg == "--proton") proton = nextArg;
            else if (arg == "--beammp") beammp = nextArg;
            else return help();
            i++; // Skip next argument because it was already used.
        }
        else return help();
    }

    if (steam == "" || pfx == "" || proton == "" || beammp == "") {
        if (steam == "") std::cout << "Cannot find Steam executable file." << "\n";
        if (pfx == "") std::cout << "Cannot find BeamNG Proton prefix directory." << "\n";
        if (proton == "") std::cout << "Cannot find Proton Experimental executable file." << "\n";
        if (beammp == "") std::cout << "Cannot find BeamMP executable file." << "\n";
        std::cout << "\nSee `$ beammp-launcher --help` for help.\n";
        return 1;
    }
    

    setenv("STEAM_COMPAT_DATA_PATH", pfx.c_str(), 1);
    setenv("STEAM_COMPAT_CLIENT_INSTALL_PATH", steam.c_str(), 1);
    

    std::cout << "Proton prefix directory: " << std::getenv("STEAM_COMPAT_DATA_PATH") << "\n";
    std::cout << "Steam executable directory: " << std::getenv("STEAM_COMPAT_CLIENT_INSTALL_PATH") << "\n";
    std::cout << "Proton executable file: " << proton << "\n";

    try {
        std::filesystem::path beammpDir = beammp;
        beammpDir = beammpDir.remove_filename();

        std::filesystem::current_path(beammpDir);
        std::string command = proton;
        command += " run ";
        command += beammp;
        std::cout << "Executing: " << command.c_str() << "\n\n";
        system(command.c_str());
    } catch(std::exception& error) {
        std::cout << error.what() << "\n\n";
        std::cout << "Error likely occurred because of incorrect path. See `beammp-launcher --help` for help.\n";
        return 1;
    }
    
    return 0;
}