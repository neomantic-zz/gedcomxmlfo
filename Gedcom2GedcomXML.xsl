<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<!-- 
 ******************************************************************************
 ******************************************************************************
    Copyright � 2004 Chad Albers
     
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
 <!-- ************************************************************************
 	This file contains excerpts from "The GEDCOM Standard Release 5.5"
 	copyrighted by the The Church of Jesus Christ of Latter-day Saints, the
 	10 January 1996 version.  The excerpts are for documenation purposes
 	only.
 	
	Copyright � 1987, 1989, 1992, 1993, 1995 by The Church of Jesus Christ
	of Latter-day Saints. 

 ***************************************************************************-->
<!-- $Id$ -->

<xsl:output method="xml" indent="yes"/>
<!-- FIX this global variable doesn't work in the program I am using, 
	however, correct it is in implementation -->
<xsl:param name="FileCreationDate"/>

<!-- TODO
	* implement generic EVEN 
       	* Check in AGE handle
       	* Handle ALIA ?
 -->
<!-- For Debugging -->
<xsl:template match="/">
<!-- <xsl:call-template name="EventRecs"/> -->
	<xsl:apply-templates select="//INDI"/>
</xsl:template>

<!-- **********************************************************************
***************************************************************************

	Root Template

***************************************************************************
************************************************************************ -->
<xsl:template match="real">
	<GEDCOM>
 	<xsl:apply-templates select="//HEAD"/>
 	<xsl:apply-templates select="//FAM"/>
 	
 	<xsl:apply-templates select="//INDI"/>
 	<xsl:call-template name="makeDummyIndividualRec"/>
	
	<!-- EventRecs -->
 	<xsl:call-template name="EventRecs"/>
	
	<!--  LDSOrdRecs -->
	<xsl:call-template name="LDSOrdRecs"/>
	
	<!-- ContactRec -->
 	<xsl:call-template name="ContactRecs"/>
 	
	<!-- SourceRec  -->
	<xsl:call-template name="SourceRecs"/>

	
	<!-- RepositoryRec -->
	<xsl:apply-templates select="//REPO"/>
	<xsl:call-template name="makeDummyRepositoryRec"/>
	
	<!-- Not creating any GroupRec because there is no equivalent in GEDCOM 5.5 -->

 	</GEDCOM>
</xsl:template>

<!-- **********************************************************************
***************************************************************************
**																		 **
**	Templates Related to the Header and its associated elements			 ** 												
**		* HEAD -> <HeaderRec>											 **
**		* SOUR -> <FileCreation>										 **
**		* DATA -> <Caption>											 	 **
**																		 **
***************************************************************************
*********************************************************************** -->
 
<!-- **********************************************************************
***************************************************************************

	HEAD Template to create HeaderRec

***************************************************************************
************************************************************************ -->
<!-- Some of the mapping here are suspect because the SOUR tag purpose is ambiguous -->
<xsl:template match="HEAD">
	<HeaderRec>
		<!-- Call this template to create the FileCreation Element in case it is needed -->
		<xsl:apply-templates select="SOUR" mode="HeaderRec"/>
		<xsl:if test="SOUR/DATA">
			<Citation>
				<!-- To generate Caption element-->
				<xsl:apply-templates select="SOUR/DATA" mode="HeaderRec"/>
				<xsl:if test="SOUR/DATA/DATE">
					<WhenRecorded>
						<xsl:value-of select="SOUR/DATA/DATE"/>
					</WhenRecorded>
				</xsl:if>
				<xsl:if test="SOUR/DATA/COPR">
					<Note>
						<xsl:text>Copyright:  </xsl:text>
						<xsl:value-of select="SOUR/DATA/COPR"/>
					</Note>
				</xsl:if>
			</Citation>
		</xsl:if>
		
		<xsl:call-template name="Submitter"/>
	</HeaderRec>
</xsl:template> <!-- end Template for HEAD to HeaderRec -->

<!-- **********************************************************************
***************************************************************************

	SOUR Template mode HeaderRec - the SOUR tag that occurs in the 
		HEADER is unlike any of the other SOUR tags, so this templates
		maps its values with valid HeaderRec elements and attributes

***************************************************************************
*********************************************************************** -->
<xsl:template match="SOUR" mode="HeaderRec">
 	<FileCreation>
 		<xsl:attribute name="Date">
 			<!-- DOC Fill Date with global variable -->
			<xsl:value-of select="$FileCreationDate"/>
 		</xsl:attribute>
		<!-- TODO the TIME attribute is option but it can be implement on a contingent basis-->
		<xsl:variable name="theName" select="name(NAME)"/>
		<xsl:if test="NAME or VERS or CORP or DATA/COPR" >
			<!-- Creates Product Element-->
			<Product>
				<!-- DOC mapped SOUR APPROVED_SYSTEM_ID  to ProductId Element -->
				<xsl:variable name="ProductId" select="text()"/>
				<xsl:if test="(string-length( $ProductId )) != 0">
					<ProductId>
						<xsl:value-of select="$ProductId"/>
					</ProductId>
				</xsl:if>
				
				<Version>
					<xsl:value-of select="VERS"/>
				</Version>
								
				<Name>
					<xsl:value-of select="NAME"/>
				</Name>
				
				<xsl:if test="CORP">
					<Supplier>
						<Link>
							<xsl:attribute name="Target">ContactRec</xsl:attribute>
							<xsl:attribute name="Ref">
								<xsl:value-of select="generate-id( CORP )"/>
							</xsl:attribute>
						</Link>
					</Supplier>
				</xsl:if>
				
				<!-- Creates Copyright element-->
				<xsl:if test="../COPR">
					<Copyright>
						<xsl:value-of select="../COPR"/>
					</Copyright>
				</xsl:if>
			</Product>
		</xsl:if>
 	</FileCreation>
</xsl:template>

<!-- **********************************************************************

	DATA Template mode=HeaderRec - creates the Caption element which
	is possibly part of the Citation element in the HeaderRec

************************************************************************ -->
<xsl:template match="DATA" mode="HeaderRec">
	<Caption>
		<xsl:value-of select="text()"/>
	</Caption>
</xsl:template>

<!-- **********************************************************************
***************************************************************************
**																		 **
**	Templates related to the IndividualRecs and its associated elements	 ** 												
**		* INDI -> <IndividualRec>										 **
**		* NAME -> <IndivName>					 						 **
**		* FAMS -> For Wife Husband's Surname							 **
**		* NAME mode=Surname -> For Wife Husband's Surname				 **
**		* CAST, DSCR, EDUC, IDNO, NATI, NCHI, NMR, OCCU, 				 **
**		  PROP, RELI, RESI, SSN, TITL -> <PersInfo>						 **
**		* AGE -> <Note>						 							 **
**										 								 **
***************************************************************************
*********************************************************************** -->

<!-- **********************************************************************
***************************************************************************

	INDI Template to create IndividualRec

***************************************************************************
************************************************************************ -->
<xsl:template match="INDI">
	<IndividualRec>
		<xsl:attribute name="Id">
			<xsl:value-of select="generate-id()"/>
		</xsl:attribute>
		<xsl:apply-templates select="NAME">
			<xsl:with-param name="Gender" select="SEX"/>
		</xsl:apply-templates>
		
		<xsl:if test="SEX">
			<Gender>
				<xsl:value-of select="SEX"/>
			</Gender>
		</xsl:if>

		<xsl:call-template name="persinfo"/>

		<xsl:call-template name="ExternalIDs"/>
		
		 <xsl:call-template name="Submitter"/>
 		
 		<xsl:apply-templates select="NOTE"/>
 				
		<xsl:call-template name="addIndividualEvidence"/>
		
		<xsl:apply-templates select="CHAN"/>
	</IndividualRec>
 </xsl:template><!-- end Template for INDI to IndividualRec -->


<!-- **********************************************************************

	NAME Template for IndivName elements

************************************************************************ -->
<xsl:template match="NAME">
	<xsl:param name="Gender" select="'M'"/><!-- Default to Male-->

	<xsl:variable name="fullname" select="normalize-space( text() )"/>
	
	<IndivName>

 			<xsl:choose>
 			 	<xsl:when test="SURN">
 			 		<xsl:if test="$Gender = 'M' ">
 						<NamePart Type="surname" Level="1">
 							<xsl:value-of select="SURN"/>
 						</NamePart>
 					</xsl:if>
 					<xsl:if test="$Gender= 'F'">
 						<NamePart Type="maiden name" Level="2">
 							<xsl:value-of select="SURN"/>
 						</NamePart> 						
						<xsl:apply-templates select="../FAMS[@REF]"/>
 					</xsl:if>
 				 </xsl:when>
				 
 				 <xsl:otherwise>
 				 	<xsl:if test="$Gender = 'M'">
 				 		<xsl:if test="string-length(substring-before(substring-after($fullname,'/'), '/')) &gt; 0">			
							<NamePart Type="surname" Level="1">
								<xsl:value-of select="substring-before(substring-after($fullname,'/'), '/')"/>			
							</NamePart>
						</xsl:if>
					</xsl:if>
					 <xsl:if test="$Gender = 'F'">
					 	 <xsl:if test="string-length(substring-before(substring-after($fullname,'/'), '/')) &gt; 0">			
							<NamePart Type="maiden name" Level="2">
								<xsl:value-of select="substring-before(substring-after($fullname,'/'), '/')"/>			
							</NamePart>
						</xsl:if>
						<xsl:apply-templates select="../FAMS[@REF]"/>
 					</xsl:if>
 				 </xsl:otherwise>
 			</xsl:choose>
 			 			
 			<xsl:choose>
 	 			<xsl:when test="GIVN">
 					<NamePart Type="given name" Level="3">
 						<xsl:value-of select="GIVN"/>
 					</NamePart>
 				</xsl:when>
 				<xsl:otherwise>
 					<xsl:if test="string-length(substring-before($fullname, '/')) &gt; 0">		    			
						<NamePart Type="given name" Level="3">
							<xsl:value-of select="substring-before($fullname, '/')"/>        
						</NamePart>
					</xsl:if>
 				</xsl:otherwise>
 			</xsl:choose>

 					
		    	<xsl:if test="NPFX">
 				<NamePart Type="prefix">
 					<xsl:value-of select="NPFX"/>
 				</NamePart>
 			</xsl:if>
 			
 			<xsl:if test="SPFX">
 				<NamePart Type="surname prefix">
 					<xsl:value-of select="SPFX"/>
 				</NamePart>
 			</xsl:if>

			<xsl:choose>
 				<xsl:when test="NSFX">
	 				<NamePart Type="suffix">
	 					<xsl:value-of select="NSFX"/>
	 				</NamePart>
				</xsl:when>
				<xsl:otherwise>
					<xsl:if test="string-length(substring-after(substring-after($fullname,'/'), '/')) &gt; 0">
						<NamePart Type="suffix">
							<xsl:value-of select="substring-after(substring-after($fullname,'/'), '/')"/>
						</NamePart>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>

 			<xsl:if test="NICK">
 				<NamePart Type="nickname">
 					<xsl:value-of select="normalize-space( NICK )"/>
 				</NamePart>
 			</xsl:if>
	<!-- Would love to find a way to just dump text() into the IndiviName if all the above
		conditionals failed -->

	</IndivName>
</xsl:template>
<!-- **********************************************************************

	FAMS Template for tracing out a female's husband's surname

************************************************************************ -->
<xsl:template match="FAMS[@REF]">
	
	<xsl:variable name="FamID" select="@REF"/>
	
	<xsl:variable name="HusbID" select="//FAM[@ID = $FamID]/HUSB/@REF"/>

	<xsl:if test="$HusbID">
		<NamePart Type="surname" Level="1">
			<xsl:apply-templates select="//INDI[@ID = $HusbID]/NAME" mode="Surname"/>
		</NamePart>
	</xsl:if>
</xsl:template>

<!-- **********************************************************************

	NAME Template which returns on the Surname - for use when INDI is a
		female and the surname of her husband is needed

************************************************************************ -->
<xsl:template match="NAME" mode="Surname">

	<xsl:choose>
		<xsl:when test="SURN">
			<xsl:value-of select="SURN"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:variable name="fullname" select="text()"/>
			<xsl:if test="string-length(.) = 2 + string-length(translate(., '/', ''))">
				<xsl:if test="string-length(substring-before(substring-after($fullname,'/'), '/')) &gt; 0">
					<xsl:if test="contains( surnameDone, 'false' )">
						<NamePart Type="surname" Level="1">
							<xsl:value-of select="substring-before(substring-after($fullname,'/'), '/')"/>			
						</NamePart>
					</xsl:if>
				</xsl:if>
			</xsl:if>		
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>
 
<!-- **********************************************************************

	Persinfo Template - called to generate PersInfo elements

************************************************************************ -->
<xsl:template name="persinfo">
	<xsl:apply-templates select="CAST|DSCR|EDUC|IDNO|NATI|NCHI|NMR|OCCU|PROP|RELI|RESI|SSN|TITL"/>
