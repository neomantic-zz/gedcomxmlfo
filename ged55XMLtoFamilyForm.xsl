<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet 
    version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:fo="http://www.w3.org/1999/XSL/Format" 
    xmlns:date="http://exslt.org/dates-and-times" 
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    extension-element-prefixes="date">
    
    <dc:creator>Chad Albers</dc:creator>
    <dc:publisher>Chad Albers</dc:publisher>
    <dc:date>2008-8-12</dc:date>
    <dc:title>ged55XMLtoFamilyForm.xsl version 0.1</dc:title>
    <dc:description>This XSLT stylesheet can be applied to a GEDCOM 5.5 XML document 
(http://www.neomantic.com/gedcom55XML) to create an XSL-FO stylesheet.  This stylesheet can 
converted into a PDf document using fop (http://xmlgraphics.apache.org/fop/).
The pdf document resembles genealogy recording keeping forms produced by 
ProGenealogists.com.</dc:description>
    <dc:identifier>http://www.neomantic.com/downloads/ged55XMLtoFamilyForm-0.1/</dc:identifier>
    <dc:type>software</dc:type>
    <dc:format>application/xml</dc:format>
    <dc:language>en-US</dc:language>
    <dc:rights>Copyright (c) 2008 Chad Albers mailto:chad@neomantic.com 
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA</dc:rights>

<xsl:output indent="yes" method="xml"/>
<!-- Stylesheet Version 0.1 -->
<!--
#===============================================================================
# XSLT processor parameters and global variables
# All processor parameters and global variables begin with capital letters.  All
# local variables and template parameters start with lowercase letters
#===============================================================================
-->
<!-- 
#===============================================================================
# XSLT processor parameters. 
# These parameters alter the output of the XSLT processor.
#
#   IncludeIDs - accepts either 'true' or 'false' and acts as a flag to include 
#       the XREF ID number of FAM element of the family record and the INDI 
#       elements of family members, including the spouses of children
#
#   IncludeDateGenerated - accepts either 'true or 'false'. If 'true', the date 
#       that the XSLT processor applied this stylesheet to a GEDCOM 5.5 XML 
#       document is included in the footer of the pdf document. It relies on the
#       http://exslt.org/dates-and-times extension. If the XSLT processor does 
#       not support this extension, the stylesheet may fail to be applied to the
#       XML document. To be on the safe side, it defaults to 'false.'
#
#   FamID - accepts the XREF ID of one FAM element. If this value is supplied, 
#       the stylesheet will produce a document containing only the family record
#       with the value in famID. If it this parameter is not supplied, the 
#       stylesheet is applied to all FAM elements in the XML document. 
#
#   SortFamilies - accepts either 'true or 'false'. If the IDs of the FAM 
#       elements are structured in a way that can be sorted ascending or 
#       descending order, this parameter tells the stylesheet to sort these IDs,
#       and output the families in that order. It defaults to 'false'. 
#
#   BorderLineStyle - this parameter allows the user to determine the look of 
#       the borders in the tables, rows, and cells.  It defaults to 'solid', but
#       could accept the following values: none, hidden, dotted, dashed, double,
#       groove, ridge, inset, and outset.  Use these other values at your own 
#       risk.  The stylesheet has been built assuming solid borders.
#
#   BorderLineWidth - this parameter enables the width of the borders to be set.
#       It defaults to .3mm.  Change this value at your own risk.  The 
#       stylesheet has been built assuming the default value.
#===============================================================================
-->

<xsl:param name="IncludeIDs" select="false()"/>
<xsl:param name="IncludeDateGenerated" select="false()"/>
<xsl:param name="FamID"/>
<xsl:param name="SortFamilies" select="false()"/>
<xsl:param name="BorderLineStyle">solid</xsl:param>
<xsl:param name="BorderLineWidth">.3mm</xsl:param>

<!-- 
#===============================================================================
# Global Variables
#   MaxNumberOfPageRows - the value of this variable is used in calculating when
#       page breaks should be inserted.  It can be changed to a new value, if, 
#       say, you want to change the length of your documents from US Letter (the
#       default) to A4.  (Since A4 is also narrower, though, the row and column
#       lengths would have to be decreased as well).
#===============================================================================
-->
<xsl:variable name="MaxNumberOfPageRows">39</xsl:variable>

<!-- 
#===============================================================================
# The root template begins the process of building the xsl-fo document.  The
# document it constructs processes all FAM elements into on long table that
# is divided by page breaks.  Another method would have been to place it each
# family record into its on page sequence
#===============================================================================
-->
<xsl:template match="/">
    <!--FIX for some reason the dublic core namespace is included in the fo 
    output -->
    <fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format">
        <fo:layout-master-set>
            <fo:simple-page-master 
                margin-bottom=".2cm" 
                margin-left="1.2cm" 
                margin-right="1cm" 
                margin-top="1.25cm" 
                master-name="Family" 
                page-height="11in" 
                page-width="8.5in">
                <fo:region-body 
                    margin-top="1cm" 
                    margin-bottom="0cm"/>
                <fo:region-before 
                    extent="1cm"/>
                <fo:region-after 
                    extent=".5cm"/>
            </fo:simple-page-master>
        </fo:layout-master-set>

        <xsl:choose>
            <xsl:when test="$FamID">
                <xsl:apply-templates select="//FAM[@ID = $FamID]"/>
            </xsl:when>
            <xsl:otherwise>
                    <!-- conditional enables user to disable sorting of families -->
                    <xsl:choose>
                        <xsl:when test="SortFamilies = false()">
                            <xsl:apply-templates select="//FAM"/>
                         </xsl:when>
                         <xsl:otherwise>
                            <xsl:apply-templates select="//FAM">
                                <xsl:sort order="ascending" select="@ID"/>
                             </xsl:apply-templates>
                        </xsl:otherwise>
                   </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>

    </fo:root>
</xsl:template>

<!-- 
#===============================================================================
# The "FAM" templates processes a GEDCOM 5.5 XML FAM element.  It calls 
# templates for each portion of the family record. It calls 
# "makeSpouseNameAndEventTables" template twice for each spouse. It adds the row
# separating the Spouse/Parents from the children.  Finally, it begins the 
# process of adding the children to the output by calling "makeChildren"
#===============================================================================
-->
<xsl:template match="FAM">

    <fo:page-sequence 
    country="us" 
    initial-page-number="auto" 
    language="en" 
    master-reference="Family" 
    force-page-count="no-force">
    
    <!-- Header -->
    <fo:static-content 
        flow-name="xsl-region-before">
        <fo:block 
            font-family="sans-serif" 
            font-size="14pt" 
            text-align="center">
            <xsl:text>Family Group Record</xsl:text>
        </fo:block>
        <fo:block 
            font-family="sans-serif" 
            font-size="6pt" 
            text-align="right"
            margin-right=".5cm">
            <xsl:if test="$IncludeIDs = true()">
                <xsl:text>(Fam. ID </xsl:text>
                <fo:retrieve-marker retrieve-class-name="famID"/>
                <xsl:text>)</xsl:text>
            </xsl:if>
        </fo:block>
    </fo:static-content>
    
    <!-- Footer -->
    <fo:static-content 
        flow-name="xsl-region-after">
        <fo:block 
            font-family="sans-serif" 
            font-size="8pt" 
            text-align="left">
            <xsl:if test="$IncludeDateGenerated = true()">
                <xsl:text>Generated: </xsl:text>
                <xsl:value-of select="substring( date:date-time(), 0, 11)"/>
            </xsl:if>
        </fo:block>
        <fo:block 
            font-family="sans-serif" 
            font-size="8pt" 
            text-align="right" 
            margin-right=".5cm">
            <fo:page-number/>
        </fo:block>
    </fo:static-content>
    
    <!-- body -->
    <fo:flow 
        flow-name="xsl-region-body">

        <!-- insert marker for header, in case, IncludeIDs has been enables -->
        <fo:block 
            font-family="sans-serif" 
            font-size="8pt" 
            text-align="left">
            <fo:marker marker-class-name="famID">
                <xsl:value-of select="@ID"/>
            </fo:marker>
        </fo:block>
         
         <!-- add Husband -->
        <xsl:call-template name="makeSpouseNameAndEventsTables">
            <xsl:with-param name="indiID">
                    <!-- for some reason, the @REF is not passed if I just set it
                        via the select attribute of the param -->
                <xsl:value-of select="HUSB/@REF"/>
            </xsl:with-param>
            <xsl:with-param name="spouseRole" select="'Husband'"/>
        </xsl:call-template>
        <!-- 7 rows created -->
        
        <!-- add Wife -->
        <xsl:call-template name="makeSpouseNameAndEventsTables">
            <xsl:with-param name="indiID">
                <xsl:value-of select="WIFE/@REF"/>
            </xsl:with-param>
            <xsl:with-param name="spouseRole" select="'Wife'"/>
        </xsl:call-template>        
        <!-- 6 rows created, total = 13 -->
        
        <!-- add separator row between Spouses and Children -->
        <xsl:call-template name="makeChildListLabel"/>
        <!-- one row created, total = 14 -->
                
        <!-- addChildren -->
        <xsl:call-template name="makeChildren">
            <xsl:with-param name="numberOfChildren" select="count( CHIL )"/>
            <xsl:with-param name="rowNumber" select="14"/> <!-- the number of rows 
                                                            already created -->
        </xsl:call-template>
        </fo:flow> <!-- body -->
    </fo:page-sequence>
</xsl:template>
<!-- 
#===============================================================================
# The "makeChildren" template starts the process of adding both existing 
# children to the output and blank children to fill up the page. The template is
# intended to be called recursively for each CHIL element of a Family Record. 
# It adds each child's data by calling "makeChildNameEventsTables". 
#
# As it adds the children it calculates the number of rows that have and will be 
# added to the output.  This number is used to determine if the page break should 
# be inserted before it adds a new child. If so, it will add header rows (with
# the children's parent's given and surnames) to the top of each page following
# the first page.
# 
# Additionally, the final number of rows is also used to determine how many 
# "empty" children - (blank rows for potential child data) - will be added at the
# end of the family's record.
# 
# Finally, it adds notes rows after the children to fill the pages
#
# The template accepts 3 parameters:
#
#   numberOfChildren - which is supplied usually by a count() function
#
#   childNumber - each child is labeled with a number - representing its order 
#       in the family.  This is determine by the interation in the recursion.
#
#   rowNumber - a parameter that is incremented every time makeChildren is 
#       called
#===============================================================================
-->
<!--TODO this algorithm is entirely too complicated and needs to be broken up and
rewritten.-->
<!--FIX There are also occassionas where it doesn't add enough Note rows -->
<xsl:template name="makeChildren">
    <xsl:param name="numberOfChildren"/>
    <xsl:param name="childNumber" select="1"/>
    <xsl:param name="rowNumber"/>

    <!-- if the number of children created is less that the total number of children, create new children  -->
    <xsl:if test="$childNumber &lt;= $numberOfChildren">
    
        <!-- get child's indiID -->
        <xsl:variable name="indiID" select="CHIL[position() = $childNumber]/@REF"/>
    
        <!-- set the numberOfMarriages by either counting them, or if there are no marriages, set it to at least 1 -->
        <xsl:variable name="numberOfMarriages">
            <xsl:variable name="howManyMarriages" select="count(//INDI[@ID = $indiID]/FAMS)"/>
            <xsl:choose>
                <xsl:when test="$howManyMarriages = 0">1</xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$howManyMarriages"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!--add 4 rows for name, birth, death, burial rows, plus 2 rows per child marriage -->
       <xsl:variable name="numberOfChildRows" select="$rowNumber + 4 + ($numberOfMarriages * 2)"/>
        
        <!-- Break to new page, and add Page Two Headers, if the number of rows generated so far exceeds the max per page -->
        <xsl:if test="$numberOfChildRows &gt; $MaxNumberOfPageRows">
        
            <xsl:comment><xsl:text>rowNumber </xsl:text><xsl:value-of select="$rowNumber"/></xsl:comment>
            
            <xsl:if test="$rowNumber &lt;= $MaxNumberOfPageRows">
            
                <xsl:comment><xsl:text>rowNumber is less than MaxNumberOfPageRows</xsl:text></xsl:comment>
                
                 <xsl:call-template name="addNotesTable">
                    <xsl:with-param name="numberOfNoteRows" select="$MaxNumberOfPageRows - $rowNumber"/>
                 </xsl:call-template>
            </xsl:if>
        
            <xsl:call-template name="addPageTwoPlusHeaders">
                <xsl:with-param name="famID" select="@ID"/>
            </xsl:call-template>
        </xsl:if>
    
        <!-- make the child -->
        <xsl:call-template name="makeChildNameAndEventsTables">
            <xsl:with-param name="indiID" select="$indiID"/>
            <xsl:with-param name="childNumber" select="$childNumber"/>
            <xsl:with-param name="numberOfMarriages" select="$numberOfMarriages"/>
        </xsl:call-template>

        <!-- call makeChildren again, and make the next child -->
        <xsl:call-template name="makeChildren">
            <xsl:with-param name="childNumber" select="$childNumber + 1"/>
            <xsl:with-param name="numberOfChildren" select="$numberOfChildren"/>
            <xsl:with-param name="rowNumber">
                  <!-- If the addPageTwoHeaders was called,  this resets the 
                  rowNumber to 2, to account for the 2 rows in the 
                  PageTwoPlusHeader, otherwise it defaults to the current row 
                  count.  Additionally it adds the 4 lines for the Name, Born, 
                  Died, Buried Rows, and 2 rows for each marriage -->
                <xsl:choose>
                    <xsl:when test="$numberOfChildRows &gt; $MaxNumberOfPageRows">
                        <xsl:value-of select="2 + 4 + ($numberOfMarriages * 2)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$numberOfChildRows"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:if>

    <!-- this conditional prevents this call-template from being repeated after every 
       recursive call to makeChildren -->
    <xsl:if test="$childNumber &gt; $numberOfChildren">
         <xsl:call-template name="addBlankChildren">
            <xsl:with-param name="numberOfChildrenToAdd">
                <xsl:value-of select="( ( $MaxNumberOfPageRows - $rowNumber ) div 6) - ( ( ($MaxNumberOfPageRows - $rowNumber) div 6) mod 1)"/>
            </xsl:with-param>
             <xsl:with-param name="childNumber" select="$childNumber"/>
        </xsl:call-template>
        
        <!-- add notes rows -->
        <xsl:variable name="numberOfNoteRows">
           <xsl:variable name="numberOfBlankChildren">
                <xsl:value-of select="( ( $MaxNumberOfPageRows - $rowNumber ) div 6) - ( ( ($MaxNumberOfPageRows - $rowNumber) div 6) mod 1)"/>
           </xsl:variable>
            <xsl:value-of select="$MaxNumberOfPageRows - (($numberOfBlankChildren * 6) + $rowNumber)"/>    
        </xsl:variable>

        <xsl:if test="($numberOfNoteRows + $rowNumber) &lt; $MaxNumberOfPageRows">
            <xsl:call-template name="addNotesTable">
                <xsl:with-param name="numberOfNoteRows" select="$numberOfNoteRows"/>
            </xsl:call-template>
        </xsl:if>
        
    </xsl:if>
    
</xsl:template>
<!-- 
#===============================================================================
# The "makeChildNameAndEventsTables" template actually builds the fo-tables 
# for the individual children.  It calls the templates to add the child's name -
# "makeChildNameRowCells", calls the templates for the birth, death, and buried
# events - "makeEventTableRows", and finally calls the template to add the 
# child's marriages - "makeChildMarriages".
#
# The template takes 3 parameters:
#
#   indiID - the ID of the INDI element for the child
#
#   childNumber - the child's position in the family and number added to their
#       burial row
#
#   numberOfMarriages - this defaults to 1, but the "makeChildren" template
#        which calls this could increases this number
#===============================================================================
-->
<xsl:template name="makeChildNameAndEventsTables">
    <xsl:param name="indiID"/>
    <xsl:param name="childNumber"/>
    <xsl:param name="numberOfMarriages">1</xsl:param>

    <!-- Table with Child's Name -->
    <xsl:element
        name="fo:table">
        <xsl:call-template name="addChildNameColumns"/>
        <fo:table-body>
            <xsl:element 
                name="fo:table-row" 
                use-attribute-sets="rowHeight">
                <xsl:call-template name="makeChildNameRowCells">
                    <xsl:with-param name="indiID" select="$indiID"/>
                </xsl:call-template>
            </xsl:element><!-- table-row -->
        </fo:table-body>
    </xsl:element><!-- fo:table -->

    <!-- Table with all Events -->
    <fo:table>
        <xsl:call-template name="addEventColumns"/>
        <fo:table-body>
            <!-- Born row -->
            <xsl:call-template name="makeEventTableRows">
                <xsl:with-param name="indiID" select="$indiID"/>
                <xsl:with-param name="eventName" select="'Born'"/>
            </xsl:call-template>
            <!-- Died row -->
            <xsl:call-template name="makeEventTableRows">
                <xsl:with-param name="indiID" select="$indiID"/>
                <xsl:with-param name="eventName" select="'Died'"/>
            </xsl:call-template>
            <!-- Buried row -->
            <xsl:call-template name="makeEventTableRows">
                <xsl:with-param name="indiID" select="$indiID"/>
                <xsl:with-param name="eventName" select="'Buried'"/>
                <xsl:with-param name="childNumber" select="$childNumber"/>
            </xsl:call-template>    
        </fo:table-body>
    </fo:table>

    <xsl:call-template name="makeChildMarriages">
        <xsl:with-param name="indiID" select="$indiID"/>
        <xsl:with-param name="numberOfMarriages" select="$numberOfMarriages"/>
    </xsl:call-template>

</xsl:template>
<!-- 
#===============================================================================
# The "makeChildMarriages" template is intended to be called recursively for 
# each of a child's marriages.  To add the data to the xsl-fo document it calls 
# the "makeChildMarriageTables" templates.
#
# This template takes 3 parameters:
#
#   indiID - the ID of the INDI element for the child
#
#   marriageNumber - it defaults to 1, and is used in the recursion increments
#
#   numberOfMarriages - the total number of FAMS records belonging to a CHIL's
#       INDI record, and the total number of times this template will be called
#===============================================================================
-->
<xsl:template name="makeChildMarriages">
    <xsl:param name="indiID"/>
    <xsl:param name="marriageNumber">1</xsl:param>
    <xsl:param name="numberOfMarriages">1</xsl:param>
 
    <xsl:if test="$marriageNumber &lt;= $numberOfMarriages">
        <xsl:call-template name="makeChildMarriageTables">
            <!-- NOTE for some reason, select="//INDI[@ID = $indID]/FAMS[$marriageNumber]/@REF is too greedy
                 it selects multiple @REFs to position() is used instead -->
            <xsl:with-param name="famID" select="//INDI[@ID = $indiID]/FAMS[position()=$marriageNumber]/@REF"/>
            <xsl:with-param name="indiID" select="$indiID"/>
            <xsl:with-param name="lastChildMarriage">
                <xsl:choose>
                    <xsl:when test="$marriageNumber = $numberOfMarriages">
                        <xsl:value-of select="true()"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="false()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>

        <!-- recursively call itself to cycle through all child marriages -->
        <xsl:call-template name="makeChildMarriages">
            <xsl:with-param name="indiID" select="$indiID"/>
            <xsl:with-param name="marriageNumber" select="$marriageNumber + 1"/>
            <xsl:with-param name="numberOfMarriages" select="$numberOfMarriages"/>
        </xsl:call-template>
    </xsl:if>

</xsl:template>
<!-- 
#===============================================================================
# The "makeSpouseNameAndEventsTables" template creates the tables and begins 
# populating them with data for each family record's spouse/parent (husband or 
# wife).  To add the name rows, it calls "makeSpouseNameRows".  To create the 
# born, died, and buried rows it calls "makeEventTableRows". If the 
# spouse/parent is the husband, it adds the marriage event row.  Finally, it 
# adds the husband or wife's parents by calling "makeParentNameRow". 
#
# This template takes 3 paramaters:
#
#   indiID - the ID of the INDI element of either the husband or wife of the 
#       family
#
#   spouseRole - the role of the individual, either 'Husband' or 'Wife'
#
#   break - used to determine if a page break should be inserted.
#===============================================================================
-->
<xsl:template name="makeSpouseNameAndEventsTables">
    <xsl:param name="indiID"/>
    <xsl:param name="spouseRole"/>
    
    <!-- Table with Spouse Names -->
    <xsl:element 
        name="fo:table" 
        use-attribute-sets="bordersTop">
        
        <xsl:call-template name="addSpouseNameColumns"/>
        
        <fo:table-body>
            <xsl:call-template name="makeSpouseNameRow">
                <xsl:with-param name="spouseRole" select="$spouseRole"/>
                <xsl:with-param name="indiID" select="$indiID"/>
            </xsl:call-template>
        </fo:table-body>
    </xsl:element><!-- fo:table -->

    <!-- Table with all Events -->
    <fo:table>
        <xsl:call-template name="addEventColumns"/>
        <fo:table-body>
            <!-- Born row -->
            <xsl:call-template name="makeEventTableRows">
                <xsl:with-param name="indiID" select="$indiID"/>
                <xsl:with-param name="eventName" select="'Born'"/>
            </xsl:call-template>
            <!-- Died row -->
            <xsl:call-template name="makeEventTableRows">
                <xsl:with-param name="indiID" select="$indiID"/>
                <xsl:with-param name="eventName" select="'Died'"/>
            </xsl:call-template>
            <!-- Buried row -->
            <xsl:call-template name="makeEventTableRows">
                <xsl:with-param name="indiID" select="$indiID"/>
                <xsl:with-param name="eventName" select="'Buried'"/>
            </xsl:call-template>
        
            <!-- Married row Only include for husband -->
            <xsl:if test="$spouseRole = 'Husband'">
                <xsl:call-template name="makeEventTableRows">
                    <xsl:with-param name="famID" select="@REF"/>
                    <xsl:with-param name="eventName" select="'Married'"/>
                </xsl:call-template>
            </xsl:if>
    
        </fo:table-body>
    </fo:table>

    <!-- Table with Spouse's parents -->
    <fo:table>
        <xsl:call-template name="addSpouseParentNamesColumns"/>
        <fo:table-body>
            <!-- Spouse's Family -->
            <xsl:variable name="famID" select="//INDI[@ID = $indiID]/FAMC/@REF"/>
        
            <!-- Assumes traditional family (male/female) -->
            <!-- Spouse's Father -->
            <xsl:call-template name="makeParentNameRow">
                <xsl:with-param name="indiID" select="//FAM[@ID = $famID]/HUSB/@REF"/>
                <xsl:with-param name="spouseRole" select="$spouseRole"/>
                <xsl:with-param name="parentRole" select="'Father'"/>
            </xsl:call-template>
            
            <!-- Spouse's Mother -->
            <xsl:call-template name="makeParentNameRow">
                <xsl:with-param name="indiID" select="//FAM[@ID = $famID]/WIFE/@REF"/>
                <xsl:with-param name="spouseRole" select="$spouseRole"/>
                <xsl:with-param name="parentRole" select="'Mother'"/>
            </xsl:call-template>
    
        </fo:table-body>
    </fo:table>
</xsl:template>
<!-- 
#===============================================================================
# The "makeSpouseNameRow" template adds a row with the family's husband/wife's 
# given Name and surname. 
#
# It takes 2 parameters:
#
#   spouseRole - either 'Wife' or 'Husband' - it is used for the label in the
#       row; e.g., "Husband's Given name(s)"
#
#   indiID  - the ID of the INDI element of the husband or wife of the family
#===============================================================================
-->
<xsl:template name="makeSpouseNameRow">
    <xsl:param name="spouseRole"/>
    <xsl:param name="indiID"/>

    <xsl:element 
        name="fo:table-row" 
        use-attribute-sets="rowHeight bordersLeft bordersRight">
        <xsl:element 
            name="fo:table-cell" 
            use-attribute-sets="bordersBottom">
            <xsl:attribute name="padding-top">.5mm</xsl:attribute>
            <xsl:attribute name="padding-left">.75mm</xsl:attribute>
            <xsl:element 
                name="fo:block"
                use-attribute-sets="styleOfLabelFonts">
                <xsl:value-of select="$spouseRole"/>
                <xsl:text>&#8217;s Given name(s)</xsl:text>
            </xsl:element><!-- fo:block -->
        </xsl:element> <!-- fo:table-cell -->

        <!-- Insert Given Name Cell -->
        <xsl:call-template name="makeGivenNameCell">
            <xsl:with-param name="indiID" select="$indiID"/>
        </xsl:call-template>
    
        <xsl:element 
            name="fo:table-cell" 
            use-attribute-sets="bordersBottom">
            <xsl:attribute name="padding-right">1mm</xsl:attribute>
            <xsl:attribute name="padding-top">.5mm</xsl:attribute>
            <xsl:attribute name="padding-left">.75mm</xsl:attribute>
        
            <xsl:element 
                name="fo:block"
                use-attribute-sets="styleOfLabelFonts">
                <xsl:text>Last name</xsl:text>
             </xsl:element><!-- fo:block -->
       </xsl:element><!-- fo:table-cell -->
    
    <!-- Insert Surname table-cell -->
    <xsl:call-template name="makeSurnameCell">
        <xsl:with-param name="indiID" select="$indiID"/>
    </xsl:call-template>

    </xsl:element><!-- table-row -->

</xsl:template>

<!-- 
#===============================================================================
# The "addNotesTable" template begins the process of adding blank not rows. This
# template creates one blank note row, with the note label.  It then calls the
# template responsible for adding additional blank note rows.
#
# The template takes 1 parameters:
#
#   numberOfNoteRows - the number of rows to be added
#===============================================================================
-->
<xsl:template name="addNotesTable">
    <xsl:param name="numberOfNoteRows">0</xsl:param>
        <fo:table>
        <fo:table-column column-width="7mm"/>
        <fo:table-column column-width="183mm"/>
        <xsl:element 
            name="fo:table-body"
            use-attribute-sets="bordersLeft bordersRight bordersBottom">
            <xsl:element 
                name="fo:table-row"
                use-attribute-sets="rowHeight">                 
                 <xsl:element 
                    name="fo:table-cell" 
                    use-attribute-sets="labelPadding">
                    <xsl:element 
                        name="fo:block"
                        use-attribute-sets="styleOfLabelFonts">
                        <xsl:text>Notes</xsl:text>
                    </xsl:element><!-- fo:block -->
                </xsl:element><!-- fo:table-cell -->
                 
                <fo:table-cell>
                    <fo:block/>
                </fo:table-cell>
            </xsl:element><!-- fo:table-row -->
            <xsl:if test="$numberOfNoteRows &gt; 1">
                <xsl:call-template name="addAdditionalNoteRows">
                   <xsl:with-param name="rowsToAdd" select="$numberOfNoteRows - 1"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:element>
    </fo:table>
</xsl:template>

<!-- 
#===============================================================================
# The "addAdditionalNoteRows" template recursively adds additional blank rows to
# the "Notes" section at the end of each page 
#
# The template takes 2 parameters:
#
#   rowsToAdd - the number of additional blank rows to add
#
#   rowNumber - called by the template itself when it recursively calls itself
#===============================================================================
-->
<xsl:template name="addAdditionalNoteRows">
    <xsl:param name="rowsToAdd">1</xsl:param>
    <xsl:param name="rowNumber">0</xsl:param>
   
    <xsl:if test="$rowNumber &lt;= $rowsToAdd">    
        <xsl:element 
        name="fo:table-row"
        use-attribute-sets="rowHeight">
            <fo:table-cell><fo:block/></fo:table-cell>
            <fo:table-cell><fo:block/></fo:table-cell>            
        </xsl:element>
        
        <xsl:call-template name="addAdditionalNoteRows">
            <xsl:with-param name="rowsToAdd" select="$rowsToAdd"/>
            <xsl:with-param name="rowNumber" select="$rowNumber + 1"/>
       </xsl:call-template>
    </xsl:if>
    
</xsl:template>
<!-- 
#===============================================================================
# The "makeGivenNameCell" template adds the row cell containing the given name 
# of the family member. It works for every family member (husband, wife, their 
# parents, the children, and the children's spouse(s).
#
# It takes 1 parameter:
#
#   indiID - the ID of the INDI element of the family member
#===============================================================================
-->
<!-- Creates table-cell with Given Name -->
<xsl:template name="makeGivenNameCell">
    <xsl:param name="indiID"/>

    <xsl:element 
        name="fo:table-cell" 
        use-attribute-sets="bordersRight bordersBottom">
        <xsl:attribute name="padding-top">1mm</xsl:attribute>
        <xsl:attribute name="padding-left">1mm</xsl:attribute>
        
        <fo:block 
        font-family="serif" 
        font-size=".9em"
        font-weight="bold">
            <xsl:choose>
                <xsl:when test="//INDI[@ID = $indiID]/NAME/GIVN">
                    <xsl:value-of select="//INDI[@ID = $indiID]/NAME/GIVN"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Retrieve First Name -->
                    <xsl:if test="string-length(substring-before( normalize-space( //INDI[@ID = $indiID]/NAME) , '/')) &gt; 0">
                        <xsl:value-of select="substring-before( normalize-space( //INDI[@ID = $indiID]/NAME) , '/')"/>
                    </xsl:if>
                    <xsl:if test="$IncludeIDs = true()">
                        <xsl:if test="$indiID">
                            <fo:inline font-family="serif" font-size="8pt">
                                <xsl:text>   (</xsl:text>
                                <xsl:value-of select="$indiID"/>
                                <xsl:text>)</xsl:text>
                            </fo:inline>
                        </xsl:if>
                    </xsl:if>            
                </xsl:otherwise>
            </xsl:choose>   
        </fo:block>
    </xsl:element><!-- fo:table-cell -->
</xsl:template>

<!-- 
#===============================================================================
# The "makeSurnameCell" template adds the cell containing the surname (or last 
# name) of the family member. It works for every family member, with the 
# exception of the children's whose surname is not added to the output.
#
# It takes 1 parameter:
#
#   indiID - the ID of the INDI element of the family member
#===============================================================================
-->
<!-- Creates table-cell with Last Name -->

<xsl:template name="makeSurnameCell">
    <xsl:param name="indiID"/>

    <xsl:element 
        name="fo:table-cell" 
        use-attribute-sets="bordersBottom">
        <xsl:attribute name="padding-top">1mm</xsl:attribute>
        <xsl:attribute name="padding-left">1mm</xsl:attribute>
    
        <fo:block 
            font-family="serif" 
            font-size=".9em"
            font-weight="bold">
            <!-- Surname -->
            <xsl:choose>
                <xsl:when test="//INDI[@ID = $indiID]/NAME/SURN">
                    <xsl:value-of select="//INDI[@ID = $indiID]/NAME/SURN"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="string-length(substring-before(substring-after( normalize-space( //INDI[@ID = $indiID]/NAME),'/'), '/')) &gt; 0">
                        <xsl:value-of select="substring-before(substring-after( normalize-space( //INDI[@ID = $indiID]/NAME),'/'), '/')"/>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </fo:block>
    </xsl:element><!-- fo:table-cell -->
</xsl:template>
<!-- 
#===============================================================================
# The "makeEventTableRows" template adds the rows containing the event's data
# (birth, death, burial, marriage) for the family members.  It is used for a 
# family's husband and wife, and their children.  It calls templates DATE and 
# PLAC to add the cells containing the actual data.
#
# This template takes 5 parameters:
#
#   indiID - the ID of the INDI element of the family member
#
#   eventName - the name of the event to be processed.  Acceptable values are
#       'Born', 'Died', 'Buried', 'Married'.
#
#   famID - the ID of the FAM element for either the husband/wife or children's
#       families.  It is used to process the MARR/DATE MARR/PLAC data in a FAM 
#       element
#
#   childNumber - the number to be added in the burial row of a child.  It 
#      indicates the birth order of the child in the family.
#
#   addBorderHack - accepts the value true() or false().  It is an ugly hack
#      used to add a missing cell border in rows for children's marriages
#===============================================================================
-->
<xsl:template name="makeEventTableRows">
    <xsl:param name="indiID"/><!-- mandatory for any event -->
    <xsl:param name="eventName"/><!-- mandatory for any event -->
    <xsl:param name="famID"/> <!-- added for spouse and child married events -->
    <xsl:param name="childNumber"/><!-- added for child burial events -->
    <xsl:param name="addBorderHack" select="false()"/><!--  this last parameter 
                  was added to ensure that there was a border on the left column
                  at the end of child marriage rows.  I consider it a ugly hack-->
          
    <!-- Event Rows have Bottom Borders -->
    <xsl:element 
        name="fo:table-row" 
        use-attribute-sets="rowHeight bordersRight bordersLeft">
        <xsl:attribute name="keep-with-previous.within-line">always</xsl:attribute>
        <xsl:element
            name="fo:table-cell"
            use-attribute-sets="labelPadding">
            <xsl:if test="$addBorderHack = 'true'">
                <xsl:call-template name="bordersBottom"/>
            </xsl:if>
            <fo:block 
                font-family="sans-serif" 
                font-size=".7em" 
                text-indent="2pt"> <!-- note that this label, the child number is
                    set to larger than the default label font size -->
                <!-- Insert Child's number if this is a burial event -->
                <xsl:if test="$eventName = 'Buried'">
                    <xsl:value-of select="$childNumber"/>
                </xsl:if>
            </fo:block>
        </xsl:element>
        <xsl:element 
            name="fo:table-cell" 
            use-attribute-sets="bordersBottom bordersLeft labelPadding">
            <xsl:element 
                name="fo:block"
                use-attribute-sets="styleOfLabelFonts">
                <!-- Insert "Born", "Died", or "Buried" -->
                <xsl:value-of select="$eventName"/>
            </xsl:element><!-- fo:block -->
        </xsl:element> <!-- fo:table-cell -->

        <xsl:element 
            name="fo:table-cell" 
            use-attribute-sets="bordersRight bordersBottom">
            <xsl:attribute name="padding-top">1mm</xsl:attribute>

            <!-- DATE -->
            <xsl:choose>
                <xsl:when test="$eventName = 'Born'">
                    <xsl:choose>
                        <xsl:when test="//INDI[@ID = $indiID]/BIRT/DATE">
                            <xsl:apply-templates select="//INDI[@ID = $indiID]/BIRT/DATE"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <fo:block/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$eventName = 'Died'">
                    <xsl:choose>
                        <xsl:when test="//INDI[@ID = $indiID]/DEAT/DATE">
                            <xsl:apply-templates select="//INDI[@ID = $indiID]/DEAT/DATE"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <fo:block/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$eventName = 'Buried'">
                    <xsl:choose>
                        <xsl:when test="//INDI[@ID = $indiID]/BURI/DATE">
                            <xsl:apply-templates select="//INDI[@ID = $indiID]/BURI/DATE"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <fo:block/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$eventName = 'Married'">
                    <xsl:choose>
                        <xsl:when test="//FAM[@ID = $famID]/MARR/DATE">
                            <xsl:apply-templates select="//FAM[@ID = $famID]/MARR/DATE"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <fo:block/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>
        </xsl:element><!-- fo:table-cell -->
        <!-- place cells -label -->
        <xsl:element 
            name="fo:table-cell" 
            use-attribute-sets="bordersBottom labelPadding">
            <!-- Place Label -->
            <xsl:element 
                name="fo:block"
                use-attribute-sets="styleOfLabelFonts">
                <xsl:text>Place</xsl:text>
           </xsl:element><!-- fo:block -->
        </xsl:element><!-- fo:table-cell -->
         <!-- place cells - data -->   
        <xsl:element 
            name="fo:table-cell" 
            use-attribute-sets="bordersBottom">
            <xsl:attribute name="padding-top">1mm</xsl:attribute>
            <xsl:attribute name="padding-left">.75mm</xsl:attribute>
            
            <!--Place of Event -->
            <xsl:choose>
                <xsl:when test="$eventName = 'Born'">
                    <xsl:choose>
                        <xsl:when test="//INDI[@ID = $indiID]/BIRT/PLAC">
                            <xsl:apply-templates select="//INDI[@ID = $indiID]/BIRT/PLAC"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <fo:block/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$eventName = 'Died'">
                    <xsl:choose>
                        <xsl:when test="//INDI[@ID = $indiID]/DEAT/PLAC">
                            <xsl:apply-templates select="//INDI[@ID = $indiID]/DEAT/PLAC"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <fo:block/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$eventName = 'Buried'">
                    <xsl:choose>
                        <xsl:when test="//INDI[@ID = $indiID]/BURI/PLAC">
                            <xsl:apply-templates select="//INDI[@ID = $indiID]/BURI/PLAC"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <fo:block/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$eventName = 'Married'">
                    <xsl:choose>
                        <xsl:when test="//FAM[@ID = $famID]/MARR/PLAC">
                            <xsl:apply-templates select="//FAM[@ID = $famID]/MARR/PLAC"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <fo:block/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
            </xsl:choose>
        </xsl:element><!-- fo:table-cell -->
    </xsl:element><!-- table-row -->
</xsl:template>
<!-- 
#===============================================================================
# The "makeParentNameRow" template creates the row for a husband/wife's parent's
# names.  To add the actual data it calls "makeGivenNameCell" and "makeSurnameCell".
#
# It accepts 3 parameters:
#
#   indiID - the ID of the INDI element of the mother or father of the family
#       record
#
#   spouseRole - this accepts either 'Husband' or 'Wife' and is used for
#       the label; e.g., "Husband's Mother's Given name(s)"
#
#   parentRole - this accepts either 'Father or 'Mother' and is used for the
#       label shown above
#===============================================================================
-->
<xsl:template name="makeParentNameRow">
    <xsl:param name="indiID"/>
    <xsl:param name="spouseRole"/><!-- either Husband or Wife -->
    <xsl:param name="parentRole"/><!-- either Father or Mother -->

    <xsl:element 
        name="fo:table-row" 
        use-attribute-sets="rowHeight bordersRight bordersLeft">
        <fo:table-cell>
            <fo:block/>
        </fo:table-cell>
        <xsl:element 
            name="fo:table-cell" 
            use-attribute-sets="bordersBottom bordersLeft">
            <xsl:attribute name="padding-top">.5mm</xsl:attribute>
            <xsl:attribute name="padding-left">1mm</xsl:attribute>

            <xsl:element 
                name="fo:block"
                use-attribute-sets="styleOfLabelFonts">
                <xsl:value-of select="$spouseRole"/>
                <xsl:text>&#8217;s </xsl:text>
                <xsl:value-of select="$parentRole"/>
                <xsl:text>&#8217;s Given name(s)</xsl:text>
            </xsl:element><!-- fo:block -->
        </xsl:element><!-- fo:table-cell -->
    
        <!-- Insert Given Name table-cell -->
        <xsl:call-template name="makeGivenNameCell">
            <xsl:with-param name="indiID" select="$indiID"/>
        </xsl:call-template>

        <xsl:element 
            name="fo:table-cell" 
            use-attribute-sets="bordersBottom">
            <xsl:attribute name="padding-top">.5mm</xsl:attribute>
            <xsl:attribute name="padding-left">1mm</xsl:attribute>

            <xsl:element 
                name="fo:block"
                use-attribute-sets="styleOfLabelFonts">
                <xsl:text>Last name</xsl:text>
            </xsl:element><!-- fo:block -->
        </xsl:element><!-- table-cell -->
    
        <!-- Insert Surname Cell-->
        <xsl:call-template name="makeSurnameCell">
            <xsl:with-param name="indiID" select="$indiID"/>
        </xsl:call-template>

    </xsl:element><!-- table-row -->
</xsl:template>

<!-- 
#===============================================================================
# The "addBlankChildren" template adds empty child name and event rows to fill 
# the page by calling "makeChildNameAndEventsTables" and recursively calling 
# itself for each new blank child.
#
# It accepts 2 parameters:
#
#   numberOfChildrenToAdd - the number of blank children to add to the document
#
#   childNumber - primes the recursion and increments with every recursion
#===============================================================================
-->
<xsl:template name="addBlankChildren">
    <xsl:param name="numberOfChildrenToAdd"/>
    <xsl:param name="childNumber">1</xsl:param>

    <xsl:if test="$childNumber &lt; ($childNumber + $numberOfChildrenToAdd)">
        <xsl:call-template name="makeChildNameAndEventsTables">
            <xsl:with-param name="childNumber" select="$childNumber"/>
        </xsl:call-template>
    
        <xsl:call-template name="addBlankChildren">
            <xsl:with-param name="childNumber" select="$childNumber + 1"/>
            <xsl:with-param name="numberOfChildrenToAdd" select="$numberOfChildrenToAdd - 1"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>
<!-- 
#===============================================================================
# The "addPageTwoPlusHeaders" adds a header for every family record page after 
# the first page.  The header contains 2 rows with the husband's and wife's 
# given names and surnames.  To produce each row it calls "makeSpouseNameRow."
#
# This parameter takes 1 parameter:
#
#   famID - the ID of the FAM record containing the husband and wife
#===============================================================================
-->
<xsl:template name="addPageTwoPlusHeaders">
    <xsl:param name="famID"/>
    
    <xsl:element 
        name="fo:table" 
        use-attribute-sets="bordersTop">
        <xsl:attribute name="break-before">page</xsl:attribute>
        <xsl:call-template name="addSpouseNameColumns"/>
        <fo:table-body>
            <!-- Insert name of Family Record's Husband/Father -->
            <xsl:call-template name="makeSpouseNameRow">
                <xsl:with-param name="spouseRole" select="'Husband'"/>
                <xsl:with-param name="indiID" select="//FAM[@ID = $famID]/HUSB/@REF"/>
            </xsl:call-template>
            <!-- Insert name of Family Record's Wife/Mother -->            
            <xsl:call-template name="makeSpouseNameRow">
                <xsl:with-param name="spouseRole" select="'Wife'"/>
                <xsl:with-param name="indiID" select="//FAM[@ID = $famID]/WIFE/@REF"/>
            </xsl:call-template>
        </fo:table-body>
    </xsl:element><!-- fo:table -->
</xsl:template>
<!-- 
#===============================================================================
# The "makeChildListLabel" creates a table, its rows, and cells, that contain 
# the label "Children - List each child in the order of birth."  It is used to 
# visually separate the family's parents from the children.
#===============================================================================
-->
<xsl:template name="makeChildListLabel">

    <xsl:element 
        name="fo:table" 
        use-attribute-sets="bordersTop">
        <!-- add columns -->
        <xsl:call-template name="addChildListLabelColumns"/>
        <fo:table-body>
            <xsl:element 
                name="fo:table-row" 
                use-attribute-sets="rowHeight">
                <xsl:element 
                    name="fo:table-cell" 
                    use-attribute-sets="bordersTop bordersRight bordersBottom bordersLeft">
                    <xsl:attribute name="padding-top">1.5mm</xsl:attribute>
                    <xsl:attribute name="padding-left">2mm</xsl:attribute>
                
                    <fo:block 
                        font-family="sans-serif" 
                        font-size=".8em">
                        <xsl:text>Children - List each child in order of birth</xsl:text>
                    </fo:block>

                </xsl:element><!-- fo:table-cell -->
            </xsl:element><!-- table-row -->
        </fo:table-body>
    </xsl:element><!-- fo:table -->
</xsl:template>
<!-- 
#===============================================================================
# The "makeChildNameRowCells" template adds the row and the cells containing the
# name of a family's child.  It adds the sex of the child, and leaves out the 
# child's surname, because it is unnecessary.  To add the cell with the given 
# name it calls "makeGivenNameCell".
#
# It accepts 1 parameter:
#
#   indiID - the ID of the INDI element for the child
#===============================================================================
-->
<xsl:template name="makeChildNameRowCells">
    <xsl:param name="indiID"/>    
    <!-- add Gender (M or F) -->
    <xsl:element 
        name="fo:table-cell" 
        use-attribute-sets="bordersTop bordersRight bordersBottom bordersLeft">
        <xsl:attribute name="padding-top">.3mm</xsl:attribute>
        <xsl:attribute name="padding-left">1mm</xsl:attribute>
        <xsl:element 
            name="fo:block"
            use-attribute-sets="styleOfLabelFonts">
            <xsl:attribute name="text-indent">1pt</xsl:attribute>
                <xsl:text>Sex</xsl:text>
        </xsl:element><!-- fo:block -->
        <fo:block 
            font-family="sans-serif" 
            font-size=".5em" 
            text-indent="2pt">
            <xsl:value-of select="//INDI[@ID = $indiID]/SEX"/>
        </fo:block>
    </xsl:element><!-- fo:table-cell -->
    
    <!-- add Given Name -->
    <xsl:element 
        name="fo:table-cell" 
        use-attribute-sets="bordersBottom labelPadding">
        <xsl:element 
            name="fo:block"
            use-attribute-sets="styleOfLabelFonts">
            <xsl:attribute name="padding-left">1mm</xsl:attribute>
            <xsl:text>Given name(s)</xsl:text>
        </xsl:element><!-- fo:block -->
    </xsl:element><!-- fo:table-cell -->

    <!-- Insert Given Name Cell -->
    <xsl:call-template name="makeGivenNameCell">
        <xsl:with-param name="indiID" select="$indiID"/>
    </xsl:call-template>
    
    <!-- No Surname -->

</xsl:template>
<!-- 
#===============================================================================
# The "makeChildMarriageTables" template produces the tables, rows, and cells 
# that are populated with data regarding a child's marriage.  It adds a row with
# the child's spouse's given name(s) and surname - calling "makeGivenNameCell" 
# and "makeSurnameCell."  It adds the date and place of the marriage by calling
# "makeEventTableRows".
#
# It accepts 3 variables:
#
#   famID - the ID of the FAM element for the child's FAMS.
#
#   indiID - the ID of the INDI element of the child.  It is used to test if the
#       right family has been selected
#
#   lastChildMarriage - all the marriages of a child are included in the output.
#       This parameter is used as a trigger for the addBorderHack (see above).  
#       It accepts either true() or false() and is primed with false()
#===============================================================================
-->
<xsl:template name="makeChildMarriageTables">
    <xsl:param name="famID"/>
    <xsl:param name="indiID"/>
    <xsl:param name="lastChildMarriage" select="false()"/>

    <!-- table and row with spouse name -->
    <fo:table>
        <!-- add columns -->
        <xsl:call-template name="addChildSpouseNameColumns"/>
        <fo:table-body>
            <xsl:element 
                name="fo:table-row" 
                use-attribute-sets="rowHeight bordersLeft bordersRight">
                <xsl:attribute name="keep-with-previous.within-line">always</xsl:attribute>

                <fo:table-cell>
                    <fo:block/>
                </fo:table-cell>
                <xsl:element 
                    name="fo:table-cell" 
                    use-attribute-sets="bordersBottom bordersLeft labelPadding">
                    <!-- Spouse's Given name(s) Label -->
                    <xsl:element 
                        name="fo:block"
                        use-attribute-sets="styleOfLabelFonts">
                        <xsl:text>Spouse&#8217;s Given name(s)</xsl:text>
                    </xsl:element><!-- fo:block -->
                </xsl:element><!-- fo:table-cell -->
                
                <!-- Insert Given Name table-cell -->
                <xsl:choose>
                    <!-- If the family has a HUSB with an REF different from their Spouse's ID -->
                    <xsl:when test="//FAM[@ID = $famID]/HUSB[@REF = $indiID]">
                        <xsl:call-template name="makeGivenNameCell">
                            <xsl:with-param name="indiID" select="//FAM[@ID = $famID]/WIFE/@REF"/>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- If the family has a WIFE with an REF different from their Spouse's ID -->
                    <xsl:when test="//FAM[@ID = $famID]/WIFE[@REF = $indiID]">
                        <xsl:call-template name="makeGivenNameCell">
                            <xsl:with-param name="indiID" select="//FAM[@ID = $famID]/HUSB/@REF"/>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- otherwise insert blank given name cell -->
                    <xsl:otherwise>
                        <xsl:call-template name="makeGivenNameCell"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:element 
                    name="fo:table-cell" 
                    use-attribute-sets="bordersBottom bordersLeft labelPadding">    
                    <!-- Last name Label -->
                    <xsl:element 
                        name="fo:block"
                        use-attribute-sets="styleOfLabelFonts">
                        <xsl:text>Last name</xsl:text>
                    </xsl:element><!-- fo:block -->
                </xsl:element><!-- fo:table-cell -->
                
                <!-- Insert Surname Cell-->
                <xsl:choose>
                    <!-- If the family has a HUSB with an REF different from their Spouse's ID -->
                    <xsl:when test="//FAM[@ID = $famID]/HUSB[@REF = $indiID]">
                        <xsl:call-template name="makeSurnameCell">
                            <xsl:with-param name="indiID" select="//FAM[@ID = $famID]/WIFE/@REF"/>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- If the family has a WIFE with an REF different from their Spouse's ID -->
                    <xsl:when test="//FAM[@ID = $famID]/WIFE[@REF = $indiID]">
                        <xsl:call-template name="makeSurnameCell">
                            <xsl:with-param name="indiID" select="//FAM[@ID = $famID]/HUSB/@REF"/>
                        </xsl:call-template>
                    </xsl:when>
                    <!-- otherwise insert blank given name cell -->
                    <xsl:otherwise>
                        <xsl:call-template name="makeSurnameCell"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:element><!-- table-row -->
        </fo:table-body>
    </fo:table>	

    <!-- Table with Married Event -->
    <fo:table>
        <xsl:call-template name="addEventColumns"/>
        <fo:table-body>
            <xsl:call-template name="makeEventTableRows">
                <xsl:with-param name="eventName" select="'Married'"/>
                <xsl:with-param name="famID" select="$famID"/>
                <xsl:with-param name="addBorderHack" select="$lastChildMarriage"/>
            </xsl:call-template>
        </fo:table-body>
    </fo:table>
    
</xsl:template>
<!-- 
#===============================================================================
# The "DATE" template matches all DATE elements.  It is used for all events.
#===============================================================================
-->
<xsl:template match="DATE">

    <!-- DATE_VALUE's range is 1<35 -->
    <xsl:choose>
        <!-- When it is greater than 12, but less that 15, change font to 10pt -->
        <xsl:when test="(string-length( normalize-space( . )) &gt; 12 ) and (string-length( normalize-space( . ) ) &lt;= 15)">
            <fo:block 
                font-family="serif" 
                font-size="10pt">
                <xsl:value-of select="normalize-space( . )"/>
            </fo:block>
        </xsl:when>
        <!-- Truncate -->
        <xsl:when test="string-length( normalize-space( . ) ) &gt; 15">
            <fo:block 
            font-family="serif" 
            font-size="10pt">
                <xsl:choose>
                    <xsl:when test="string-length( normalize-space( . ) ) &gt; 16">
                        <xsl:value-of select="substring( normalize-space( . ), 1, 13 )"/>
                        <xsl:text>...</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="normalize-space( . )"/>
                    </xsl:otherwise>
                </xsl:choose>
            </fo:block>
        </xsl:when>
        <!-- default to .9em -->
        <xsl:otherwise>
            <fo:block 
                font-family="serif" 
                font-size=".9em">
                <xsl:value-of select="normalize-space( . )"/>
            </fo:block>
        </xsl:otherwise>
    </xsl:choose>

</xsl:template>

<!-- 
#===============================================================================
# The "PLAC" template matches all PLAC elements.  It is used for all events.
#===============================================================================
-->
<xsl:template match="PLAC">

    <!-- return the text of PLAC not the text of its child elements -->
    <xsl:variable name="stringLength" select="string-length(normalize-space( text() ) )"/>

    <xsl:choose>
        <xsl:when test="$stringLength &gt;= 97">
            <fo:block 
                font-family="serif" 
                font-size="8pt">
                <xsl:value-of select="substring( normalize-space( text() ), 1, 94 )"/>
                <xsl:text>...</xsl:text>
            </fo:block>
        </xsl:when>
        <xsl:when test="($stringLength &gt;= 87) and ($stringLength &lt; 97)">
            <fo:block 
                font-family="serif" 
                font-size="8pt">
                <xsl:value-of select="normalize-space( text() )"/>
            </fo:block>
        </xsl:when>
        <xsl:when test="$stringLength &gt;= 86">
            <fo:block 
                font-family="serif" 
                font-size="9pt">
                <xsl:value-of select="substring( normalize-space( text() ), 1, 83 )"/>
                <xsl:text>...</xsl:text>
            </fo:block>
        </xsl:when>
        <xsl:when test="($stringLength &gt;= 77) and ($stringLength &lt; 86)">
            <fo:block 
                font-family="serif" 
                font-size="9pt">
                <xsl:value-of select="normalize-space( text() )"/>
            </fo:block>
        </xsl:when>
        <xsl:when test="$stringLength &gt;= 76">
            <fo:block 
                font-family="serif" 
                font-size="10pt">
                <xsl:value-of select="substring( normalize-space( text() ), 1, 73 )"/>
                <xsl:text>...</xsl:text>
            </fo:block>
        </xsl:when>
        <xsl:when test="($stringLength &gt;= 70) and ($stringLength &lt; 75)">
            <fo:block 
                font-family="serif" 
                font-size="10pt">
                <xsl:value-of select="normalize-space( text() )"/>
            </fo:block>
        </xsl:when>
        <xsl:when test="$stringLength &gt;= 71">
            <fo:block 
                font-family="serif" 
                font-size=".9em">
                <xsl:value-of select="substring( normalize-space( text() ), 1, 69 )"/>
                <xsl:text>...</xsl:text>
            </fo:block>
        </xsl:when>
        <xsl:otherwise>
            <fo:block 
                font-family="serif" 
                font-size=".9em">
                <xsl:value-of select="normalize-space( text() )"/>
            </fo:block>
        </xsl:otherwise>
    </xsl:choose>

</xsl:template>
<!--
#===============================================================================
# Unlike XHTML and CSS, it is difficult to separate content from style in
# xsl-fo documents.  However, some effort has been made to do so.  This has
# been accomplished in two ways: templates and attribute sets. The templates 
# below insert the formatting elements into the output.  The attribute sets are 
# used to add attributes to fo elements created by xsl:element elements.
#===============================================================================
-->
<!--
#===============================================================================
# "Formatting" templates
# Note that most of these templates insert the fo:table-columns used for the
# tables.  Each row is 190mm long.  Some rows contain a blank column that is 6mm
# long
#===============================================================================
-->

<xsl:template name="addChildNameColumns">
    <!-- empty column -->
    <xsl:element name="fo:table-column" use-attribute-sets="blankColumnWidth"/>
    <fo:table-column column-width="8mm"/><!-- label -->
    <fo:table-column column-width="176mm"/><!-- data -->
</xsl:template>

<xsl:template name="addEventColumns">
    <!-- empty column -->
    <xsl:element name="fo:table-column" use-attribute-sets="blankColumnWidth"/>
    <fo:table-column column-width="10mm"/><!-- label -->
    <fo:table-column column-width="31mm"/><!-- data -->
    <fo:table-column column-width="7mm"/><!-- label -->
    <fo:table-column column-width="136mm"/><!-- data -->
</xsl:template>

<xsl:template name="addChildSpouseNameColumns">
    <!-- empty column -->
    <xsl:element name="fo:table-column" use-attribute-sets="blankColumnWidth"/>
    <fo:table-column column-width="14mm"/> <!-- label -->
    <fo:table-column column-width="79mm"/> <!-- data -->
    <xsl:call-template name="addLastNameColumns"/>
</xsl:template>

<xsl:template name="addSpouseParentNamesColumns">
    <!-- empty column -->
    <xsl:element name="fo:table-column" use-attribute-sets="blankColumnWidth"/>
    <fo:table-column column-width="22mm"/><!-- label -->
    <fo:table-column column-width="71mm"/><!-- data -->
    <xsl:call-template name="addLastNameColumns"/>
</xsl:template>

<xsl:template name="addSpouseNameColumns">    
    <fo:table-column column-width="14mm"/><!-- label -->
    <fo:table-column column-width="85mm"/><!-- data -->
    <xsl:call-template name="addLastNameColumns"/>
</xsl:template>

<xsl:template name="addLastNameColumns">
    <fo:table-column column-width="7mm"/><!-- "Last Name" label -->
    <fo:table-column column-width="84mm"/><!-- Surname data -->
</xsl:template>

<xsl:template name="addChildListLabelColumns">
   <fo:table-column column-width="190mm"/>
</xsl:template>

<xsl:template name="bordersBottom">
    <xsl:attribute name="border-right-color">black</xsl:attribute>
    <xsl:attribute name="border-bottom-style"><xsl:value-of select="$BorderLineStyle"/></xsl:attribute>
    <xsl:attribute name="border-bottom-width"><xsl:value-of select="$BorderLineWidth"/></xsl:attribute>
</xsl:template>
<!--
#===============================================================================
# Attribute Sets
#===============================================================================
-->
<xsl:attribute-set name="blankColumnWidth">
    <xsl:attribute name="column-width">6mm</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="bordersRight">
    <xsl:attribute name="border-right-color">black</xsl:attribute>
    <xsl:attribute name="border-right-style"><xsl:value-of select="$BorderLineStyle"/></xsl:attribute>
    <xsl:attribute name="border-right-width"><xsl:value-of select="$BorderLineWidth"/></xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="bordersBottom">
    <xsl:attribute name="border-bottom-color">black</xsl:attribute>
    <xsl:attribute name="border-bottom-style"><xsl:value-of select="$BorderLineStyle"/></xsl:attribute>
    <xsl:attribute name="border-bottom-width"><xsl:value-of select="$BorderLineWidth"/></xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="bordersLeft">
    <xsl:attribute name="border-left-color">black</xsl:attribute>
    <xsl:attribute name="border-left-style"><xsl:value-of select="$BorderLineStyle"/></xsl:attribute>
    <xsl:attribute name="border-left-width"><xsl:value-of select="$BorderLineWidth"/></xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="bordersTop">
    <xsl:attribute name="border-top-color">black</xsl:attribute>
    <xsl:attribute name="border-top-style"><xsl:value-of select="$BorderLineStyle"/></xsl:attribute>
    <xsl:attribute name="border-top-width"><xsl:value-of select="$BorderLineWidth"/></xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="rowHeight">
    <xsl:attribute name="height">5mm</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="labelPadding">
    <xsl:attribute name="padding-top">.75mm</xsl:attribute>
    <xsl:attribute name="padding-left">.75mm</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="styleOfLabelFonts">
      <xsl:attribute name="font-family">sans-serif</xsl:attribute>
      <xsl:attribute name="font-size">.45em</xsl:attribute>
</xsl:attribute-set>

</xsl:stylesheet>
