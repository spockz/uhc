{-# EXCLUDE_IF_TARGET js #-}

-----------------------------------------------------------------------------
-- |
-- Module      :  System.CPUTime
-- Copyright   :  (c) The University of Glasgow 2001
-- License     :  BSD-style (see the file libraries/base/LICENSE)
-- 
-- Maintainer  :  libraries@haskell.org
-- Stability   :  provisional
-- Portability :  portable
--
-- The standard CPUTime library.
--
-----------------------------------------------------------------------------

module System.CPUTime 
        (
         getCPUTime,       -- :: IO Integer
         cpuTimePrecision  -- :: Integer
        ) where

import Prelude
import Data.Ratio

#ifdef __HUGS__
import Hugs.Time ( getCPUTime, clockTicks )
#endif

#ifdef __NHC__
import CPUTime ( getCPUTime, cpuTimePrecision )
#endif

#if defined(__GLASGOW_HASKELL__) || defined(__UHC__)
import Foreign
import Foreign.C

#include "HsBase.h"
#endif

-- Converts a real to an integer by rounding it.
realToInteger :: Real a => a -> Integer 
realToInteger x = round (realToFrac x :: Double)


#if defined(__GLASGOW_HASKELL__) || defined(__UHC__)
-- -----------------------------------------------------------------------------
-- |Computation 'getCPUTime' returns the number of picoseconds CPU time
-- used by the current program.  The precision of this result is
-- implementation-dependent.

getCPUTime :: IO Integer
getCPUTime = do

#if !defined(mingw32_HOST_OS) && !defined(cygwin32_HOST_OS)
-- getrusage() is right royal pain to deal with when targetting multiple
-- versions of Solaris, since some versions supply it in libc (2.3 and 2.5),
-- while 2.4 has got it in libucb (I wouldn't be too surprised if it was back
-- again in libucb in 2.6..)
--
-- Avoid the problem by resorting to times() instead.
--
#if defined(HAVE_GETRUSAGE) && ! irix_HOST_OS && ! solaris2_HOST_OS
    allocaBytes (#const sizeof(struct rusage)) $ \ p_rusage -> do
    getrusage (#const RUSAGE_SELF) p_rusage

    let ru_utime = (#ptr struct rusage, ru_utime) p_rusage
    let ru_stime = (#ptr struct rusage, ru_stime) p_rusage
    u_sec  <- (#peek struct timeval,tv_sec)  ru_utime :: IO CTime
#ifdef __UHC__
    u_usec <- (#peek struct timeval,tv_usec) ru_utime :: IO CUSeconds
#else
    u_usec <- (#peek struct timeval,tv_usec) ru_utime :: IO CTime
#endif
    s_sec  <- (#peek struct timeval,tv_sec)  ru_stime :: IO CTime
#ifdef __UHC__
    s_usec <- (#peek struct timeval,tv_usec) ru_stime :: IO CUSeconds
#else
    s_usec <- (#peek struct timeval,tv_usec) ru_stime :: IO CTime
#endif
    return ((realToInteger u_sec * 1000000 + realToInteger u_usec + 
             realToInteger s_sec * 1000000 + realToInteger s_usec) 
                * 1000000)

type CRUsage = ()
foreign import ccall unsafe "HsBase.h getrusage" getrusage :: CInt -> Ptr CRUsage -> IO CInt
#else
# if defined(HAVE_TIMES)
    allocaBytes (#const sizeof(struct tms)) $ \ p_tms -> do
    times p_tms
    u_ticks  <- (#peek struct tms,tms_utime) p_tms :: IO CClock
    s_ticks  <- (#peek struct tms,tms_stime) p_tms :: IO CClock
    return (( (realToInteger u_ticks + realToInteger s_ticks) * 1000000000000) 
                        `div` fromIntegral clockTicks)

type CTms = ()
foreign import ccall unsafe "HsBase.h times" times :: Ptr CTms -> IO CClock
# else
    ioException (IOError Nothing UnsupportedOperation 
                         "getCPUTime"
                         "can't get CPU time"
                         Nothing)
# endif
#endif

#else /* win32 */
     -- NOTE: GetProcessTimes() is only supported on NT-based OSes.
     -- The counts reported by GetProcessTimes() are in 100-ns (10^-7) units.
    allocaBytes (#const sizeof(FILETIME)) $ \ p_creationTime -> do
    allocaBytes (#const sizeof(FILETIME)) $ \ p_exitTime -> do
    allocaBytes (#const sizeof(FILETIME)) $ \ p_kernelTime -> do
    allocaBytes (#const sizeof(FILETIME)) $ \ p_userTime -> do
    pid <- getCurrentProcess
    ok <- getProcessTimes pid p_creationTime p_exitTime p_kernelTime p_userTime
    if toBool ok then do
      ut <- ft2psecs p_userTime
      kt <- ft2psecs p_kernelTime
      return (ut + kt)
     else return 0
  where 
        ft2psecs :: Ptr FILETIME -> IO Integer
        ft2psecs ft = do
          high <- (#peek FILETIME,dwHighDateTime) ft :: IO Word32
          low  <- (#peek FILETIME,dwLowDateTime)  ft :: IO Word32
            -- Convert 100-ns units to picosecs (10^-12) 
            -- => multiply by 10^5.
          return (((fromIntegral high) * (2^32) + (fromIntegral low)) * 100000)

    -- ToDo: pin down elapsed times to just the OS thread(s) that
    -- are evaluating/managing Haskell code.

type FILETIME = ()
type HANDLE = ()
-- need proper Haskell names (initial lower-case character)
foreign import stdcall unsafe "HsBase.h GetCurrentProcess" getCurrentProcess :: IO (Ptr HANDLE)
foreign import stdcall unsafe "HsBase.h GetProcessTimes" getProcessTimes :: Ptr HANDLE -> Ptr FILETIME -> Ptr FILETIME -> Ptr FILETIME -> Ptr FILETIME -> IO CInt

#endif /* not _WIN32 */
#endif /* __GLASGOW_HASKELL__ || __UHC__ */

-- |The 'cpuTimePrecision' constant is the smallest measurable difference
-- in CPU time that the implementation can record, and is given as an
-- integral number of picoseconds.

#ifndef __NHC__
cpuTimePrecision :: Integer
cpuTimePrecision = round ((1000000000000::Integer) % fromIntegral (clockTicks))
#endif

#if defined(__GLASGOW_HASKELL__) || defined(__UHC__)
clockTicks :: Int
clockTicks =
#if defined(CLK_TCK)
    (#const CLK_TCK)
#else
    unsafePerformIO (sysconf (#const _SC_CLK_TCK) >>= return . fromIntegral)
foreign import ccall unsafe "HsBase.h sysconf" sysconf :: CInt -> IO CLong
#endif
#endif /* __GLASGOW_HASKELL__ || __UHC__*/
