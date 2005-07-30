<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" 
	xmlns:fo="http://www.w3.org/1999/XSL/Format" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:date="http://exslt.org/dates-and-times"
  	extension-element-prefixes="date">
<!-- $Id$ -->

<!-- 
 ******************************************************************************
 ******************************************************************************
    Copyright (c) 2005 Chad Albers
     
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
<!-- <xsl:variable name="includeID" select="false()"/> -->
 
<xsl:template match="/">

	
		<fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format">
			<fo:layout-master-set>
				<fo:simple-page-master margin-bottom=".2cm" margin-left="2.5cm" margin-right="1cm" margin-top="1.5cm" master-name="Family" page-height="11in" page-width="8.5in">
					<fo:region-before extent="1cm"/>
					<fo:region-body margin-top="1cm" margin-bottom="1cm"/>
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
				font-size="16pt"
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
					<xsl:value-of select="( ( $numberOfChildren + 1 ) div 6 ) - ( ( ( $numberOfChildren + 1 ) div 6 ) mod 1 ) + 1"/>		

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
				<xsl:text>Generated: </xsl:text>
				<xsl:value-of select="xsl:substring( date:date-time(), 0, 10)"/>
			</fo:block>
		</fo:static-content>
	
		<fo:flow flow-name="xsl-region-body">
			<xsl:call-template name="spouse">
				<xsl:with-param name="IndiID" select="HUSB/@REF"/>
				<xsl:with-param name="role" select="'Husband'"/>
			</xsl:call-template>
			<xsl:call-template name="spouse">
				<xsl:with-param name="IndiID" select="WIFE/@REF"/>
				<xsl:with-param name="role" select="'Wife'"/>
			</xsl:call-template>			
    
    		<!-- Children -->
     		<xsl:call-template name="children">
    			<xsl:with-param name="numberOfChildren" select="$numberOfChildren"/>
				<xsl:with-param name="fatherID" select="HUSB/@REF"/>
				<xsl:with-param name="motherID" select="WIFE/@REF"/>
    		</xsl:call-template> 
 
		</fo:flow>
	</fo:page-sequence>
</xsl:template>


<xsl:template name="spouse">
	<xsl:param name="IndiID"/>
	<xsl:param name="role"/>
	
	<!-- Table with Spouse Names -->
	<fo:table table-layout="fixed"
		border-top-color="black" 
		border-top-style="solid" 
		border-top-width=".1mm">
		<fo:table-column column-width="22mm"/>
		<fo:table-column column-width="72mm"/>
		<fo:table-column column-width="12mm"/>
		<fo:table-column column-width="74mm"/>
		<fo:table-body>
        	<xsl:call-template name="spouseNameRow">
        		<xsl:with-param name="role" select="$role"/>
        		<xsl:with-param name="IndiID" select="$IndiID"/>
        	</xsl:call-template>
		</fo:table-body>
	</fo:table>

	<!-- Table with all Events -->
	<!-- TODO Probably make the 2nd Column smaller for Born/Died/Burried Events 
		 to give more date Information -->
	<fo:table table-layout="fixed">
		<fo:table-column column-width="6mm"/>
		<fo:table-column column-width="10mm"/>
		<fo:table-column column-width="26mm"/>
		<fo:table-column column-width="8mm"/>
		<fo:table-column column-width="130mm"/>
		<fo:table-body>
		
		<!-- Born row -->
			<xsl:call-template name="event">
				<xsl:with-param name="IndiID" select="$IndiID"/>
				<xsl:with-param name="eventName" select="'Born'"/>
			</xsl:call-template>
		<!-- Died row -->
			<xsl:call-template name="event">
				<xsl:with-param name="IndiID" select="$IndiID"/>
				<xsl:with-param name="eventName" select="'Died'"/>
			</xsl:call-template>
		<!-- Buried row -->			
			<xsl:call-template name="event">
				<xsl:with-param name="IndiID" select="$IndiID"/>
				<xsl:with-param name="eventName" select="'Buried'"/>
			</xsl:call-template>
			
		<!-- Married row Only include for husband -->
		<xsl:if test="$role = 'Husband'">
			<xsl:call-template name="married">
				<xsl:with-param name="FamID" select="@REF"/>
			</xsl:call-template>			
		</xsl:if>
		
		</fo:table-body>
	</fo:table>
	
	<!-- Table with Spouse's parents -->
	<fo:table table-layout="fixed">
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
			<xsl:call-template name="parentNameRow">
				<xsl:with-param name="IndiID" select="//FAM[@ID = $FamID]/HUSB/@REF"/>
				<xsl:with-param name="role" select="$role"/>
				<xsl:with-param name="gender" select="'Male'"/>
			</xsl:call-template>
			
			<!-- Spouse's Mother -->
			<xsl:call-template name="parentNameRow">
				<xsl:with-param name="IndiID" select="//FAM[@ID = $FamID]/WIFE/@REF"/>
				<xsl:with-param name="role" select="$role"/>
				<xsl:with-param name="gender" select="'Female'"/>
			</xsl:call-template>
					
		</fo:table-body>
	</fo:table>
