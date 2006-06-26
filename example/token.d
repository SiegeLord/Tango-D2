/*******************************************************************************

        Tokenize input from the console. There are a variety of handy
        tokenizers in the tango.text package ~ this illustrates usage
        of an iterator that recognizes quoted-strings within an input
        array, and splits tokens on a provided set of delimeters

*******************************************************************************/

private import tango.io.Console;

private import tango.text.QuoteIterator;
  
void main()
{
        // flush the console output, since we have no newline present
        Cout ("Please enter some space-delimited tokens: ") ();

        // create quote-aware tokenizer for handling space-delimited
        // tokens from the console input
        auto token = new QuoteIterator (Cin.get, " \t");
        
        // scan and display trimmed tokens
        Cout ("You entered: ");
        while (token.next)
               Cout ("{") (token.trim.get) ("} ");

        Cout.newline;
}
