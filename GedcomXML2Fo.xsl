<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<!-- $Id$ -->
<xsl:output indent="yes" method="xml"/>
 
<xsl:template match="/">
		<fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format">
			<fo:layout-master-set>
				<fo:simple-page-master margin-bottom="1cm" margin-left="2.5cm" margin-right="1cm" margin-top="1.5cm" master-name="Family1" page-height="11in" page-width="8.5in">
					<fo:region-before extent="1cm"/>
					<fo:region-body margin-top="1cm"/>
					<fo:region-after extent="1cm"/>
				</fo:simple-page-master>
				<fo:simple-page-master margin-bottom="1cm" margin-left="2.5cm" margin-right="1cm" margin-top="1.5cm" master-name="Family2" page-height="11in" page-width="8.5in">
					<fo:region-before extent="1cm"/>
					<fo:region-body margin-top="1cm"/>
					<fo:region-after extent="1cm"/>
				</fo:simple-page-master>
			</fo:layout-master-set>
			
			<xsl:apply-templates select="//FamilyRec"/>
	
		</fo:root>
</xsl:template>
	
	
<xsl:template match="FamilyRec">

	<xsl:variable name="numberOfChildren" select="count( Child )"/>

	<fo:page-sequence country="us" initial-page-number="1" language="en" master-reference="Family1">
		<fo:static-content flow-name="xsl-region-before">
			<fo:block 
				font-family="sans-serif" 
				font-size="16pt"
				text-align="center">
				Family Group Record
			</fo:block>
			<fo:block	
				font-family="sans-serif" 
				font-size="6pt"
				text-align="right">
				Page of
				<xsl:text> </xsl:text>
				<xsl:if test="( $numberOfChildren div 6  ) &lt;= 1">
					<xsl:if test="$numberOfChildren &lt;= 4">
						<xsl:text>1</xsl:text>
					</xsl:if>
					<xsl:if test="( $numberOfChildren = 5 ) or ( $numberOfChildren = 6 )">
						<xsl:text>2</xsl:text>
					</xsl:if>
				</xsl:if>
				<xsl:if test="( $numberOfChildren div 6 ) &gt; 1">
					<xsl:value-of select="( $numberOfChildren div 6 ) - ( $numberOfChildren mod 6 ) + 2"/>
				</xsl:if>
			</fo:block>
		</fo:static-content>
		
		<fo:static-content flow-name="xsl-region-after">
			<fo:block 
				font-family="sans-serif" 
				font-size="10pt"
				text-align="left">
				Printed: xx/xx/xxxx
			</fo:block>
		</fo:static-content>
	
		<fo:flow flow-name="xsl-region-body">
			<xsl:call-template name="spouse">
				<xsl:with-param name="role" select="'HusbFath'"/>
			</xsl:call-template>
			<xsl:call-template name="spouse">
				<xsl:with-param name="role" select="'WifeMoth'"/>
			</xsl:call-template>
			
			<!-- Start of Chlldren -->
			<fo:table>
				<fo:table-column column-width="180mm"/>
				<fo:table-body>
					<fo:table-row 
						height="6mm">
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
							padding="1mm">
							<fo:block		
								font-family="sans-serif" 
								font-size="10pt">
								Children - List each child in order of birth
							</fo:block>
						</fo:table-cell>
					</fo:table-row>
				</fo:table-body>
			</fo:table>
			

			<xsl:call-template name="children">
				<xsl:with-param name="count" select="$numberOfChildren"/>
				<xsl:with-param name="numberOfChildren" select="$numberOfChildren"/>
			</xsl:call-template>
		</fo:flow>
	</fo:page-sequence>
</xsl:template>

