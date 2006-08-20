module example.reference.chapter11;

import tango.store.HashMap;
import tango.store.LinkSeq;
import tango.io.Stdout;

void linkedListExample(){
    Stdout.format( "linkedListExample" ).newline;
    alias LinkSeqT!(char[]) StrList;
    StrList lst = new StrList();

    lst.append( "value1" );
    lst.append( "value2" );
    lst.append( "value3" );

    auto it = lst.elements();
    // The call to .more gives true, if there are more elements
    // and switches the iterator to the next one if available.
    while( it.more ){
        char[] item_value = it.value;
        Stdout.format( "Value:{0}", item_value ).newline;
    }
}

void hashMapExample(){
    Stdout.format( "hashMapExample" ).newline;
    alias HashMapT!(char[], char[]) StrStrMap;
    StrStrMap map = new StrStrMap();
    map.putAt( "key1", "value1" );
    char[] key = "key1";
    Stdout.format( "Key: {0}, Value:{1}", key, map.get( key )).newline;


    auto it = map.keys();
    // The call to .more gives true, if there are more elements
    // and switches the iterator to the next one if available.
    while( it.more ){
        char[] item_key = it.key; // only for maps.
        char[] item_value = it.value;
        Stdout.format( "Key: {0}, Value:{1}", item_key, item_value ).newline;
    }
}

void main(){
    Stdout.format( "reference - Chapter 11 Example" ).newline;
    hashMapExample();
    linkedListExample();
    Stdout.format( "=== End ===" ).newline;
}


