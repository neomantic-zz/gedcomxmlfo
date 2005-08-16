#! /bin/sh
# $1 -> is the gedcom file (<filename>.ged)
# $2 -> is the gedml file (<filename>.xml)

stylesheet="/home/calbers/works/src/gedcom2gedcomxml/GedML2FO.xsl"
saxon="/home/calbers/bin/jing-20030619/bin/saxon.jar"
saxParserDir="/home/calbers/works/src/gedml/"

java -cp ${saxon}:${saxParserDir} com.icl.saxon.StyleSheet -x GedcomParser $1 ${saxParserDir}GedcomToXml.xsl > $2

