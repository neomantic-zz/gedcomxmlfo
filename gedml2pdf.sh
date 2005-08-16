#! /bin/sh
# $1 -> is the gedml file (<filename>.xml)
# $2 -> is the pdf file (<filename>.pdf)

# set to absolute path of fop.sh
fop="/usr/local/share/java/fop/fop.sh"

#set to absolute path of GedML2F0.xsl stylesheet
stylesheet="/home/joesmo/GedML2FO.xsl"

${fop} -xsl ${stylesheet} -xml $1 -pdf $2

