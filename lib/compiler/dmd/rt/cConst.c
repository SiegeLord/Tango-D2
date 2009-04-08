// utility that expose some C consts to D

#ifndef _WIN32
#include <sys/fcntl.h>

// this is needed only by rt.cover
int fcntl_O_RDONLY(){
    return O_RDONLY;
}
#endif

