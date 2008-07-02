<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" 
	xmlns:fo="http://www.w3.org/1999/XSL/Format" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:date="http://exslt.org/dates-and-times"
  	extension-element-prefixes="date">
<!--
 ******************************************************************************
 ******************************************************************************
    Copyright (c) 2005 Chad Albers - chad@neomantic.com
     
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
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
    
 ******************************************************************************
 ******************************************************************************
 -->

<xsl:output indent="yes" method="xml"/>

<!-- change this global variable if you don't want the FAM XREF or the INDI XREF to be included -->
<xsl:variable name="includeID" select="true()"/>
<xsl:variable name="numberOfChildrenOnFirstPage" select="4"/>
<xsl:variable name="numberOfChildrenOnSecondPlusPages" select="6"/>
<xsl:variable name="maxNumberOfPageRows" select="38"/>
<xsl:variable name="whenGenerated" select="false()"/>
<xsl:variable name="lineStyle">solid</xsl:variable>
<xsl:variable name="lineWidth">.3mm</xsl:variable>
<!-- <xsl:variable name="includeID" select="false()"/> -->

<!-- TODO - 
     test on extreme cases
     determine if I need to add lineNumbers for blank children
     fix the blank children to depend upon lineNumbers and not number of children
     collapse fo elements, into xsl elements, separating formating from code
     Truncated length of cell functions
-->
     
<xsl:template match="/">

    <fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format">
        <fo:layout-master-set>
            <fo:simple-page-master 
                margin-bottom=".2cm" 
                margin-left="2.5cm" 
                margin-right="1cm" 
                margin-top="1cm" 
                master-name="Family" 
                page-height="11in" 
                page-width="8.5in">
                <fo:region-body margin-top="1cm" margin-bottom="0cm"/>
                <fo:region-before extent="1cm"/>
                 <fo:region-after extent=".5cm"/>
            </fo:simple-page-master>
        </fo:layout-master-set>
        
        <xsl:apply-templates select="//FAM"/>
            
    </fo:root>
</xsl:template>
	
<xsl:template match="FAM">
	
	<fo:page-sequence 
		country="us" 
		initial-page-number="1" 
		language="en" 
		master-reference="Family"
		force-page-count="no-force">

	<xsl:variable name="numberOfChildren" select="count( CHIL )"/>

		<!-- Header -->
		<fo:static-content flow-name="xsl-region-before">
			<fo:block 
				font-family="sans-serif" 
				font-size="14pt"
				text-align="center">
				<xsl:text>Family Group Record</xsl:text>
			</fo:block>
			<fo:block	
				font-family="sans-serif" 
				font-size="6pt"
				text-align="right">
				<xsl:text>Page </xsl:text>
					<fo:page-number/>
						<xsl:text> of </xsl:text>
					<xsl:value-of select="( ( $numberOfChildren + 1 ) div $numberOfChildrenOnSecondPlusPages ) - ( ( ( $numberOfChildren + 1 ) div $numberOfChildrenOnSecondPlusPages ) mod 1 ) + 1"/>		

				<xsl:if test="$includeID = true()">
    				<xsl:text> (Fam. ID </xsl:text>
    				<xsl:value-of select="@ID"/>
    				<xsl:text>)</xsl:text>
    			</xsl:if>
			</fo:block>
		</fo:static-content>
		
        <!-- Footer -->
		<fo:static-content flow-name="xsl-region-after">
			<fo:block 
				font-family="sans-serif" 
				font-size="8pt"
				text-align="left">
                <xsl:if test="$whenGenerated = true()">

				<xsl:text>Generated: </xsl:text>
                <!-- Disabling insert date because missing extension -->
				<!-- <xsl:value-of select="xsl:substring( date:date-time(), 0, 10)"/> -->
                </xsl:if>
			</fo:block>
           
		</fo:static-content>

        <fo:flow flow-name="xsl-region-body">
            <xsl:call-template name="makeFamily"/>

        </fo:flow>
    </fo:page-sequence>
</xsl:template>


<xsl:template name="makeFamily">

            <!-- Husband and Wife -->
                <xsl:call-template name="makeSpouseNameAndEventsTables">
                    <xsl:with-param name="IndiID" select="HUSB/@REF"/>
                    <xsl:with-param name="role" select="'Husband'"/>
                </xsl:call-template>
                <!-- 7 rows created -->
                <xsl:call-template name="makeSpouseNameAndEventsTables">
                    <xsl:with-param name="IndiID" select="WIFE/@REF"/>
                    <xsl:with-param name="role" select="'Wife'"/>
                </xsl:call-template>
                <!-- 6 rows created, total = 13 -->
                <!-- insert separator row between father -->
                <xsl:call-template name="makeChildListLabel"/>
                <!-- one row created, total = 14 -->

                <xsl:call-template name="makeChildren">
                    <xsl:with-param name="numberOfChildren" select="count( CHIL )"/>
                    <xsl:with-param name="lineNumber" select="14"/>
                </xsl:call-template>

</xsl:template>

