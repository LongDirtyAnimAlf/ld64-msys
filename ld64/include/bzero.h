#ifndef BZERO_H
#define BZERO_H

#ifndef bzero
#define bzero(b,len) (memset((b), '\0', (len)), (void) 0)
#endif

#ifndef MIN // ld64-port: #ifndef
#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#endif

#ifndef MAX // ld64-port: #ifndef
#define MAX(a, b) (((a) > (b)) ? (a) : (b))
#endif

#endif // BZERO_H