<xsl:template name="children">
	<xsl:param name="count"/>
	<xsl:param name="numberOfChildren"/>
	<xsl:param name="firstPageDone" select="false()"/>

	
	<xsl:for-each select="Child">
				
		<xsl:if test="( $count mod 4) or ($count mod 6 )">
			<xsl:apply-templates select="current()">
				<xsl:with-param name="childNbr" select="$numberOfChildren - $count + 1"/>	
			</xsl:apply-templates>
			
			<xsl:choose>
				<xsl:when test="$numberOfChildren &lt; 4">
					<xsl:call-template name="children">
						<xsl:with-param name="count" select="$count - 1"/>
						<xsl:with-param name="numberOfChildren" select="$numberOfChildren"/>
						<xsl:with-param name="firstPageDone" select="true()"/>
					</xsl:call-template>			
				</xsl:when>
				<xsl:when test="$numberOfChildren &gt; 4">
					<xsl:call-template name="children">
						<xsl:with-param name="count" select="$count - 1"/>
						<xsl:with-param name="numberOfChildren" select="$numberOfChildren"/>
						<xsl:with-param name="firstPageDone" select="true()"/>
					</xsl:call-template>	
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="children">
						<xsl:with-param name="count" select="$count - 1"/>
						<xsl:with-param name="numberOfChildren" select="$numberOfChildren"/>
						<xsl:with-param name="firstPageDone" select="false()"/>
					</xsl:call-template>
				</xsl:otherwise>		
			</xsl:choose>												
		</xsl:if>
		
		<xsl:if test="( ( $count mod 4 ) = 0 ) and not( $firstPageDone )" >
			<!-- The flow will start new page. Add parents to the first two rows -->

			<xsl:call-template name="spouseName">
				<xsl:with-param name="role" select="'HusbFath'"/>
			</xsl:call-template>
			<xsl:call-template name="spouseName">
				<xsl:with-param name="role" select="'WifeMoth'"/>
			</xsl:call-template>
			
			<!-- Continue adding children -->
			<xsl:apply-templates select="current()">
				<xsl:with-param name="childNbr" select="$numberOfChildren - $count + 1"/>	
			</xsl:apply-templates>
			<xsl:call-template name="children">
				<xsl:with-param name="count" select="$count - 1"/>
				<xsl:with-param name="numberOfChildren" select="$numberOfChildren"/>
				<xsl:with-param name="firstPageDone" select="true()"/>
			</xsl:call-template>
		</xsl:if>
		
		<xsl:if test=" ( $count mod 6 ) = 0">
			<!-- The flow will start new page. Add parents to the first two rows -->
			<xsl:if test="$count &gt; 6">
				<xsl:call-template name="spouseName">
					<xsl:with-param name="role" select="'HusbFath'"/>
				</xsl:call-template>
				<xsl:call-template name="spouseName">
					<xsl:with-param name="role" select="'WifeMoth'"/>
				</xsl:call-template>			
			</xsl:if>
						
			<!-- Continue adding children -->
			<xsl:apply-templates select="current()">
				<xsl:with-param name="childNbr" select="$numberOfChildren - $count + 1"/>	
			</xsl:apply-templates>
			<xsl:call-template name="children">
				<xsl:with-param name="count" select="$count - 1"/>
				<xsl:with-param name="numberOfChildren" select="$numberOfChildren"/>
				<xsl:with-param name="firstPageDone" select="true()"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:for-each>
</xsl:template>

<xsl:template name="spouse">
	<xsl:param name="role"/>

	<xsl:variable name="spouseID" select="$role/Link/@Ref"/>
	
	<xsl:call-template name="spouseName">
		<xsl:with-param name="role" select="$role"/>
		<xsl:with-param name="spouseID" select="$spouseID"/>
	</xsl:call-template>

	<fo:table>
		<fo:table-column column-width="6mm"/>
		<fo:table-column column-width="10mm"/>
		<fo:table-column column-width="26mm"/>
		<fo:table-column column-width="10mm"/>
		<fo:table-column column-width="128mm"/>
		<fo:table-body>
			<xsl:call-template name="born">
				<xsl:with-param name="IndividualRef" select="$spouseID"/>
			</xsl:call-template>
			<xsl:call-template name="died">
				<xsl:with-param name="IndividualRef" select="$spouseID"/>
			</xsl:call-template>
			<xsl:call-template name="buried">
				<xsl:with-param name="IndividualRef" select="$spouseID"/>
			</xsl:call-template>
			
			<!-- only include Marriage date and place under husband-->
			<xsl:if test="$role = 'HusbFath'">
				<xsl:call-template name="married">
					<xsl:with-param name="IndividualRef" select="$spouseID"/>
				</xsl:call-template>			
			</xsl:if>

		</fo:table-body>
	</fo:table>
		
			
		<xsl:if test="$role = 'HusbFath'">
			<xsl:call-template name="parents">
				<xsl:with-param name="IndividualRef" select="$spouseID"/>
				<xsl:with-param name="role" select="'Husband'"/>
			</xsl:call-template>
		</xsl:if>
		
		<xsl:if test="$role = 'WifeMoth'">
			<xsl:call-template name="parents">
				<xsl:with-param name="IndividualRef" select="$spouseID"/>
				<xsl:with-param name="role" select="'Wife'"/>
			</xsl:call-template>
		</xsl:if>
</xsl:template>