<xsl:template name="makeChildren">
    <xsl:param name="numberOfChildren"/>
    <xsl:param name="childNumber" select="1"/>
    <xsl:param name="lineNumber"/>

   <!-- if the number of childern created is less that the total number of children, create new children  -->    
   <xsl:if test="$childNumber &lt;= $numberOfChildren">
   
        <!-- get child's IndiID -->
        <xsl:variable name="IndiID" select="CHIL[$childNumber]/@REF"/>
   
        <!-- set the numberOfMarriages by either counting them, or if there are now marriages, set it to at least 1 -->
        <xsl:variable name="numberOfMarriages">
             <xsl:variable name="howManyMarriages" select="count(//INDI[@ID = $IndiID]/FAMS)"/>
             <xsl:choose>
                 <xsl:when test="$howManyMarriages = 0">1</xsl:when>
                 <xsl:otherwise>
                    <xsl:value-of select="$howManyMarriages"/>
                 </xsl:otherwise>
             </xsl:choose>
        </xsl:variable>

        <!--add 4 rows for name, birth, death, burial rows, plus 2 rows per child marriage -->
        <xsl:variable name="numberOfChildRows" select="$lineNumber + 4 + ($numberOfMarriages * 2)"/>
        
        <!-- Break to new page, and add Page Two Headers, if the number of rows generated so far exceeds the max per page -->
        <xsl:if test="$numberOfChildRows &gt; $maxNumberOfPageRows">
                <xsl:call-template name="addPageTwoPlusHeaders"/>
        </xsl:if>

        <!-- make the child, or move on to make the next child (if it is a recursive call to makeChildren) -->
        <xsl:call-template name="makeChildNameAndEventsTables">
            <xsl:with-param name="IndiID" select="$IndiID"/>
            <xsl:with-param name="childNumber" select="$childNumber"/>
            <xsl:with-param name="numberOfMarriages" select="$numberOfMarriages"/>
        </xsl:call-template>
        
        <!-- If the addPageTwoHeaders was called,  this resets the lineNumber to 2, to account for
              the 2 rows in the PageTwoPlusHeader, otherwise it defaults to the current row count-->
        <xsl:variable name="ifNewLineNumber">
            <xsl:choose>
                <xsl:when test="$numberOfChildRows &gt; $maxNumberOfPageRows">2</xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$numberOfChildRows"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- call makeChildren again, and make the next child -->
        <xsl:call-template name="makeChildren">
            <xsl:with-param name="childNumber" select="$childNumber + 1"/>
            <xsl:with-param name="numberOfChildren" select="$numberOfChildren"/>
            <xsl:with-param name="lineNumber" select="$ifNewLineNumber"/>
        </xsl:call-template>
    </xsl:if>
    
    <!-- At this point, all the children have been created by recursively called makeChildren, when now
    proceeded to test if blankChildren should be created to fill up the page -->

    <xsl:if test="$childNumber &gt; $numberOfChildren">
           <!-- If the numberOfChildren was less that 4, then there is only one page of the Family Record,
             then the rest of the page must be filled up with blank children, and then the number
             of blank children to create is obtained by subtracting the numberOfChildren from 4 -->
           <xsl:if test="$numberOfChildren &lt; $numberOfChildrenOnFirstPage">
                <xsl:call-template name="addBlankChildren">
                    <xsl:with-param name="numberOfChildrenToAdd" select="$numberOfChildrenOnFirstPage - $numberOfChildren"/>
                    <xsl:with-param name="childNumber" select="$childNumber"/>
                </xsl:call-template>
            </xsl:if>
            <!-- If the numberOfChildren is greater than 4, then there are more than one page for
              the Family Record, then there are 6 children per 2nd page+, and the number of children
              is obtained through the mod -->
            <xsl:if test="$numberOfChildren &gt; $numberOfChildrenOnFirstPage">
                <xsl:call-template name="addBlankChildren">
                     <xsl:with-param name="numberOfChildrenToAdd" select="$numberOfChildrenOnSecondPlusPages - (($numberOfChildren + 2) mod $numberOfChildrenOnSecondPlusPages)"/>
                     <xsl:with-param name="childNumber" select="$childNumber"/>
                </xsl:call-template>
            </xsl:if>
    </xsl:if>

</xsl:template>

<xsl:template name="makeChildNameAndEventsTables">
	<xsl:param name="IndiID"/>
    <xsl:param name="childNumber"/>
    <xsl:param name="numberOfMarriages">1</xsl:param>
    
     <!-- Table with Child's Name -->
	<fo:table>
		<fo:table-column column-width="6mm"/>
		<fo:table-column column-width="14mm"/>
		<fo:table-column column-width="160mm"/>
		<fo:table-body>
			<fo:table-row>
    			<xsl:call-template name="makeChildNameRowCells">
    				<xsl:with-param name="IndiID" select="$IndiID"/>
    			</xsl:call-template>
			</fo:table-row>
		</fo:table-body>
	</fo:table>
    <!-- 1 row created -->
    
	<!-- Table with all Events -->
	<fo:table>
        <xsl:call-template name="eventColumns"/>
		<fo:table-body>
			<!-- Born row -->
			<xsl:call-template name="makeEventTable">
				<xsl:with-param name="IndiID" select="$IndiID"/>
				<xsl:with-param name="eventName" select="'Born'"/>
			</xsl:call-template>
            <!-- 1 row created, total child row 2 -->
			<!-- Died row -->
			<xsl:call-template name="makeEventTable">
				<xsl:with-param name="IndiID" select="$IndiID"/>
				<xsl:with-param name="eventName" select="'Died'"/>
			</xsl:call-template>
            <!-- 1 row created, total child row 3 -->
			<!-- Buried row -->			
			<xsl:call-template name="makeEventTable">
				<xsl:with-param name="IndiID" select="$IndiID"/>
				<xsl:with-param name="eventName" select="'Buried'"/>
				<xsl:with-param name="childNumber" select="$childNumber"/>
			</xsl:call-template>
            <!-- 1 row created, total child row 4 -->
		</fo:table-body>
	</fo:table>
 
    <xsl:call-template name="makeChildMarriages">
        <xsl:with-param name="IndiID" select="$IndiID"/>
        <xsl:with-param name="numberOfMarriages" select="$numberOfMarriages"/>
    </xsl:call-template>
    
</xsl:template>

