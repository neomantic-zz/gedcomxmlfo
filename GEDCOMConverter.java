/**
 * GEDCOMConverter.java
 *
 *
 * Created:
 *
 * @author Chad Albers
 * @version
 *
 * $Id$ 
 *
 ***********/

package com.soma.GEDCOMConverter;
 
import java.io.*;
import java.net.URL;
import org.xml.sax.*;
import org.xml.sax.helpers.*;

//$Id$

import com.soma.GEDCOMConverter.*;

public class GEDCOMConverter {
	public static void main (String args[] ) {

		try {
		File theFile = new File( args[0] );
		FileInputStream theFileInputStream = new FileInputStream( theFile );
		if ( theFileInputStream == null ) {
			System.exit(0);
		}
		InputSource theInputSource = new InputSource( theFileInputStream );

		GedcomParser theParser = new GedcomParser();

		GEDMLOutputter theContentHandler = new GEDMLOutputter(); 

		theParser.setContentHandler( theContentHandler );
	
		theParser.parse( theInputSource );
				
		
		} catch ( FileNotFoundException fnfe ) {
			System.out.println( fnfe );
		} catch ( SAXException se ) {
			System.out.println( se );
		} catch (IOException ie ) {
			System.out.println( ie );
		}
		

		
		System.exit( 0 );
	}
}
