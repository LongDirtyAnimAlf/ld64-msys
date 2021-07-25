#ifndef TARGET_CPU
#define TARGET_CPU "x86_64"
#endif

#ifndef OS_VER_MIN
#define OS_VER_MIN "4.2"
#endif

#ifndef SDK_DIR
#define SDK_DIR ""
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

#if defined(__MINGW32__) || defined(__MINGW64__)
#include <errno.h>
int setenv( const char *var, const char *value, int overwrite )
{
  /* Core implementation for both setenv() and unsetenv() functions;
   * at the outset, assume that the requested operation may fail.
   */
  int retval = -1;

  /* The specified "var" name MUST be non-NULL, not a zero-length
   * string, and must not include any '=' character.
   */
  if( var && *var && (strchr( var, '=' ) == NULL) )
  {
    /* A properly named variable may be added to, removed from,
     * or modified within the environment, ONLY if "overwrite"
     * mode is enabled, OR if the named variable does not yet
     * exist...
     */
    if( overwrite || getenv( var ) == NULL )
    {
      /* ... in which cases, we convert the specified name and
       * value into the appropriate form for use with putenv(),
       * (noting that we accept a NULL "value" as equivalent to
       * a zero-length string, which renders putenv() as the
       * equivalent of unsetenv()).
       */
      const char *fmt = "%s=%s";
      const char *val = value ? value : "";
      char buf[1 + snprintf( NULL, 0, fmt, var, val )];
      snprintf( buf, sizeof( buf ), fmt, var, val );

      /* "buf" is now formatted as "var=value", in the form
       * required by putenv(), but it exists only within our
       * volatile stack-frame space.  POSIX.1 suggests that we
       * should copy it to more persistent storage, before it
       * is passed to putenv(), to associate an environment
       * pointer with it.  However, we note that Microsoft's
       * putenv() implementation appears to make such a copy
       * in any case, so we do not do so; (in fact, if we did
       * strdup() it (say), then we would leak memory).
       */
      if( (retval = putenv( buf )) != 0 )
    /*
     * If putenv() returns non-zero, indicating failure, the
     * most probable explanation is that there wasn't enough
     * free memory; ensure that errno is set accordingly.
     */
        errno = ENOMEM;
    }
    else
      /* The named variable already exists, and overwrite mode
       * was not enabled; there is nothing to be done.
       */
      retval = 0;
  }
  else
    /* The specified environment variable name was invalid.
     */
    errno = EINVAL;

  /* Succeed or fail, "retval" has now been set to indicate the
   * appropriate status for return.
   */
  return retval;
}

int unsetenv( const char *__name )
{
  return setenv( __name, NULL, 1 );
}
#endif

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

void target_info(char *argv[], char **triple, char **compiler)
{
    char *p = get_filename(argv[0]);
    char *x = strrchr(p, '-');
    if (!x) abort();
    *compiler = &x[1];
    *x = '\0';
    *triple = p;
}

void env(char **p, const char *name, char *fallback)
{
    char *ev = getenv(name);
    if (ev) { *p = ev; return; }
    *p = fallback;
}

int main(int argc, char *argv[])
{
    char **args = alloca(sizeof(char*) * (argc+50));
    int i, j;

    char execpath[PATH_MAX+1];
    char sdkpath[PATH_MAX+1];
    char compilerpath[PATH_MAX+1];
    char osvermin[64];

    char *compiler;
    char *target;

    char *sdk;
    char *cpu;
    char *osmin;


    if (!get_executable_path(execpath, sizeof(execpath))) abort();

    target_info(argv, &target, &compiler);

    snprintf(compilerpath, sizeof(compilerpath), "%s/%s", execpath, compiler);


    if (!fileExists(compilerpath))
    {
        snprintf(compilerpath, sizeof(compilerpath), "%s", compiler);
    }

    //snprintf(sdkpath, sizeof(sdkpath), "%s/../SDK", execpath);
    snprintf(sdkpath, sizeof(sdkpath), "%s/../SDK/" SDK_DIR, execpath);

    // Dedicated libs

    if (!dirExists(sdkpath))
    {
        snprintf(sdkpath, sizeof(sdkpath), "%s/../../lib/x86_64-darwin/" SDK_DIR, execpath);
    }
    if (!dirExists(sdkpath))
    {
        snprintf(sdkpath, sizeof(sdkpath), "%s/../../../lib/x86_64-darwin/" SDK_DIR, execpath);
    }
    
    if (!dirExists(sdkpath))
    {
        snprintf(sdkpath, sizeof(sdkpath), "%s/../../lib/x86_64-darwin/SDK", execpath);
    }
    if (!dirExists(sdkpath))
    {
        snprintf(sdkpath, sizeof(sdkpath), "%s/../../lib/x86_64-darwin", execpath);
    }
    
    if (!dirExists(sdkpath))
    {
        snprintf(sdkpath, sizeof(sdkpath), "%s/../../../lib/x86_64-darwin/SDK", execpath);
    }
    if (!dirExists(sdkpath))
    {
        snprintf(sdkpath, sizeof(sdkpath), "%s/../../../lib/x86_64-darwin", execpath);
    }

    // Universal libs

    if (!dirExists(sdkpath))
    {
        snprintf(sdkpath, sizeof(sdkpath), "%s/../../lib/all-darwin/" SDK_DIR, execpath);
    }
    if (!dirExists(sdkpath))
    {
        snprintf(sdkpath, sizeof(sdkpath), "%s/../../../lib/all-darwin/" SDK_DIR, execpath);
    }
    
    if (!dirExists(sdkpath))
    {
        snprintf(sdkpath, sizeof(sdkpath), "%s/../../lib/all-darwin/SDK", execpath);
    }
    if (!dirExists(sdkpath))
    {
        snprintf(sdkpath, sizeof(sdkpath), "%s/../../lib/all-darwin", execpath);
    }
    
    if (!dirExists(sdkpath))
    {
        snprintf(sdkpath, sizeof(sdkpath), "%s/../../../lib/all-darwin/SDK", execpath);
    }
    if (!dirExists(sdkpath))
    {
        snprintf(sdkpath, sizeof(sdkpath), "%s/../../../lib/all-darwin", execpath);
    }

    
    env(&sdk, "OSX_SDK_SYSROOT", sdkpath);
    env(&cpu, "OSX_TARGET_CPU", TARGET_CPU);

    env(&osmin, "MACOSX_DEPLOYMENT_TARGET", OS_VER_MIN);
    unsetenv("MACOSX_DEPLOYMENT_TARGET");

    snprintf(osvermin, sizeof(osvermin), "-mmacosx-version-min=%s", osmin);

    for (i = 1; i < argc; ++i)
    {
        if (!strcmp(argv[i], "-arch"))
        {
            cpu = NULL;
            break;
        }
    }

    i = 0;

    args[i++] = compilerpath;
    args[i++] = "-target";
    args[i++] = target;
    args[i++] = "-isysroot";
    args[i++] = sdk;

    /*
    if (cpu)
    {
        args[i++] = "-arch";
        args[i++] = cpu;
    }
    */

    args[i++] = osvermin;
    args[i++] = "-mlinker-version=540";
    // args[i++] = "-Wl,-adhoc_codesign";
    args[i++] = "-Wno-unused-command-line-argument";
    args[i++] = "-Wno-overriding-t-option";

    for (j = 1; j < argc; ++i, ++j)
        args[i] = argv[j];

    args[i] = NULL;

    setenv("COMPILER_PATH", execpath, 1);
    execvp(compilerpath, args);

    fprintf(stderr, "cannot invoke compiler!\n");
    
    return 1;
}