</xsl:template>

<xsl:template name="spouseNameRow">
	<xsl:param name="role"/>	
	<xsl:param name="IndiID"/>

	<fo:table-row 
		height="6mm">
		<fo:table-cell 
			border-left-color="black" 
			border-left-style="solid" 
			border-left-width=".1mm"
			border-bottom-color="black" 
			border-bottom-style="solid" 
			border-bottom-width=".1mm">
			padding-top=".3mm"
			padding-left="1mm">
			<fo:block 
				font-family="sans-serif"
				font-size="8pt"
				text-indent="2pt">
				<xsl:value-of select="$role"/>
			</fo:block>
			<fo:block 
				font-family="sans-serif"
				font-size="7pt"
				padding-left="1mm"
				text-indent="2pt">
				<xsl:text>Given name(s)</xsl:text>
			</fo:block>
		</fo:table-cell>
	
		<!-- Insert Given Name Cell -->
		<xsl:call-template name="givenName">
			<xsl:with-param name="IndiID" select="$IndiID"/>
		</xsl:call-template>
		
		<fo:table-cell 
			border-bottom-color="black" 
			border-bottom-style="solid" 
			border-bottom-width=".1mm">
			padding-top=".3mm"
			padding-left="1mm"
			padding-right="1mm">
			<fo:block 
				font-family="sans-serif"
				font-size="8pt"
				text-indent="2pt">
				<xsl:if test="$role = 'Husband'">
					<xsl:text>Last</xsl:text>
				</xsl:if>
				<xsl:if test="$role = 'Wife'">
					<xsl:text>Maiden</xsl:text>
				</xsl:if>
			</fo:block>
			<fo:block 
				font-family="sans-serif"
				font-size="8pt"
				text-indent="2pt">
				<xsl:text>name</xsl:text>
			</fo:block>
		</fo:table-cell>
		
		<!-- Insert Surname table-cell -->
		<xsl:call-template name="surname">
			<xsl:with-param name="IndiID" select="$IndiID"/>
		</xsl:call-template>
		
	</fo:table-row>
</xsl:template>

<!-- Creates table-cell with Given Name -->

<xsl:template name="givenName">
	<xsl:param name="IndiID"/>

	<fo:table-cell
		border-right-color="black" 
		border-right-style="solid" 
		border-right-width=".1mm"
		border-bottom-color="black" 
		border-bottom-style="solid" 
		border-bottom-width=".1mm"> 
		<fo:block 
			font-family="serif" 
			font-size="12pt"
			padding-top="1.5mm">				
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
		
		
	</fo:table-cell>					
</xsl:template>

<!-- Creates table-cell with Last Name -->