</xsl:template>

<!-- **********************************************************************
***************************************************************************

	INDIVIDUAL_ATTRIBUTE_STRUCTURE Template - creates PersInfo elements

***************************************************************************
************************************************************************ -->
<xsl:template match="CAST|DSCR|EDUC|IDNO|NATI|NCHI|NMR|OCCU|PROP|RELI|RESI|SSN|TITL">
	<xsl:variable name="tag" select="name()"/>
	
	<xsl:variable name="Attribute">
		<xsl:if test="$tag = 'CAST'">
			<xsl:value-of select="'caste'"/>
		</xsl:if>
		<xsl:if test="$tag = 'DSCR'">
			<xsl:value-of select="'description'"/>
		</xsl:if>
		<xsl:if test="$tag = 'EDUC'">
			<xsl:value-of select="'education'"/>
		</xsl:if>
		<xsl:if test="$tag = 'IDNO'">
			<xsl:value-of select="'identification number'"/>
		</xsl:if>
		<xsl:if test="$tag = 'NATI'">
			<xsl:value-of select="'nationality'"/>
		</xsl:if>
		<xsl:if test="$tag = 'NCHI'">
			<xsl:value-of select="'children'"/>
		</xsl:if>
		<xsl:if test="$tag = 'NMR'">
			<xsl:value-of select="'marriage'"/>
		</xsl:if>
		<xsl:if test="$tag = 'OCCU'">
			<xsl:value-of select="'occupation'"/>
		</xsl:if>
		<xsl:if test="$tag = 'PROP'">
			<xsl:value-of select="'property'"/>
		</xsl:if>
		<xsl:if test="$tag = 'RELI'">
			<xsl:value-of select="'religion'"/>
		</xsl:if>
		<xsl:if test="$tag = 'RESI'">
			<xsl:value-of select="'residence'"/>
		</xsl:if>
		<xsl:if test="$tag = 'SSN'">
			<xsl:value-of select="'social security number'"/>
		</xsl:if>
		<!-- FIX? This Probably belongs in the name structure-->
		<xsl:if test="$tag = 'TITL'">
			<xsl:value-of select="'title'"/>
		</xsl:if>
	</xsl:variable>
	
	<PersInfo>
		<xsl:attribute name="Type">
			<xsl:value-of select="$Attribute"/>
		</xsl:attribute>
		<Information>
			<xsl:value-of select="text()"/>
		</Information>
		
		<xsl:apply-templates select="DATE"/>

		<xsl:call-template name="addEventPlace"/>
		
		<xsl:call-template name="addEventEvidence"/>
	</PersInfo>
</xsl:template>

<!-- **********************************************************************
***************************************************************************
**																		 **
**	Templates applicable to Individual, Family, and LDS Events	 		 **													 										
**		* AGE -> <Age>													 **
**		* CAUS -> <Note>
**		* addEventPlace -> PLAC+ADDR=<Place>					 **
**	 	* PLAC -> 												 **
**		* ADDR -> <PlacePart>							 **
**																		 **
***************************************************************************
*********************************************************************** -->

<!-- **********************************************************************

	EventRecs Template - call templates that create individual, family
	and LDS EventRecs

************************************************************************ -->
<xsl:template name="EventRecs">
 	<!-- INDIVIDUAL_EVENT_STRUCTURE -->
 	<!-- Both BIRT and ADOP are handled separately because  GEDCOM 5.5 allows to add other participants 
 		besides the principles to the event -->
 	<xsl:apply-templates select="//INDI/BIRT"/>
 	<xsl:apply-templates select="//INDI/ADOP"/>
 	<xsl:apply-templates select="
//INDI/DEAT|
//INDI/CHR|
//INDI/BURI|
//INDI/CREM|
//INDI/BAPM|
//INDI/BARM|
//INDI/BASM|
//INDI/BLES|
//INDI/CHRA|
//INDI/CONF|
//INDI/FCOM|
//INDI/ORDN|
//INDI/NATU|
//INDI/EMIG|
//INDI/IMMI|
//INDI/CENS|
//INDI/PROB|
//INDI/WILL|
//INDI/GRAD|
//INDI/RETI" mode="Individual"/>
	
	<!-- FAMILY_EVENT_STRUCTURE -->
	<xsl:apply-templates select="//FAM/ANUL|
//FAM/CENS|
//FAM/DIV|
//FAM/DIVF|
//FAM/ENGA|
//FAM/MARR|
//FAM/MARB|
//FAM/MARC|
//FAM/MARL|
//FAM/MARS" mode="Family"/>

	<xsl:apply-templates select="//INDI/EVEN" mode="Individual"/>
	<xsl:apply-templates select="//FAM/EVEN" mode="Family"/>

</xsl:template><!-- end EventRecs template -->

<!-- **********************************************************************

	AGE Template for Events

************************************************************************ -->
<xsl:template match="AGE">
	<Age>
		<xsl:value-of select="."/>
	</Age>
</xsl:template>

<!-- **********************************************************************

	CAUS Template - GEDCOM 6.0 XML eliminates this tag, but it is important
		information.  To include with a individual it is surronded by a
		Note element 

************************************************************************ -->
<!-- TODO - make sure this template gets called -->
<xsl:template match="CAUS">
 	<Note><xsl:text>Cause of death:  </xsl:text>
 		<xsl:value-of select="."/>
 	</Note>
</xsl:template>

<!-- **********************************************************************

	addEventPlace Template - GEDCOM 5.5 can have 2 place elements
		in an EVENT_DETAIL:  PLAC and ADDR.  GEDCOM 6.0 XML
		can only have one Place element.  This template attempts
		to combine PLAC and ADDR in one Place Element

************************************************************************ -->

<xsl:template name="addEventPlace">
	<xsl:choose>
		<!-- 
		 This is not the most ideal solution.  The following GEDCOM 5.5
		 data:
		 2 PLAC Placename, City, Township, County, State, Country
		 2 ADDR AddrPlacename
		    3 ADR1 Street
		    3 CITY City
		    3 STAE State
		 2 PHON 555-555-555
		 
		 will look like this
		 <Place>
		 	<PlaceName>Placename, City, Township, County, State, Country AddrPlacename
		 		<PlacePart>Street
		 		</PlacePart>
		 		<PlacePart>City
		 		</PlacePart>
		 		<PlacePart>State
		 		</PlacePart>
		 	</PlaceName>
		 </Place>
		The reason I choose this implementation is because I wanted to preserve the Township and County
		data.  Perhaps another implemantion would utilize the FORM tag
		-->
		<xsl:when test="PLAC and ADDR">
			<Place>
				<PlaceName>
					<xsl:apply-templates select="PLAC"/>
					<xsl:text> </xsl:text>
					<xsl:apply-templates select="ADDR" mode="Place"/>
				</PlaceName>
			</Place>
		</xsl:when>
		<xsl:when test="PLAC">
			<Place>
				<PlaceName>
					<xsl:apply-templates select="PLAC"/>
				</PlaceName>
			</Place>
		</xsl:when>
		<xsl:when test="ADDR">
			<Place>
				<PlaceName>
					<xsl:apply-templates select="ADDR" mode="Place"/>
				</PlaceName>
			</Place>
		</xsl:when>
	</xsl:choose>
</xsl:template>

<!-- **********************************************************************

	PLAC Template - handles a simple PLACE_VALUE of the comma delimited
		form City, Township, County, State, USA - without breaking it 
		down into PlaceParts

************************************************************************ -->
<!-- TODO? it may be possible to breakdown the above info into PlaceName 
	elements given the HEAD's FORM PLACE_HIERARCHY value -->
<xsl:template match="PLAC">
	<xsl:call-template name="handleCONCT"/>	

</xsl:template>

<!-- **********************************************************************
***************************************************************************

	ADDR Template mode=Place - Handles ADDR which occur in INDI, OBJE and
		SOUR tags.  Since the MailAddress element can only occur
		inside the GroupRec and the ContactRec and these cannot be link to
		in the other Recs, ADDRESS_STRUCTURE data is tagged using the
		<Place>, <PlaceName>, and <PlacePart> elements.
		
***************************************************************************
************************************************************************ -->
<!-- DOC Again this isn't the most ideal solution for handling this GEDCOM 5.5 structure:
  n  ADDR <ADDRESS_LINE>  {0:1}
    +1 CONT <ADDRESS_LINE>  {0:M}
    +1 ADR1 <ADDRESS_LINE1>  {0:1}
    +1 ADR2 <ADDRESS_LINE2>  {0:1}
    +1 CITY <ADDRESS_CITY>  {0:1}
    +1 STAE <ADDRESS_STATE>  {0:1}
    +1 POST <ADDRESS_POSTAL_CODE>  {0:1}
    +1 CTRY <ADDRESS_COUNTRY>  {0:1}
  n  PHON <PHONE_NUMBER>
  
  FIX - The first problem is with the first line.  The contents of a ADDR field
  may be the name of a building "Springfield Hospital" or person's name
  "Homer Simpson."  It could also be a mere street address. 
  
  The following template assumes that ADDR <ADDRESS_LINE> actually specifies a 
  building name, business name, or personal name and places this data inside
  the <PlaceName> element which permits both PCDATA and PlacePart elements.
  
  DOC The second problem involves the PHON tag.  There is no equivalent in a <Place> element.  
 
-->
<xsl:template match="ADDR" mode="Place">

	<xsl:value-of select="text()"/>
	<xsl:apply-templates select="CONT" mode="Place"/>
	
	 <xsl:for-each select="node()">
		<xsl:choose>
	 		<xsl:when test="self::ADR1">
	 				<!-- DOC street name is not localized -->
	 			<PlacePart Level="7" Type="street name">
	 				<xsl:value-of select="self::ADR1"/>
	 			</PlacePart>					
	 		</xsl:when>
	 		<xsl:when test="self::ADR2">
	 			<PlacePart Level="6" Type="street name">
	 				<xsl:value-of select="self::ADR2"/>
				</PlacePart>
	 		</xsl:when>
			<xsl:when test="self::CITY">
	 			<PlacePart Level="4" Type="city">
					<xsl:value-of select="self::CITY"/>
	 			</PlacePart>					
	 		</xsl:when>
			<xsl:when test="self::STAE">
	 			<PlacePart Level="2" Type="state">
	 				<xsl:value-of select="self::STAE"/>
	 			</PlacePart>
			</xsl:when>
 			<xsl:when test="self::POST">
 				<PlacePart Level="5" Type="postal code">
 					<xsl:value-of select="self::POST"/>
 				</PlacePart> 					
 			</xsl:when>
			<xsl:when test="self::CTRY">
 				<PlacePart Level="1" Type="country">
 					<xsl:value-of select="self::CTRY"/>
 				</PlacePart>
 			</xsl:when>
 		</xsl:choose>
 	</xsl:for-each>
</xsl:template>
 
 <!-- **********************************************************************

	CONT Template mode=Place - handles the CONT tag that may occur
		in the ADDR line of a ADDRESS_STRUCTURE.  But since it is the context
		of a Place element it simply padds each ADDR's CONT line with a 
		whitespace

*********************************************************************** -->
<xsl:template match="CONT" mode="Place">
 	<!-- Pad with space between content of ADDR and CONT and other CONT tags-->
 	<xsl:text> </xsl:text>
 	<xsl:value-of select="."/>
</xsl:template>

<!-- **********************************************************************
***************************************************************************
**																		 **
**	Templates related to the Individual Events and its associated		 **
**  elements	 														 ** 												
**		* DEAT, CHR, BURI, CREM, BAPM, BARM, BASM, BLES, CHRA,			 **
**	  	  CONF, FCOM, ORDN, NATU, EMIG, IMMI, CENS, PROB,				 **
**		  WILL, GRAD, RETI  -> <EventRec>								 **
**		* BIRT -> <EventRec>											 **
**	 	* ADOP -> <EventRec>											 **
**		* FAMC -> <Participants> in birth and adoption events			 **
**		* EVEN ->  <EventRect>
**																				 **
***************************************************************************
*********************************************************************** -->

<!-- **********************************************************************
***************************************************************************

	INDIVIDUAL_EVENT_STRUCTURE Template - creates all individual events 
	except BIRTand ADOP