<xsl:template name="makeChildMarriages">
    <xsl:param name="IndiID"/>
	<xsl:param name="marriageNumber" select="1"/>
	<xsl:param name="numberOfMarriages" select="1"/>
    
    <xsl:if test="$marriageNumber &lt;= $numberOfMarriages">
        <xsl:call-template name="makeChildMarriageTables">
             <xsl:with-param name="FamID" select="//INDI[@ID = $IndiID]/FAMS[$marriageNumber]/@REF"/>
             <xsl:with-param name="IndiID" select="$IndiID"/>
        </xsl:call-template>
        <!-- 2 more rows produced -->
                
        <xsl:call-template name="makeChildMarriages">
            <xsl:with-param name="IndiID" select="$IndiID"/>
            <xsl:with-param name="marriageNumber" select="$marriageNumber + 1"/>
            <xsl:with-param name="numberOfMarriages" select="$numberOfMarriages"/>
        </xsl:call-template>
    </xsl:if>

</xsl:template>

<xsl:template name="makeSpouseNameAndEventsTables">
	<xsl:param name="IndiID"/>
	<xsl:param name="role"/>
	
	<!-- Table with Spouse Names -->
	<xsl:element 
        name="fo:table" 
        use-attribute-sets="bordersTop">

		<fo:table-column column-width="22mm"/>
		<fo:table-column column-width="72mm"/>
		<fo:table-column column-width="12mm"/>
		<fo:table-column column-width="74mm"/>
		<fo:table-body>
        	<xsl:call-template name="makeSpouseNameRow">
        		<xsl:with-param name="role" select="$role"/>
        		<xsl:with-param name="IndiID" select="$IndiID"/>
        	</xsl:call-template>
		</fo:table-body>
	</xsl:element><!-- fo:table -->

	<!-- Table with all Events -->
	<!-- TODO Probably make the 2nd Column smaller for Born/Died/Burried Events 
		 to give more date Information -->
	<fo:table>
        <xsl:call-template name="eventColumns"/>
		<fo:table-body>
		
		<!-- Born row -->
			<xsl:call-template name="makeEventTable">
				<xsl:with-param name="IndiID" select="$IndiID"/>
				<xsl:with-param name="eventName" select="'Born'"/>
			</xsl:call-template>
		<!-- Died row -->
			<xsl:call-template name="makeEventTable">
				<xsl:with-param name="IndiID" select="$IndiID"/>
				<xsl:with-param name="eventName" select="'Died'"/>
			</xsl:call-template>
		<!-- Buried row -->			
			<xsl:call-template name="makeEventTable">
				<xsl:with-param name="IndiID" select="$IndiID"/>
				<xsl:with-param name="eventName" select="'Buried'"/>
			</xsl:call-template>
			
		<!-- Married row Only include for husband -->
		<xsl:if test="$role = 'Husband'">
			<xsl:call-template name="makeMarriedEventRow">
				<xsl:with-param name="FamID" select="@REF"/>
			</xsl:call-template>			
		</xsl:if>
		
		</fo:table-body>
	</fo:table>
	
	<!-- Table with Spouse's parents -->
	<fo:table>
		<fo:table-column column-width="6mm"/>
		<fo:table-column column-width="22mm"/>				
		<fo:table-column column-width="66mm"/>
		<fo:table-column column-width="10mm"/>
		<fo:table-column column-width="76mm"/>
		<fo:table-body>
		
			<!-- Spouse's Family -->
			<xsl:variable name="FamID" select="//INDI[@ID = $IndiID]/FAMC/@REF"/>
		
			<!-- TODO?  Confirm Biological status -->
			<!-- Assumes traditional family (male/female) 
			     but in this case, it is biological -->
			<!-- Spouse's Father -->
			<xsl:call-template name="makeParentNameRow">
				<xsl:with-param name="IndiID" select="//FAM[@ID = $FamID]/HUSB/@REF"/>
				<xsl:with-param name="role" select="$role"/>
				<xsl:with-param name="gender" select="'Male'"/>
			</xsl:call-template>
			
			<!-- Spouse's Mother -->
			<xsl:call-template name="makeParentNameRow">
				<xsl:with-param name="IndiID" select="//FAM[@ID = $FamID]/WIFE/@REF"/>
				<xsl:with-param name="role" select="$role"/>
				<xsl:with-param name="gender" select="'Female'"/>
			</xsl:call-template>
					
		</fo:table-body>
	</fo:table>
</xsl:template>

<xsl:template name="makeSpouseNameRow">
	<xsl:param name="role"/>	
	<xsl:param name="IndiID"/>

	<fo:table-row 
		height="4.75mm">
            
        <xsl:element 
            name="fo:table-cell" 
            use-attribute-sets="bordersBottom bordersLeft">
            <xsl:attribute name="padding-top">.5mm</xsl:attribute>
            <xsl:attribute name="padding-left">.75mm"</xsl:attribute>
			<fo:block 
				font-family="sans-serif"
				font-size="6pt">
				<xsl:value-of select="$role"/>
			</fo:block>
			<fo:block 
				font-family="sans-serif"
				font-size="5pt">
				<xsl:text>Given name(s)</xsl:text>
			</fo:block>        
       </xsl:element> <!-- fo:table-cell -->
	
		<!-- Insert Given Name Cell -->
		<xsl:call-template name="makeGivenNameCell">
			<xsl:with-param name="IndiID" select="$IndiID"/>
		</xsl:call-template>
		
		<xsl:element 
            name="fo:table-cell" 
            use-attribute-sets="bordersBottom"> 
            <xsl:attribute name="padding-right">1mm</xsl:attribute>
			<xsl:attribute name="padding-left">.75mm</xsl:attribute>
            <xsl:attribute name="padding-top">.5mm"</xsl:attribute>

			<fo:block 
				font-family="sans-serif"
				font-size="6pt">
				<xsl:if test="$role = 'Husband'">
					<xsl:text>Last</xsl:text>
				</xsl:if>
				<xsl:if test="$role = 'Wife'">
					<xsl:text>Maiden</xsl:text>
				</xsl:if>
			</fo:block>
			<fo:block 
				font-family="sans-serif"
				font-size="5pt">
				<xsl:text>name</xsl:text>
			</fo:block>
       </xsl:element><!-- fo:table-cell -->
		
		<!-- Insert Surname table-cell -->
		<xsl:call-template name="makeSurnameCell">
			<xsl:with-param name="IndiID" select="$IndiID"/>
		</xsl:call-template>
		
	</fo:table-row>
