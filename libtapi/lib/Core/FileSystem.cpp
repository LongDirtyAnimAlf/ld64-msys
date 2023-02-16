//===- lib/Core/FileSystem.cpp - File System --------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
///
/// \file
/// \brief Implements the additional file system support.
///
//===----------------------------------------------------------------------===//

#include "tapi/Core/FileSystem.h"
#include "tapi/Core/LLVM.h"
#include "llvm/ADT/Twine.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/Path.h"
#include <sys/stat.h>
#include <sys/time.h>
#include <unistd.h>

using namespace llvm;

#ifdef __MINGW32__

#include <errno.h>
#include <stdlib.h>
#include <windows.h>

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

//  else if( access( name, 4 ) == 0 )
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

      retname = (char*)malloc( _MAX_PATH );
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

    else if (_fullpath( retname, name, _MAX_PATH ) == NULL )
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

TAPI_NAMESPACE_INTERNAL_BEGIN

std::error_code realpath(SmallVectorImpl<char> &path) {
  if (path.back() != '\0')
    path.append({'\0'});
  SmallString<PATH_MAX> result;

  errno = 0;
  const char *ptr = nullptr;
  #ifdef __MINGW32__
  if ((ptr = __realpath(path.data(), result.data())) == nullptr)
  #else
  if ((ptr = ::realpath(path.data(), result.data())) == nullptr)
  #endif
    return {errno, std::generic_category()};

  assert(ptr == result.data() && "Unexpected pointer");
  result.truncate(strlen(result.data()));
  path.swap(result);
  return {};
}

std::error_code read_link(const Twine &path, SmallVectorImpl<char> &linkPath) {
  errno = 0;
  SmallString<PATH_MAX> pathStorage;
  auto p = path.toNullTerminatedStringRef(pathStorage);
  SmallString<PATH_MAX> result;
  ssize_t len;
  #ifdef __MINGW32__
  if ((len = __readlink(p.data(), result.data(), PATH_MAX)) == -1)
  #else
  if ((len = ::readlink(p.data(), result.data(), PATH_MAX)) == -1)
  #endif
    return {errno, std::generic_category()};

  result.truncate(len);
  linkPath.swap(result);

  return {};
}

std::error_code shouldSkipSymlink(const Twine &path, bool &result) {
  result = false;
  SmallString<PATH_MAX> pathStorage;
  auto p = path.toNullTerminatedStringRef(pathStorage);
  sys::fs::file_status stat1;
  auto ec = sys::fs::status(p.data(), stat1);
  if (ec == std::errc::too_many_symbolic_link_levels) {
    result = true;
    return {};
  }

  if (ec)
    return ec;

  StringRef parent = sys::path::parent_path(p);
  while (!parent.empty()) {
    sys::fs::file_status stat2;
    if (auto ec = sys::fs::status(parent, stat2))
      return ec;

    if (sys::fs::equivalent(stat1, stat2)) {
      result = true;
      return {};
    }

    parent = sys::path::parent_path(parent);
  }

  return {};
}

std::error_code make_relative(StringRef from, StringRef to,
                              SmallVectorImpl<char> &relativePath) {
  SmallString<PATH_MAX> src = from;
  SmallString<PATH_MAX> dst = to;
  if (auto ec = sys::fs::make_absolute(src))
    return ec;

  if (auto ec = sys::fs::make_absolute(dst))
    return ec;

  SmallString<PATH_MAX> result;
  src = sys::path::parent_path(src);
  auto it1 = sys::path::begin(src), it2 = sys::path::begin(dst),
       ie1 = sys::path::end(src), ie2 = sys::path::end(dst);
  // ignore the common part.
  for (; it1 != ie1 && it2 != ie2; ++it1, ++it2) {
    if (*it1 != *it2)
      break;
  }

  for (; it1 != ie1; ++it1)
    sys::path::append(result, "../");

  for (; it2 != ie2; ++it2)
    sys::path::append(result, *it2);

  if (result.empty())
    result = ".";

  relativePath.swap(result);

  return {};
}

TAPI_NAMESPACE_INTERNAL_END