***************************************************************************
************************************************************************ -->
<xsl:template match="DEAT|CHR|BURI|CREM|BAPM|BARM|BASM|BLES|CHRA|CONF|FCOM|ORDN|NATU|EMIG|IMMI|CENS|PROB|WILL|GRAD|RETI"
 mode="Individual">
 <!-- Added mode because of the CENS tag which can also be a Family Event -->
 	<xsl:variable name="tag" select="name()"/>
 	
 	<EventRec>
 		<xsl:attribute name="Id">
 			<xsl:value-of select="generate-id()"/>
 		</xsl:attribute>
		
		<!-- Set #REQUIRED Attribute Type -->
 		<xsl:attribute name="Type">
			<xsl:if test="$tag = 'DEAT'">
				<xsl:value-of select="'death'"/>
			</xsl:if>
			<xsl:if test="$tag = 'CHR'">
				<xsl:value-of select="'christening'"/>
			</xsl:if>
			<xsl:if test="$tag = 'BURI'">
				<xsl:value-of select="'burial'"/>
			</xsl:if>
			<xsl:if test="$tag = 'CREM'">
				<xsl:value-of select="'cremation'"/>
			</xsl:if>
			<xsl:if test="$tag = 'BAPM'">
				<xsl:value-of select="'baptism'"/>
			</xsl:if>
			<xsl:if test="$tag = 'BARM'">
				<xsl:value-of select="'bar mitzvah'"/>
			</xsl:if>
			<xsl:if test="$tag = 'BASM'">
				<xsl:value-of select="'bas mitzvah'"/>
			</xsl:if>
			<xsl:if test="$tag = 'BLES'">
				<xsl:value-of select="'blessing'"/>
			</xsl:if>
			<xsl:if test="$tag = 'CHRA'">
				<xsl:value-of select="'adult christening'"/>
			</xsl:if>
			<xsl:if test="$tag = 'CONF'">
				<xsl:value-of select="'confirmation'"/>
			</xsl:if>
			<xsl:if test="$tag = 'FCOM'">
				<xsl:value-of select="'first communion'"/>
			</xsl:if>
			<xsl:if test="$tag = 'ORDN'">
				<xsl:value-of select="'ordination'"/>
			</xsl:if>
			<xsl:if test="$tag = 'NATU'">
				<xsl:value-of select="'naturalization'"/>
			</xsl:if>
			<xsl:if test="$tag = 'EMIG'">
				<xsl:value-of select="'emigration'"/>
			</xsl:if>
			<xsl:if test="$tag = 'IMMI'">
				<xsl:value-of select="'immigration'"/>
			</xsl:if>
			<xsl:if test="$tag = 'CENS'">
				<xsl:value-of select="'census'"/>
			</xsl:if>
			<xsl:if test="$tag = 'PROB'">
				<xsl:value-of select="'probate'"/>
			</xsl:if>
			<xsl:if test="$tag = 'WILL'">
				<xsl:value-of select="'will'"/>
			</xsl:if>
			<xsl:if test="$tag = 'GRAD'">
				<xsl:value-of select="'graduation'"/>
			</xsl:if>
			<xsl:if test="$tag = 'RETI'">
				<xsl:value-of select="'retirement'"/>
			</xsl:if>
 		</xsl:attribute>
 	
		<!-- Set #IMPLIED VitalType Attribute if it is necessary -->
		<xsl:if test="$tag = 'DEAT'">
			<xsl:attribute name="VitalType"><xsl:value-of select="'death'"/></xsl:attribute>
		</xsl:if>
		<xsl:if test="$tag = 'BURI'">
			<xsl:attribute name="VitalType"><xsl:value-of select="'death'"/></xsl:attribute>
		</xsl:if>
		<xsl:if test="$tag = 'CREM'">
			<xsl:attribute name="VitalType"><xsl:value-of select="'death'"/></xsl:attribute>
		</xsl:if>
 
 		<Participant>
 			<Link>
 				<xsl:attribute name="Target">IndividualRec</xsl:attribute>
 				<xsl:attribute name="Ref">
 					<xsl:value-of select="generate-id(..)"/>
 				</xsl:attribute>
 			</Link>
 			<!-- OP pointless element in translation at least -->
 			<Role>principal</Role>
 			<!-- OP I refuse to implement the Living element because it is pointless for the most part
 				and the spec only implies that it is valid only for ordination; that is, only for
				LDS events which can occur after death -->
 			<xsl:apply-templates select="AGE"/>
 		</Participant>
 		
 		
 		<xsl:apply-templates select="DATE"/>
 		
 		<xsl:call-template name="addEventPlace"/>
 		
 		<xsl:call-template name="Submitter"/>
 		
 		<xsl:apply-templates select="NOTE"/>
 		
 		<xsl:call-template name="addEventEvidence"/>
 		
 		<!-- Since this event is created from the INDI record we assign this the same
				Change element as it has -->
		<xsl:apply-templates select="../CHAN"/>
 	</EventRec>
</xsl:template>
 

<!-- **********************************************************************

	BIRT Template

************************************************************************ -->
 <!-- DOC  - it handles BIRT event including bio mom -->
<xsl:template match="BIRT">
 	<EventRec>
 		<xsl:attribute name="Id">
 			<xsl:value-of select="generate-id()"/>
 		</xsl:attribute>
 		<xsl:attribute name="Type">birth</xsl:attribute>
 		<xsl:attribute name="VitalType">birth</xsl:attribute>
 		<Participant>
			<Link>
				<xsl:attribute name="Target">IndividualRec</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:value-of select="generate-id(..)"/>
				</xsl:attribute>
			</Link>
			<Role>child</Role>
		</Participant>
	
		<xsl:apply-templates select="../FAMC" mode="BirthEvent"/>

		<xsl:apply-templates select="DATE"/>

		<xsl:call-template name="addEventPlace"/>

 		<xsl:call-template name="Submitter"/>
		<xsl:apply-templates select="NOTE"/>
		<xsl:call-template name="addEventEvidence"/>
			<!-- Since this event is created from the INDI record we assign this the same
				Change element as it has -->
		<xsl:apply-templates select="../CHAN"/>
 	</EventRec>
</xsl:template><!-- End BIRT template -->

<!-- **********************************************************************

	FAMC Template mode="BirthEvent" - handler meant to identify mother at
		the birth event

************************************************************************ -->
<!-- DOC? Althougth the FAMC has been eliminated from GEDCOM XML 6.0, it will
	be helpful to locate other participants of a birth event.  The only 
	guaranteed participant at this event would be the mother.  Although
 	the husband made the birth (he or his sperm was/were definitely
	participant(s) at conception), the  father may be absent from the event
	of the birth.  One drawback with this approach is that a birth of a father's
	child does not show up in the record of there life events.  There is one
	important caveat.  A child may have several mothers: one and only one biological
	and several mothers by adoption -->
<xsl:template match="FAMC" mode="BirthEvent">
	<xsl:variable name="FamilyID" select="@REF"/>
	
	<xsl:variable name="pedigree" select="PEDI"/>
	<xsl:if test="not( contains( $pedigree, 'adopted'))">
		<xsl:if test="//FAM[@ID=$FamilyID]/WIFE">
			<xsl:variable name="MotherID" select="//FAM[@ID=$FamilyID]/WIFE/@REF"/>
			<Participant>
				<Link>
					<xsl:attribute name="Target">IndividualRec</xsl:attribute>
					<xsl:attribute name="Ref">
						<xsl:choose>
							<xsl:when test="//INDI[@ID=$MotherID]">
								<xsl:value-of select="generate-id(//INDI[@ID=$MotherID])"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="'IndividualUnknown'"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
				</Link>
				<Role>mother</Role>
			</Participant>
		</xsl:if>
	</xsl:if>
</xsl:template>

<!-- **********************************************************************

	ADOP Template - this templates create an ADOP EventRect and attempts
		to add the adoptive parents at the event, by call the FAMC template
		in AdoptionEvent mode

************************************************************************ -->
 <!-- DOC say how it handles adoption events -->
<xsl:template match="ADOP">
 	<EventRec>
 		<xsl:attribute name="Id">
 			<xsl:value-of select="generate-id()"/>
 		</xsl:attribute>
 		<xsl:attribute name="Type">adoption</xsl:attribute>
 		<Participant>
			<Link>
				<xsl:attribute name="Target">IndividualRec</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:value-of select="generate-id(..)"/>
				</xsl:attribute>
			</Link>
			<Role>child</Role>
		</Participant>
		<!-- Add adoptive parents to the event -->
		<!-- Handles the this tag structure
		 	n ADOP
		 	   +1 FAMC @F2@ 
		 -->
		<xsl:apply-templates select="FAMC" mode="AdoptionEvent"/>


		<xsl:apply-templates select="DATE"/>

		<xsl:call-template name="addEventPlace"/>
		 
 		<xsl:call-template name="Submitter"/>
		<xsl:apply-templates select="NOTE"/>
		<xsl:call-template name="addEventEvidence"/>
			<!-- Since this event is created from the INDI record we assign this the same
				Change element as it has -->
		<xsl:apply-templates select="../CHAN"/>
 	</EventRec>
</xsl:template><!-- End BIRT template -->

<!-- **********************************************************************

	FAMC Template mode=AdoptionEvent - when called from the ADOP template
		this template attempts to add the adoptive parents as the participants
		to this event.  To do so, it test the value of the ADOP tag whose
		valid values are HUSB, WIFE, or BOTH

************************************************************************ -->
<xsl:template match="FAMC" mode="AdoptionEvent">
	<!-- Get Family Ref -->
	<xsl:variable name="FamilyID" select="@REF"/>
	<!-- Get value of ADOP tag under FAMC -->
	<xsl:variable name="AdoptionParents" select="ADOP"/>

	<xsl:if test="contains( $AdoptionParents, 'HUSB')">
		<xsl:variable name="FatherID" select="//FAM[@ID=$FamilyID]/HUSB/@REF"/>
		<Participant>
			<Link>
				<xsl:attribute name="Target">IndividualRec</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:choose>
						<xsl:when test="//INDI[@ID=$FatherID]">
							<xsl:value-of select="generate-id(//INDI[@ID=$FatherID])"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'IndividualUnknown'"/>
						</xsl:otherwise>
					</xsl:choose>				
				</xsl:attribute>
			</Link>
			<Role>father</Role>
		</Participant>
	</xsl:if>
	<xsl:if test="contains( $AdoptionParents, 'WIFE')">
		<xsl:variable name="MotherID" select="//FAM[@ID=$FamilyID]/WIFE/@REF"/>
		<Participant>
			<Link>
				<xsl:attribute name="Target">IndividualRec</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:choose>
						<xsl:when test="//INDI[@ID=$MotherID]">
							<xsl:value-of select="generate-id(//INDI[@ID=$MotherID])"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'IndividualUnknown'"/>
						</xsl:otherwise>
					</xsl:choose>				
				</xsl:attribute>
			</Link>
			<Role>mother</Role>
		</Participant>
	</xsl:if>
	<xsl:if test="contains( $AdoptionParents, 'BOTH')">
		<!-- TODO consolidate reduntant code -->
		<xsl:variable name="FatherID" select="//FAM[@ID=$FamilyID]/HUSB/@REF"/>
		<Participant>
			<Link>
				<xsl:attribute name="Target">IndividualRec</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:choose>
						<xsl:when test="//INDI[@ID=$FatherID]">
							<xsl:value-of select="generate-id(//INDI[@ID=$FatherID])"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'IndividualUnknown'"/>
						</xsl:otherwise>
					</xsl:choose>				
				</xsl:attribute>
			</Link>
			<Role>father</Role>
		</Participant>
		<xsl:variable name="MotherID" select="//FAM[@ID=$FamilyID]/WIFE/@REF"/>
		<Participant>
			<Link>
				<xsl:attribute name="Target">IndividualRec</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:choose>
						<xsl:when test="//INDI[@ID=$MotherID]">
							<xsl:value-of select="generate-id(//INDI[@ID=$MotherID])"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'IndividualUnknown'"/>
						</xsl:otherwise>
					</xsl:choose>				
				</xsl:attribute>
			</Link>
			<Role>mother</Role>
		</Participant>
	</xsl:if>
</xsl:template>

<!-- **********************************************************************

	EVEN Template for Individual Events

************************************************************************ -->
<xsl:template match="EVEN" mode="Individual">
 	<EventRec>
 		 <xsl:attribute name="Id">
 			<xsl:value-of select="generate-id()"/>
 		</xsl:attribute>
 		<xsl:attribute name="Type">
 			<xsl:value-of select="TYPE"/>
 		</xsl:attribute>
 		<Participant>
 			<Link>
 				<xsl:attribute name="Target">IndividualRec</xsl:attribute>
 				<xsl:attribute name="Ref">
					<xsl:value-of select="generate-id(..)"/>
				</xsl:attribute>
				<Role>Principal</Role>
				<xsl:apply-templates select="AGE"/>
 			</Link>
 		</Participant>
 		
 		<xsl:apply-templates select="DATE"/>
 		
 		<xsl:call-template name="addEventPlace"/>
 		
 		<xsl:call-template name="Submitter"/>
 		
 		<xsl:apply-templates select="NOTE"/>
 		
 		<xsl:call-template name="addEventEvidence"/>
 		
 		<!-- Since this event is created from the INDI record we assign this the same
				Change element as it has -->
		<xsl:apply-templates select="../CHAN"/>
 	</EventRec>
</xsl:template>