<xsl:template name="surname">
	<xsl:param name="IndiID"/>
	<fo:table-cell  
		border-right-color="black" 
		border-right-style="solid" 
		border-right-width=".1mm"
		border-bottom-color="black" 
		border-bottom-style="solid" 
		border-bottom-width=".1mm"
		padding-top="1.5mm">
		<fo:block 
			font-family="serif" 
			font-size="12pt">
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
	</fo:table-cell>
</xsl:template>
				
<xsl:template name="event">
	<xsl:param name="IndiID"/>
	<xsl:param name="eventName"/>
	<xsl:param name="childNumber"/>
	
	<!-- Event Rows have Bottom Borders -->
	<fo:table-row 
		height="6mm"
		keep-with-previous.within-line="always">
		<fo:table-cell 
			border-left-color="black" 
			border-left-style="solid" 
			border-left-width=".1mm" 
			padding="2pt">
			<fo:block 
				font-family="sans-serif" 
				font-size="10pt"
				text-indent="2pt">
				<!-- Insert Child's number if this is a burial event -->
				<xsl:if test="$eventName = 'Buried'">
					<xsl:value-of select="$childNumber"/>
				</xsl:if>
			</fo:block>
		</fo:table-cell>
		<fo:table-cell
			border-left-color="black" 
			border-left-style="solid" 
			border-left-width=".1mm" 
    		border-bottom-color="black" 
    		border-bottom-style="solid" 
    		border-bottom-width=".1mm" 
			padding="2pt">
			<fo:block 
				font-family="sans-serif" 
				font-size="6pt">
				<!-- Insert "Born", "Died", or "Buried" -->
				<xsl:value-of select="$eventName"/>
			</fo:block>
		</fo:table-cell>
    	<fo:table-cell
    		border-right-color="black" 
			border-right-style="solid" 
			border-right-width=".1mm"
    		border-bottom-color="black" 
    		border-bottom-style="solid" 
    		border-bottom-width=".1mm" 
    		padding-top="1.5mm">
    		<fo:block 
    			font-family="serif" 
    			font-size="12pt">	
    	
    			<!-- DATE -->
    			<xsl:choose>
    				<xsl:when test="$eventName = 'Born'">
    					<xsl:apply-templates select="//INDI[@ID = $IndiID]/BIRT/DATE"/>
    				</xsl:when>
    				<xsl:when test="$eventName = 'Died'">
    					<xsl:apply-templates select="//INDI[@ID = $IndiID]/DEAT/DATE"/>			
    				</xsl:when>
    				<xsl:when test="$eventName = 'Buried'">
    					<xsl:apply-templates select="//INDI[@ID = $IndiID]/BURI/DATE"/>				
    				</xsl:when>
    			</xsl:choose>
    
    		</fo:block>	
    	</fo:table-cell>
    	<fo:table-cell  
    		border-bottom-color="black" 
    		border-bottom-style="solid" 
    		border-bottom-width=".1mm"
    		padding="2pt">
    		<fo:block 
    			font-family="sans-serif" 
    			font-size="6pt">
    			<xsl:text>Place</xsl:text>
    		</fo:block>
    	</fo:table-cell>					
		<fo:table-cell 
			border-right-color="black" 
			border-right-style="solid" 
			border-right-width=".1mm" 
    		border-bottom-color="black" 
    		border-bottom-style="solid" 
    		border-bottom-width=".1mm"
			padding-top="1.5mm">
			<fo:block 
				font-family="serif" 
				font-size="12pt">

			<!--Place of Event -->						
    			<xsl:choose>
    				<xsl:when test="$eventName = 'Born'">
    					<xsl:apply-templates select="//INDI[@ID = $IndiID]/BIRT/PLAC"/>
    				</xsl:when>
    				<xsl:when test="$eventName = 'Died'">
    					<xsl:apply-templates select="//INDI[@ID = $IndiID]/DEAT/PLAC"/>				
    				</xsl:when>
    				<xsl:when test="$eventName = 'Buried'">
    					<xsl:apply-templates select="//INDI[@ID = $IndiID]/BURI/PLAC"/>				
    				</xsl:when>
    			</xsl:choose>
    						
			</fo:block>
		</fo:table-cell>
	</fo:table-row>