<xsl:template  name="spouseName">
	<xsl:param name="role"/>	
	<xsl:param name="spouseID"/>
	
	<fo:table>
		<fo:table-column column-width="22mm"/>
		<fo:table-column column-width="72mm"/>
		<fo:table-column column-width="10mm"/>
		<fo:table-column column-width="76mm"/>
		<fo:table-body>
			<fo:table-row 
				height="6mm">
				<fo:table-cell 
					border-left-color="black" 
					border-left-style="solid" 
					border-left-width=".1mm" 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding-top=".3mm"
					padding-left="1mm">
					<fo:block 
						font-family="sans-serif"
						font-size="8pt">
						<xsl:if test="$role = 'HusbFath'">
							<xsl:text>Husband</xsl:text>
						</xsl:if>
						<xsl:if test="$role = 'WifeMoth'">
							<xsl:text>Wife</xsl:text>
						</xsl:if>
					</fo:block>
					<fo:block 
						font-family="sans-serif"
						font-size="7pt"
						padding-left="1mm">
						<xsl:text>Given name(s)</xsl:text>
					</fo:block>
				</fo:table-cell>					
				<fo:table-cell 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm">
					<fo:block 
						font-family="sans-serif" 
						font-size="10pt"
						padding-top="1.5mm">
						<xsl:value-of select="//IndividualRec[@Id=$spouseID]/IndivName/NamePart[@Level = '3']"/>
					</fo:block>
				</fo:table-cell>					
				<fo:table-cell 
					border-left-color="black" 
					border-left-style="solid" 
					border-left-width=".1mm" 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding-top=".3mm"
					padding-left="1mm">
					<fo:block 
						font-family="sans-serif"
						font-size="8pt">
						<xsl:if test="$role = 'HusbFath'">
							<xsl:text>Last</xsl:text>
						</xsl:if>
						<xsl:if test="$role = 'WifeMoth'">
							<xsl:text>Maiden</xsl:text>
						</xsl:if>
					</fo:block>
					<fo:block 
						font-family="sans-serif"
						font-size="8pt">
						<xsl:text>name</xsl:text>
					</fo:block>
				</fo:table-cell>
				<fo:table-cell  
					border-right-color="black" 
					border-right-style="solid" 
					border-right-width=".1mm" 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding-top="1.5mm">
					<fo:block 
						font-family="sans-serif" 
						font-size="10pt">
						<xsl:if test="$role = 'HusbFath'">
							<xsl:value-of select="//IndividualRec[@Id=$spouseID]/IndivName/NamePart[@Level = '1']"/>
						</xsl:if>
						<xsl:if test="$role = 'WifeMoth'">
							<xsl:value-of select="//IndividualRec[@Id=$spouseID]/IndivName/NamePart[@Level = '2']"/>
						</xsl:if>
					</fo:block>
				</fo:table-cell>
			</fo:table-row>
		</fo:table-body>
	</fo:table>

</xsl:template>

<xsl:template match="Child">

	<xsl:variable name="childID" select="Link/@Ref"/>
	
	<xsl:variable name="gender" select="//IndividuaRec[@Id = $childID]/Gender"/>

	<fo:table>
		<fo:table-column column-width="6mm"/>
		<fo:table-column column-width="14mm"/>
		<fo:table-column column-width="160mm"/>
		<fo:table-body>
			<fo:table-row 
				height="6mm">
				<fo:table-cell 
				  	border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm" 
					border-left-color="black" 
					border-left-style="solid" 
					border-left-width=".1mm" 
					padding-top=".1mm"
					padding-left="1mm">
					<fo:block 
						font-family="sans-serif" 
						font-size="6pt">
						Sex
					</fo:block>
					<fo:block 
						font-family="sans-serif"
						font-size="6pt">
						<xsl:value-of select="$gender"/>	
					</fo:block>
				</fo:table-cell>
				<fo:table-cell 
					border-left-color="black" 
					border-left-style="solid" 
					border-left-width=".1mm" 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding-top=".1mm"
					padding-left="1mm">
					<fo:block 
						font-family="sans-serif"
						font-size="6pt">
						Given
					</fo:block>
					<fo:block 
						font-family="sans-serif"
						font-size="6pt">
						name(s)
					</fo:block>
				</fo:table-cell>
				<fo:table-cell  
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					border-right-color="black" 
					border-right-style="solid" 
					border-right-width=".1mm"
					padding-top="1.5mm">
					<fo:block 
						font-family="sans-serif" 
						font-size="10pt">
						<xsl:value-of select="//IndividualRec[@Id=$childID]/IndivName/NamePart[@Level = '3']"/>
					</fo:block>
				</fo:table-cell>
			</fo:table-row>
		</fo:table-body>
	</fo:table>	

	<xsl:call-template name="born">
		<xsl:with-param name="IndividualRef" select="$childID"/>
	</xsl:call-template>
	<xsl:call-template name="died">
		<xsl:with-param name="IndividualRef" select="$childID"/>
	</xsl:call-template>
	<xsl:call-template name="buried">
		<xsl:with-param name="IndividualRef" select="$childID"/>
		<xsl:with-param name="count" select="number()"/>		
	</xsl:call-template>

	<!-- Child's spouse -->
	
	<xsl:choose>
		<xsl:when test="//FamilyRec/WifeMoth/Link[@Ref=$childID]">
			<xsl:apply-templates select="//FamilyRec/WifeMoth/Link[@Ref=$childID]" mode="childSpouse">
				<xsl:with-param name="role" select="'husband'"/>
			</xsl:apply-templates>
		</xsl:when>
		<xsl:when test="//FamilyRec/WifeMoth/Link[@Ref=$childID]">
			<xsl:apply-templates select="//FamilyRec/HusbFath/Link[@Ref=$childID]" mode="childSpouse">
				<xsl:with-param name="role" select="'wife'"/>
			</xsl:apply-templates>		
		</xsl:when>
		<xsl:otherwise>			
			<xsl:call-template name="blankChildSpouse"/>
		</xsl:otherwise>
	</xsl:choose>

	
	<!-- Child's date of marriage -->

		<xsl:choose>
			<xsl:when test="$gender = 'F'">
				<xsl:call-template name="married">
					<xsl:with-param name="IndividualRef" select="$childID"/>
					<xsl:with-param name="role" select="'wife'"/>
				</xsl:call-template>

			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="married">
					<xsl:with-param name="IndividualRef" select="$childID"/>
					<xsl:with-param name="role" select="'husband'"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>

	

		