<!-- **********************************************************************
***************************************************************************
**																		 **
**	Templates related to the Family Events and its associated elements	 ** 												
**		* ANUL, CENS, DIV, DIVF, ENGA, MARR, MARB, 						 **
**		  MARC, MARL, MARS ->  <EventRec>								 **
**		* CHIL -> <Participant>	in divorce and census events			 **
**		* EVEN - <EventRec>
**																		 **
***************************************************************************
*********************************************************************** -->

<!-- **********************************************************************
***************************************************************************

	FAMILY_EVENT_STRUCTURE Template

***************************************************************************
************************************************************************ -->
<xsl:template match="ANUL|CENS|DIV|DIVF|ENGA|MARR|MARB|MARC|MARL|MARS" mode="Family">
 <!-- Added mode because of the CENS tag which can also be a Family Event -->
 	<xsl:variable name="tag" select="name()"/>
   	<EventRec>
 		<xsl:attribute name="Id">
 			<xsl:value-of select="generate-id()"/>
 		</xsl:attribute>
 		<xsl:attribute name="Type">
			<xsl:if test="$tag = 'ANUL'">
				<xsl:value-of select="'annulment'"/>
			</xsl:if>
			<xsl:if test="$tag = 'CENS'">
				<xsl:value-of select="'census'"/>
			</xsl:if>
			<xsl:if test="$tag = 'DIV'">
				<xsl:value-of select="'divorce'"/>
			</xsl:if>
			<xsl:if test="$tag = 'DIVF'">
				<xsl:value-of select="'divorce filed'"/>
			</xsl:if>
			<xsl:if test="$tag = 'ENGA'">
				<xsl:value-of select="'engagement'"/>
			</xsl:if>
			<xsl:if test="$tag = 'MARR'">
				<xsl:value-of select="'marriage'"/>
			</xsl:if>
			<xsl:if test="$tag = 'MARB'">
				<xsl:value-of select="'marriage banns'"/>
			</xsl:if>
			<xsl:if test="$tag = 'MARC'">
				<xsl:value-of select="'marriage contract'"/>
			</xsl:if>
			<xsl:if test="$tag = 'MARL'">
				<xsl:value-of select="'marriage license'"/>
			</xsl:if>
			<xsl:if test="$tag = 'MARS'">
				<xsl:value-of select="'marriage settlement'"/>
			</xsl:if>
 		</xsl:attribute>
		
		<!-- Sets #IMPLIED VitalType attribute if it is possible -->
  		<xsl:if test="$tag = 'ANUL'">
			<xsl:attribute name="VitalType"><xsl:value-of select="'marriage'"/></xsl:attribute>
		</xsl:if>
		<xsl:if test="$tag = 'DIV'">
			<xsl:attribute name="VitalType"><xsl:value-of select="'divorce'"/></xsl:attribute>
		</xsl:if>
		<xsl:if test="$tag = 'MARR'">
			<xsl:attribute name="VitalType"><xsl:value-of select="'marriage'"/></xsl:attribute>
		</xsl:if>
		<xsl:if test="$tag = 'MARB'">
			<xsl:attribute name="VitalType"><xsl:value-of select="'marriage'"/></xsl:attribute>
		</xsl:if>
		<xsl:if test="$tag = 'MARC'">
			<xsl:attribute name="VitalType"><xsl:value-of select="'marriage'"/></xsl:attribute>
		</xsl:if>
		<xsl:if test="$tag = 'MARL'">
			<xsl:attribute name="VitalType"><xsl:value-of select="'marriage'"/></xsl:attribute>
		</xsl:if>
		<xsl:if test="$tag = 'MARS'">
			<xsl:attribute name="VitalType"><xsl:value-of select="'marriage'"/></xsl:attribute>
		</xsl:if>
 		
 	 	
	 	<xsl:if test="../HUSB">
	 		<xsl:variable name="HusbID" select="../HUSB/@REF"/>
 	 		<Participant>
				<Link>
					<xsl:attribute name="Target">IndividualRec</xsl:attribute>
					<xsl:attribute name="Ref">
						<xsl:choose>
							<xsl:when test="//INDI[@ID=$HusbID]">
								<xsl:value-of select="generate-id(//INDI[@ID=$HusbID])"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="IndividualUnknown"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
				</Link>
				<Role>husband</Role>
				<xsl:apply-templates select="HUSB/AGE"/>
			</Participant>
		</xsl:if>
		 <xsl:if test="../WIFE">
		 	<xsl:variable name="WifeID" select="../WIFE/@REF"/>
 	 		<Participant>
				<Link>
					<xsl:attribute name="Target">IndividualRec</xsl:attribute>
					<xsl:attribute name="Ref">
						<xsl:choose>
							<xsl:when test="//INDI[@ID=$WifeID]">
								<xsl:value-of select="generate-id(//INDI[@ID=$WifeID])"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="'IndividualUnknown'"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
				</Link>
				<Role>wife</Role>
				<xsl:apply-templates select="WIFE/AGE"/>
			</Participant>
		</xsl:if>
		<!-- Handle All FAM events that one would need to mention the involvment of children. Of course,
			there could be children preceding the marriage but this situation is difficult to determine
			using GEDCOM 5.5 structures (Theorectically, this may be accounted for if one compares the date
			of the marriage with the date of birth of the children). -->
		<xsl:variable name="NodeName" select="name()"/>
		<xsl:if test="contains($NodeName, 'DIV') or
				contains( $NodeName, 'DIVF') or 
				contains( $NodeName, 'CENS')">
			<xsl:apply-templates select="../CHIL" mode="Events"/>
		</xsl:if>

		<xsl:apply-templates select="DATE"/>
		
		<xsl:call-template name="addEventPlace"/>
		
 		<xsl:call-template name="Submitter"/>
		<xsl:apply-templates select="NOTE"/>
		<xsl:call-template name="addEventEvidence"/>
			<!-- Since this event is created from the FAM record we assign this the same
				Change element as it has -->
		<xsl:apply-templates select="../CHAN"/>
	</EventRec>
</xsl:template>

<!-- **********************************************************************

	CHIL Template mode="Events" - handles child elements in the context
		of creating Family EventRec, of which there are two possibilities:
		CENS and DIV.  The template simply adds them as a Participant
		to the event as well as providing a link to the IndividualRec

*********************************************************************** -->

<xsl:template match="CHIL" mode="Events">
	<xsl:variable name="ChildID" select="CHIL/@REF"/>
	
	<Participant>			
		<Link>
			<xsl:attribute name="Target">IndividualRec</xsl:attribute>
			<xsl:attribute name="Ref">
				<xsl:choose>
					<xsl:when test="//INDI[@ID=$ChildID]">
						<xsl:value-of select="generate-id(//INDI[@ID=$ChildID])"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="'IndividualUnknown'"/>			
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
		</Link>
		<Role>child</Role>
	</Participant>
</xsl:template>

<!-- **********************************************************************

	EVEN Template for Family Events

************************************************************************ -->

<xsl:template match="EVEN" mode="Family">
 	<EventRec>
 		 <xsl:attribute name="Id">
 			<xsl:value-of select="generate-id()"/>
 		</xsl:attribute>
 		<xsl:attribute name="Type">
 			<xsl:value-of select="TYPE"/>
 		</xsl:attribute>
 	 	<xsl:if test="../HUSB">
	 		<xsl:variable name="HusbID" select="../HUSB/@REF"/>
 	 		<Participant>
				<Link>
					<xsl:attribute name="Target">IndividualRec</xsl:attribute>
					<xsl:attribute name="Ref">
						<xsl:choose>
							<xsl:when test="//INDI[@ID=$HusbID]">
								<xsl:value-of select="generate-id(//INDI[@ID=$HusbID])"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="IndividualUnknown"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
				</Link>
				<Role>husband</Role>
				<xsl:apply-templates select="HUSB/AGE"/>
			</Participant>
		</xsl:if>
		 <xsl:if test="../WIFE">
		 	<xsl:variable name="WifeID" select="../WIFE/@REF"/>
 	 		<Participant>
				<Link>
					<xsl:attribute name="Target">IndividualRec</xsl:attribute>
					<xsl:attribute name="Ref">
						<xsl:choose>
							<xsl:when test="//INDI[@ID=$WifeID]">
								<xsl:value-of select="generate-id(//INDI[@ID=$WifeID])"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="'IndividualUnknown'"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
				</Link>
				<Role>wife</Role>
				<xsl:apply-templates select="WIFE/AGE"/>
			</Participant>
		</xsl:if>

		<!-- DOC Assumes that all EVEN that occure in a FAM apply to all children of the FAM -->
		<xsl:apply-templates select="../CHIL" mode="Events"/>

	
 		<xsl:apply-templates select="DATE"/>
 		
 		<xsl:call-template name="addEventPlace"/>
 		
 		<xsl:call-template name="Submitter"/>
 		
 		<xsl:apply-templates select="NOTE"/>
 		
 		<xsl:call-template name="addEventEvidence"/>
 		
 		<!-- Since this event is created from the FAM record we assign this the same
				Change element as it has -->
		<xsl:apply-templates select="../CHAN"/>
 	</EventRec>
</xsl:template> 



<!-- **********************************************************************
***************************************************************************
**																		 **
**	Templates Related to Sources and Evidence and their associated		 **
**		 elements		 												 **
**		* SOUR -> <Evidence>											 **
**		* SOUR[@REF] -> <Evidence>										 **
**		* SOUR[@ID] -> <SourceRec>									 	 **
**		* TITL -> <Title>												 **
**		* AUTH -> <Author>												 **
**		* PUBL -> <Publishing>											 **
**		* OBJE[@REF] -> <Evidence>										 **
**		* OBJE[@ID] -> <SourceRec>										 **
**		* OBJE -> <Evidence>					**
**		* TEXT -> <Extract>						**
**		* addEventEvidence						**
**		* addIndividualEvidence					**
**		* addPersInfoEvidence						**
**										**								 **
***************************************************************************
*********************************************************************** -->

<!-- **********************************************************************


	SourceRecs Template - called to call SOUR and OBJE templates needed to
		create SourceRecs

************************************************************************ -->
<xsl:template name="SourceRecs">
  	<xsl:apply-templates select="//SOUR[@ID]"/>
  	<xsl:apply-templates select="//OBJE[@ID]"/>
  	<xsl:call-template name="makeDummySourceRec"/>
</xsl:template>

<!-- **********************************************************************

	addEventEvidence Template - adds the PLAC sources as Evindence
		to the EventRec

************************************************************************ -->
<xsl:template name="addEventEvidence">
	
	<xsl:apply-templates select="SOUR"/>
	<xsl:apply-templates select="OBJE"/>
	<xsl:apply-templates select="SOUR[@REF]"/>
	<xsl:apply-templates select="OBJE[@REF]"/>
	
	<!-- PLAC appears in the context of an EVENT_DETAIL-->
	<xsl:apply-templates select="PLAC/SOUR">
		<xsl:with-param name="evidenceKind" select="'place'"/>
	</xsl:apply-templates>
	<xsl:apply-templates select="PLAC/SOUR[@REF]">
		<xsl:with-param name="evidenceKind" select="'place'"/>
	</xsl:apply-templates>
	<xsl:apply-templates select="PLAC/SOUR/OBJE">
		<xsl:with-param name="evidenceKind" select="'place'"/>
	</xsl:apply-templates>
	<xsl:apply-templates select="PLAC/SOUR/OBJE[@REF]">
		<xsl:with-param name="evidenceKind" select="'place'"/>
	</xsl:apply-templates>
</xsl:template>



<!-- **********************************************************************

	addIndividualEvidence Template - adds the first level SOUR and OBJE
		and evidence regarding the NAME to the IndividualRec

************************************************************************ -->
<xsl:template name="addIndividualEvidence">

	<xsl:apply-templates select="SOUR"/>
	<xsl:apply-templates select="OBJE"/>

	<!-- Adds Evidence regarding the IndivName -->
	<xsl:apply-templates select="NAME/SOUR">
 		<xsl:with-param name="evidenceKind" select="'the name'"/>
 	</xsl:apply-templates>
 		
 	<xsl:apply-templates select="NAME/SOUR/OBJE">
 		<xsl:with-param name="evidenceKind" select="'the name'"/>
 	</xsl:apply-templates>
</xsl:template>

<!-- **********************************************************************
***************************************************************************

	SOUR Template - Handles simple GEDCOM 5.5 SOUR_CITATION of the form
	
	n SOUR <SOURCE_DESCRIPTION>  {1:1}
    	+1 [ CONC | CONT ] <SOURCE_DESCRIPTION>  {0:M}
		+1 TEXT <TEXT_FROM_SOURCE>  {0:M}
			+2 [CONC | CONT ] <TEXT_FROM_SOURCE>  {0:M}
			+1 <<NOTE_STRUCTURE>>  {0:M}
	
	To handle this tag, the template create Evidence and its associated
		elements

