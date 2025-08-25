// Use this only if you want to enable logging to file instead of UAE console (heavy performance hit, not recommended)
#define GENERIC_MAIN_LOG_PATH "game.log"

#include <ace/generic/main.h>

void genericCreate(void)
{
    // Here goes your startup code
    logWrite("Hello, Amiga!\n");
}

void genericProcess(void)
{
    // Here goes code done each game frame
    // Nothing here right now
    gameExit();
}

void genericDestroy(void)
{
    // Here goes your cleanup code
    logWrite("Goodbye, Amiga!\n");
}