package com.soma.GEDCOMConverter;

import org.xml.sax.*;
import org.xml.sax.helpers.DefaultHandler;
import java.io.*;

/**
*  A SAX ContentHandler that writes the events to standard output
*  in GEDCOM format.
*  <p>This class expects to receive the data in normalised form, that is,
*  each contiguous piece of character data arrives in a single call of
*  the characters() interface.</p>
*
*  @author mhkay@iclway.co.uk
*  @version 21 January 2001: modified to conform to SAX2
*/

//$Id$
  
public class GEDMLOutputter extends DefaultHandler
{
    int level = -1;
    boolean acceptCharacters = true;
    boolean endTagDone = false;
	GedcomLine line = new GedcomLine();
    Writer writer;
 
 
   /**
    * Start of the document. 
    */
    public void startDocument () throws SAXException
    {
        // Create/open the output file
        try {
            writer = new OutputStreamWriter(System.out);
			writer.write( "<GEDML>\n" );
        } catch (Exception err) {
            throw new SAXException("Failed to create output stream", err);
        }
    }

    /**
    * End of the document.
    */

    public void endDocument () throws SAXException
    {
        try {
            if (line.level>=0) flushLine();
            writer.write("</GEDML>\n");
            writer.close();
        } catch (java.io.IOException err) {
            throw new SAXException(err);
        }
    }

    /**
    * Start of an element.
    */
    
    public void startElement (String pref, String ns, String name, Attributes attributes) throws SAXException
    {
        if (name.equals("GED")) return;

	level++;
        if (line.level>=0) flushLine();
        
        line.level = level;
        line.id = attributes.getValue("", "ID");       
        line.tag = name;
        line.ref = attributes.getValue("", "REF");
        line.text.setLength(0);

        acceptCharacters = true;
    }

    /**
    * End of an element.
    */

    public void endElement (String prefix, String ns, String name) throws SAXException 
    {
        level--;
        if (line.level>=0) flushLine();
        acceptCharacters = false;
		
		
		try {
		if ( !name.equals("GED") ) {
				//switch to prevent the following:
				// <NICK/>
				// </NICK>
				if ( !endTagDone ) {
					writer.write( "</" + name + ">\n" );
				}
				
			}
		} catch (java.io.IOException err) {
                throw new SAXException(err);
        }
		
		endTagDone = false;
	}

    /**
    * Character data.
    */
    
    public void characters (char ch[], int start, int length) throws SAXException
    {
        if (!acceptCharacters) {
            for (int i=start; i<start+length; i++) {
                if (!Character.isWhitespace(ch[i])) {
                    throw new SAXException("Character data not allowed after end tag");
                }
            }
        } else {
            line.text.append(ch, start, length);
        }
        
    }

    /**
    * Ignore ignorable whitespace.
    */

    public void ignorableWhitespace (char ch[], int start, int length)
    {}


    /**
    * Handle a processing instruction.
    */
    
    public void processingInstruction (String target, String data)
    {}

    /**
    * Flush the accumulated output line
    */
    
    private void flushLine() throws SAXException {
        String text = line.text.toString().trim();
               	
		line.write(level);
		
        line.text.setLength(0);
        line.level = -1;
    }

    /**
    * Inner class representing a line of GEDCOM output
    */

    private class GedcomLine {
        public int level = -1;
        public String id;
        public String tag;
        public String ref;
        public StringBuffer text = new StringBuffer();

        /**
        * Write the GEDCOM line using the current writer
        */

		//added (int level) so that the function knows that
		//there is a new element following this line and therefore
		//the tag is not empty like <NICK/>
        public void write( int level ) throws SAXException {
            try {
               	writer.write( "<" + line.tag );
				if ( line.id != null ) {
					writer.write( " ID=\"" + line.id + "\"" );
				} else if ( line.ref != null ) {
					writer.write( " REFN=\"" + line.ref + "\"" );
				}
		
				String theText = text.toString();

				if( level > line.level ) { // new element, so it is not empty
					writer.write( ">\n" );
					if (!theText.equals( "" ) ) {
						writer.write( theText + "\n" );
					}
					endTagDone = false;
				} else if ( !theText.equals( "" ) ) {
					writer.write( ">\n" + theText + "\n" );
					endTagDone = false;
				} else {
					writer.write( "/>\n" );
					endTagDone = true;
				}
				
           } catch (java.io.IOException err) {
                throw new SAXException(err);
            }
        }
    }

 
 
}