</xsl:template>

<xsl:template name="married">
	
	<!-- Added this param so that it will work with the Child's spouse.  Probably
		not the most optimal implementation fo speed -->
	<xsl:param name="FamID"/>
	
	<!-- (Lamely) added this variable to avoid redundant code when it comes to
	    creating the married row for a child.  If the role is 'Child', then
	    it causes this template to added a bottom line to the normally blank
	    outside cell/column -->
	<xsl:param name="role"/>

	<fo:table-row 
		height="6mm"
		keep-with-previous.within-line="always">
		<xsl:choose>
			<xsl:when test="$role = 'Child'">

        		<fo:table-cell 
        			border-left-color="black" 
        			border-left-style="solid" 
        			border-left-width=".1mm" 
        			border-bottom-color="black" 
        			border-bottom-style="solid" 
        			border-bottom-width=".1mm"
        			padding="2pt">
        			<fo:block 
        				font-family="sans-serif" 
        				font-size="10pt">
        			</fo:block>
        		</fo:table-cell>
			
			</xsl:when>
			<xsl:otherwise>

        		<fo:table-cell 
        			border-left-color="black" 
        			border-left-style="solid" 
        			border-left-width=".1mm" 
        			padding="2pt">
        			<fo:block 
        				font-family="sans-serif" 
        				font-size="10pt">
        			</fo:block>
        		</fo:table-cell>
			
			</xsl:otherwise>
		</xsl:choose>

		<fo:table-cell 
			border-left-color="black" 
			border-left-style="solid" 
			border-left-width=".1mm"
			border-bottom-color="black" 
			border-bottom-style="solid" 
			border-bottom-width=".1mm"
			padding="2pt">
			<fo:block 
				font-family="sans-serif" 
				font-size="6pt">
				<xsl:text>Married</xsl:text>
			</fo:block>
		</fo:table-cell>
    	<fo:table-cell
    		border-bottom-color="black" 
    		border-bottom-style="solid" 
    		border-bottom-width=".1mm" 
    		padding-top="1.5mm">
    		<fo:block 
    			font-family="serif" 
    			font-size="12pt">	
    	
    			<!-- DATE -->
    			<xsl:apply-templates select="//FAM[@ID=$FamID]/MARR/DATE"/>
    
    		</fo:block>	
    	</fo:table-cell>
    	<fo:table-cell 
    		border-left-color="black" 
    		border-left-style="solid" 
    		border-left-width=".1mm"
    		border-bottom-color="black" 
    		border-bottom-style="solid" 
    		border-bottom-width=".1mm"
    		padding="2pt">
    		<fo:block 
    			font-family="sans-serif" 
    			font-size="6pt">
    			<xsl:text>Place</xsl:text>
    		</fo:block>
		</fo:table-cell>					
		<fo:table-cell 
			border-right-color="black" 
			border-right-style="solid" 
			border-right-width=".1mm"
    		border-bottom-color="black" 
    		border-bottom-style="solid" 
    		border-bottom-width=".1mm" 
			padding-top="1.5mm">
			<fo:block 
				font-family="serif" 
				font-size="12pt">

			<!--Place of Event -->								
		 		<xsl:apply-templates select="//FAM[@ID=$FamID]/MARR/PLAC"/>
			
			</fo:block>
		</fo:table-cell>

	</fo:table-row>
</xsl:template>


