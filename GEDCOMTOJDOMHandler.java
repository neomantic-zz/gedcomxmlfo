package com.soma.GEDCOMConverter;

import org.xml.sax.*;
//import org.xml.sax.helpers.DefaultHandler;
import java.io.*;
import org.jdom.input.SAXHandler;
import org.jdom.input.JDOMFactory;

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
public class GEDCOMTOJDOMHandler extends SAXHandler;
{
    int level = -1;
    Document theJDOMDocument;
 
 
   /**
    * Start of the document. 
    */
    public void startDocument () throws SAXException
    {
        // Create/open the output file
		currentElement = new Element( "GEDML" );
		theJDOMDocument = JDOMFactory.document( currentElement );
	}
	

    /**
    * End of the document.
    */

    public void endDocument () throws SAXException
    {
 
	}

    /**
    * Start of an element.
    */
    
    public void startElement (String pref, String ns, String name, Attributes attributes) throws SAXException
    {
 
       	if (name.equals("GED")) return;
	   
        String id = attributes.getValue("", "ID");       
		String ref = attributes.getValue("", "REF");

		previousElement = currentElement;
		currentElement = null;
		currentElement = new Element( name );
		if( id != null ) {
			theElement.setAttributes( "ID", id );
		} else if( ref != null ) {
			theElement.setAttributes( "REF", ref );
		}
	
	}

    /**
    * End of an element.
    */

    public void endElement (String prefix, String ns, String name) throws SAXException 
    {
		if ( name.equals("GED") ) return;
	
		if( !previousCDATA ) {
			previousElement.addContent( currentElement );
			previousElement = currentElement;
			currentElement = null;
		}

	}

    /**
    * Character data.
    */
    
    public void characters (char ch[], int start, int length) throws SAXException
    {
		String theText = new String( ch, start, length );
        
		currentElement.addContent( theText );
		      
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
