import tango.io.Stdout,
       tango.io.FilePath;

import tango.io.vfs.FileFolder;
      
import Array = tango.core.Array;

int main (char[][] args)
{
        if (args.length != 3)
           {
           Stdout.formatln ("usage: shuffle fromdir todir");
           return 1;
           }
        
        // file filter
        bool filter (VfsInfo info)
        {
                if (info.name.length >= 4)
                   {
                   auto suffix = info.name [$-4 .. $];
                   return (suffix == ".mp3" || suffix == ".wma"|| suffix == ".m4a");
                   }
                return false;
        }

        // recursively search for all the mp3, wma and w4a files in specified directory 
        VfsFile[] songs;
        foreach (song; (new FileFolder(args[1])).tree.catalog(&filter))
                 songs ~= song.dup;
        Stdout.formatln ("{} music files found", songs.length);

        // shuffle the files and copy them
        if (songs.length)
           {
           Array.shuffle (songs);

           // set our destination into a filepath editor and sequentially fill the target
           // until done, or until it quits with an exception when the device is full
           auto dst = new FilePath;
           dst.path = args[2]; 
           foreach (song; songs)
                    dst.file(song.name).copy(song.toString);
           }
        Stdout.formatln ("Done");
        return 0;
}
