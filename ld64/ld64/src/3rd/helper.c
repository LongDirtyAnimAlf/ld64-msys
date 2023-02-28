#define VAL(x) #x
#define STRINGIFY(x) VAL(x)

const char ldVersionString[] = "@(#)PROGRAM:ld  PROJECT:ld64-" STRINGIFY(LD64_VERSION_NUM) "\n";

#ifndef __APPLE__

#include <unistd.h>
#include <inttypes.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <sys/attr.h>
#include <sys/param.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <errno.h>
#include <assert.h>
#include <mach/mach.h>
#include <mach/mach_error.h>
#include <mach/mach_time.h>
#include <mach/mach_host.h>
#include <mach/host_info.h>

#if defined(__FreeBSD__) || defined(__OpenBSD__) || defined(__DragonFly__)
#include <sys/sysctl.h>
#endif

#ifdef __OpenBSD__
#include <sys/types.h>
#include <sys/user.h>
#include <sys/stat.h>
#endif

#if defined(__MINGW32__) || defined(__CYGWIN__)
#include <windows.h>
#endif

#include "helper.h"

#ifdef __MINGW32__

ssize_t pread(int fd, void *buf, size_t count, long long offset)
{
	OVERLAPPED o;
	HANDLE fh = (HANDLE)_get_osfhandle(fd);
	DWORD bytes;
	BOOL ret;

	if (fh == INVALID_HANDLE_VALUE) {
		errno = EBADF;
		return -1;
	}

  memset(&o, 0, sizeof(o));
  o.Offset = (DWORD) offset;
  o.OffsetHigh = (DWORD)(offset>>32);

	ret = ReadFile(fh, buf, (DWORD)count, &bytes, &o);
	if (!ret) {
    int err = (int)GetLastError();
    if (err == ERROR_HANDLE_EOF)
      return 0;
    else
      // throw makeOsException(GetLastError(), "pread");
	    errno = EIO;
	    return -1;
	}
    else
  	  return (ssize_t)bytes;
}

ssize_t pwrite(int fd, const void *buf, size_t count, long long offset)
{
	OVERLAPPED o;
	HANDLE fh = (HANDLE)_get_osfhandle(fd);
	DWORD bytes;
	BOOL ret;

	if (fh == INVALID_HANDLE_VALUE) {
		errno = EBADF;
		return -1;
	}

  memset(&o, 0, sizeof(o));
  o.Offset = (DWORD) offset;
  o.OffsetHigh = (DWORD)(offset>>32);

	ret = WriteFile(fh, buf, (DWORD)count, &bytes, &o);
	if (!ret) {
		errno = EIO;
		return -1;
	}

	return (ssize_t)bytes;
}

#ifndef _GNU_SOURCE

#include <stdio.h> /* needed for vsnprintf */
#include <stdlib.h> /* needed for malloc-free */
#include <stdarg.h> /* needed for va_list */

#ifndef _vscprintf
/* For some reason, MSVC fails to honour this #ifndef. */
/* Hence function renamed to _vscprintf_so(). */
int _vscprintf_so(const char * format, va_list pargs) {
    int retval;
    va_list argcopy;
    va_copy(argcopy, pargs);
    retval = vsnprintf(NULL, 0, format, argcopy);
    va_end(argcopy);
    return retval;}
#endif // _vscprintf

#ifndef vasprintf
int vasprintf(char **strp, const char *fmt, va_list ap) {
    int len = _vscprintf_so(fmt, ap);
    if (len == -1) return -1;
    char *str = (char*)malloc((size_t) len + 1);
    if (!str) return -1;
    int r = vsnprintf(str, len + 1, fmt, ap); /* "secure" version of vsprintf */
    if (r == -1) return free(str), -1;
    *strp = str;
    return r;}
#endif // vasprintf

#ifndef asprintf
int asprintf(char *strp[], const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    int r = vasprintf(strp, fmt, ap);
    va_end(ap);
    return r;}
#endif // asprintf

#endif

#define __realpath realpath
#define __readlink readlink

char *
__realpath( const char *__restrict__ name, char *__restrict__ resolved )
{
  char *retname = NULL;  /* we will return this, if we fail */
  char *p;

  /* SUSv3 says we must set `errno = EINVAL', and return NULL,
   * if `name' is passed as a NULL pointer.
   */

  if( name == NULL )
    errno = EINVAL;

  /* Otherwise, `name' must refer to a readable filesystem object,
   * if we are going to resolve its absolute path name.
   */

  //else if( access( name, 4 ) == 0 )
  else if(TRUE)
  {
    /* If `name' didn't point to an existing entity,
     * then we don't get to here; we simply fall past this block,
     * returning NULL, with `errno' appropriately set by `access'.
     *
     * When we _do_ get to here, then we can use `_fullpath' to
     * resolve the full path for `name' into `resolved', but first,
     * check that we have a suitable buffer, in which to return it.
     */

    if( (retname = resolved) == NULL )
    {
      /* Caller didn't give us a buffer, so we'll exercise the
       * option granted by SUSv3, and allocate one.
       *
       * `_fullpath' would do this for us, but it uses `malloc', and
       * Microsoft's implementation doesn't set `errno' on failure.
       * If we don't do this explicitly ourselves, then we will not
       * know if `_fullpath' fails on `malloc' failure, or for some
       * other reason, and we want to set `errno = ENOMEM' for the
       * `malloc' failure case.
       */

      retname = malloc( _MAX_PATH );
    }

    /* By now, we should have a valid buffer.
     * If we don't, then we know that `malloc' failed,
     * so we can set `errno = ENOMEM' appropriately.
     */

    if( retname == NULL )
      errno = ENOMEM;

    /* Otherwise, when we do have a valid buffer,
     * `_fullpath' should only fail if the path name is too long.
     */

    else if( (retname = _fullpath( retname, name, _MAX_PATH )) == NULL )
      errno = ENAMETOOLONG;
  }

  while ((p = strchr (retname, '\\')) != NULL)
  {
    *p = '/';
  }  

  /* By the time we get to here,
   * `retname' either points to the required resolved path name,
   * or it is NULL, with `errno' set appropriately, either of which
   * is our required return condition.
   */

  return retname;
}