</xsl:template>

<xsl:template match="Link" mode="childSpouse">

	<xsl:param name="role"/>	
	<!-- Child Spouse-->
	
	<xsl:variable name="spouseID" select="../../HusbFath/Link/@Ref"/>
	
	<fo:table>
		<fo:table-column column-width="6mm"/>
		<fo:table-column column-width="23mm"/>
		<fo:table-column column-width="66mm"/>
		<fo:table-column column-width="10mm"/>
		<fo:table-column column-width="75mm"/>
		<fo:table-body>
			<fo:table-row 
				height="6mm">
				<fo:table-cell 
					border-left-color="black" 
					border-left-style="solid" 
					border-left-width=".1mm" 
					padding-top=".1mm"
					padding-left="1mm">
					<fo:block 
						font-family="sans-serif" 
						font-size="10pt">
					</fo:block>
				</fo:table-cell>
				<fo:table-cell 
					border-left-color="black" 
					border-left-style="solid" 
					border-left-width=".1mm" 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding-top=".1mm"
					padding-left="1mm">
					<fo:block 
						font-family="sans-serif"
						font-size="6pt">
						Spouse
					</fo:block>
					<fo:block 
						font-family="sans-serif"
						font-size="6pt">
						Given name(s)
					</fo:block>
				</fo:table-cell>
				<fo:table-cell  
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding-top="1.5mm">
					<fo:block 
						font-family="sans-serif" 
						font-size="10pt">
						<xsl:value-of select="//IndividualRec[@ID = $spouseID]/IndiviName/Namepart[@Level = '3']"/>
					</fo:block>
				</fo:table-cell>
				<fo:table-cell 
					border-left-color="black" 
					border-left-style="solid" 
					border-left-width=".1mm" 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding-top=".1mm"
					padding-left="1mm">
					<fo:block 
						font-family="sans-serif"
						font-size="6pt">
						<xsl:choose>
							<xsl:when test="$role = 'wife'">
								Maiden
							</xsl:when>
							<xsl:otherwise>
								Last
							</xsl:otherwise>
						</xsl:choose>
					</fo:block>
					<fo:block 
						font-family="sans-serif"
						font-size="6pt">
						name
					</fo:block>
				</fo:table-cell>
				<fo:table-cell  
					border-right-color="black" 
					border-right-style="solid" 
					border-right-width=".1mm" 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding-top="1.5mm">
					<fo:block 
						font-family="sans-serif" 
						font-size="10pt">
						<xsl:choose>
							<xsl:when test="$role = 'wife'">
								<xsl:value-of select="//IndividualRec[@ID = $spouseID]/IndiviName/Namepart[@Level = '2']"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="//IndividualRec[@ID = $spouseID]/IndiviName/Namepart[@Level = '1']"/>
							</xsl:otherwise>
						</xsl:choose>
					</fo:block>
				</fo:table-cell>
			</fo:table-row>
		</fo:table-body>
	</fo:table>
	
</xsl:template>

