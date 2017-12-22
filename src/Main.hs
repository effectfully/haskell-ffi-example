module Main where

import Foreign
import Foreign.C.Types
import Data.Foldable
import Control.Monad
import Control.Concurrent
import System.IO.Unsafe
import System.Mem

foreign import ccall "low.h new_array"
  c_new_array :: CInt -> IO (Ptr CInt)

foreign import ccall "low.h &free_array"
  c_free_array :: FunPtr (Ptr CInt -> IO ())

newArrIO :: Int -> IO (ForeignPtr CInt)
newArrIO size = do
  arr <- c_new_array $ fromIntegral size
  if arr /= nullPtr
    then newForeignPtr c_free_array arr
    else fail "nope"

newArr :: Int -> ForeignPtr CInt
newArr = unsafePerformIO . newArrIO
{-# NOINLINE newArr #-}

main :: IO ()
main =
  for_ [1..200] $ \i -> do
    withForeignPtr (newArr 5000000) $ \ptr -> do
      v <- peek ptr
      putStrLn $ concat ["Iteration: ", show i, ", value: ", show v]
    -- Uncomment this and you'll get a nice loop where each array is
    -- allocated and freed immediately. So the problem is in GC,
    -- but see the next note.
    -- performMinorGC

    -- Surprisingly `threadDelay` doesn't affect anything.
    -- If `performMinorGC` is not enabled then no matter what the delay is,
    -- exactly 126 arrays are allocated before any of them get freed,
    -- then they are freed and then the rest 74 arrays are allocated
    -- and freed in the same way.
    threadDelay 10000

    -- It seems GHC just doesn't think that `< 126` pointers is
    -- a sufficient reason to start GC.
