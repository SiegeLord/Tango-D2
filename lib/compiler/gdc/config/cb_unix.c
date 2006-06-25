/* GDC -- D front-end for GCC
   Copyright (C) 2004 David Friedman
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
 
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
 
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include <stat.h>
#include <sys/stat.h>
#include <unistd.h>


#define X(f) *f = stat_buf.st_##f
int _d_gnu_cb_fstat(int fd, int *dev, uint *ino,
    ushort *mode, ushort *nlink,
    uint *uid, uint *gid,
    int *rdev, off_t *size,
    long *blocks , uint * blksize, uint *flags)
{
    struct stat stat_buf;
    int result = fstat(fd, & stat_buf);
    if (result == 0) {
	X(dev); X(ino);
	X(mode); X(nlink);
	X(uid); X(gid);
	X(rdev); X(size);
	X(blocks); X(blksize); X(flags);
    }
    return result;
}

int _d_gnu_cb_stat(char * path, int *dev, uint *ino,
    ushort *mode, ushort *nlink,
    uint *uid, uint *gid,
    int *rdev, off_t *size,
    long *blocks , uint * blksize, uint *flags)
{
    struct stat stat_buf;
    int result = stat(path, & stat_buf);
    if (result == 0) {
	X(dev); X(ino);
	X(mode); X(nlink);
	X(uid); X(gid);
	X(rdev); X(size);
	X(blocks); X(blksize); X(flags);
    }
    return result;
}