<xsl:template name="born">
	<xsl:param name="IndividualRef"/>	
	<fo:table-row 
		height="6mm">
		<fo:table-cell 
			border-left-color="black" 
			border-left-style="solid" 
			border-left-width=".1mm" 
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
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
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			padding="2pt">
			<fo:block 
				font-family="sans-serif" 
				font-size="6pt">
				Born
			</fo:block>
		</fo:table-cell>
			
		<xsl:choose>
			<xsl:when test="//EventRec[@Type = 'birth' ]/Participant/Link[@Ref = $IndividualRef]">
				<xsl:apply-templates select="//EventRec[@Type = 'birth' ]/Participant/Link[@Ref = $IndividualRef]">
					<xsl:with-param name="role" select="'child'"/>
				</xsl:apply-templates>					
			</xsl:when>
			<xsl:otherwise>
				<fo:table-cell 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding-top="1.5mm">
					<fo:block 
						font-family="sans-serif" 
						font-size="10pt">	
					</fo:block>	
				</fo:table-cell>
				<fo:table-cell 
					border-left-color="black" 
					border-left-style="solid" 
					border-left-width=".1mm" 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding="2pt">
						<fo:block 
							font-family="sans-serif" 
							font-size="6pt">
							Place
						</fo:block>
				</fo:table-cell>					
				<fo:table-cell 
					border-right-color="black" 
					border-right-style="solid" 
					border-right-width=".1mm" 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding-top="1.5mm">
					<fo:block 
						font-family="sans-serif" 
						font-size="10pt">			
					</fo:block>
				</fo:table-cell>				
			</xsl:otherwise>				
		</xsl:choose>			
	</fo:table-row>
</xsl:template>


<xsl:template match="Link">

	<xsl:param name="role"/>

	<fo:table-cell 
		border-top-color="black" 
		border-top-style="solid" 
		border-top-width=".1mm"
		padding-top="1.5mm">
		<fo:block 
			font-family="sans-serif" 
			font-size="10pt">	
	
			<xsl:if test="../Role =  $role">
				<xsl:value-of select="../../Date"/>
			</xsl:if>

		</fo:block>	
	</fo:table-cell>
	<fo:table-cell 
		border-left-color="black" 
		border-left-style="solid" 
		border-left-width=".1mm" 
		border-top-color="black" 
		border-top-style="solid" 
		border-top-width=".1mm"
		padding="2pt">
		<fo:block 
			font-family="sans-serif" 
			font-size="6pt">
			Place
		</fo:block>
		</fo:table-cell>					
		<fo:table-cell 
			border-right-color="black" 
			border-right-style="solid" 
			border-right-width=".1mm" 
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			padding-top="1.5mm">
			<fo:block 
				font-family="sans-serif" 
				font-size="10pt">
			
				<xsl:if test="../Role = $role">
					<xsl:apply-templates select="../../Place/PlaceName"/>
				</xsl:if>
								
			</fo:block>
		</fo:table-cell>
</xsl:template>


<xsl:template match="PlaceName">
	<xsl:value-of select="text()"/>
	<xsl:text>, </xsl:text>
	<xsl:value-of select="PlacePart[@Level = '1']"/>
	<xsl:text>, </xsl:text>
	<xsl:value-of select="PlacePart[@Level = '2']"/>
	<xsl:text>, </xsl:text>
	<xsl:value-of select="PlacePart[@Level = '3']"/>
	<xsl:text>, </xsl:text>
	<xsl:value-of select="PlacePart[@Level = '4']"/>
	<xsl:text>, </xsl:text>
	<xsl:value-of select="PlacePart[@Level = '5']"/>
	<xsl:text>, </xsl:text>
	<xsl:value-of select="PlacePart[@Level = '6']"/>
	<xsl:text>, </xsl:text>
	<xsl:value-of select="PlacePart[@Level = '7']"/>
</xsl:template>

<xsl:template name="died">
	<xsl:param name="IndividualRef"/>	
	<fo:table-row 
		height="6mm">
		<fo:table-cell 
			border-left-color="black" 
			border-left-style="solid" 
			border-left-width=".1mm" 
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
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
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			padding="2pt">
			<fo:block 
				font-family="sans-serif" 
				font-size="6pt">
				Died
			</fo:block>
		</fo:table-cell>
			
		<xsl:choose>
			<xsl:when test="//EventRec[@Type = 'death' ]/Participant/Link[@Ref = $IndividualRef]">
				<xsl:apply-templates select="//EventRec[@Type = 'death' ]/Participant/Link[@Ref = $IndividualRef]">
					<xsl:with-param name="role" select="'principle'"/>
				</xsl:apply-templates>					
			</xsl:when>
			<xsl:otherwise>
				<fo:table-cell 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding-top="1.5mm">
					<fo:block 
						font-family="sans-serif" 
						font-size="10pt">	
					</fo:block>	
				</fo:table-cell>
				<fo:table-cell 
					border-left-color="black" 
					border-left-style="solid" 
					border-left-width=".1mm" 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding="2pt">
						<fo:block 
							font-family="sans-serif" 
							font-size="6pt">
							Place
						</fo:block>
				</fo:table-cell>					
				<fo:table-cell 
					border-right-color="black" 
					border-right-style="solid" 
					border-right-width=".1mm" 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding-top="1.5mm">
					<fo:block 
						font-family="sans-serif" 
						font-size="10pt">			
					</fo:block>
				</fo:table-cell>				
			</xsl:otherwise>				
		</xsl:choose>			
	</fo:table-row>
