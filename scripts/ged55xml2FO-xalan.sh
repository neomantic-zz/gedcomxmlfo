#! /bin/sh
# transforms an GEDCOM 5.5 XML file to an FO data stream to the stdout 
# $1 -> is the GEDCOM 5.5 XML file (<filename>.xml)

JAVA="/usr/bin/java"
STYLESHEET="../gedcom55XMLtoXSL-FO.xsl"
XALAN="/usr/share/java/xalan2.jar"

${JAVA} -cp ${XALAN} org.apache.xalan.xslt.Process -DIAG -IN -XSL ${STYLESHEET} $1 
