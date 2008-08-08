#! /bin/sh
# transforms an GEDCOM 5.5 XML file to an FO data stream 
# which is sent to stdout
# $1 -> is the GedML file (<filename>.xml)
# This script is not designed to accept paramaters that could be sent
# to saxon and alter the FO output

JAVA="/usr/bin/java"
STYLESHEET="../gedcom55XMLtoXSL-FO.xsl"
SAXON="/usr/share/java/saxon.jar"

${JAVA} -cp ${SAXON} com.icl.saxon.StyleSheet -t $1 ${STYLESHEET}