</xsl:template>


<xsl:template name="buried">
	<xsl:param name="IndividualRef"/>
	<!-- this variable is used to label each child with a number -->
	<xsl:param name="count"/>
	<fo:table-row 
		height="6mm">
		<fo:table-cell 
			border-left-color="black" 
			border-left-style="solid" 
			border-left-width=".1mm" 
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			padding-top="2mm"
			padding-left="2mm">
			<fo:block 
				font-family="sans-serif" 
				font-size="8pt">
				<xsl:if test="$count">
					<xsl:value-of select="$count"/>
				</xsl:if>
			</fo:block>
		</fo:table-cell>
		<fo:table-cell 
			border-left-color="black" 
			border-left-style="solid" 
			border-left-width=".1mm" 
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			padding="2pt">
			<fo:block 
				font-family="sans-serif" 
				font-size="6pt">
				Buried
			</fo:block>
		</fo:table-cell>
			
		<xsl:choose>
			<xsl:when test="//EventRec[@Type = 'burial' ]/Participant/Link[@Ref = $IndividualRef]">
				<xsl:apply-templates select="//EventRec[@Type = 'burial' ]/Participant/Link[@Ref = $IndividualRef]">
					<xsl:with-param name="role" select="'principle'"/>
				</xsl:apply-templates>					
			</xsl:when>
			<xsl:otherwise>
				<fo:table-cell 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding-top="1.5mm">
					<fo:block 
						font-family="sans-serif" 
						font-size="10pt">	
					</fo:block>	
				</fo:table-cell>
				<fo:table-cell 
					border-left-color="black" 
					border-left-style="solid" 
					border-left-width=".1mm" 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding="2pt">
						<fo:block 
							font-family="sans-serif" 
							font-size="6pt">
							Place
						</fo:block>
				</fo:table-cell>					
				<fo:table-cell 
					border-right-color="black" 
					border-right-style="solid" 
					border-right-width=".1mm" 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding-top="1.5mm">
					<fo:block 
						font-family="sans-serif" 
						font-size="10pt">			
					</fo:block>
				</fo:table-cell>				
			</xsl:otherwise>				
		</xsl:choose>			
	</fo:table-row>

</xsl:template>

<xsl:template name="married">
	<xsl:param name="role"/>
	<xsl:param name="IndividualRef"/>	
	
	<fo:table-row 
		height="6mm">
		<fo:table-cell 
			border-left-color="black" 
			border-left-style="solid" 
			border-left-width=".1mm" 
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
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
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			padding="2pt">
			<fo:block 
				font-family="sans-serif" 
				font-size="6pt">
				Married
			</fo:block>
		</fo:table-cell>
			
		<xsl:choose>
			<xsl:when test="//EventRec[@Type = 'marriage' ]/Participant/Link[@Ref = $IndividualRef]">
				<xsl:apply-templates select="//EventRec[@Type = 'marriage' ]/Participant/Link[@Ref = $IndividualRef]">
					<xsl:with-param name="role" select="husband"/>
				</xsl:apply-templates>					
			</xsl:when>
			<xsl:otherwise>
				<fo:table-cell 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding-top="1.5mm">
					<fo:block 
						font-family="sans-serif" 
						font-size="10pt">	
					</fo:block>	
				</fo:table-cell>
				<fo:table-cell 
					border-left-color="black" 
					border-left-style="solid" 
					border-left-width=".1mm" 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding="2pt">
						<fo:block 
							font-family="sans-serif" 
							font-size="6pt">
							Place
						</fo:block>
				</fo:table-cell>					
				<fo:table-cell 
					border-right-color="black" 
					border-right-style="solid" 
					border-right-width=".1mm" 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding-top="1.5mm">
					<fo:block 
						font-family="sans-serif" 
						font-size="10pt">			
					</fo:block>
				</fo:table-cell>				
			</xsl:otherwise>				
		</xsl:choose>			
	</fo:table-row>
</xsl:template>