***************************************************************************
************************************************************************ -->
<!-- DOC should note where that the SOURCE_DESCRIPTION has been mapped to Caption Element -->
<xsl:template match="SOUR">
	<xsl:param name="evidenceKind"/>
	<Evidence>
		<Citation>
			<!-- There must be at least a Link element, but nothing to match it to-->
			<Link Ref="SourceUnknown" Target="SourceRec"/>
			
			<Caption>
				<xsl:call-template name="handleCONCT"/>
			</Caption>
			
			<!-- Creates Extract element -->
			<xsl:apply-templates select="TEXT"/>
			<xsl:apply-templates select="NOTE"/>
			<xsl:if test="$evidenceKind != ''">
				<Note>
 					<xsl:text>Evidence regarding </xsl:text>
					<xsl:value-of select="$evidenceKind"/>
				</Note>
			</xsl:if>
			
		</Citation>
 	</Evidence>
</xsl:template>

<!-- **********************************************************************
***************************************************************************

	SOUR[@REF] Template - Handles GEDCOM 5.5 SOUR_CITATION of the form:

	n SOUR @<XREF:SOUR>@    /* pointer to source record */  {1:1}
	  	+1 PAGE <WHERE_WITHIN_SOURCE>  {0:1}
		+1 EVEN <EVENT_TYPE_CITED_FROM>  {0:1}
			+2 ROLE <ROLE_IN_EVENT>  {0:1}
		+1 DATA        {0:1}
			+2 DATE <ENTRY_RECORDING_DATE>  {0:1}
			+2 TEXT <TEXT_FROM_SOURCE>  {0:M}
				+3 [ CONC | CONT ] <TEXT_FROM_SOURCE>  {0:M}
		+1 QUAY <CERTAINTY_ASSESSMENT>  {0:1}
		+1 <<MULTIMEDIA_LINK>>  {0:M}
		+1 <<NOTE_STRUCTURE>>  {0:M}
	
	To handle this tag, the template create Evidence and its associated
		elements

***************************************************************************		
************************************************************************ -->
<!-- DOC Current implementationation discards the valid OBJE or OBJE @O1@ tag inside the SOUR. -->
<!-- DOC should note that QUAY's CERTAINTY_ASSESMENT has been mapped to Note element -->
<xsl:template match="SOUR[@REF]">
	<xsl:param name="evidenceKind"/>
 	<xsl:variable name="SourceID" select="@REF"/>
 	<Evidence>
 		<Citation>
			<Link>
				<xsl:attribute name="Target">SourceRec</xsl:attribute>
 				<xsl:attribute name="Ref">
 					<xsl:choose>
 						<xsl:when test="//SOUR[@ID=$SourceID]">
 							<xsl:value-of select="generate-id(//SOUR[@ID=$SourceID])"/>
 						</xsl:when>
 						<xsl:otherwise>
 							<xsl:value-of select="'SourceUnknown'"/>
 						</xsl:otherwise>
 					</xsl:choose>
 				</xsl:attribute>
 			</Link>

 			<xsl:if test="//SOUR[@ID=$SourceID]/TITL">
				<Caption>
					<xsl:value-of select="//SOUR[@ID=$SourceID]/TITL"/>
				</Caption>
 			</xsl:if>
 			 
 			 <xsl:if test="PAGE">
	  			<WhereInSource>
	 				<xsl:text>Page: </xsl:text>
	 				<xsl:value-of select="PAGE"/>
	 			</WhereInSource>			 
 			 </xsl:if>

 			
 			<!-- DOC no caption element because not clear what to map it to -->
 			<!-- //SOUR[@ID]/DATA/DATE indicates a DATE_PERIOD - FROM date TO date, so this
 				won't be used for a WhenRecorded element -->

			<xsl:if test="DATA/DATE">
				<WhenRecorded>
 					<xsl:value-of select="DATA/DATE"/>
 				</WhenRecorded>			
			</xsl:if>
 
 			
 			<!-- Specific extract from the DATA of the SOUR record -->
 			<xsl:if test="DATA/TEXT">
 				<xsl:apply-templates select="DATA/TEXT"/>
 			</xsl:if>
 			<!-- Since we do not want to loose the TEXT from the 0 @S*@ SOUR, because it
 				is inexplicably not contained in the SourceRec element anymore, the TEXT
 				is now import into the Evidence element -->
 			<xsl:if test="//SOUR[@ID=$SourceID]/TEXT">
 				<xsl:apply-templates select="//SOUR[@ID=$SourceID]/TEXT"/>
 			</xsl:if>		
			<xsl:if test="QUAY">
 				<Note>
 					<xsl:text>The GEDCOM 5.5 quality of this source is:  </xsl:text>
 					<xsl:value-of select="QUAY"/>
 				</Note>
 			</xsl:if>
			<!-- There can be more than one Note element-->
 			<xsl:apply-templates select="NOTE"/>
	
			<xsl:if test="$evidenceKind != ''">
				<Note>
 					<xsl:text>Evidence regarding </xsl:text>
					<xsl:value-of select="$evidenceKind"/>
				</Note>
			</xsl:if>
			
 		</Citation>
	</Evidence>
</xsl:template>

<!-- **********************************************************************
***************************************************************************

	SOUR[@ID] Template - handles SOURCE_RECORD - 0 @S2@ SOUR - and creates
		SourceRecs

***************************************************************************
************************************************************************ -->
<xsl:template match="SOUR[@ID]">
 	<SourceRec>
 		<xsl:attribute name="Id">
			<xsl:value-of select="generate-id()"/>
 		</xsl:attribute>
 		<xsl:apply-templates select="REPO[@REF]"/>
 		<Title>
 		 	<xsl:apply-templates select="TITL"/>
 		</Title>
 		<xsl:apply-templates select="AUTH"/>
 		<xsl:if test="OBJE/FILE">
 			<URI>
 				<xsl:value-of select="OBJE/FILE"/>
 			</URI>
 		</xsl:if>
 		<xsl:apply-templates select="PUBL"/>
 		<xsl:apply-templates select="NOTE"/> 		
 		
 		 <xsl:apply-templates select="CHAN"/>

 	</SourceRec>
</xsl:template>

<!-- **********************************************************************

	TITL Template - despite the same GEDCOM 5.5 occuring as an
		INDIVIDUAL_ATTRIBUTE, this template is intended to handle
		SOURCE_DESCRIPTIVE_TITLE

************************************************************************ -->  
<xsl:template match="TITL">
	<xsl:call-template name="handleCONCT"/>
</xsl:template>

<!-- **********************************************************************

	AUTH Template - creates Author element

*********************************************************************** -->
<xsl:template match="AUTH">
	<Author>
		<xsl:call-template name="handleCONCT"/>
	</Author>
</xsl:template>

<!-- **********************************************************************

	PUBL Template - creates Publishing Element

*********************************************************************** -->
<xsl:template match="PUBL">
	<Publishing>
		<xsl:call-template name="handleCONCT"/>
	</Publishing>
</xsl:template>

  
<!-- **********************************************************************
***************************************************************************

	OBJE[@ID] Template - handles MULTIMEDIA_RECORDs and creates SourceRecs

***************************************************************************
*********************************************************************** -->
<xsl:template match="OBJE[@ID]">
	<SourceRec>
		<xsl:attribute name="Id">
			<xsl:value-of select="generate-id()"/>
		</xsl:attribute>
		<!-- In GEDCOM 5.5 there are only 7 permissible forms:
				bmp, gif, jpeg, ole, pcx, tiff, wav -->
		<xsl:if test="FORM">
			<xsl:attribute name="Type">
				<xsl:value-of select="FORM"/>
			</xsl:attribute>
		</xsl:if>

		<Title>
			<xsl:value-of select="TITL"/>
		</Title>

		<xsl:if test="BLOB">
			<URI>
				<xsl:value-of select="BLOB"/>
			</URI>
		</xsl:if>
		
		<xsl:apply-templates select="NOTE"/>

		<xsl:apply-templates select="CHAN"/>
	</SourceRec>
</xsl:template>

<!-- **********************************************************************
***************************************************************************

	OBJE[@REF] Template - handle MULTIMEDIA_LINKs and creates Evidence
		elements
		
***************************************************************************
*********************************************************************** -->
<xsl:template match="OBJE[@REF]">
	<xsl:param name="evidenceKind"/>
	<xsl:variable name="ObjeID" select="@REF"/>	
	<Evidence>
		<Citation>
			<Link>
				<xsl:attribute name="Target">SourceRec</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:choose>
						<xsl:when test="//OBJE[@ID=$ObjeID]">
							<xsl:value-of select="generate-id(//OBJE[@ID=$ObjeID])"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'SourceUnknown'"/>	
						</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
			</Link>

			<xsl:if test="//OBJE[@ID=$ObjeID]/TITL">
				<Caption>
					<xsl:value-of select="//OBJE[@ID=$ObjeID]/TITL"/>
				</Caption>
			</xsl:if>
			

			<xsl:if test="//OBJE[@ID=$ObjeID]/SOUR[@REF]/DATA/DATE">
				<WhenRecorded>
					<xsl:value-of select="//OBJE[@ID=$ObjeID]/SOUR[@REF]/DATA/DATE"/>
				</WhenRecorded>			
			</xsl:if>

			<xsl:apply-templates select="NOTE"/>
			
			<xsl:if test="$evidenceKind != ''">
				<Note>
 					<xsl:text>Evidence regarding </xsl:text>
					<xsl:value-of select="$evidenceKind"/>
				</Note>
			</xsl:if>
		</Citation>
	</Evidence>
</xsl:template>

<!-- **********************************************************************
***************************************************************************

	OBJE Template - handles MULTIMEDIA_LINKs that are not really links.
	
	n  OBJE           {1:1}
    	+1 FORM <MULTIMEDIA_FORMAT>  {1:1}
		+1 TITL <DESCRIPTIVE_TITLE>  {0:1}
		+1 FILE <MULTIMEDIA_FILE_REFERENCE>  {1:1}
		+1 <<NOTE_STRUCTURE>>  {0:M}

	This template creates the Evidence element and its associates

***************************************************************************
*********************************************************************** -->
<xsl:template match="OBJE">
	<xsl:param name="evidenceKind"/>
	<Evidence>
		<Citation>
			<Link Ref="SourceUnknown" Target="SourceRec"/>
			<xsl:if test="TITL">
				<Caption>
					<xsl:value-of select="TITL"/>
				</Caption>			
			</xsl:if>
			<xsl:apply-templates select="NOTE"/>
			<xsl:if test="$evidenceKind != ''">
				<Note>
 					<xsl:text>Evidence regarding </xsl:text>
					<xsl:value-of select="$evidenceKind"/>
				</Note>
			</xsl:if>
		</Citation>
	</Evidence>
</xsl:template>

<!-- **********************************************************************

	TEXT Template - handles TEXT tag pads CONT and CONC when they are 
		eliminated

*********************************************************************** -->
<xsl:template match="TEXT">
	<Extract>
		<xsl:value-of select="text()"/>
		<xsl:for-each select="node()">
			<xsl:choose>
				<xsl:when test="self::CONT">
					<!-- Insert line break for every CONT-->
					<br/>
					<xsl:value-of select="self::CONT"/>
				</xsl:when>
				<xsl:when test="self::CONC">
					<xsl:text> </xsl:text>
					<xsl:value-of select="self::CONC"/>
				</xsl:when>
			</xsl:choose>
		</xsl:for-each>
	</Extract>
</xsl:template>

<!-- **********************************************************************
***************************************************************************
**										**								 **
**	Templates Related to ContactRecs and its associated elements	**
**		* CORP -> <ContactRec>					**
**		* SUBM[@ID] -> <ContactRec>		           	**
**		* ADDR -> <MailAddress>					**
**		* PHON -> <Phone>						**
**										**								 **
***************************************************************************
*********************************************************************** -->

<!-- **********************************************************************
***************************************************************************
	
	ContactRecs Template - call to create ContactRec elements from the
		//SUBM and //HEAD/SOUR/CORP tags

***************************************************************************
************************************************************************-->
<xsl:template name="ContactRecs">
	<xsl:apply-templates select="//HEAD/SOUR/CORP"/>
  	<xsl:apply-templates select="//SUBM"/>
  	<xsl:call-template name="makeDummyContactRec"/>
</xsl:template>

<!-- **********************************************************************

	CORP Template - generates a ContactRect containing information about
		the product used to create the GEDCOM 5.5 file

*********************************************************************** -->
<xsl:template match="CORP">
	<ContactRec>
		<xsl:attribute name="Id">
			<xsl:value-of select="generate-id()"/>
		</xsl:attribute>
		<xsl:attribute name="Type">business</xsl:attribute>
		<Name>
			<xsl:value-of select="text()"/>
		</Name>
		<!-- This call assumes that the ADDR structure under the CORP tag actually repeats the business' name.
			Since the ADDR structure is one level deeper it would seem to suggest that the ADDR text contains
			a street address in fact.  A with-param could be passed to this template, if it is implemented, but
			there is no way to tell what is the CONT
		-->
		<xsl:apply-templates select="ADDR" mode="MailAddress">
			<xsl:with-param name="PlaceName" select="text()"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="PHON"/>
		<!-- Cannot map any more items of the CORP tag to the ContactRec elements-->
		<!-- DOC -->
		<Public/>
	</ContactRec>
