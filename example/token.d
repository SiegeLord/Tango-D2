/*******************************************************************************

        Tokenize input from the console. There are a variety of handy
        tokenizers in the tango.text package ~ this illustrates simple
        usage.

*******************************************************************************/

private import tango.io.Console;

private import tango.text.QuoteIterator;
  
void main()
{
        char[] args;

        // prompt user
        Cout ("Please enter some space-delimited tokens: ");

        // get console input
        Cin (args);

        // create quote-aware tokenizer for handling space-delimited tokens
        auto token = new QuoteIterator (args, " \t");
        
        // scan and display trimmed tokens
        Cout ("You entered: ");
        while (token.next)
               Cout ("{") (token.trim.get) ("} ");
}