</xsl:template>

<!-- Creates table-cell with Given Name -->

<xsl:template name="makeGivenNameCell">
	<xsl:param name="IndiID"/>
    
    <xsl:element 
        name="fo:table-cell" 
        use-attribute-sets="bordersRight bordersBottom"> 
        <xsl:attribute name="padding-top">1mm</xsl:attribute>

		<fo:block 
			font-family="serif" 
			font-size="11pt">				
			<xsl:choose>
				<xsl:when test="//INDI[@ID = $IndiID]/NAME/GIVN">
					<xsl:value-of select="//INDI[@ID = $IndiID]/NAME/GIVN"/>
				</xsl:when>
				<xsl:otherwise>
			       <!-- Retrieve First Name -->
					<xsl:if test="string-length(substring-before( normalize-space( //INDI[@ID = $IndiID]/NAME) , '/')) &gt; 0">                        
						<xsl:value-of select="substring-before( normalize-space( //INDI[@ID = $IndiID]/NAME) , '/')"/>        
					</xsl:if>
					
        		<!-- only include id in parentheses when it exists -->
        		<xsl:if test="$includeID = true()">
            		<xsl:if test="$IndiID">
                		<fo:inline font-family="serif" 
                			font-size="8pt">
                			<xsl:text>   (</xsl:text>
                			<xsl:value-of select="$IndiID"/>
                			<xsl:text>)</xsl:text>
                		</fo:inline>
                	</xsl:if>
            	</xsl:if>

				</xsl:otherwise>
			</xsl:choose>

		</fo:block>
	</xsl:element><!-- fo:table-cell -->					
</xsl:template>

<!-- Creates table-cell with Last Name -->

<xsl:template name="makeSurnameCell">
	<xsl:param name="IndiID"/>

    <xsl:element 
        name="fo:table-cell" 
        use-attribute-sets="bordersRight bordersBottom"> 
        <xsl:attribute name="padding-top">1mm</xsl:attribute>

		<fo:block 
			font-family="serif"
			font-size="11pt">
			<!-- Surname -->
			<xsl:choose>
				<xsl:when test="//INDI[@ID = $IndiID]/NAME/SURN">
					<xsl:value-of select="//INDI[@ID = $IndiID]/NAME/SURN"/>
				</xsl:when>
				<xsl:otherwise>
					  <xsl:if test="string-length(substring-before(substring-after( normalize-space( //INDI[@ID = $IndiID]/NAME),'/'), '/')) &gt; 0">            
						<xsl:value-of select="substring-before(substring-after( normalize-space( //INDI[@ID = $IndiID]/NAME),'/'), '/')"/>            
					  </xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</fo:block>
	</xsl:element><!-- fo:table-cell -->
</xsl:template>
				