</xsl:template>

<!-- **********************************************************************

	SUBM[@ID] Template - handles the SUBMITTER_RECORD and creates a
		ContactRec

*********************************************************************** -->
<xsl:template match="SUBM[@ID]">
	<ContactRec>
		<xsl:attribute name="Id">
			<xsl:value-of select="generate-id()"/>
		</xsl:attribute>
		<!-- TODO?  implement Type attribute with the following values: person, business, organization -->
		<Name>
			<xsl:value-of select="NAME"/>
		</Name>
		<xsl:apply-templates select="ADDR" mode="MailAddress">
			<xsl:with-param name="PlaceName" select="NAME"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="PHON"/>
		
		<!-- Handle OBJE hits as either a <Evidence> Element or as a SourceRec link -->
		<xsl:apply-templates select="OBJE"/>
		
		<xsl:apply-templates select="NOTE"/>
		
 		
 		<xsl:apply-templates select="CHAN"/>
	</ContactRec>
</xsl:template>

<!-- **********************************************************************
***************************************************************************

	ADDR Template mode=MailAddress - creates the MailAddress element and its
		associated elements.  MailAddress is pretty limited and can only
		occur inside a GroupRec or ContactRec.  

***************************************************************************
************************************************************************ -->
<!-- DOC This does not handle the PHON element of a ADDRESS_STRUCTURE -->
<xsl:template match="ADDR" mode="MailAddress">
 	<xsl:param name="PlaceName"/>
 	<!-- Strange, if text() is passed as the default of PlaceName it return the text of the children and this
 		text() doesn't -->
 	<xsl:variable name="TagText" select="text()"/>
 		<MailAddress>
 			<!-- If $PlaceName is not the 'same' as the $TagText, assume that the $PlaceName 
 				should be the addressee name and that the $TagText is acually a street name-->
 			<xsl:if test="contains($TagText, $PlaceName )">
 				<AddrLine>
 					<Addressee>
 						<xsl:value-of select="$TagText"/>
 					</Addressee>
 				</AddrLine>
  				<!-- Assume that CONT further qualifies the addressee
  					 name and handle multiple instances-->
 				<xsl:apply-templates select="CONT" mode="MailAddress"/>
 			</xsl:if>
 			<xsl:if test="not(contains($TagText, $PlaceName ))">
 				<AddrLine>
 					<Addressee>
 						<xsl:value-of select="$PlaceName"/>
 					</Addressee>
 				</AddrLine>
  				<!-- Assume that CONT further qualifies the addressee
  				 name and handle multiple instances-->
 				<xsl:apply-templates select="CONT" mode="MailAddress"/>
 				<AddrLine>
 					<PlacePart Type="street">
 						<xsl:value-of select="$TagText"/>
 					</PlacePart>
 				</AddrLine>
 			</xsl:if>
			<xsl:if test="ADR1">
				<AddrLine>
					<PlacePart Type="street">
						<xsl:value-of select="ADR1"/>
					</PlacePart>
				</AddrLine>
			</xsl:if>
			<xsl:if test="ADR2">
				<AddrLine>
					<PlacePart Type="street">
						<xsl:value-of select="ADR2"/>
					</PlacePart>
				</AddrLine>
			</xsl:if>
			<xsl:if test="CITY or STAE or POST or CTRY">
				<AddrLine>
					<xsl:if test="CITY">
						<PlacePart Type="city">
							<xsl:value-of select="CITY"/>
						</PlacePart>
					</xsl:if>

					<xsl:if test="STAE">
						<PlacePart Type="state">
							<xsl:value-of select="STAE"/>
						</PlacePart>
					</xsl:if>
					<xsl:if test="POST">
						<PlacePart Type="postal code">
							<xsl:value-of select="POST"/>
						</PlacePart>
					</xsl:if>
				</AddrLine>
				<xsl:if test="CTRY">
					<AddrLine>
						<PlacePart Type="country">
							<xsl:value-of select="CTRY"/>
						</PlacePart>
					</AddrLine>
				</xsl:if>
			</xsl:if>
 		</MailAddress>
</xsl:template><!-- end ADDR mode=MailAddress template -->

<!-- **********************************************************************

	CONT Template mode MailAddress - handles the CONT tag that may occur
		in the ADDR line of a ADDRESS_STRUCTURE and surrounds the content
		by the AddrLine element

*********************************************************************** -->
<xsl:template match="CONT" mode="MailAddress">
	<AddrLine>
		<xsl:value-of select="."/>
	</AddrLine>
</xsl:template>

<!-- **********************************************************************

	PHON Template 

*********************************************************************** -->
<!-- FIX if at all possible.  Usually the PHON tag belongs to the MailAddress ContactRec
	The problem is that GEDCOM 5.5 strict places the PHON and the ADDR tags at the same
	level.  The current implementation simply surrounds the Phone element with at ContactRec, losing, IOW,
	the relationship between the MailAddress and the Phone
-->
<xsl:template match="PHON">
	<Phone>
		<xsl:value-of select="."/>
	</Phone>
</xsl:template>
 
<!-- **********************************************************************
***************************************************************************
**																		 **
**	Templates Related to Familes and its associated elements			 **
**		* FAM -> <FamilyRec>											 **
**		* CHIL -> <Child>												 **
**																		 **
***************************************************************************
*********************************************************************** -->

<!-- **********************************************************************
***************************************************************************

	FAM Template - creates the FamilyRec and related elements, checking
		to determine there is a MARR event supporting this, checking
		to determine the ID of both parents if they are available.

n @<XREF:FAM>@   FAM   {1:1}
    +1 HUSB @<XREF:INDI>@  {0:1}
    +1 WIFE @<XREF:INDI>@  {0:1}
    +1 CHIL @<XREF:INDI>@  {0:M}
    +1 SUBM @<XREF:SUBM>@  {0:M}
    +1 SOUR @<XREF:SOUR>@     {1:1}
         +2 PAGE <WHERE_WITHIN_SOURCE>  {0:1}
         +2 DATA        {0:1}
            +3 DATE <ENTRY_RECORDING_DATE>  {0:1}
            +3 TEXT <TEXT_FROM_SOURCE>  {0:M}
                +4 [ CONC | CONT ] <TEXT_FROM_SOURCE>  {0:M}
         +2 QUAY <CERTAINTY_ASSESSMENT>  {0:1}
     +1 NOTE @<XREF:NOTE>@  {1:1}
     +1 NOTE [<SUBMITTER_TEXT> | <NULL>]  {1:1}
          +2 [ CONC | CONT ] <SUBMITTER_TEXT>  {0:M}
     +1 SOUR <SOURCE_DESCRIPTION>  {1:1}
          +2 [ CONC | CONT ] <SOURCE_DESCRIPTION>  {0:M}
          +2 TEXT <TEXT_FROM_SOURCE>  {0:M}
      	   +3 [CONC | CONT ] <TEXT_FROM_SOURCE>  {0:M}
          +2  NOTE @<XREF:NOTE>@  {1:1}
          +2  NOTE [<SUBMITTER_TEXT> | <NULL>]  {1:1}
          +2 [ CONC | CONT ] <SUBMITTER_TEXT>  {0:M}   
      +2 <<NOTE_STRUCTURE>>  {0:M}
      +2 <<MULTIMEDIA_LINK>>  {0:M}
    
    +1 <<MULTIMEDIA_LINK>>  {0:M}
    +1 NOTE @<XREF:NOTE>@  {1:1}
    +1 NOTE [<SUBMITTER_TEXT> | <NULL>]  {1:1}
        +2 [ CONC | CONT ] <SUBMITTER_TEXT>  {0:M}
    +1 REFN <USER_REFERENCE_NUMBER>  {0:M}
    +1 RIN <AUTOMATED_RECORD_ID>  {0:1}
    +1 CHAN          {1:1}
        +2 DATE <CHANGE_DATE>  {1:1}
             + 3 TIME <TIME_VALUE>  {0:1}
		
***************************************************************************
*********************************************************************** -->
<xsl:template match="FAM">
	<FamilyRec>
		<xsl:attribute name="Id">
			<xsl:value-of select="generate-id()"/>
		</xsl:attribute>
			<xsl:if test="HUSB">
				<HusbFath>
				<xsl:variable name="husbID" select="HUSB/@REF"/>
					<Link>
						<xsl:attribute name="Target">IndividualRec</xsl:attribute>
					 	<xsl:attribute name="Ref">
 							<xsl:choose>
 								<xsl:when test="//INDI[@ID=$husbID]">
 									<xsl:value-of select="generate-id(//INDI[@ID=$husbID])"/>
 								</xsl:when>
 								<xsl:otherwise>
 									<xsl:value-of select="'IndividualUnknown'"/>
 								</xsl:otherwise>
 							</xsl:choose>
						</xsl:attribute>
 					</Link>
				</HusbFath>
			</xsl:if>
			<xsl:if test="WIFE">
				<WifeMoth>
					<xsl:variable name="wifeID" select="WIFE/@REF"/>
					<Link>
						<xsl:attribute name="Target">IndividualRec</xsl:attribute>
						<xsl:attribute name="Ref">
 							<xsl:choose>
 								<xsl:when test="//INDI[@ID=$wifeID]">
 									<xsl:value-of select="generate-id(//INDI[@ID=$wifeID])"/>
 								</xsl:when>
 								<xsl:otherwise>
 									<xsl:value-of select="'IndividualUnknown'"/>
 								</xsl:otherwise>
 							</xsl:choose>
 						</xsl:attribute>
  					</Link>
				</WifeMoth>
			</xsl:if>
			
		<!-- Add children to the FamilyRec -->
		<xsl:apply-templates select="CHIL"/>
		<xsl:if test="MARR">
			<BasedOn>
				<Link>
					<xsl:attribute name="Target">EventRec</xsl:attribute>
					<xsl:attribute name="Ref">
						<xsl:value-of select="generate-id(child::MARR)"/>
					</xsl:attribute>
				</Link>
			</BasedOn>
		</xsl:if>
		<xsl:call-template name="ExternalIDs"/>

		<xsl:call-template name="Submitter"/>

		<xsl:apply-templates select="NOTE"/>
		
		<xsl:apply-templates select="SOUR"/>
		<xsl:apply-templates select="OBJE"/>
		
		<xsl:apply-templates select="CHAN"/>
	</FamilyRec>
</xsl:template>

<!-- **********************************************************************

	CHIL Template - creates <Child> elements inside a FamilyRec.  It will
		also determine the RelToMoth and RelToFath information based on
		the ADOP tag

*********************************************************************** -->
<xsl:template match="CHIL">
	<xsl:variable name="childID" select="@REF"/>
	<Child>	
		<Link>
			<xsl:attribute name="Target">IndividualRec</xsl:attribute>
 			<xsl:attribute name="Ref">
 				<xsl:choose>
 					<xsl:when test="//INDI[@ID=$childID]">
 						<xsl:value-of select="generate-id(//INDI[@ID=$childID])"/>
 					</xsl:when>
 					<xsl:otherwise>
 						<xsl:value-of select="'IndividualUnknown'"/>
 					</xsl:otherwise>
 				</xsl:choose>
			</xsl:attribute>
		</Link>
		<ChildNbr><xsl:number/></ChildNbr>
		<xsl:choose>
 			<xsl:when test="//INDI[@ID=$childID]/ADOP">
				<xsl:element name="RelToFath">adopted</xsl:element>
				<xsl:element name="RelToMoth">adopted</xsl:element>
 			</xsl:when>
			<xsl:otherwise>
				<xsl:element name="RelToFath">biological</xsl:element>
				<xsl:element name="RelToMoth">biological</xsl:element>
			</xsl:otherwise>
		</xsl:choose>
	</Child>
</xsl:template>

<!-- **********************************************************************
***************************************************************************
**																		 **
**	Templates Related to Repositories and its associated elements		 **
**		* REPO[@REF] -> <Repository>									 **
**		* REPO[@ID] -> <RepositoryRec>									 **
**																		 **
***************************************************************************
*********************************************************************** -->

<!-- **********************************************************************
***************************************************************************

	REPO[@REF] Template - from a linked reference to repository, occuring
		in a SourceRec

***************************************************************************
*********************************************************************** -->
<xsl:template match="REPO[@REF]">
	<Repository>
		<Link>
			<xsl:variable name="RepoID" select="@REF"/>
			<xsl:attribute name="Target">RepositoryRec</xsl:attribute>
			<xsl:attribute name="Id">
				<xsl:choose>
					<xsl:when test="//REPO[@ID=$RepoID]">
						<xsl:value-of select="generate-id(//REPO[@ID=$RepoID])"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="'RepositoryUnknown'"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
		</Link>
		<xsl:apply-templates select="CALN"/>
	</Repository>
</xsl:template>

<!-- **********************************************************************

	CALN Template - creates CallNbr element for Repository Elements

