import  tango.io.Stdout,
        tango.io.FilePath,
        tango.io.FileScan;

import  Array = tango.core.Array;

int main (char[][] args)
{
        if (args.length != 3)
           {
           Stdout.formatln ("usage: shuffle fromdir todir");
           return 1;
           }

        // set destination path, and add trailing separator as necessary
        auto dst = new FilePath;
        dst.path = args[2]; 

        // recursively search for all the mp3, wma and w4a files in specified directory 
        auto songs = new FileScan;
        songs (args[1], (FilePath fp, bool isDir)
                        {return isDir || fp.suffix == ".mp3" || fp.suffix == ".wma"|| fp.suffix == ".m4a";});

        // shuffle the files 
        Stdout.formatln ("{} music files", songs.files.length);
        Array.shuffle (songs.files);

        // sequentially fill the target until done, or it quits with an
        // exception when the device is full
        foreach (song; songs.files)
                 dst.file(song.file).copy(song);

        Stdout.formatln ("Done");
        return 0;
}