<xsl:template name="makeEventTable">
	<xsl:param name="IndiID"/>
	<xsl:param name="eventName"/>
	<xsl:param name="childNumber"/>
	
	<!-- Event Rows have Bottom Borders -->
	<fo:table-row 
		height="4.75mm"
		keep-with-previous.within-line="always">
		<xsl:element 
            name="fo:table-cell" 
            use-attribute-sets="bordersLeft"> 
            <xsl:attribute name="padding-top">.75mm</xsl:attribute>
			<xsl:attribute name="padding-left">.75mm</xsl:attribute>
			
			<fo:block 
				font-family="sans-serif" 
				font-size="10pt"
				text-indent="2pt">
				<!-- Insert Child's number if this is a burial event -->
				<xsl:if test="$eventName = 'Buried'">
					<xsl:value-of select="$childNumber"/>
				</xsl:if>
			</fo:block>
            </xsl:element><!-- fo:table-cell -->
		<xsl:element 
            name="fo:table-cell" 
            use-attribute-sets="bordersBottom bordersLeft"> 
            <xsl:attribute name="padding-top">.75mm</xsl:attribute>
			<xsl:attribute name="padding-left">.75mm</xsl:attribute>
			<fo:block 
				font-family="sans-serif" 
				font-size="6pt">
				<!-- Insert "Born", "Died", or "Buried" -->
				<xsl:value-of select="$eventName"/>
			</fo:block>
        </xsl:element> <!-- fo:table-cell -->
            
        <xsl:element 
            name="fo:table-cell" 
            use-attribute-sets="bordersRight bordersBottom"> 
            <xsl:attribute name="padding-top">1.5mm</xsl:attribute>
           
            <!-- DATE -->
    			<xsl:choose>
    				<xsl:when test="$eventName = 'Born'">
                        <xsl:choose>
                            <xsl:when test="//INDI[@ID = $IndiID]/BIRT/DATE">
                                <xsl:apply-templates select="//INDI[@ID = $IndiID]/BIRT/DATE"/>				
                            </xsl:when>
                            <xsl:otherwise>
                                <fo:block 
                                    font-family="serif" 
                                    font-size="11pt">
                                       <xsl:text/>
                                </fo:block>
                             </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
    				<xsl:when test="$eventName = 'Died'">
    				     <xsl:choose>
                            <xsl:when test="//INDI[@ID = $IndiID]/DEAT/DATE">
                                <xsl:apply-templates select="//INDI[@ID = $IndiID]/DEAT/DATE"/>				
                            </xsl:when>
                            <xsl:otherwise>
                                <fo:block 
                                    font-family="serif" 
                                    font-size="11pt">
                                       <xsl:text/>
                                </fo:block>
                             </xsl:otherwise>
                        </xsl:choose>    				
                    </xsl:when>
    				<xsl:when test="$eventName = 'Buried'">
    				    <xsl:choose>
                            <xsl:when test="//INDI[@ID = $IndiID]/BURI/DATE">
                                <xsl:apply-templates select="//INDI[@ID = $IndiID]/BURI/DATE"/>				
                            </xsl:when>
                            <xsl:otherwise>
                                <fo:block 
                                    font-family="serif" 
                                    font-size="11pt">
                                       <xsl:text/>
                                </fo:block>
                             </xsl:otherwise>
                        </xsl:choose>
                   </xsl:when>
    			</xsl:choose>
       	</xsl:element><!-- fo:table-cell -->
		<xsl:element 
            name="fo:table-cell" 
            use-attribute-sets="bordersBottom"> 
            <xsl:attribute name="padding-top">.75mm</xsl:attribute>
			<xsl:attribute name="padding-left">.75mm</xsl:attribute>
    		<fo:block 
    			font-family="sans-serif" 
    			font-size="6pt">
    			<xsl:text>Place</xsl:text>
    		</fo:block>
        </xsl:element><!-- fo:table-cell -->

		<xsl:element 
            name="fo:table-cell" 
            use-attribute-sets="bordersRight bordersBottom"> 
            <xsl:attribute name="padding-top">1.5mm</xsl:attribute>
            
			<!--Place of Event -->						
    			<xsl:choose>
    				<xsl:when test="$eventName = 'Born'">
                        <xsl:choose>
                            <xsl:when test="//INDI[@ID = $IndiID]/BIRT/PLAC">
                                <xsl:apply-templates select="//INDI[@ID = $IndiID]/BIRT/PLAC"/>				
                            </xsl:when>
                            <xsl:otherwise>
                                <fo:block 
                                    font-family="serif" 
                                    font-size="11pt">
                                       <xsl:text/>
                                </fo:block>
                             </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
    				<xsl:when test="$eventName = 'Died'">
                        <xsl:choose>
                            <xsl:when test="//INDI[@ID = $IndiID]/DEAT/PLAC">
                                <xsl:apply-templates select="//INDI[@ID = $IndiID]/DEAT/PLAC"/>				
                            </xsl:when>
                            <xsl:otherwise>
                                <fo:block 
                                    font-family="serif" 
                                    font-size="11pt">
                                       <xsl:text/>
                                </fo:block>
                             </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="$eventName = 'Buried'">
                        <xsl:choose>
                            <xsl:when test="//INDI[@ID = $IndiID]/BURI/PLAC">
                                <xsl:apply-templates select="//INDI[@ID = $IndiID]/BURI/PLAC"/>				
                            </xsl:when>
                            <xsl:otherwise>
                                <fo:block 
                                    font-family="serif" 
                                    font-size="11pt">
                                       <xsl:text/>
                                </fo:block>
                             </xsl:otherwise>
                        </xsl:choose>
                        </xsl:when>
    			</xsl:choose>
         </xsl:element><!-- fo:table-cell -->
   </fo:table-row>
</xsl:template>

<xsl:template name="makeMarriedEventRow">
	
	<!-- Added this param so that it will work with the Child's spouse.  Probably
		not the most optimal implementation for speed -->
	<xsl:param name="FamID"/>
	
	<!-- (Lamely) added this variable to avoid redundant code when it comes to
	    creating the married row for a child.  If the role is 'Child', then
	    it causes this template to added a bottom line to the normally blank
	    outside cell/column -->
	<xsl:param name="role"/>

	<fo:table-row 
		height="4.75mm"
		keep-with-previous.within-line="always">
		<xsl:choose>
			<xsl:when test="$role = 'Child'">

                <xsl:element 
                    name="fo:table-cell" 
                    use-attribute-sets="bordersBottom bordersLeft"> 
                    <xsl:attribute name="padding-top">.75mm</xsl:attribute>
                    <xsl:attribute name="padding-left">.75mm</xsl:attribute>

        			<fo:block 
        				font-family="sans-serif" 
        				font-size="10pt">
                        <!-- enable to insert FamID of Child 
        				<xsl:value-of select="$FamID"/> -->
                        <xsl:text/>
        			</fo:block>
                </xsl:element><!-- fo:table-cell -->
			
			</xsl:when>
			<xsl:otherwise>
                <xsl:element 
                    name="fo:table-cell" 
                    use-attribute-sets="bordersLeft"> 
                    <xsl:attribute name="padding-top">.75mm</xsl:attribute>
                    <xsl:attribute name="padding-left">.75mm</xsl:attribute>
                    
        			<fo:block 
        				font-family="sans-serif" 
        				font-size="10pt">
        			</fo:block>
        		</xsl:element><!-- fo:table-cell -->
			
			</xsl:otherwise>
		</xsl:choose>
        
            <xsl:element 
                name="fo:table-cell" 
                use-attribute-sets="bordersBottom bordersLeft"> 
                <xsl:attribute name="padding-top">.75mm</xsl:attribute>
                <xsl:attribute name="padding-left">.75mm</xsl:attribute>

                <fo:block 
                    font-family="sans-serif" 
                    font-size="6pt">
                    <xsl:text>Married</xsl:text>
                </fo:block>
             </xsl:element><!-- fo:table-cell -->
             <xsl:element 
                name="fo:table-cell" 
                use-attribute-sets="bordersBottom"> 
                <xsl:attribute name="padding-top">1.5mm</xsl:attribute>
            
                <!-- DATE -->
                <xsl:choose>
                    <xsl:when test="//FAM[@ID=$FamID]/MARR/DATE">
                        <xsl:apply-templates select="//FAM[@ID=$FamID]/MARR/DATE"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <fo:block 
                            font-family="serif" 
                            font-size="11pt">
                               <xsl:text/>
                        </fo:block>
                    </xsl:otherwise>
                </xsl:choose>
                
           </xsl:element><!-- fo:table-cell -->
            <xsl:element 
                name="fo:table-cell" 
                use-attribute-sets="bordersBottom bordersLeft"> 
                <xsl:attribute name="padding-top">.75mm</xsl:attribute>
                <xsl:attribute name="padding-left">.75mm</xsl:attribute>

                <fo:block 
                    font-family="sans-serif" 
                    font-size="6pt">
                    <xsl:text>Place</xsl:text>
                </fo:block>

            </xsl:element><!-- fo:table-cell -->
       		<xsl:element 
               name="fo:table-cell" 
               use-attribute-sets="bordersRight bordersBottom"> 
               <xsl:attribute name="padding-top">1.5mm</xsl:attribute>
    
                <!--Place of Event -->								
                <xsl:choose>
                    <xsl:when test="//FAM[@ID=$FamID]/MARR/PLAC">
                        <xsl:apply-templates select="//FAM[@ID=$FamID]/MARR/PLAC"/>
                    </xsl:when>
                    <xsl:otherwise>
                       <fo:block 
                            font-family="serif" 
                            font-size="11pt">
                           <xsl:text/>
                    </fo:block>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:element><!-- table-cell -->

	</fo:table-row>
