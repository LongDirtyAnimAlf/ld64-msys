#define _GNU_SOURCE
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/param.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <mach-o/dyld.h>

#include "find_executable.h"
#include "strlcpy.h"
#include "helper.h"

char *find_executable(const char *name)
{
    char *p;
    char path[8192];
    char epath[MAXPATHLEN];
    char cctools_path[MAXPATHLEN];
    const char *env_path = getenv("PATH");
    struct stat st;

    if (!env_path)
        return NULL;

    unsigned int bufsize = MAXPATHLEN;

    if (_NSGetExecutablePath(cctools_path, &bufsize) == -1)
        cctools_path[0] = '\0';

#if defined(__MINGW32__)
    if ((p = strrchr(cctools_path, '\\')))
        *p = '\0';
    snprintf(path, sizeof(path), "%s;%s", cctools_path, env_path);
    p = strtok(path, ";");
#else
    if ((p = strrchr(cctools_path, '/')))
        *p = '\0';

    snprintf(path, sizeof(path), "%s:%s", cctools_path, env_path);

    p = strtok(path, ":");
#endif

    while (p != NULL)
    {
        snprintf(epath, sizeof(epath), "%s/%s", p, name);

        if ((p = realpath(epath, NULL)))
        {
            strlcpy(epath, p, sizeof(epath));
            free(p);
        }

        if (stat(epath, &st) == 0 && access(epath, F_OK|X_OK) == 0)
            return strdup(epath);

#if defined(__MINGW32__)
        p = strtok(NULL, ";");
#else
        p = strtok(NULL, ":");
#endif
    }

    return NULL;
}
 
