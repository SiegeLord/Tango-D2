/*******************************************************************************

        Tokenize input from the console. There are a variety of handy
        tokenizers in the tango.text package ~ this illustrates simple
        usage.

*******************************************************************************/

private import tango.io.Console;

private import tango.text.QuoteIterator;
  
void main()
{
        Cout ("Please enter some space-delimited tokens: ");

        // create quote-aware tokenizer for handling space-delimited
        // tokens from the console input
        auto token = new QuoteIterator (Cin.get, " \t");
        
        Cout ("You entered: ");
        
        // scan and display trimmed tokens
        while (token.next)
               Cout ("{") (token.trim.get) ("} ");
}