*********************************************************************** -->
<xsl:template match="CALN">
	<CallNbr>
		<xsl:value-of select="text()"/>
	</CallNbr>
</xsl:template>

<!-- **********************************************************************
***************************************************************************

	REPO[@ID] Template - creates RepositoryRecs

***************************************************************************
*********************************************************************** -->
<xsl:template match="REPO[@ID]">
	<RepositoryRec>
		<xsl:attribute name="Id">
			<xsl:value-of select="generate-id()"/>
		</xsl:attribute> 
		<Name>
			<xsl:value-of select="NAME"/>
		</Name>
		<xsl:apply-templates select="ADDR" mode="MailAddress">
			<xsl:with-param name="PlaceName" select="NAME"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="PHON"/>
		<!-- not implementing Email or URI elements because no equivalent in GEDCOM 5.5 -->
		<xsl:apply-templates select="NOTE"/>
		<xsl:apply-templates select="CHAN"/>
	</RepositoryRec>
</xsl:template>


<!-- **********************************************************************
***************************************************************************
**							   		           **
**	Templates Applicable for multiple records or different elements	**
**		* NOTE[@REF] -> <Note>					**
**		* NOTE[@ID] -> <Note>					**
**		* CONT, CONC							**
**		* DATE -> <Date>						**
**		* RIN, RFN, AFN, REFN -> <ExternalID>			**
**		* CHAN -> <Changed>				 	**
**		* NOTE mode Changed 					**
**		* NOTE[@REF] mode Changed					**
**										**
***************************************************************************
*********************************************************************** -->

<!-- DOC  -->
<!-- **********************************************************************

	NOTE[@REF] Template - handles a linked NOTE_STRUCTURE or a 
		reference to notes.  NOTE tags that reference a NOTE_RECORD will
		not be linked in GEDCOM XML 6.0 because there is no mechanism for
		that.  There contents will instead be place in the element which
		referenced them.

*********************************************************************** -->
<xsl:template match="NOTE[@REF]">
	<xsl:variable name="NoteID" select="@REF"/>
	<xsl:apply-templates select="//NOTE[@ID=$NoteID]"/>
</xsl:template>

<!-- **********************************************************************
***************************************************************************

	NOTE[@REF] Template - handles a linked NOTE_STRUCTURE or a 
		reference to notes.  NOTE tags that reference a NOTE_RECORD will
		not be linked in GEDCOM XML 6.0 because there is no mechanism for
		that.  There contents will instead be place in the element which
		referenced them.

***************************************************************************
*********************************************************************** -->
<xsl:template match="NOTE[@ID]">
	<Note>
		<xsl:call-template name="handleCONCT"/>
	</Note>
</xsl:template>

<!-- **********************************************************************

	NOTE Template - handles a "simple" NOTE_STRUCTURE which simply 
		contains SUBMITTER_TEXT and CONC/CONT tags.  This template
		ignores the SOUR element, but this info will be captured in the
		SOUR sweep

*********************************************************************** -->
<xsl:template match="NOTE">
	<Note>
		<xsl:call-template name="handleCONCT"/>
	</Note>
</xsl:template>

<!-- **********************************************************************

	handleCONCT Template - utility template that handles the multiple
		occurance of CONC and CONT.  It is never used in the case of 
		text intended to be an <Extract> because, in this case, <br/>
		are permissable and CONT could be translated to <br/>

*********************************************************************** -->
<xsl:template name="handleCONCT">
	<xsl:value-of select="text()"/>
	<xsl:for-each select="node()">
		<xsl:choose>
			<xsl:when test="self::CONT">
				<xsl:text> </xsl:text>
				<xsl:value-of select="self::CONT"/>
			</xsl:when>
			<xsl:when test="self::CONC">
				<xsl:text> </xsl:text>
				<xsl:value-of select="self::CONC"/>
			</xsl:when>
		</xsl:choose>
	</xsl:for-each>
</xsl:template>

<!-- **********************************************************************

	DATE Template - current implementations assumes that all dates are
		Gregorian

************************************************************************ -->
<!-- TODO enable it to handle non-Gregorian calendars -->
<xsl:template match="DATE">
	<Date Calendar="Gregorian">
		<xsl:value-of select="normalize-space( text() )"/>
	</Date>
</xsl:template>

<!-- **********************************************************************

	ExternalIDs template - called add ExternalId elements

*********************************************************************** -->
<!-- DOC at one place in the draft specification it says there are only 2 values for attribute 
	Type - AFN and User, but at another it say REFN, RIN, and RFN are also permissible 
	the DTD does not specify either way -->
<xsl:template name="ExternalIDs">
		<xsl:apply-templates select="REFN"/>
		<xsl:if test="RIN">
			<ExternalID>
				<xsl:attribute name="Type">RIN</xsl:attribute>
				<xsl:attribute name="Id">
					<xsl:value-of select="RIN"/>
				</xsl:attribute>
			</ExternalID>
		</xsl:if>
		<xsl:if test="RFN">
			<ExternalID>
				<xsl:attribute name="Type">RFN</xsl:attribute>
				<xsl:attribute name="Id">
					<xsl:value-of select="RFN"/>
				</xsl:attribute>
			</ExternalID>
		</xsl:if>
		<xsl:if test="AFN">
			<ExternalID>
				<xsl:attribute name="Type">AFN</xsl:attribute>
				<xsl:attribute name="Id">
					<xsl:value-of select="AFN"/>
				</xsl:attribute>
			</ExternalID>
		</xsl:if>
		<ExternalID>
			<xsl:attribute name="Type">user</xsl:attribute>
			<xsl:attribute name="Id">
				<xsl:value-of select="@ID"/>
			</xsl:attribute>
		</ExternalID>
</xsl:template>

<!-- **********************************************************************

	REFN template - adds ExternalID element contains 
		REFN's USER_REFERENCE_NUMBER 

*********************************************************************** -->
<xsl:template match="REFN">
	<ExternalID>
		<xsl:attribute name="Type">REFN</xsl:attribute>
		<xsl:attribute name="Id">
			<xsl:value-of select="text()"/>
		</xsl:attribute>
	</ExternalID>
</xsl:template>

<!-- **********************************************************************

	CHAN Template - creates the Changed element and sets the Date and Time
		attributes

*********************************************************************** -->
<xsl:template match="CHAN">
	<!-- both the Date and the Time attributes are #REQUIRED -->
	<Changed>
		<xsl:for-each select="node()">
			<xsl:choose>
				<xsl:when test="self::DATE">
					<xsl:attribute name="Date">
						<xsl:value-of select="text()"/>
					</xsl:attribute>				
				</xsl:when>
			</xsl:choose>
		</xsl:for-each>
		<xsl:attribute name="Time">
				<xsl:value-of select="DATE/TIME"/>
		</xsl:attribute>

		<xsl:apply-templates select="NOTE" mode="Changed"/>
		
	</Changed>
</xsl:template>

<!-- **********************************************************************

	NOTE and NOTE[@REF] templates mode Changed- help templates
	for the Changed element which only allows for one and only one Note
	Element.  These templates collapses all NOTE tags under a CHAN
	tag into one Note element

*********************************************************************** -->
<xsl:template match="NOTE" mode="Changed">
	<Note>
		<xsl:call-template name="handleCONCT"/>
		<!-- Adds a single space pad-->
		<xsl:text> </xsl:text>
	</Note>
</xsl:template>
<xsl:template match="NOTE[@REF]" mode="Changed">
	<xsl:call-template name="handleCONCT"/>
	<!-- Adds a single space pad-->
	<xsl:text> </xsl:text>
</xsl:template>

<!-- **********************************************************************

	Submitter Template creates the Submitter elements and links it
		to the **first** SUBM it finds.  This is in contrast to 
		GEDCOM 5.5 which allows for multiple SUBM.  Gedcom 6.0XML
		only allows for one.  Hence, this implementation is lossy.

*********************************************************************** -->
<xsl:template name="Submitter">
 	<xsl:if test="SUBM">
	 	<Submitter>
	 		<Link>
				<xsl:attribute name="Target">ContactRec</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:variable name="SubmID" select="../SUBM/@REF"/>
					<xsl:choose>
						<xsl:when test="//SUBM[@ID=$SubmID]">
	 						<xsl:value-of select="generate-id(//SUBM[@ID=$SubmID])"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'ContactUnknown'"/>
						</xsl:otherwise>
					</xsl:choose>
	
				</xsl:attribute>
			</Link>
	 	</Submitter>
 	</xsl:if>
</xsl:template>


<!-- **********************************************************************

	makeDummySourceRec template - need for validity purposes because
		there can be SOUR and OBJE tags translated to Evidence.Citations
		which need Link elements but there is nothing to link them to

*********************************************************************** -->

<xsl:template name="makeDummySourceRec">
	<SourceRec Id="SourceUnknown">
		<Title>Source Unknown</Title>
	</SourceRec>
</xsl:template>
<xsl:template name="makeDummyIndividualRec">
	<IndividualRec Id="IndividualUnknown"/>
</xsl:template>
<xsl:template name="makeDummyContactRec">
	<ContactRec Id="ContactUnknown">
		<Name>Contact Unknown</Name>
	</ContactRec>
</xsl:template>
<xsl:template name="makeDummyRepositoryRec">
	<RepositoryRec Id="RepositoryUnknown">
		<Name>Repository Unknown</Name>
	</RepositoryRec>
</xsl:template>

<!-- **********************************************************************
****************************************************************************

	Templates  related to LDSOrdRecs
		* LDSOrdRecs template -> calls all LDSOrdRec templates
		* BAPL, CONL, ENDL -> <LDSOrdRec>
		* SLGS -> <LDSOrdRec>
		* SLGC -> <LDSordRec>
		* STAT -> <OrdStat>
		* FAMC mode ChildSealing -> <Particpant>Mother and Father

***************************************************************************
*********************************************************************** -->

<!-- **********************************************************************

	LDSOrdRecs template - calls all the templates necessary for making
		LDSOrdRec elements

*********************************************************************** -->
<xsl:template name="LDSOrdRecs">
	<xsl:apply-templates select="//INDI/BAPL|//INDI/CONL|//INDI/ENDL"/>
	<xsl:apply-templates select="//INDI/SLGC"/>
	<xsl:apply-templates select="//FAM/SLGS"/>
</xsl:template>

<!-- **********************************************************************

	BAPL, CONL, EDNL template - handles these ordinances
	
  n  [ BAPL | CONL ]  {1:1}
    +1 STAT <LDS_BAPTISM_DATE_STATUS>  {0:1}
    +1 DATE <DATE_LDS_ORD>  {0:1}
    +1 TEMP <TEMPLE_CODE>  {0:1}
    +1 PLAC <PLACE_LIVING_ORDINANCE>  {0:1}
    +1 SOUR @<XREF:SOUR>@     {1:1}
         +2 PAGE <WHERE_WITHIN_SOURCE>  {0:1}
         +2 DATA        {0:1}
            +3 DATE <ENTRY_RECORDING_DATE>  {0:1}
            +3 TEXT <TEXT_FROM_SOURCE>  {0:M}
                +4 [ CONC | CONT ] <TEXT_FROM_SOURCE>  {0:M}
         +2 QUAY <CERTAINTY_ASSESSMENT>  {0:1}
     +1 NOTE @<XREF:NOTE>@  {1:1}
     +1 NOTE [<SUBMITTER_TEXT> | <NULL>]  {1:1}
          +2 [ CONC | CONT ] <SUBMITTER_TEXT>  {0:M}
     +1 SOUR <SOURCE_DESCRIPTION>  {1:1}
          +2 [ CONC | CONT ] <SOURCE_DESCRIPTION>  {0:M}
          +2 TEXT <TEXT_FROM_SOURCE>  {0:M}
      	   +3 [CONC | CONT ] <TEXT_FROM_SOURCE>  {0:M}
          +2  NOTE @<XREF:NOTE>@  {1:1}
          +2  NOTE [<SUBMITTER_TEXT> | <NULL>]  {1:1}
          +2 [ CONC | CONT ] <SUBMITTER_TEXT>  {0:M}
    +1  NOTE @<XREF:NOTE>@  {1:1}
    +1  NOTE [<SUBMITTER_TEXT> | <NULL>]  {1:1}
          +2 [ CONC | CONT ] <SUBMITTER_TEXT>  {0:M}

  n  ENDL          {1:1}
    +1 STAT <LDS_ENDOWMENT_DATE_STATUS>  {0:1}
    +1 DATE <DATE_LDS_ORD>  {0:1}
    +1 TEMP <TEMPLE_CODE>  {0:1}
    +1 PLAC <PLACE_LIVING_ORDINANCE>  {0:1}
    +1 SOUR @<XREF:SOUR>@     {1:1}
        +2 PAGE <WHERE_WITHIN_SOURCE>  {0:1}
        +2 DATA        {0:1}
            +3 DATE <ENTRY_RECORDING_DATE>  {0:1}
            +3 TEXT <TEXT_FROM_SOURCE>  {0:M}
                +4 [ CONC | CONT ] <TEXT_FROM_SOURCE>  {0:M}
        +2 QUAY <CERTAINTY_ASSESSMENT>  {0:1}
     +1 NOTE @<XREF:NOTE>@  {1:1}
     +1 NOTE [<SUBMITTER_TEXT> | <NULL>]  {1:1}
         +2 [ CONC | CONT ] <SUBMITTER_TEXT>  {0:M}
     +1 SOUR <SOURCE_DESCRIPTION>  {1:1}
          +2 [ CONC | CONT ] <SOURCE_DESCRIPTION>  {0:M}
          +2 TEXT <TEXT_FROM_SOURCE>  {0:M}
      	   +3 [CONC | CONT ] <TEXT_FROM_SOURCE>  {0:M}
          +2  NOTE @<XREF:NOTE>@  {1:1}
          +2  NOTE [<SUBMITTER_TEXT> | <NULL>]  {1:1}
          +2 [ CONC | CONT ] <SUBMITTER_TEXT>  {0:M}
    +1 NOTE @<XREF:NOTE>@  {1:1}
    +1 NOTE [<SUBMITTER_TEXT> | <NULL>]  {1:1}
         +2 [ CONC | CONT ] <SUBMITTER_TEXT>  {0:M}