</xsl:template>


<xsl:template name="makeParentNameRow">
	<xsl:param name="IndiID"/>
	<xsl:param name="role"/>
	<xsl:param name="gender"/>
	
	<fo:table-row 
		height="4.75mm">
        <xsl:element 
            name="fo:table-cell" 
            use-attribute-sets="bordersLeft"> 
            <xsl:attribute name="padding-top">.75mm</xsl:attribute>
			<xsl:attribute name="padding-left">.75mm</xsl:attribute>

			<fo:block 
				font-family="sans-serif" 
				font-size="10pt">
			</fo:block>
		</xsl:element><!-- fo:table-cell -->
   		<xsl:element 
            name="fo:table-cell" 
            use-attribute-sets="bordersBottom bordersLeft"> 
            <xsl:attribute name="padding-top">.5mm</xsl:attribute>
			<xsl:attribute name="padding-left">1mm</xsl:attribute>
            
			<!-- In contrast to Husband and Wife, the Father/Mother label is set at 6pt -->
			<fo:block
				font-family="sans-serif"
				font-size="6pt">
				<xsl:value-of select="$role"/>	
				
				<!-- Determine if label is "mother" or "father", default to "father" -->
				<xsl:choose>
					<xsl:when test="$gender = 'Female'">
						<xsl:text>&#8217;s mother</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>&#8217;s father</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</fo:block>
			<fo:block 
				font-family="sans-serif"
				font-size="5pt">
				<xsl:text>Given name(s)</xsl:text>
			</fo:block>
		</xsl:element><!-- fo:table-cell -->
		
		<!-- Insert Given Name table-cell -->
		<xsl:call-template name="makeGivenNameCell">
			<xsl:with-param name="IndiID" select="$IndiID"/>
		</xsl:call-template>
		
        <xsl:element 
            name="fo:table-cell" 
            use-attribute-sets="bordersBottom"> 
            <xsl:attribute name="padding-top">.5mm</xsl:attribute>
			<xsl:attribute name="padding-left">1mm</xsl:attribute>

			<!-- In contrast to Husband and Wife, the Father/Mother label is set at 6pt -->
			<fo:block 
				font-family="sans-serif"
				font-size="5pt">
				<!-- Determine if label "Last" or "Maiden", default to "Last" -->
				<xsl:choose>
					<xsl:when test="$gender = 'Female'">
						<xsl:text>Maiden</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>Last</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</fo:block>
			<fo:block 
				font-family="sans-serif"
				font-size="5pt">
				<xsl:text>name</xsl:text>
			</fo:block>
		</xsl:element><!-- table-cell -->
		
		<!-- Insert Surname Cell-->
		<xsl:call-template name="makeSurnameCell">
			<xsl:with-param name="IndiID" select="$IndiID"/>
		</xsl:call-template>
		
	</fo:table-row>

</xsl:template>

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