<xsl:template name="parentNameRow">
	<xsl:param name="IndiID"/>
	<xsl:param name="role"/>
	<xsl:param name="gender"/>
	
	<fo:table-row 
		height="6mm">
		<fo:table-cell 
			border-left-color="black" 
			border-left-style="solid" 
			border-left-width=".1mm"
			padding="2pt">
			<fo:block 
				font-family="sans-serif" 
				font-size="10pt">
			</fo:block>
		</fo:table-cell>
		<fo:table-cell 							
			border-left-color="black" 
			border-left-style="solid" 
			border-left-width=".1mm"
    		border-bottom-color="black" 
    		border-bottom-style="solid" 
    		border-bottom-width=".1mm"
			padding-top="1.5mm"
			padding-left="1mm">
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
				font-size="6pt">
				<xsl:text>Given name(s)</xsl:text>
			</fo:block>
		</fo:table-cell>
		
		<!-- Insert Given Name table-cell -->
		<xsl:call-template name="givenName">
			<xsl:with-param name="IndiID" select="$IndiID"/>
		</xsl:call-template>
		
		<fo:table-cell 
    		border-bottom-color="black" 
    		border-bottom-style="solid" 
    		border-bottom-width=".1mm" 
			padding-top=".3mm"
			padding-left="1mm">
			<!-- In contrast to Husband and Wife, the Father/Mother label is set at 6pt -->
			<fo:block 
				font-family="sans-serif"
				font-size="6pt">
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
				font-size="6pt">
				<xsl:text>name</xsl:text>
			</fo:block>
		</fo:table-cell>
		
		<!-- Insert Surname Cell-->
		<xsl:call-template name="surname">
			<xsl:with-param name="IndiID" select="$IndiID"/>
		</xsl:call-template>
		
	</fo:table-row>

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


