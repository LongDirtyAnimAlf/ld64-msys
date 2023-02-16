#ifndef _HELPER_H
#define _HELPER_H

#ifndef __USE_GNU
#define __USE_GNU
#endif

#ifdef __cplusplus
#if !__has_include(<string_view>)
//#warning does this really work as expected?
#define string_view string
#endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

#include <mach/mach_time.h>
#include <mach/mach_host.h>
#include <mach/host_info.h>
#include <sys/time.h>
#include <dlfcn.h>

#ifdef __MINGW32__

#include <stdint.h>
#include <direct.h>

//#ifndef HAVE_LOCALTIME_R
#define localtime_r(a, b)               localtime_s(b, a)
//#endif

ssize_t pread(int fd, void *buf, size_t count, long long offset);
ssize_t pwrite(int fd, const void *buf, size_t count, long long offset);

#ifndef _GNU_SOURCE

#include <stdarg.h> /* needed for va_list */

#ifndef _vscprintf
int _vscprintf_so(const char * format, va_list pargs);
#endif // _vscprintf
#ifndef vasprintf
int vasprintf(char **strp, const char *fmt, va_list ap);
#endif // vasprintf
#ifndef asprintf
int asprintf(char *strp[], const char *fmt, ...);
#endif // asprintf

#endif

char *realpath (const char *name, char *resolved);
int readlink (const char *path, char *buf, size_t bufsize);

#define  mkdir( D, M )   _mkdir( D )
// #define  mkdir( D, M )   mkdir( D )

#endif

size_t strcspn (const char *s, const char *reject);

char *strndup( const char *s1, size_t n);

struct dyld_unwind_sections
{
    const struct mach_header*      mh;
    const void*                    dwarf_section;
    intptr_t                       dwarf_section_length;
    const void*                    compact_unwind_section;
    intptr_t                       compact_unwind_section_length;
};

typedef Dl_info dl_info;

#ifndef __APPLE__
typedef char uuid_string_t__[37];
#define uuid_string_t uuid_string_t__
#endif

int _NSGetExecutablePath(char *path, unsigned int *size);
int _dyld_find_unwind_sections(void* i, struct dyld_unwind_sections* sec);
mach_port_t mach_host_self(void);
kern_return_t host_statistics ( host_t host_priv, host_flavor_t flavor, host_info_t host_info_out, mach_msg_type_number_t *host_info_outCnt);
uint64_t mach_absolute_time(void);

#ifdef __cplusplus
}
#endif

#endif
