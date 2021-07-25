#ifndef TARGET_CPU
#define TARGET_CPU "x86_64"
#endif

#define _GNU_SOURCE

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stddef.h>
#include <unistd.h>
#include <limits.h>
#include <sys/stat.h>
#include <sys/types.h>

#ifdef __APPLE__
#include <mach-o/dyld.h>
#endif

#if defined(__FreeBSD__) || defined(__OpenBSD__) || defined(__DragonFly__)
#include <sys/sysctl.h>
#endif

#ifdef __OpenBSD__
#include <sys/user.h>
#endif

#if defined(WINDOWS) || defined(_WIN32) || defined(__CYGWIN__)
#include <windows.h>
#endif

int fileExists (char *filename)
{
  struct stat info;
  return (stat (filename, &info) == 0);
}

int dirExists(const char *path)
{
    struct stat info;

    if(stat( path, &info ) != 0)
        return 0;
    else if(info.st_mode & S_IFDIR)
        return 1;
    else
        return 0;
}

char *get_executable_path(char *epath, size_t buflen)
{
    char *p;
#ifdef __APPLE__
    unsigned int l = buflen;
    if (_NSGetExecutablePath(epath, &l) != 0) return NULL;
#elif defined(__FreeBSD__) || defined(__DragonFly__)
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PATHNAME, -1 };
    size_t l = buflen;
    if (sysctl(mib, 4, epath, &l, NULL, 0) != 0) return NULL;
#elif defined(__OpenBSD__)
    int mib[4];
    char **argv;
    size_t len;
    size_t l;
    const char *comm;
    int ok = 0;
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC_ARGS;
    mib[2] = getpid();
    mib[3] = KERN_PROC_ARGV;
    if (sysctl(mib, 4, NULL, &len, NULL, 0) < 0)
        abort();
    if (!(argv = malloc(len)))
        abort();
    if (sysctl(mib, 4, argv, &len, NULL, 0) < 0)
        abort();
    comm = argv[0];
    if (*comm == '/' || *comm == '.')
    {
        char *rpath;
        if ((rpath = realpath(comm, NULL)))
        {
            strlcpy(epath, rpath, buflen);
            free(rpath);
            ok = 1;
        }
    }
    else
    {
        char *sp;
        char *xpath = strdup(getenv("PATH"));
        char *path = strtok_r(xpath, ":", &sp);
        struct stat st;
        if (!xpath)
            abort();
        while (path)
        {
            snprintf(epath, buflen, "%s/%s", path, comm);
            if (!stat(epath, &st) && (st.st_mode & S_IXUSR))
	    {
                ok = 1;
                break;
            }
            path = strtok_r(NULL, ":", &sp);
        }
        free(xpath);
    }
    free(argv);
    if (!ok) return NULL;
    l = strlen(epath);
#elif defined(WINDOWS) || defined(_WIN32) || defined(__CYGWIN__)
  char full_path[MAX_PATH];
  unsigned int l = 0;
  l = GetModuleFileName(NULL, full_path, MAX_PATH);
#if defined(__CYGWIN__)
  p = strchr(full_path, '\\');
  while (p) {
    *p = '/';
    p  = strchr(full_path, '\\');
  }

  p = strchr(full_path, ':');
  if (p)
    *p = '/';
  snprintf(epath, buflen, "%c%s%c%s", '/', "cygdrive", '/', full_path);
#else
  snprintf(epath, buflen, "%s", full_path);
#endif

#else
    ssize_t l = readlink("/proc/self/exe", epath, buflen - 1);
    if (l > 0) epath[l] = '\0';
#endif
    if (l <= 0) return NULL;
    epath[buflen - 1] = '\0';
#if defined(__MINGW32__) || defined(__MINGW64__)
    p = strrchr(epath, '\\');
#else
    p = strrchr(epath, '/');
#endif
    if (p) *p = '\0';
    return epath;
}

char *get_filename(char *str)
{
#if defined(__MINGW32__) || defined(__MINGW64__)
    char *p = strrchr(str, '\\');
#else
    char *p = strrchr(str, '/');
#endif
    return p ? &p[1] : str;
}

void target_info(char *argv[], char **triple, char **linker)
{
    char *p = get_filename(argv[0]);
    char *x = strrchr(p, '-');
    if (!x) abort();
    *linker = &x[1];
    *x = '\0';
    *triple = p;
}

int main(int argc, char *argv[])
{
    char **args = alloca(sizeof(char*) * (argc+1));
    int i, j;

    char execpath[PATH_MAX+1];
    char linkerpath[PATH_MAX+1];
    
    char *linker;
    char *target;

    if (!get_executable_path(execpath, sizeof(execpath))) abort();

    target_info(argv, &target, &linker);

    snprintf(linkerpath, sizeof(linkerpath), "%s/%s", execpath, linker);


    if (!fileExists(linkerpath))
    {
        snprintf(linkerpath, sizeof(linkerpath), "%s", linker);
    }

    i = 0;

    args[i++] = linkerpath;

    for (j = 1; j < argc; ++i, ++j)
        args[i] = argv[j];

    args[i] = NULL;

    execvp(linkerpath, args);

    fprintf(stderr, "cannot invoke linker!\n");

    return 1;
}