<xsl:template name="parents">
	<xsl:param name="IndividualRef"/>
	<xsl:param name="role"/>

	<fo:table>
		<fo:table-column column-width="6mm"/>
		<fo:table-column column-width="28mm"/>				
		<fo:table-column column-width="60mm"/>
		<fo:table-column column-width="10mm"/>
		<fo:table-column column-width="76mm"/>
		<fo:table-body>
					
			<xsl:choose>
				<xsl:when test="//FamilyRec/Child/Link[@Ref=$IndividualRef]">
					<xsl:apply-templates select="//FamilyRec/Child/Link[@Ref=$IndividualRef]" mode="parents">
						<xsl:with-param name="role" select="$role"/>
					</xsl:apply-templates>					
				</xsl:when>
				
				<xsl:otherwise>
					<xsl:call-template name="blankParents">
						<xsl:with-param name="role" select="$role"/>
					</xsl:call-template>
				</xsl:otherwise>				
			</xsl:choose>
	
		</fo:table-body>
	</fo:table>
</xsl:template>


<xsl:template match="Link" mode="parents">
	<xsl:param name="role" select="'Husband'"/>

	<xsl:variable name="fatherID" select="../../HusbFath/Link/@Ref"/>
	<xsl:variable name="motherID" select="../../WifeMoth/Link/@Ref"/>
		
	<!-- Spouse's Father-->
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
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			padding-top="1.5mm"
			padding-left="1mm">
			<fo:block
				font-family="sans-serif"
				font-size="6pt">
				<xsl:value-of select="$role"/>&#8217;s father
			</fo:block>
			<fo:block 
				font-family="sans-serif"
				font-size="6pt">
				Given name(s)
			</fo:block>
		</fo:table-cell>
		
		<fo:table-cell 
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm">
			<fo:block 
				font-family="sans-serif" 
				font-size="10pt"
				padding-top="1.5mm">
				<xsl:value-of select="//IndividualRec[@Id=$fatherID]/IndivName/NamePart[@Level = '3']"/>
			</fo:block>
		</fo:table-cell>					
		<fo:table-cell 
			border-left-color="black" 
			border-left-style="solid" 
			border-left-width=".1mm" 
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			padding-top=".3mm"
			padding-left="1mm">
			<fo:block 
				font-family="sans-serif"
				font-size="8pt">
				Last
			</fo:block>
			<fo:block 
				font-family="sans-serif"
				font-size="8pt">
				name
			</fo:block>
		</fo:table-cell>
		<fo:table-cell  
			border-right-color="black" 
			border-right-style="solid" 
			border-right-width=".1mm" 
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			padding-top="1.5mm">
			<fo:block 
				font-family="sans-serif" 
				font-size="10pt">
				<xsl:value-of select="//IndividualRec[@Id=$fatherID]/IndivName/NamePart[@Level = '1']"/>
			</fo:block>
		</fo:table-cell>					
	</fo:table-row>
	
	<!-- Spouse's Mother -->
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
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			padding-top="1.5mm"
			padding-left="1mm">
			<fo:block
				font-family="sans-serif"
				font-size="6pt">
				<xsl:value-of select="$role"/>&#8217;s mother
			</fo:block>
			<fo:block 
				font-family="sans-serif"
				font-size="6pt">
				Given name(s)
			</fo:block>
		</fo:table-cell>
		<fo:table-cell 
			border-right-color="black" 
			border-right-style="solid" 
			border-right-width=".1mm" 
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			padding-top="1.5mm">
			<fo:block 
				font-family="sans-serif" 
				font-size="10pt">
				<xsl:value-of select="//IndividualRec[@Id=$motherID]/IndivName/NamePart[@Level = '3']"/>
			</fo:block>
		</fo:table-cell>
		<fo:table-cell 
			border-left-color="black" 
			border-left-style="solid" 
			border-left-width=".1mm" 
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			padding-top=".1mm"
			padding-left="1mm">
			<fo:block 
				font-family="sans-serif"
				font-size="6pt">
				Maiden
			</fo:block>
			<fo:block 
				font-family="sans-serif"
				font-size="6pt">
				name
			</fo:block>
		</fo:table-cell>
		<fo:table-cell  
			border-right-color="black" 
			border-right-style="solid" 
			border-right-width=".1mm" 
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			padding-top="1.5mm">
			<fo:block 
				font-family="sans-serif" 
				font-size="10pt">
				<xsl:value-of select="//IndividualRec[@Id=$motherID]/IndivName/NamePart[@Level = '2']"/>
			</fo:block>
		</fo:table-cell>
	</fo:table-row>	
</xsl:template>


