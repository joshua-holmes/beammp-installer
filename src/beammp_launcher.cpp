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
        printf("Hold up cowboy! Please set your HOME and USER environment variables.\n");
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
                printf("Welcome to the BeamMP Laucher!\n");
                printf("This program launches BeamMP using an already installed Proton, which is installed using Steam.\n");
                printf("With a recent update to BeamNG, running the game without using Proton Experimental can result in black boxes appearing in the level, which is a texture caching issue.\n");
                printf("By running BeamMP with Proton, the caching issue no longer occurs. This script makes running BeamMP with Proton easier.\n\n");

                printf("Argument options are:\n");
                exitCode = 0;
            } else {
                printf("Incorrect arguments! Options are:\n");
                exitCode = 1;
            }
            
            printf("--steam <path-to-steam-executable>\n");
            printf("--pfx <directory-of-beamng's-proton-prefix>\n");
            printf("--proton <path-of-proton-executable>\n");
            printf("--beammp <path-of-windows-beammp-executable>\n");
            printf("--help   this help menu\n");
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
        if (steam == "") printf("Cannot find Steam executable file.\n");
        if (pfx == "") printf("Cannot find BeamNG Proton prefix directory.\n");
        if (proton == "") printf("Cannot find Proton Experimental executable file.\n");
        if (beammp == "") printf("Cannot find BeamMP executable file.\n");
        printf("\nSee `$ beammp-launcher --help` for help.\n");
        return 1;
    }

    setenv("STEAM_COMPAT_DATA_PATH", pfx.c_str(), 1);
    setenv("STEAM_COMPAT_CLIENT_INSTALL_PATH", steam.c_str(), 1);

    printf("Proton prefix directory: %s \n", std::getenv("STEAM_COMPAT_DATA_PATH"));
    printf("Steam executable directory: %s \n", std::getenv("STEAM_COMPAT_CLIENT_INSTALL_PATH"));
    printf("Proton executable file: %s \n", proton.c_str());

    std::filesystem::path beammpDir = beammp;
    beammpDir = beammpDir.remove_filename();

    printf("Entering this directory:\n");
    printf("%s \n", beammpDir.c_str());
    std::filesystem::current_path(beammpDir);
    std::string command = proton;
    command += " run ";
    command += beammp;
    printf("Executing: %s \n\n", command.c_str());
    system(command.c_str());

    return 0;
}