int
__readlink (const char *path, char *buf, size_t bufsize)
{
  struct stat statbuf;

  /* In general we should use lstat() here, not stat().  But on platforms
     without symbolic links lstat() - if it exists - would be equivalent to
     stat(), therefore we can use stat().  This saves us a configure check.  */
  if (stat (path, &statbuf) >= 0)
    errno = EINVAL;
  return -1;
}

#endif

size_t
strcspn (const char *s, const char *reject)
{
  size_t count = 0;

  while (*s != '\0')
    if (strchr (reject, *s++) == NULL)
      ++count;
    else
      return count;

  return count;
}

char *strndup( const char *s1, size_t n)
{
    char *copy= (char*)malloc( n+1 );
    memcpy( copy, s1, n );
    copy[n] = 0;
    return copy;
};

void __assert_rtn(const char *func, const char *file, int line, const char *msg)
{
#if defined(__FreeBSD__) || defined(__DragonFly__)
    __assert(msg, file, line, func);
#elif defined(__NetBSD__) || defined(__OpenBSD__) || defined(__CYGWIN__)
    __assert(msg, line, file);
#elif defined(__GLIBC__)
    __assert(msg, file, line);
#else
    fprintf(stderr, "Assertion failed: %s (%s: %s: %d)\n", msg, file, func, line);
    fflush(NULL);
    abort();
#endif /* __FreeBSD__ */
}

int _NSGetExecutablePath(char *epath, unsigned int *size)
{
#if defined(__FreeBSD__) || defined(__DragonFly__)
    int mib[4];
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PATHNAME;
    mib[3] = -1;
    size_t cb = *size;
    if (sysctl(mib, 4, epath, &cb, NULL, 0) != 0)
        return -1;
    *size = cb;
    return 0;
#elif defined(__OpenBSD__)
    int mib[4];
    char **argv;
    size_t len;
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
          strlcpy(epath, rpath, *size);
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
            snprintf(epath, *size, "%s/%s", path, comm);
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
    if (ok)
    {
        *size = strlen(epath);
        return 0;
    }
    return -1;
#elif defined(__CYGWIN__) || defined(__MINGW32__)
  char *p;
  char full_path[MAX_PATH];
  unsigned int l = 0;
  l = GetModuleFileNameA(NULL, full_path, MAX_PATH);
  if ((l == 0) || (l == MAX_PATH)) return -1;
  full_path[l] = '\0'; 
  while ((p = strchr (full_path, '\\')) != NULL)
  {
    *p = '/';
  }  
#if defined(__CYGWIN__)
  p = strchr(full_path, ':');
  if (p)
    *p = '/';
  snprintf(epath, *size, "%c%s%c%s", '/', "cygdrive", '/', full_path);
#else
  snprintf(epath, *size, "%s", full_path);
#endif
  return 0;
#else
    int bufsize = *size;
    int ret_size;
    ret_size = readlink("/proc/self/exe", epath, bufsize-1);
    if (ret_size != -1)
    {
        *size = ret_size;
        epath[ret_size]=0;
        return 0;
    }
    else
        return -1;
#endif
}

int _dyld_find_unwind_sections(void *i, struct dyld_unwind_sections* sec)
{
    return 0;
}

mach_port_t mach_host_self(void)
{
    return 0;
}

kern_return_t host_statistics(host_t host_priv, host_flavor_t flavor,
                              host_info_t host_info_out,
                              mach_msg_type_number_t *host_info_outCnt)
{
    return ENOTSUP;
}

uint64_t mach_absolute_time(void)
{
    struct timeval tv;
    if (gettimeofday(&tv, NULL))
      return 0;
    return (tv.tv_sec*1000000ULL)+tv.tv_usec;
}

kern_return_t mach_timebase_info(mach_timebase_info_t info)
{
    info->numer = 1000;
    info->denom = 1;
    return 0;
}

#if defined(__ppc__) && !defined(__ppc64__)

/*
 * __sync_fetch_and_add_8 is missing on ppc 32-bit for some reason.
 */

#include <pthread.h>
static pthread_mutex_t lock;

__attribute__((constructor (101)))
static void init_mutex() { pthread_mutex_init(&lock, NULL); }

int64_t __clang_does_not_like_redeclaring_sync_fetch_and_add_8(
    volatile int64_t *ptr, int64_t value, ...)
{
    pthread_mutex_lock(&lock);
    *ptr = value;
    pthread_mutex_unlock(&lock);
    return *ptr;
}

asm
(
    ".global __sync_fetch_and_add_8\n"
    ".weak   __sync_fetch_and_add_8\n"
    ".type   __sync_fetch_and_add_8, @function\n"
    "__sync_fetch_and_add_8:\n"
    "b       __clang_does_not_like_redeclaring_sync_fetch_and_add_8\n"
    ".size   __sync_fetch_and_add_8, .-__sync_fetch_and_add_8"
);

#endif /* __ppc__ && !__ppc64__ */

int32_t OSAtomicAdd32(int32_t __theAmount, volatile int32_t *__theValue)
{
   return __sync_fetch_and_add(__theValue, __theAmount);
}

int64_t OSAtomicAdd64(int64_t __theAmount, volatile int64_t *__theValue)
{
   return __sync_fetch_and_add(__theValue, __theAmount);
}

#endif /* __APPLE__ */