<xsl:template name="children">
	<xsl:param name="numberOfChildren"/>
	<xsl:param name="fatherID"/>
	<xsl:param name="motherID"/>
	
	<!-- Start of Children -->
	<xsl:call-template name="childListLabel"/>
	
	<xsl:for-each select="CHIL">

		<xsl:if test="( position() mod 6 ) = 5">
			<!-- Insert Spouse name (Child's Father) -->
        	<!-- Table with Spouse Names -->
         	<fo:table table-layout="fixed"
        		border-top-color="black" 
        		border-top-style="solid" 
        		border-top-width=".1mm"
        		break-before="page"> <!-- this breaks to the new page -->
        		<fo:table-column column-width="22mm"/>
        		<fo:table-column column-width="72mm"/>
        		<fo:table-column column-width="12mm"/>
        		<fo:table-column column-width="74mm"/>
        		<fo:table-body>

                	<xsl:call-template name="spouseNameRow">
                		<xsl:with-param name="role" select="'Husband'"/>
                		<xsl:with-param name="IndiID" select="$fatherID"/>
                	</xsl:call-template>
                	
				</fo:table-body>
			</fo:table>
			
			<!-- Insert Spouse name (Child's Mother) -->
        	<!-- Table with Spouse Names -->
         	<fo:table table-layout="fixed"
        		border-top-color="black" 
        		border-top-style="solid" 
        		border-top-width=".1mm">
        		<fo:table-column column-width="22mm"/>
        		<fo:table-column column-width="72mm"/>
        		<fo:table-column column-width="12mm"/>
        		<fo:table-column column-width="74mm"/>
        		<fo:table-body>

                	<xsl:call-template name="spouseNameRow">
                		<xsl:with-param name="role" select="'Wife'"/>
                		<xsl:with-param name="IndiID" select="$motherID"/>
                	</xsl:call-template>
                	
				</fo:table-body>
			</fo:table>			

			<xsl:call-template name="childListLabel"/>		
		</xsl:if>

		<xsl:call-template name="child">
			<xsl:with-param name="IndiID" select="@REF"/>
			<xsl:with-param name="childNumber" select="position()"/>
		</xsl:call-template>	
	</xsl:for-each>

	<!-- If the Number of Children is less than 4 on the first page,
		 then this conditional will create blankChildren to fill the page -->	
	<xsl:if test="$numberOfChildren &lt; 4 ">
		<xsl:call-template name="addBlankChildren">
			<xsl:with-param name="childNumber" select="$numberOfChildren + 1"/>
			<xsl:with-param name="numberOfBlankChildren" select="4 - $numberOfChildren"/>
		</xsl:call-template>
	</xsl:if>

	<!-- If the Number of Children is greater than four (which means that it is on
		the second page), then this conditional will create blankChildren to fill the page -->		

	<!-- Note: the 2nd conditional tests if blank children need to be created at all -->
    <xsl:if test="$numberOfChildren &gt; 4 ">
	    <xsl:if test="(6 - ( ( $numberOfChildren + 2 ) mod 6 )) &lt; 6">
	   		<xsl:call-template name="addBlankChildren">
  				<xsl:with-param name="childNumber" select="$numberOfChildren + 1"/>
  				<xsl:with-param name="numberOfBlankChildren" select="6 - ( ( $numberOfChildren + 2 ) mod 6 )"/>
   			</xsl:call-template>			
    	</xsl:if>
    </xsl:if>
	
	
</xsl:template>

<xsl:template name="addBlankChildren">
	<xsl:param name="childNumber"/>
	<xsl:param name="numberOfBlankChildren"/>
	
	<xsl:if test="$numberOfBlankChildren > 0">
    	<xsl:call-template name="child">
    		<xsl:with-param name="childNumber" select="$childNumber"/>
    	</xsl:call-template>

    	<xsl:call-template name="addBlankChildren">
    		<xsl:with-param name="childNumber" select="$childNumber + 1"/>
    		<xsl:with-param name="numberOfBlankChildren" select="$numberOfBlankChildren - 1"/>
    	</xsl:call-template>	
	</xsl:if>
</xsl:template>


<xsl:template name="childListLabel">

	<fo:table table-layout="fixed"
		border-top-color="black" 
		border-top-style="solid" 
		border-top-width=".1mm">
		<fo:table-column column-width="180mm"/>
		<fo:table-body>
			<fo:table-row 
				height="6mm">
				<fo:table-cell 	
					padding-top="1.5mm"
					padding-left="2mm"
            		border-left-color="black" 
            		border-left-style="solid" 
            		border-left-width=".1mm" 
            		border-right-color="black" 
            		border-right-style="solid" 
            		border-right-width=".1mm"
        			border-bottom-color="black" 
        			border-bottom-style="solid" 
        			border-bottom-width=".1mm">
					<fo:block		
						font-family="sans-serif" 
						font-size="10pt">
						<xsl:text>Children - List each child in order of birth</xsl:text>
					</fo:block>
				</fo:table-cell>
			</fo:table-row>
		</fo:table-body>
	</fo:table>

</xsl:template>

<xsl:template name="child">
	
	<xsl:param name="IndiID"/>
	<xsl:param name="childNumber"/>
	
	<!-- Table with Child's Name -->
	<fo:table table-layout="fixed">
		<fo:table-column column-width="6mm"/>
		<fo:table-column column-width="14mm"/>
		<fo:table-column column-width="160mm"/>
		<fo:table-body>
			<fo:table-row>
    			<xsl:call-template name="childNameRow">
    				<xsl:with-param name="IndiID" select="$IndiID"/>
    			</xsl:call-template>
			</fo:table-row>			
		</fo:table-body>
	</fo:table>

	<!-- Table with all Events -->
	<fo:table table-layout="fixed">
		<fo:table-column column-width="6mm"/>
		<fo:table-column column-width="10mm"/>
		<fo:table-column column-width="26mm"/>
		<fo:table-column column-width="8mm"/>
		<fo:table-column column-width="130mm"/>
		<fo:table-body>
		
			<!-- Born row -->
			<xsl:call-template name="event">
				<xsl:with-param name="IndiID" select="$IndiID"/>
				<xsl:with-param name="eventName" select="'Born'"/>
			</xsl:call-template>
			<!-- Died row -->
			<xsl:call-template name="event">
				<xsl:with-param name="IndiID" select="$IndiID"/>
				<xsl:with-param name="eventName" select="'Died'"/>
			</xsl:call-template>
			<!-- Buried row -->			
			<xsl:call-template name="event">
				<xsl:with-param name="IndiID" select="$IndiID"/>
				<xsl:with-param name="eventName" select="'Buried'"/>
				<xsl:with-param name="childNumber" select="$childNumber"/>
			</xsl:call-template>

		</fo:table-body>
	</fo:table>

	<xsl:call-template name="childMarriage">
		<xsl:with-param name="FamID" select="//INDI[@ID = $IndiID]/FAMS/@REF"/>
		<xsl:with-param name="IndiID" select="$IndiID"/>
	</xsl:call-template>

</xsl:template>

<xsl:template name="childNameRow">
	<xsl:param name="IndiID"/>
		
		<!-- Gender -->
		<fo:table-cell
			border-left-color="black" 
			border-left-style="solid" 
			border-left-width=".1mm"
			border-right-color="black" 
			border-right-style="solid" 
			border-right-width=".1mm"
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			border-bottom-color="black" 
			border-bottom-style="solid" 
			border-bottom-width=".1mm"
			padding-top=".3mm"
			padding-left="1mm">
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
		</fo:table-cell>
		<!-- Given Name -->
		<fo:table-cell 
			border-bottom-color="black" 
			border-bottom-style="solid" 
			border-bottom-width=".1mm"
			padding-top=".3mm"
			padding-left="1mm">
			<fo:block 
				font-family="sans-serif"
				font-size="7pt"
				padding-left="1mm">
				<xsl:text>Given name(s)</xsl:text>
			</fo:block>
		</fo:table-cell>
	
		<!-- Insert Given Name Cell -->
		<xsl:call-template name="givenName">
			<xsl:with-param name="IndiID" select="$IndiID"/>
		</xsl:call-template>
		
		<!-- No Surname -->
				
</xsl:template>


<xsl:template name="childMarriage">
	<xsl:param name="FamID"/>
	<xsl:param name="IndiID"/>
	
		<!-- Created because parser doesn't like it when I just pass @REF is a [ ] expression -->
			
		<!-- Create spouse row -->
    	<fo:table table-layout="fixed">
    		<fo:table-column column-width="6mm"/>
    		<fo:table-column column-width="18mm"/>				
    		<fo:table-column column-width="70mm"/>
    		<fo:table-column column-width="10mm"/>
    		<fo:table-column column-width="76mm"/>
    		<fo:table-body>
    
            	<fo:table-row 
            		height="6mm"
            		keep-with-previous.within-line="always">
            		<fo:table-cell 
            			border-left-color="black" 
            			border-left-style="solid" 
            			border-left-width=".1mm" 
            			padding="2pt">
            			<fo:block 
            				font-family="sans-serif" 
            				font-size="10pt">
            			</fo:block>
            		</fo:table-cell>
            		<fo:table-cell 							
            			border-left-color="black" 
            			border-left-style="solid" 
            			border-left-width=".1mm"
            			border-bottom-color="black" 
            			border-bottom-style="solid" 
            			border-bottom-width=".1mm"
            			padding-top="1.5mm"
            			padding-left="1mm">
            			<!-- set at 6pt -->
            			<fo:block
            				font-family="sans-serif"
            				font-size="6pt">				
            				<xsl:text>Spouse&#8217;s </xsl:text>
            			</fo:block>
            			<fo:block 
            				font-family="sans-serif"
            				font-size="6pt">
            				<xsl:text>Given name(s)</xsl:text>
            			</fo:block>
            		</fo:table-cell>
            		
            		<!-- Insert Given Name table-cell -->
            		<!-- This should be able to handle FAM that have 2 Husbands or 2 Wives (Fuck tradition) -->
            		<xsl:choose>
            			<!-- If the family has a HUSB with an REF different from their Spouse's ID -->
            			<xsl:when test="//FAM[@ID = $FamID]/HUSB[@REF != $IndiID]">
       						<xsl:call-template name="givenName">
            					<xsl:with-param name="IndiID" select="//FAM[@ID = $FamID]/HUSB[@REF != $IndiID]/@REF"/>
            				</xsl:call-template>
            			</xsl:when>
            			<!-- If the family has a WIFE with an REF different from their Spouse's ID -->
            			<xsl:when test="//FAM[@ID = $FamID]/WIFE[@REF != $IndiID]">
       						<xsl:call-template name="givenName">
            					<xsl:with-param name="IndiID" select="//FAM[@ID = $FamID]/WIFE[@REF != $IndiID]/@REF"/>
         					</xsl:call-template>  
            			</xsl:when>
            			<!-- otherwise insert blank given name cell -->
            			<xsl:otherwise>
            				<xsl:call-template name="givenName"/>
            			</xsl:otherwise>
            		</xsl:choose>            		
            				
            		<fo:table-cell 
            			border-left-color="black" 
            			border-left-style="solid" 
            			border-left-width=".1mm"
            			border-bottom-color="black" 
            			border-bottom-style="solid" 
            			border-bottom-width=".1mm" 
            			padding-top=".3mm"
            			padding-left="1mm">
            			<!-- set at 6pt -->
            			<fo:block 
            				font-family="sans-serif"
            				font-size="6pt">
            				<xsl:text>Last</xsl:text>
            			</fo:block>
            			<fo:block 
            				font-family="sans-serif"
            				font-size="6pt">
            				<xsl:text>name</xsl:text>
            			</fo:block>
            		</fo:table-cell>
            		
            		<!-- Insert Surname Cell-->
            		<!-- This should be able to handle FAM that have 2 Husbands or 2 Wives (Fuck tradition) -->
            		<xsl:choose>
            			<!-- If the family has a HUSB with an REF different from their Spouse's ID -->
            			<xsl:when test="//FAM[@ID = $FamID]/HUSB[@REF != $IndiID]">
       						<xsl:call-template name="surname">
            					<xsl:with-param name="IndiID" select="//FAM[@ID = $FamID]/HUSB[@REF != $IndiID]/@REF"/>
            				</xsl:call-template>
            			</xsl:when>
            			<!-- If the family has a WIFE with an REF different from their Spouse's ID -->
            			<xsl:when test="//FAM[@ID = $FamID]/WIFE[@REF != $IndiID]">
       						<xsl:call-template name="surname">
            					<xsl:with-param name="IndiID" select="//FAM[@ID = $FamID]/WIFE[@REF != $IndiID]/@REF"/>
         					</xsl:call-template>  
            			</xsl:when>
            			<!-- otherwise insert blank given name cell -->
            			<xsl:otherwise>
            				<xsl:call-template name="surname"/>
            			</xsl:otherwise>
            		</xsl:choose>            		
    		
    			</fo:table-row>
    		</fo:table-body>
    	</fo:table>	
	
		<!-- Table with Married Event -->
		<fo:table 
			table-layout="fixed">
    		<fo:table-column column-width="6mm"/>
    		<fo:table-column column-width="10mm"/>
    		<fo:table-column column-width="26mm"/>
    		<fo:table-column column-width="8mm"/>
    		<fo:table-column column-width="130mm"/>
    			<fo:table-body>

                	<xsl:call-template name="married">
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
		<!-- default to 12pt -->
		<xsl:otherwise>
			<fo:block 
				font-family="serif" 
				font-size="12pt">
				<xsl:value-of select="normalize-space( . )"/>	
			</fo:block>
		</xsl:otherwise>				
	</xsl:choose>

</xsl:template>


</xsl:stylesheet>