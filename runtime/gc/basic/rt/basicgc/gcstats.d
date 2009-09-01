/**
 * This module contains garbage collector statistics functionality.
 *
 * Copyright: Copyright (C) 2005-2006 Digital Mars, www.digitalmars.com.
 *            All rights reserved.
 * License:
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, in both source and binary form, subject to the following
 *  restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 * Authors:   Walter Bright, Sean Kelly
 */
module rt.basicgc.gcstats;

/// NOTE: The content of this structure are gc dependent, but opIndex, opIn and keys
/// are supposed to be available for all gc
struct GCStatsInternal
{
    void* dummy;
    size_t poolSize;        /// total size of pool
    size_t usedSize;        /// bytes allocated
    size_t freeBlocks;      /// number of blocks marked FREE
    size_t freelistSize;    /// total of memory on free lists
    size_t pageBlocks;      /// number of blocks marked PAGE
    size_t gcCounter;       /// number of GC phases (twice the number of gc collections)
    real totalPagesFreed;   /// total pages freed
    real totalMarkTime;     /// seconds spent in mark-phase
    real totalSweepTime;    /// seconds spent in sweep-phase
    ulong totalAllocTime;   /// total time spent in alloc and malloc,calloc,realloc,...free
    ulong totalAllocTimeFreq;   /// frequancy for totalAllocTime
    ulong nAlloc;           /// number of calls to allocation/free routines
    
    /// return the statistical information for the given key
    real opIndex(char[] prop){
        switch(prop){
        case "poolSize":
            return cast(real)poolSize;
        case "usedSize":
            return cast(real)usedSize;
        case "freeBlocks":
            return cast(real)freeBlocks;
        case "freelistSize":
            return cast(real)freelistSize;
        case "pageBlocks":
            return cast(real)pageBlocks;
        case "gcCounter":
            return 0.5*cast(real)gcCounter;
        case "totalPagesFreed":
            return totalPagesFreed;
        case "totalMarkTime":
            return totalMarkTime;
        case "totalSweepTime":
            return totalSweepTime;
        case "totalAllocTime":
            return cast(real)totalAllocTime/cast(real)(totalAllocTimeFreq==0?1UL:totalAllocTimeFreq);
        case "nAlloc":
            return cast(real)nAlloc;
        default:
            throw new Exception("unsupported property",__FILE__,__LINE__);
        }
    }
    /// returns if the given string is a valid key
    bool opIn_r(char[] c){
        return (c=="poolSize")||(c=="usedSize")||(c=="freeBlocks")||(c=="freelistSize")
            || (c=="pageBlocks")||(c=="gcCounter")||(c=="totalPagesFreed")||(c=="totalMarkTime")
            || (c=="totalSweepTime")||(c=="totalAllocTime")||(c=="nAlloc");
    }
    /// returns the valid keys
    char[][]keys(){
        return ["poolSize"[],"usedSize","freeBlocks","freelistSize","pageBlocks",
        "gcCounter","totalPagesFreed","totalMarkTime","totalSweepTime","totalAllocTime",
        "nAlloc"];
    }
}

