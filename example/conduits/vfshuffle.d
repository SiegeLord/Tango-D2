import  tango.io.File,
        tango.io.Stdout,
        tango.io.FilePath;

import  tango.io.vfs.FileFolder,
        tango.io.vfs.model.Vfs;

import  Array = tango.core.Array;

int main (char[][] args)
{
        if (args.length != 3)
           {
           Stdout.formatln ("usage: shuffle fromdir todir");
           return 1;
           }

        // build an array of FilePath instances
        FilePath[] songs;

        // file filter
        bool filter (VfsInfo info)
        {
                auto fp = new FilePath (info.path);
                if (fp.suffix == ".mp3" || fp.suffix == ".wma"|| fp.suffix == ".m4a")
                    songs ~= fp;
                return false;
        }

        // set destination path, and add trailing separator as necessary
        auto dst = new FilePath;
        dst.path = args[2]; 

        // recursively search for all the mp3, wma and w4a files in specified directory 
        (new FileFolder(args[1])).tree.catalog(&filter);

        // shuffle the files 
        Stdout.formatln ("{} music files", songs.length);
        Array.shuffle (songs);

        // sequentially fill the target until done, or it quits with an
        // exception when the device is full
        foreach (song; songs)
                 dst.file(song.file).copy(song);

        Stdout.formatln ("Done");
        return 0;
}