*********************************************************************** -->
<xsl:template match="BAPL|CONL|ENDL">

	<xsl:variable name="ordinance" select="name()"/>
	
	<LDSOrdRec>
		<xsl:attribute name="Id">
			<xsl:value-of select="generate-id()"/>
		</xsl:attribute>
		<xsl:attribute name="Type">
			<xsl:choose>
				<xsl:when test="$ordinance = 'BAPL'">
					<xsl:value-of select="'B'"/>
				</xsl:when>
				<xsl:when test="$ordinance = 'CONL'">
					<xsl:value-of select="'C'"/>
				</xsl:when>
				<xsl:when test="$ordinance = 'ENDL'">
					<xsl:value-of select="'E'"/>
				</xsl:when>
			</xsl:choose>
		</xsl:attribute>
		
		<Participant>
			<Link>
				<xsl:attribute name="Target">IndividualRec"</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:value-of select="generate-id()"/>
				</xsl:attribute>
			</Link>
		</Participant>
		
		
		<xsl:apply-templates select="STAT"/>
		
		<xsl:if test="TEMP">
			<TempleCode>
				<xsl:value-of select="TEMP"/>
			</TempleCode>
		</xsl:if>
		<xsl:apply-templates select="DATE"/>

		<xsl:call-template name="addEventPlace"/>
		
		<xsl:apply-templates select="NOTE"/>
		
		<xsl:call-template name="addEventEvidence"/>
		
	</LDSOrdRec>

</xsl:template>
<!-- **********************************************************************

	SLGC template - handles child sealing ordinance

n  SLGC          {1:1}
    +1 STAT <LDS_CHILD_SEALING_DATE_STATUS>  {0:1}
    +1 DATE <DATE_LDS_ORD>  {0:1}
    +1 TEMP <TEMPLE_CODE>  {0:1}
    +1 PLAC <PLACE_LIVING_ORDINANCE>  {0:1}
    +1 FAMC @<XREF:FAM>@  {1:1}
    +1 SOUR @<XREF:SOUR>@     {1:1}
        +2 PAGE <WHERE_WITHIN_SOURCE>  {0:1}
        +2 DATA        {0:1}
            +3 DATE <ENTRY_RECORDING_DATE>  {0:1}
            +3 TEXT <TEXT_FROM_SOURCE>  {0:M}
                +4 [ CONC | CONT ] <TEXT_FROM_SOURCE>  {0:M}
        +2 QUAY <CERTAINTY_ASSESSMENT>  {0:1}
     +1 NOTE @<XREF:NOTE>@  {1:1}
     +1 NOTE [<SUBMITTER_TEXT> | <NULL>]  {1:1}
          +2 [ CONC | CONT ] <SUBMITTER_TEXT>  {0:M}
     +1 SOUR <SOURCE_DESCRIPTION>  {1:1}
          +2 [ CONC | CONT ] <SOURCE_DESCRIPTION>  {0:M}
          +2 TEXT <TEXT_FROM_SOURCE>  {0:M}
      	   +3 [CONC | CONT ] <TEXT_FROM_SOURCE>  {0:M}
          +2  NOTE @<XREF:NOTE>@  {1:1}
          +2  NOTE [<SUBMITTER_TEXT> | <NULL>]  {1:1}
          +2 [ CONC | CONT ] <SUBMITTER_TEXT>  {0:M}
    +1 NOTE @<XREF:NOTE>@  {1:1}
    +1 NOTE [<SUBMITTER_TEXT> | <NULL>]  {1:1}
         +2 [ CONC | CONT ] <SUBMITTER_TEXT>  {0:M}
    
*********************************************************************** -->
<xsl:template match="SLGC">
	<LDSOrdRec>
		<xsl:attribute name="Id">
			<xsl:value-of select="generate-id()"/>
		</xsl:attribute>
		<xsl:attribute name="Type">
			<xsl:value-of select="'SP'"/>
		</xsl:attribute>
		
		<Participant>
			<Link>
				<xsl:attribute name="Target">IndividualRec"</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:value-of select="generate-id(..)"/>
				</xsl:attribute>
			</Link>
			<Role>Child</Role>
		</Participant>
		
		<xsl:apply-templates select="FAMC" mode="ChildSealing"/>
		
		<xsl:apply-templates select="STAT"/>
		
		<xsl:if test="TEMP">
			<TempleCode>
				<xsl:value-of select="TEMP"/>
			</TempleCode>
		</xsl:if>
		<xsl:apply-templates select="DATE"/>

		<xsl:call-template name="addEventPlace"/>
		
		<xsl:apply-templates select="NOTE"/>
		
		<xsl:call-template name="addEventEvidence"/>
		
	</LDSOrdRec>

</xsl:template>
<!-- **********************************************************************

	SLGS template - handles spouse sealing ordinance
 
 n  SLGS          {1:1}
    +1 STAT <LDS_SPOUSE_SEALING_DATE_STATUS>  {0:1}
    +1 DATE <DATE_LDS_ORD>  {0:1}
    +1 TEMP <TEMPLE_CODE>  {0:1}
    +1 PLAC <PLACE_LIVING_ORDINANCE>  {0:1}
    +1 <<SOURCE_CITATION>>  {0:M}
    +1 <<NOTE_STRUCTURE>>  {0:M}
    +1 SOUR @<XREF:SOUR>@     {1:1}
        +2 PAGE <WHERE_WITHIN_SOURCE>  {0:1}
        +2 DATA        {0:1}
            +3 DATE <ENTRY_RECORDING_DATE>  {0:1}
            +3 TEXT <TEXT_FROM_SOURCE>  {0:M}
                +4 [ CONC | CONT ] <TEXT_FROM_SOURCE>  {0:M}
        +2 QUAY <CERTAINTY_ASSESSMENT>  {0:1}
     +1 NOTE @<XREF:NOTE>@  {1:1}
     +1 NOTE [<SUBMITTER_TEXT> | <NULL>]  {1:1}
         +2 [ CONC | CONT ] <SUBMITTER_TEXT>  {0:M}
     +1 SOUR <SOURCE_DESCRIPTION>  {1:1}
          +2 [ CONC | CONT ] <SOURCE_DESCRIPTION>  {0:M}
          +2 TEXT <TEXT_FROM_SOURCE>  {0:M}
      	   +3 [CONC | CONT ] <TEXT_FROM_SOURCE>  {0:M}
          +2  NOTE @<XREF:NOTE>@  {1:1}
          +2  NOTE [<SUBMITTER_TEXT> | <NULL>]  {1:1}
          +2 [ CONC | CONT ] <SUBMITTER_TEXT>  {0:M}
    +1 NOTE @<XREF:NOTE>@  {1:1}
    +1 NOTE [<SUBMITTER_TEXT> | <NULL>]  {1:1}
        + 2 [ CONC | CONT ] <SUBMITTER_TEXT>  {0:M}
    	
*********************************************************************** -->
<xsl:template match="SLGS">

	<xsl:variable name="ordinance" select="name()"/>
	
	<LDSOrdRec>
		<xsl:attribute name="Id">
			<xsl:value-of select="generate-id()"/>
		</xsl:attribute>
		<xsl:attribute name="Type">
			<xsl:value-of select="'SS'"/>
		</xsl:attribute>
		
		<xsl:if test="../HUSB/@REF">
			<xsl:variable name="HusbID" select="../HUSB/@REF"/>
			<Participant>
				<Link>
					<xsl:attribute name="Target">IndividualRec</xsl:attribute>
					<xsl:attribute name="Ref">
						<xsl:choose>
							<xsl:when test="//INDI[@ID=$HusbID]">
								<xsl:value-of select="generate-id(//INDI[@ID=$HusbID])"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="'IndividualUnknown'"/>
							</xsl:otherwise>
						</xsl:choose>				
					</xsl:attribute>
				</Link>
				<Role>husband</Role>
			</Participant>
		</xsl:if>
		
		<xsl:if test="../WIFE/@REF">
			<xsl:variable name="WifeID" select="../WIFE/@REF"/>
			<Participant>
				<Link>
					<xsl:attribute name="Target">IndividualRec</xsl:attribute>
					<xsl:attribute name="Ref">
						<xsl:choose>
							<xsl:when test="//INDI[@ID=$WifeID]">
								<xsl:value-of select="generate-id(//INDI[@ID=$WifeID])"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="'IndividualUnknown'"/>
							</xsl:otherwise>
						</xsl:choose>				
					</xsl:attribute>
				</Link>
				<Role>wife</Role>
			</Participant>
		</xsl:if>

		<xsl:apply-templates select="STAT"/>
		
		<xsl:if test="TEMP">
			<TempleCode>
				<xsl:value-of select="TEMP"/>
			</TempleCode>
		</xsl:if>
		<xsl:apply-templates select="DATE"/>

		<xsl:call-template name="addEventPlace"/>
		
		<xsl:apply-templates select="NOTE"/>
		
		<xsl:call-template name="addEventEvidence"/>
		
	</LDSOrdRec>

</xsl:template>

<!-- **********************************************************************

	STAT template - creates OrdStat and handles the following data:
		* LDS_BAPTISM_DATE_STATUS
		* LDS_ENDOWMENT_DATE_STATUS
		* LDS_CHILD_SEALING_DATE_STATUS
		* LDS_SPOUSE_SEALING_DATE_STATUS

*********************************************************************** -->
<xsl:template match="STAT">

	<xsl:variable name="status" select="normalize-space( . )"/>
	
	<OrdStat>
		<xsl:attribute name="Code">
			<xsl:if test="($status != 'INFANT') and ($status != 'PRE-1970' )">
				<xsl:value-of select="translate( $status, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz' )"/>
			</xsl:if>
			<!-- There is no GEDCOM 6.0 equivalent to INFANT and PRE-1970, they are mapped to 'completed'-->
			<xsl:if test="($status != 'INFANT') and ($status != 'PRE-1970' )">
				<xsl:value-of select="'completed'"/>
			</xsl:if>
		</xsl:attribute>

	</OrdStat>
</xsl:template>

<!-- **********************************************************************

	FAMC mode ChildSealing template - handles the addition of parent
		Participant elements for a SLGC ordinance
	

*********************************************************************** -->
<xsl:template match="FAMC" mode="ChildSealing">
	<!-- Get Family Ref -->
	<xsl:variable name="FamilyID" select="@REF"/>


	<xsl:if test="//FAM[@ID=$FamilyID]/HUSB/@REF">
		<xsl:variable name="FatherID" select="//FAM[@ID=$FamilyID]/HUSB/@REF"/>
		<Participant>
			<Link>
				<xsl:attribute name="Target">IndividualRec</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:choose>
						<xsl:when test="//INDI[@ID=$FatherID]">
							<xsl:value-of select="generate-id(//INDI[@ID=$FatherID])"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'IndividualUnknown'"/>
						</xsl:otherwise>
					</xsl:choose>				
				</xsl:attribute>
			</Link>
			<Role>father</Role>
		</Participant>
	</xsl:if>
	
	<xsl:if test="//FAM[@ID=$FamilyID]/WIFE/@REF">
		<xsl:variable name="MotherID" select="//FAM[@ID=$FamilyID]/WIFE/@REF"/>
		<Participant>
			<Link>
				<xsl:attribute name="Target">IndividualRec</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:choose>
						<xsl:when test="//INDI[@ID=$MotherID]">
							<xsl:value-of select="generate-id(//INDI[@ID=$MotherID])"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'IndividualUnknown'"/>
						</xsl:otherwise>
					</xsl:choose>				
				</xsl:attribute>
			</Link>
			<Role>mother</Role>
		</Participant>
	</xsl:if>
</xsl:template>

</xsl:stylesheet>