<xsl:template name="addPageTwoPlusHeaders">

    <xsl:element 
        name="fo:table" 
        use-attribute-sets="bordersTop"> 
        <xsl:attribute name="break-before">page</xsl:attribute>
        
        <fo:table-column column-width="22mm"/>
        <fo:table-column column-width="72mm"/>
        <fo:table-column column-width="12mm"/>
        <fo:table-column column-width="74mm"/>
        <fo:table-body>

            <xsl:call-template name="makeSpouseNameRow">
                <xsl:with-param name="role" select="'Husband'"/>
                <xsl:with-param name="IndiID" select="HUSB/@REF"/>
            </xsl:call-template>
            
        </fo:table-body>
    </xsl:element><!-- fo:table -->
    
    <!-- Insert Spouse name (Child's Mother) -->
    <!-- Table with Spouse Names -->
    <xsl:element 
        name="fo:table" 
        use-attribute-sets="bordersTop"> 
        
        <fo:table-column column-width="22mm"/>
        <fo:table-column column-width="72mm"/>
        <fo:table-column column-width="12mm"/>
        <fo:table-column column-width="74mm"/>
        <fo:table-body>

            <xsl:call-template name="makeSpouseNameRow">
                <xsl:with-param name="role" select="'Wife'"/>
                <xsl:with-param name="IndiID" select="WIFE/@REF"/>
            </xsl:call-template>
            
        </fo:table-body>
    </xsl:element><!-- fo:table -->
</xsl:template>

<xsl:template name="makeChildListLabel">

    <xsl:element 
        name="fo:table" 
        use-attribute-sets="bordersTop"> 

		<fo:table-column 
            column-width="180mm"/>
		<fo:table-body>
			<fo:table-row 
				height="4.75mm">
                <xsl:element 
                    name="fo:table-cell" 
                    use-attribute-sets="bordersTop bordersRight bordersBottom bordersLeft"> 
					<xsl:attribute name="padding-top">1.5mm</xsl:attribute>
					<xsl:attribute name="padding-left">2mm</xsl:attribute>
                    
					<fo:block		
						font-family="sans-serif" 
						font-size="9pt">
						<xsl:text>Children - List each child in order of birth</xsl:text>
					</fo:block>
				</xsl:element><!-- fo:table-cell -->
			</fo:table-row>
		</fo:table-body>
	</xsl:element><!-- fo:table -->
</xsl:template>

<xsl:template name="makeChildNameRowCells">
	<xsl:param name="IndiID"/>
		
		<!-- Gender -->
        <xsl:element 
            name="fo:table-cell" 
            use-attribute-sets="bordersTop bordersRight bordersBottom bordersLeft"> 
            <xsl:attribute name="padding-top">.3mm</xsl:attribute>
            <xsl:attribute name="padding-left">1mm</xsl:attribute>
 			<fo:block 
				font-family="sans-serif" 
				font-size="6pt"
				text-indent="1pt">
				<xsl:text>Sex</xsl:text>
			</fo:block>
			<fo:block 
				font-family="sans-serif"
				font-size="9pt"
				text-indent="2pt">
					<xsl:value-of select="//INDI[@ID = $IndiID]/SEX"/>	
			</fo:block>
		</xsl:element><!-- fo:table-cell -->
		<!-- Given Name -->
        <xsl:element 
            name="fo:table-cell" 
            use-attribute-sets="bordersBottom"> 
            <xsl:attribute name="padding-top">.75mm</xsl:attribute>
            <xsl:attribute name="padding-left">.75mm</xsl:attribute>
			<fo:block 
				font-family="sans-serif"
				font-size="6pt"
				padding-left="1mm">
				<xsl:text>Given name(s)</xsl:text>
			</fo:block>
		</xsl:element><!-- fo:table-cell -->
	
		<!-- Insert Given Name Cell -->
		<xsl:call-template name="makeGivenNameCell">
			<xsl:with-param name="IndiID" select="$IndiID"/>
		</xsl:call-template>
		
		<!-- No Surname -->
				
</xsl:template>

<xsl:template name="makeChildMarriageTables">
	<xsl:param name="FamID"/>
	<xsl:param name="IndiID"/>

    <!-- Create spouse row -->
    	<fo:table>
    		<fo:table-column column-width="6mm"/>
    		<fo:table-column column-width="18mm"/>				
    		<fo:table-column column-width="70mm"/>
    		<fo:table-column column-width="10mm"/>
    		<fo:table-column column-width="76mm"/>
    		<fo:table-body>
    
            	<fo:table-row 
            		height="4.75mm"
            		keep-with-previous.within-line="always">
                    
                    <xsl:element 
                        name="fo:table-cell" 
                        use-attribute-sets="bordersLeft"> 
                        <xsl:attribute name="padding-top">.75mm</xsl:attribute>
                        <xsl:attribute name="padding-left">.75mm</xsl:attribute>
            			<fo:block 
            				font-family="sans-serif" 
            				font-size="10pt">
            			</fo:block>
            		</xsl:element><!-- fo:table-cell -->
                    <xsl:element 
                        name="fo:table-cell" 
                        use-attribute-sets="bordersBottom bordersLeft"> 
                        <xsl:attribute name="padding-top">.75mm</xsl:attribute>
                        <xsl:attribute name="padding-left">.75mm</xsl:attribute>

            			<!-- set at 6pt -->
            			<fo:block
            				font-family="sans-serif"
            				font-size="5pt">				
            				<xsl:text>Spouse&#8217;s </xsl:text>
            			</fo:block>
            			<fo:block 
            				font-family="sans-serif"
            				font-size="5pt">
            				<xsl:text>Given name(s)</xsl:text>
            			</fo:block>
            		</xsl:element><!-- fo:table-cell -->
            		
            		<!-- Insert Given Name table-cell -->
            		<!-- This should be able to handle FAM that have 2 Husbands or 2 Wives (Fuck tradition) -->
            		<xsl:choose>
            			<!-- If the family has a HUSB with an REF different from their Spouse's ID -->
            			<xsl:when test="//FAM[@ID = $FamID]/HUSB[@REF != $IndiID]">
       						<xsl:call-template name="makeGivenNameCell">
            					<xsl:with-param name="IndiID" select="//FAM[@ID = $FamID]/HUSB[@REF != $IndiID]/@REF"/>
            				</xsl:call-template>
            			</xsl:when>
            			<!-- If the family has a WIFE with an REF different from their Spouse's ID -->
            			<xsl:when test="//FAM[@ID = $FamID]/WIFE[@REF != $IndiID]">
       						<xsl:call-template name="makeGivenNameCell">
            					<xsl:with-param name="IndiID" select="//FAM[@ID = $FamID]/WIFE[@REF != $IndiID]/@REF"/>
         					</xsl:call-template>
            			</xsl:when>
            			<!-- otherwise insert blank given name cell -->
            			<xsl:otherwise>
            				<xsl:call-template name="makeGivenNameCell"/>
            			</xsl:otherwise>
            		</xsl:choose>
                    <xsl:element 
                        name="fo:table-cell" 
                        use-attribute-sets="bordersBottom bordersLeft"> 
                        <xsl:attribute name="padding-top">.75mm</xsl:attribute>
                        <xsl:attribute name="padding-left">.75mm</xsl:attribute>

            			<!-- set at 5pt -->
            			<fo:block 
            				font-family="sans-serif"
            				font-size="5pt">
            				<xsl:text>Last</xsl:text>
            			</fo:block>
            			<fo:block 
            				font-family="sans-serif"
            				font-size="5pt">
            				<xsl:text>name</xsl:text>
            			</fo:block>
            		</xsl:element><!-- fo:table-cell -->
            		
            		<!-- Insert Surname Cell-->
            		<!-- This should be able to handle FAM that have 2 Husbands or 2 Wives (Fuck tradition) -->
            		<xsl:choose>
            			<!-- If the family has a HUSB with an REF different from their Spouse's ID -->
            			<xsl:when test="//FAM[@ID = $FamID]/HUSB[@REF != $IndiID]">
       						<xsl:call-template name="makeSurnameCell">
            					<xsl:with-param name="IndiID" select="//FAM[@ID = $FamID]/HUSB[@REF != $IndiID]/@REF"/>
            				</xsl:call-template>
            			</xsl:when>
            			<!-- If the family has a WIFE with an REF different from their Spouse's ID -->
            			<xsl:when test="//FAM[@ID = $FamID]/WIFE[@REF != $IndiID]">
       						<xsl:call-template name="makeSurnameCell">
            					<xsl:with-param name="IndiID" select="//FAM[@ID = $FamID]/WIFE[@REF != $IndiID]/@REF"/>
         					</xsl:call-template>  
            			</xsl:when>
            			<!-- otherwise insert blank given name cell -->
            			<xsl:otherwise>
            				<xsl:call-template name="makeSurnameCell"/>
            			</xsl:otherwise>
            		</xsl:choose>            		
    		
    			</fo:table-row>
    		</fo:table-body>
    	</fo:table>	
	
		<!-- Table with Married Event -->
		<fo:table>
    		<fo:table-column column-width="6mm"/>
    		<fo:table-column column-width="9mm"/>
    		<fo:table-column column-width="27mm"/>
    		<fo:table-column column-width="8mm"/>
    		<fo:table-column column-width="130mm"/>
    			<fo:table-body>

                	<xsl:call-template name="makeMarriedEventRow">
                		<xsl:with-param name="FamID" select="$FamID"/>
                		<xsl:with-param name="role" select="'Child'"/>	
                	</xsl:call-template>				
    
    			</fo:table-body>
		</fo:table>	        
</xsl:template>

<xsl:template match="DATE">

	<!-- DATE_VALUE's range is 1<35 -->
	<xsl:choose>
		<!-- When it is greater than 70, but less that 80, change font to 10pt -->
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
		<!-- default to 11pt -->
		<xsl:otherwise>
			<fo:block 
				font-family="serif" 
				font-size="11pt">
				<xsl:value-of select="normalize-space( . )"/>
			</fo:block>
		</xsl:otherwise>				
	</xsl:choose>

</xsl:template>

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
    				font-size="11pt">
    				<xsl:value-of select="substring( normalize-space( text() ), 1, 69 )"/>
    				<xsl:text>...</xsl:text>
    			</fo:block>
    	</xsl:when>
    	<xsl:otherwise>
    			<fo:block 
    				font-family="serif" 
    				font-size="11pt">
    				<xsl:value-of select="normalize-space( text() )"/>
    			</fo:block>
    	</xsl:otherwise>
    </xsl:choose>

</xsl:template>

<xsl:template name="eventColumns">
    <xsl:element name="fo:table-column">
        <xsl:attribute name="column-width">6mm</xsl:attribute>
    </xsl:element>
    <xsl:element name="fo:table-column">
        <xsl:attribute name="column-width">10mm</xsl:attribute>
    </xsl:element>
    <xsl:element name="fo:table-column">
        <xsl:attribute name="column-width">26mm</xsl:attribute>
    </xsl:element>
    <xsl:element name="fo:table-column">
        <xsl:attribute name="column-width">8mm</xsl:attribute>
    </xsl:element>
    <xsl:element name="fo:table-column">
        <xsl:attribute name="column-width">130mm</xsl:attribute>
    </xsl:element>
</xsl:template>

<!-- Attribute Sets -->
<xsl:attribute-set name="bordersRight">
    <xsl:attribute name="border-right-color">black</xsl:attribute> 
    <xsl:attribute name="border-right-style"><xsl:value-of select="$lineStyle"/></xsl:attribute>
    <xsl:attribute name="border-right-width"><xsl:value-of select="$lineWidth"/></xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="bordersBottom">
    <xsl:attribute name="border-right-color">black</xsl:attribute> 
    <xsl:attribute name="border-bottom-style"><xsl:value-of select="$lineStyle"/></xsl:attribute>
    <xsl:attribute name="border-bottom-width"><xsl:value-of select="$lineWidth"/></xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="bordersLeft">
     <xsl:attribute name="border-left-color">black</xsl:attribute> 
     <xsl:attribute name="border-left-style"><xsl:value-of select="$lineStyle"/></xsl:attribute>
     <xsl:attribute name="border-left-width"><xsl:value-of select="$lineWidth"/></xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="bordersTop">
     <xsl:attribute name="border-top-color">black</xsl:attribute> 
     <xsl:attribute name="border-top-style"><xsl:value-of select="$lineStyle"/></xsl:attribute>
     <xsl:attribute name="border-top-width"><xsl:value-of select="$lineWidth"/></xsl:attribute>
</xsl:attribute-set>

</xsl:stylesheet>   