<xsl:template name="blankParents">
	<xsl:param name="role" select="'Husband'"/>
	
	<!-- Spouse's Father -->
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
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			padding-top="1.5mm"
			padding-left="1mm">
			<fo:block
				font-family="sans-serif"
				font-size="6pt">
				<xsl:value-of select="$role"/>&#8217;s father
			</fo:block>
			<fo:block 
				font-family="sans-serif"
				font-size="6pt">
				Given name(s)
			</fo:block>
		</fo:table-cell>
		
		<fo:table-cell 
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm">
			<fo:block 
				font-family="sans-serif" 
				font-size="10pt"
				padding-top="1.5mm">

			</fo:block>
		</fo:table-cell>					
		<fo:table-cell 
			border-left-color="black" 
			border-left-style="solid" 
			border-left-width=".1mm" 
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			padding-top=".3mm"
			padding-left="1mm">
			<fo:block 
				font-family="sans-serif"
				font-size="8pt">
				Last
			</fo:block>
			<fo:block 
				font-family="sans-serif"
				font-size="8pt">
				name
			</fo:block>
		</fo:table-cell>
		<fo:table-cell  
			border-right-color="black" 
			border-right-style="solid" 
			border-right-width=".1mm" 
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			padding-top="1.5mm">
			<fo:block 
				font-family="sans-serif" 
				font-size="10pt">

			</fo:block>
		</fo:table-cell>					
	</fo:table-row>
	<!-- Spouse's mother-->
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
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			padding-top="1.5mm"
			padding-left="1mm">
			<fo:block
				font-family="sans-serif"
				font-size="6pt">
				<xsl:value-of select="$role"/>&#8217;s mother
			</fo:block>
			<fo:block 
				font-family="sans-serif"
				font-size="6pt">
				Given name(s)
			</fo:block>
		</fo:table-cell>
		<fo:table-cell 
			border-right-color="black" 
			border-right-style="solid" 
			border-right-width=".1mm" 
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			padding-top="1.5mm">
			<fo:block 
				font-family="sans-serif" 
				font-size="10pt">
			</fo:block>
		</fo:table-cell>
		<fo:table-cell 
			border-left-color="black" 
			border-left-style="solid" 
			border-left-width=".1mm" 
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			padding-top=".1mm"
			padding-left="1mm">
			<fo:block 
				font-family="sans-serif"
				font-size="6pt">
				Maiden
			</fo:block>
			<fo:block 
				font-family="sans-serif"
				font-size="6pt">
				name
			</fo:block>
		</fo:table-cell>
		<fo:table-cell  
			border-right-color="black" 
			border-right-style="solid" 
			border-right-width=".1mm" 
			border-top-color="black" 
			border-top-style="solid" 
			border-top-width=".1mm"
			padding-top="1.5mm">
			<fo:block 
				font-family="sans-serif" 
				font-size="10pt">
			</fo:block>
		</fo:table-cell>
	</fo:table-row>
</xsl:template>

<xsl:template name="blankChildSpouse">

	<!-- Child Spouse-->
	<fo:table>
		<fo:table-column column-width="6mm"/>
		<fo:table-column column-width="23mm"/>
		<fo:table-column column-width="66mm"/>
		<fo:table-column column-width="10mm"/>
		<fo:table-column column-width="75mm"/>
		<fo:table-body>
			<fo:table-row 
				height="6mm">
				<fo:table-cell 
					border-left-color="black" 
					border-left-style="solid" 
					border-left-width=".1mm" 
					padding-top=".1mm"
					padding-left="1mm">
					<fo:block 
						font-family="sans-serif" 
						font-size="10pt">
					</fo:block>
				</fo:table-cell>
				<fo:table-cell 
					border-left-color="black" 
					border-left-style="solid" 
					border-left-width=".1mm" 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding-top=".1mm"
					padding-left="1mm">
					<fo:block 
						font-family="sans-serif"
						font-size="6pt">
						Spouse
					</fo:block>
					<fo:block 
						font-family="sans-serif"
						font-size="6pt">
						Given name(s)
					</fo:block>
				</fo:table-cell>
				<fo:table-cell  
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding-top="1.5mm">
					<fo:block 
						font-family="sans-serif" 
						font-size="10pt">

					</fo:block>
				</fo:table-cell>
				<fo:table-cell 
					border-left-color="black" 
					border-left-style="solid" 
					border-left-width=".1mm" 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding-top=".1mm"
					padding-left="1mm">
					<fo:block 
						font-family="sans-serif"
						font-size="6pt">
						Last
					</fo:block>
					<fo:block 
						font-family="sans-serif"
						font-size="6pt">
						name
					</fo:block>
				</fo:table-cell>
				<fo:table-cell  
					border-right-color="black" 
					border-right-style="solid" 
					border-right-width=".1mm" 
					border-top-color="black" 
					border-top-style="solid" 
					border-top-width=".1mm"
					padding-top="1.5mm">
					<fo:block 
						font-family="sans-serif" 
						font-size="10pt">

					</fo:block>
				</fo:table-cell>
			</fo:table-row>
		</fo:table-body>
	</fo:table>
</xsl:template>

</xsl:stylesheet>
