<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<!-- $Id$ -->
<!-- At the moment, this stylesheet creates the GEDCOM XML according to this pattern:
	1) Name elements
	2) Vital Event elements
	3) PersInfo elements SSN NMR NCHI OCCU EDUC
	4) Other event elements CONF BAPM IMMI 
	5) Family elements 
IOW, it does not follow how the original flow of the input GEDCOM 5.5 file -->
<xsl:output method="xml" indent="yes"/>
<!-- TODO add param to set the Type attribute in the ExternalID -->
<!-- FIX this global variable doesn't work-->
<xsl:param name="FileCreationDate"/>
<!--For Debugging -->
<xsl:template match="/">
	<xsl:apply-templates select="//HEAD"/>
</xsl:template>
<!-- Start at Root-->
<xsl:template name="full">
	<GEDCOM>
 	<xsl:apply-templates select="//HEAD"/>
 	<xsl:apply-templates select="//FAM"/>
 	<xsl:apply-templates select="//INDI"/>
 <!-- EventRecs -->
 	<xsl:call-template name="EventRecs"/>
 <!-- LDSOrdRecs -->
 <!-- ContactRec -->
 	<xsl:call-template name="ContactRecs"/>	
<!-- SourceRec  -->
	<xsl:call-template name="SourceRecs"/>
<!-- RepositoryRec -->
	<xsl:apply-templates select="//REPO"/>
<!-- Not creating any GroupRec because there is no equivalent in GEDCOM 5.5 -->
 	
 	</GEDCOM>
</xsl:template>

<!-- Template from HEAD to HeaderRec -->
<!-- Some of the mapping here are suspect because the SOUR tag purpose is ambiguous -->
<xsl:template match="HEAD">
	<HeaderRec>
		<!-- Call this template to create the FileCreation Element in case it is needed -->
		<xsl:apply-templates select="SOUR" mode="HeaderRec"/>
		<xsl:if test="SOUR/DATA">
			<Citation>
				<!-- FIX?  Is a Citation invalid if it doesn't have a link and if it isn't, what
					should this be linked to? -->
				<Link Target="" Ref=""/>
				<!-- To generate Caption element-->
				<xsl:apply-templates select="SOUR/DATA" mode="HeaderRec"/>
				<xsl:if test="SOUR/DATA/DATE">
					<WhenRecorded>
						<xsl:value-of select="SOUR/DATA/DATE"/>
					</WhenRecorded>
				</xsl:if>
				<xsl:if test="SOUR/DATA/COPR">
					<Note>
						<xsl:value-of select="SOUR/DATA/COPR"/>
					</Note>
				</xsl:if>
			</Citation>
		</xsl:if>
		<xsl:if test="SUBM">
			<Submitter>
				<Link>
					<xsl:attribute name="Target">ContactRec</xsl:attribute>
					<xsl:attribute name="Ref">
						<xsl:variable name="SubmitterID" select="@REF"/>
						<xsl:value-of select="generate-id(//SUBM[@ID=$SubmitterID])"/>
					</xsl:attribute>
				</Link>
			</Submitter>
		</xsl:if>

	</HeaderRec>
</xsl:template> <!-- end Template for HEAD to HeaderRec -->

<!-- Template create the Caption element which is possibly part of the Citation element in the HeaderRec-->
<xsl:template match="DATA" mode="HeaderRec">
	<Caption>
		<xsl:value-of select="text()"/>
	</Caption>
</xsl:template>

<!-- Template for INDI to IndividualRec -->
 <xsl:template match="INDI">
	<IndividualRec>
		<xsl:attribute name="Id">
			<xsl:value-of select="generate-id()"/>
		</xsl:attribute>
		<xsl:apply-templates select="NAME"/>
		<xsl:apply-templates select="SEX"/>

		<xsl:call-template name="persinfo"/>

		<xsl:call-template name="ExternalIDs"/>
		
		<xsl:apply-templates select="SOUR"/>

		<xsl:apply-templates select="CHAN"/>
	</IndividualRec>
 </xsl:template><!-- end Template for INDI to IndividualRec -->

 <!-- NAME Template -->
 <xsl:template match="NAME">
 <!-- TODO handle middle name -->
	<IndivName>
	    	<xsl:choose>
		    <!-- if it is a name in the form of "First Name/Last Name/" -->
    		<xsl:when test="string-length(.) = 2 + string-length(translate(., '/', ''))">
    			<xsl:variable name="fullname" select="text()"/>
    			<xsl:if test="string-length(substring-before($fullname, '/')) &gt; 0">
	    			<NamePart Type="given name" Level="3">
		        			<xsl:value-of select="substring-before($fullname, '/')"/>        
        				</NamePart>
    			</xsl:if>
    			<xsl:if test="string-length(substring-before(substring-after($fullname,'/'), '/')) &gt; 0">
    				<NamePart Type="surname" Level="1">
     					<xsl:value-of select="substring-before(substring-after($fullname,'/'), '/')"/>			
     				</NamePart>
			</xsl:if>
     			<xsl:if test="string-length(substring-after(substring-after($fullname,'/'), '/')) &gt; 0">
     				<NamePart Type="suffix">
 	        				<xsl:value-of select="substring-after(substring-after($fullname,'/'), '/')"/>
 	        			</NamePart>
     			</xsl:if>
         		</xsl:when>
		<!-- TODO implement NPFX GIVN SPFX SURN and NSFX -->
		<xsl:otherwise>
			<NamePart>
				<xsl:attribute name="Type">whole name</xsl:attribute>
				<xsl:value-of select="."/>
			</NamePart>
		</xsl:otherwise>
     		</xsl:choose>
 		<xsl:apply-templates select="NICK"/>
	</IndivName>
</xsl:template><!-- end NAME template -->

<!-- Handles NICK tag -->
<xsl:template match="NICK">
     	<NamePart Type="nickname">
     		<xsl:value-of select="."/>
     	</NamePart>
 </xsl:template> <!-- end NICK template -->
 
 <xsl:template match="SEX">
 	<Gender>
 		<xsl:value-of select="."/>
 	</Gender>
 </xsl:template>
 
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
//INDI/RETI"/>
	
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
//FAM/MARS"/>

<!-- TODO Handle all other events LDS_INDIVIDUAL_ORDINANCE -->
	
 </xsl:template>
<!-- Handles all individual events besides BIRT-->
 <xsl:template match="DEAT|CHR|BURI|CREM|BAPM|BARM|BASM|BLES|CHRA|CONF|FCOM|ORDN|NATU|EMIG|IMMI|CENS|PROB|WILL|GRAD|RETI">
 	<EventRec>
 		<xsl:attribute name="Id">
 			<xsl:value-of select="generate-id()"/>
 		</xsl:attribute>
 		<xsl:attribute name="Type">
 			<xsl:choose>
 				 <xsl:when test="contains( name(), 'DEAT')">
 					<xsl:value-of select="'death'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'CHR')">
 					<xsl:value-of select="'christening'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'BURI')">
 					<xsl:value-of select="'burial'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'CREM')">
 					<xsl:value-of select="'cremation'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'BAPM')">
 					<xsl:value-of select="'baptism'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'BARM')">
 					<xsl:value-of select="'bar mitzvah'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'BASM')">
 					<xsl:value-of select="'bas mitzvah'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'BLES')">
 					<xsl:value-of select="'blessing'"/>
 				</xsl:when>
 				<!-- FIX -->
  				<xsl:when test="contains( name(), 'CHRA')">
 					<xsl:value-of select="'adult christening'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'CONF')">
 					<xsl:value-of select="'confirmation'"/>
 				</xsl:when>
 				<!-- FIX -->
  				<xsl:when test="contains( name(), 'FCOM')">
 					<xsl:value-of select="'first communion'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'ORDN')">
 					<xsl:value-of select="'ordination'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'NATU')">
 					<xsl:value-of select="'naturalization'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'EMIG')">
 					<xsl:value-of select="'emigration'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'IMMI')">
 					<xsl:value-of select="'immigration'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'CENS')">
 					<xsl:value-of select="'census'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'PROB')">
 					<xsl:value-of select="'probate'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'WILL')">
 					<xsl:value-of select="'will'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'GRAD')">
 					<xsl:value-of select="'graduation'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'RETI')">
 					<xsl:value-of select="'retirement'"/>
 				</xsl:when>
 			</xsl:choose>
 		</xsl:attribute>
 	
 			<xsl:choose>
 				 <xsl:when test="contains( name(), 'DEAT')">
 					<xsl:attribute name="VitalType"><xsl:value-of select="'death'"/></xsl:attribute>
 				</xsl:when>
 				 <xsl:when test="contains( name(), 'BURI')">
 					<xsl:attribute name="VitalType"><xsl:value-of select="'death'"/></xsl:attribute>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'CREM')">
 					<xsl:attribute name="VitalType"><xsl:value-of select="'death'"/></xsl:attribute>
 				</xsl:when>
 			</xsl:choose>
 
 		<Participant>
 			<Link>
 				<xsl:attribute name="Target">IndividualRec</xsl:attribute>
 				<xsl:attribute name="Ref">
 					<xsl:value-of select="generate-id(..)"/>
 				</xsl:attribute>
 			</Link>
 			<!-- DOC pointless element in translation at least -->
 			<Role>principal</Role>
 			<!-- DOC I refuse to implement the Living element because it is pointless for the most part
 				and the spec only implies that it is valid only for ordination -->
 			<xsl:apply-templates select="AGE"/>
 		</Participant>
 		<xsl:apply-templates select="DATE"/>
 		<xsl:apply-templates select="PLAC"/>
 		<xsl:apply-templates select="SOUR"/>
 		
 		<!-- Since this event is created from the INDI record we assign this the same
				Change element as it has -->
		<xsl:apply-templates select="../CHAN"/>
 	</EventRec>
 </xsl:template>
 
 <!-- Strictly speaking GEDCOM 6.0 XML makes no distinction between events associated individuals and
 	other events.  But we begin parsing these 2 events within the INDI structure-->
 
 <!-- Handles BIRT Tag-->
 <!-- DOC says how it handles BIRT event including bio mom -->
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
		<!-- Add Mother, iff she is biological, i.e. child not adopted -->
		<xsl:if test="not(../ADOP)">
			<xsl:apply-templates select="../FAMC" mode="BirthEvent"/>
		</xsl:if>
		<xsl:apply-templates select="DATE"/>
		<xsl:apply-templates select="PLAC"/>
		<xsl:apply-templates select="SOUR"/>
			<!-- Since this event is created from the INDI record we assign this the same
				Change element as it has -->
		<xsl:apply-templates select="../CHAN"/>
 	</EventRec>
 </xsl:template><!-- End BIRT template -->

<!-- DOC? Althougth the FAMC has been eliminated from GEDCOM XML 6.0, it will be helpful to locate
 	other participants of a birth event.  The only guaranteed participant at this event would be the mother.  Although
 	the husband made the birth (he or his sperm was/were definitely participant(s) at conception), the  father may be 
 	absent from the event of the birth.  One drawback with this approach is that a birth of a father's child does not show
 	up in the record of there life events.  There is one important caveat.  A child may have several mothers: one and 
 	only one biological and several mothers by adoption -->		
<xsl:template match="FAMC" mode="BirthEvent">
	<xsl:variable name="FamilyID" select="@REF"/>
	<xsl:if test="//FAM[@ID=$FamilyID]/WIFE">
		<xsl:variable name="MotherID" select="//FAM[@ID=$FamilyID]/WIFE/@REF"/>
		<Participant>
			<Link>
				<xsl:attribute name="Target">IndividualRec</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:value-of select="generate-id(//INDI[@ID=$MotherID])"/>
				</xsl:attribute>
			</Link>
			<Role>mother</Role>
		</Participant>
	</xsl:if>
</xsl:template>

 <!-- Handles ADOP Tag -->
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
		<xsl:apply-templates select="FAMC" mode="AdoptionEvent"/>

		<xsl:apply-templates select="DATE"/>
		<xsl:apply-templates select="PLAC"/>
		<xsl:apply-templates select="SOUR"/>
			<!-- Since this event is created from the INDI record we assign this the same
				Change element as it has -->
		<xsl:apply-templates select="../CHAN"/>
 	</EventRec>
 </xsl:template><!-- End BIRT template -->
		
<xsl:template match="FAMC" mode="AdoptionEvent">
	<!-- Get Family Ref -->
	<xsl:variable name="FamilyID" select="@REF"/>
	<!-- Get value of ADOP tag under FAMC -->
	<xsl:variable name="AdoptionParents" select="ADOP"/>
	
	<xsl:choose>
		<xsl:when test="contains( $AdoptionParents, 'HUSB')">
			<xsl:variable name="FatherID" select="//FAM[@ID=$FamilyID]/HUSB/@REF"/>
			<Participant>
				<Link>
					<xsl:attribute name="Target">IndividualRec</xsl:attribute>
					<xsl:attribute name="Ref">
						<xsl:value-of select="generate-id(//INDI[@ID=$FatherID])"/>
					</xsl:attribute>
				</Link>
				<Role>father</Role>
			</Participant>
		</xsl:when>
		<xsl:when test="contains( $AdoptionParents, 'WIFE')">
			<xsl:variable name="MotherID" select="//FAM[@ID=$FamilyID]/WIFE/@REF"/>
			<Participant>
				<Link>
					<xsl:attribute name="Target">IndividualRec</xsl:attribute>
					<xsl:attribute name="Ref">
						<xsl:value-of select="generate-id(//INDI[@ID=$MotherID])"/>
					</xsl:attribute>
				</Link>
				<Role>mother</Role>
			</Participant>
		</xsl:when>
		<xsl:when test="contains( $AdoptionParents, 'BOTH')">
			<!-- TODO consolidate reduntant code -->
			<xsl:variable name="FatherID" select="//FAM[@ID=$FamilyID]/HUSB/@REF"/>
			<Participant>
				<Link>
					<xsl:attribute name="Target">IndividualRec</xsl:attribute>
					<xsl:attribute name="Ref">
						<xsl:value-of select="generate-id(//INDI[@ID=$FatherID])"/>
					</xsl:attribute>
				</Link>
				<Role>father</Role>
			</Participant>
			<xsl:variable name="MotherID" select="//FAM[@ID=$FamilyID]/WIFE/@REF"/>
			<Participant>
				<Link>
					<xsl:attribute name="Target">IndividualRec</xsl:attribute>
					<xsl:attribute name="Ref">
						<xsl:value-of select="generate-id(//INDI[@ID=$MotherID])"/>
					</xsl:attribute>
				</Link>
				<Role>mother</Role>
			</Participant>
		</xsl:when>
	</xsl:choose>
</xsl:template>

 <!-- Handles the FAMILY_EVENT_STRUCTURE  -->
 <xsl:template match="ANUL|CENS|DIV|DIVF|ENGA|MARR|MARB|MARC|MARL|MARS">
   	<EventRec>
 		<xsl:attribute name="Id">
 			<xsl:value-of select="generate-id()"/>
 		</xsl:attribute>
 		<xsl:attribute name="Type">
 			<xsl:choose>
 				 <xsl:when test="contains( name(), 'ANUL')">
 					<xsl:value-of select="'annulment'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'CENS')">
 					<xsl:value-of select="'census'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'DIV')">
 					<xsl:value-of select="'divorce'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'DIVF')">
 					<xsl:value-of select="'divorce filed'"/>
 				</xsl:when>
  				<xsl:when test="contains( name(), 'ENGA')">
 					<xsl:value-of select="'engagement'"/>
 				</xsl:when>
   				<xsl:when test="contains( name(), 'MARR')">
 					<xsl:value-of select="'marriage'"/>
 				</xsl:when>
   				<xsl:when test="contains( name(), 'MARB')">
 					<xsl:value-of select="'marriage banns'"/>
 				</xsl:when>
   				<xsl:when test="contains( name(), 'MARC')">
 					<xsl:value-of select="'marriage contract'"/>
 				</xsl:when>
   				<xsl:when test="contains( name(), 'MARL')">
 					<xsl:value-of select="'marriage license'"/>
 				</xsl:when>
   				<xsl:when test="contains( name(), 'MARS')">
 					<xsl:value-of select="'marriage settlement'"/>
 				</xsl:when>
 			</xsl:choose>
 		</xsl:attribute>
 		<xsl:attribute name="VitalType">
 			<xsl:choose>
  				 <xsl:when test="contains( name(), 'ANUL')">
 					<xsl:value-of select="'marriage'"/>
 				</xsl:when>
				<xsl:when test="contains( name(), 'DIV')">
 					<xsl:value-of select="'divorce'"/>
 				</xsl:when>
    				<xsl:when test="contains( name(), 'MARR')">
 					<xsl:value-of select="'marriage'"/>
 				</xsl:when>
   				<xsl:when test="contains( name(), 'MARB')">
 					<xsl:value-of select="'marriage'"/>
 				</xsl:when>
   				<xsl:when test="contains( name(), 'MARC')">
 					<xsl:value-of select="'marriage'"/>
 				</xsl:when>
   				<xsl:when test="contains( name(), 'MARL')">
 					<xsl:value-of select="'marriage'"/>
 				</xsl:when>
   				<xsl:when test="contains( name(), 'MARS')">
 					<xsl:value-of select="'marriage'"/>
 				</xsl:when>
 			</xsl:choose>
 		</xsl:attribute>
 	 	
	 	<xsl:if test="../HUSB">
 	 		<Participant>
				<Link>
					<xsl:attribute name="Target">IndividualRec</xsl:attribute>
					<xsl:attribute name="Ref">
						<xsl:variable name="HusbID" select="../HUSB/@REF"/>
						<xsl:value-of select="generate-id(//INDI[@ID=$HusbID])"/>
					</xsl:attribute>
				</Link>
				<Role>husband</Role>
				<!-- The <Age> element is not added because GEDCOM 5.5 EVENT_DETAILS have an AGE
					tag, it is unclear to whom the age refers when Family events are by definition more than
					one individual at possibly different ages -->
			</Participant>
		</xsl:if>
		 <xsl:if test="../WIFE">
 	 		<Participant>
				<Link>
					<xsl:attribute name="Target">IndividualRec</xsl:attribute>
					<xsl:attribute name="Ref">
						<xsl:variable name="WifeID" select="../WIFE/@REF"/>
						<xsl:value-of select="generate-id(//INDI[@ID=$WifeID])"/>
					</xsl:attribute>
				</Link>
				<Role>wife</Role>
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
		<xsl:apply-templates select="PLAC"/>
		<xsl:apply-templates select="SOUR"/>
			<!-- Since this event is created from the INDI record we assign this the same
				Change element as it has -->
		<xsl:apply-templates select="../CHAN"/>
	</EventRec>
 </xsl:template>

<xsl:template match="AGE">
	<Age>
		<xsl:value-of select="."/>
	</Age>
</xsl:template>
 
 <!-- Handles CAUS of death tag.  GEDCOM 6.0 XML eliminates this tag, so we surround it in a note -->
 <xsl:template match="CAUS">
 	<Note><xsl:text>Cause of death:  </xsl:text>
 		<xsl:value-of select="."/>
 	</Note>
 </xsl:template>
 <!-- end templates related to death -->
 
 <!-- Handles DATE tag -->
 <xsl:template match="DATE">
 	<!-- TODO assumes all dates are Gregorian will need to adapt to handle others calendars -->
 	<Date Calendar="Gregorian">
		<xsl:value-of select="."/>
 	</Date>
 </xsl:template>
 
 <!-- Handles simple PLAC tag (ex. Fremont, Dodge County, Nebraska, USA) -->
 <!-- TODO? it may be possible to breakdown the above info into PlaceName elements given the Headers PLACE_HIERARCHY--> 
 <xsl:template match="PLAC">
 	<Place>
 		<PlaceName>
 			<xsl:call-template name="handleCONCT"/>	
 		</PlaceName>
 	</Place>
 </xsl:template>
 
 <xsl:template name="persinfo">
	<xsl:apply-templates select="CAST|DSCR|EDUC|IDNO|NATI|NCHI|NMR|OCCU|PROP|RELI|RESI|SSN|TITL"/>
</xsl:template>

<xsl:template match="CAST|DSCR|EDUC|IDNO|NATI|NCHI|NMR|OCCU|PROP|RELI|RESI|SSN|TITL">
	<xsl:variable name="Attribute">
		<xsl:choose>
			<xsl:when test="contains( name(), 'CAST')">
				<xsl:value-of select="'caste'"/>
			</xsl:when>
			<xsl:when test="contains( name(), 'DSCR')">
				<xsl:value-of select="'description'"/>
			</xsl:when>
			<xsl:when test="contains( name(), 'EDUC')">
				<xsl:value-of select="'education'"/>
			</xsl:when>
			<xsl:when test="contains( name(), 'IDNO')">
				<xsl:value-of select="'identification number'"/>
			</xsl:when>
			<xsl:when test="contains( name(), 'NATI')">
				<xsl:value-of select="'nationality'"/>
			</xsl:when>
			<xsl:when test="contains( name(), 'NCHI')">
				<xsl:value-of select="'children'"/>
			</xsl:when>
			<xsl:when test="contains( name(), 'NMR')">
				<xsl:value-of select="'marriage'"/>
			</xsl:when>
			<xsl:when test="contains( name(), 'OCCU')">
				<xsl:value-of select="'occupation'"/>
			</xsl:when>
			<xsl:when test="contains( name(), 'PROP')">
				<xsl:value-of select="'property'"/>
			</xsl:when>
			<xsl:when test="contains( name(), 'RELI')">
				<xsl:value-of select="'religion'"/>
			</xsl:when>
			<xsl:when test="contains( name(), 'RESI')">
				<xsl:value-of select="'residence'"/>
			</xsl:when>
			<xsl:when test="contains( name(), 'SSN')">
				<xsl:value-of select="'social security number'"/>
			</xsl:when>
			<!-- This Probably belongs in the name structure-->
			<xsl:when test="contains( name(), 'TITL')">
				<xsl:value-of select="'title'"/>
			</xsl:when>
		</xsl:choose>
	</xsl:variable>
	<PersInfo>
		<xsl:attribute name="Type">
			<xsl:value-of select="$Attribute"/>
		</xsl:attribute>
		<Information>
			<xsl:value-of select="text()"/>
		</Information>
		<xsl:apply-templates select="DATE"/>
		<xsl:apply-templates select="PLAC"/>
	</PersInfo>
</xsl:template>

<xsl:template name="SourceRecs">
	<!-- If I decide to loop through all 5.5 Records searching for SOUR tag and create in their
		place Link elements, skip the SOUR tag in the HEAD Record-->
  	<xsl:apply-templates select="//SOUR[@ID]"/>
  	<xsl:apply-templates select="//OBJE[@ID]"/>
  </xsl:template>
<!-- Handles simple GEDCOM SOUR_CITATION (no link)  -->
<!-- DOC should note where that the SOURCE_DESCRIPTION has been mapped to Caption Element -->
<xsl:template match="SOUR">
	<Evidence>
		<Citation>
			<Caption>
				<xsl:call-template name="handleCONCT"/>
			</Caption>
			<xsl:apply-templates select="TEXT"/>
			<xsl:apply-templates select="NOTE"/>
		</Citation>
 	</Evidence>
</xsl:template>

<!-- Handles GEDCOM 5.5 SOUR_CITATION (linked), i.e., SOUR @S2@ or GEDML <SOUR REF="S2"/> -->
<!-- Current implementationation discards the valid OBJE or OBJE @O1@ tag inside the SOUR. -->
<!-- DOC should note that QUAY's CERTAINTY_ASSESMENT has been mapped to Note element -->
 <xsl:template match="SOUR[@REF]">
 	<Evidence>
 		<Citation>
			<Link>
				<xsl:attribute name="Target">SourceRec</xsl:attribute>
 				<xsl:attribute name="Ref">
 					<xsl:variable name="SourceID" select="@REF"/>
					<xsl:value-of select="generate-id(//SOUR[@ID=$SourceID])"/>
 				</xsl:attribute>
 			</Link>
 			<xsl:if test="PAGE">
 				<WhereInSource>
 					<xsl:value-of select="PAGE"/>
 				</WhereInSource>
 			</xsl:if>
 			
 			<xsl:if test="DATA/DATE">
 				<WhenRecorded>
 					<xsl:value-of select="DATA/DATE"/>
 				</WhenRecorded>
 			</xsl:if>			
 			
 			<xsl:if test="DATA/TEXT">
 				<xsl:apply-templates select="DATA/TEXT"/>
 			</xsl:if>
			<xsl:if test="QUAY">
 				<Note>
 					<xsl:text>The GEDCOM 5.5 quality of this source is:  </xsl:text>
 					<xsl:value-of select="QUAY"/>
 				</Note>
 			</xsl:if>
			<!-- There can be more than one Note element-->
 			<xsl:apply-templates select="NOTE"/>
 		</Citation>
	</Evidence>
 </xsl:template>
 
 <!-- Handles GEDCOM SOURCE_RECORD, ie. "0 @S2@ SOUR" or GedML <SOUR ID="S2"> -->
 <xsl:template match="SOUR[@ID]">
 	<SourceRec>
 		<xsl:attribute name="Type"/>
 		<xsl:attribute name="Id">
			<xsl:value-of select="generate-id()"/>
 		</xsl:attribute>
 		<xsl:apply-templates select="REPO[@REF]"/>
 		<xsl:apply-templates select="TITL"/>
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
  
<xsl:template match="TITL">
	<Title>
		<xsl:call-template name="handleCONCT"/>
	</Title>
</xsl:template>

<xsl:template match="AUTH">
	<Author>
		<xsl:call-template name="handleCONCT"/>
	</Author>
</xsl:template>
<xsl:template match="PUBL">
	<Publishing>
		<xsl:call-template name="handleCONCT"/>
	</Publishing>
</xsl:template>

 <xsl:template match="SOUR" mode="HeaderRec">
 	<FileCreation>
 		<xsl:attribute name="Date">
 			<!-- DOC Fill Date with global variable -->
			<xsl:value-of select="$FileCreationDate"/>
 		</xsl:attribute>
		<!-- TODO the TIME attribute is option but it can be implement on a continguent basis-->
		<xsl:variable name="theName" select="name(NAME)"/>
		<xsl:if test="NAME or VERS or CORP or DATA/COPR" >
			<!-- Creates Product Element-->
			<Product>
				<!-- TODO DOC mapped SOUR APPROVED_SYSTEM_ID  to ProductID Element -->
				<xsl:if test="VERS">
					<Version>
						<xsl:value-of select="VERS"/>
					</Version>
				</xsl:if>
				<xsl:if test="NAME">
					<Name>
						<xsl:value-of select="NAME"/>
					</Name>
				</xsl:if>
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
				<xsl:if test="DATA/COPR">
					<Copyright>
						<xsl:value-of select="DATA/COPR"/>
					</Copyright>
				</xsl:if>
			</Product>
		</xsl:if>
 	</FileCreation>
 </xsl:template>
 		
<!-- MULTIMEDIA_RECORD -->
<xsl:template match="OBJE[@ID]">
	<SourceRec>
		<xsl:attribute name="Id">
			<xsl:value-of select="generate-id()"/>
		</xsl:attribute>
		<!-- In GEDCOM 5.5 there are only 7 permissable forms: bmp, gif, jpeg, ole, pcx, tiff, wav -->
		<xsl:if test="FORM">
			<xsl:attribute name="Type">
				<xsl:value-of select="FORM"/>
			</xsl:attribute>
		</xsl:if>
		<xsl:if test="TITL">
			<Title>
				<xsl:value-of select="TITL"/>
			</Title>
		</xsl:if>
		<xsl:if test="BLOB">
			<URI>
				<xsl:value-of select="BLOB"/>
			</URI>
		</xsl:if>
		
		<xsl:apply-templates select="NOTE"/>

		<xsl:apply-templates select="CHAN"/>
	</SourceRec>
 </xsl:template>

<xsl:template match="OBJE[@REF]">
	<Evidence>
		<Citation>
			<Link>
				<xsl:attribute name="Target">SourceRec</xsl:attribute>
				<xsl:variable name="ObjeID" select="@REF"/>
				<xsl:attribute name="Ref">
					<xsl:value-of select="generate-id(//OBJE[@ID=$ObjeID])"/>
				</xsl:attribute>
			</Link>
		</Citation>
	</Evidence>
</xsl:template>

<!-- Handle internal OBJE tags, ie. those that aren't links -->
<xsl:template match="OBJE">
	<Evidence>
		<Citation>	
			<Link/>
				<xsl:attribute name="Target">SourceRec</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:value-of select="generate-id()"/>
				</xsl:attribute>
			<xsl:if test="TITL">
				<Caption>
					<xsl:value-of select="TITL"/>
				</Caption>
			</xsl:if>
			<xsl:apply-templates select="NOTE"/>
		</Citation>
	</Evidence>
</xsl:template>



<!-- Handles TEXT or TEXT_FROM_SOURCE -->
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

<xsl:template name="ContactRecs">
	<xsl:apply-templates select="//HEAD/SOUR/CORP"/>
  	<xsl:apply-templates select="//SUBM"/>
</xsl:template>

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
			<xsl:with-param name="PlaceName" select="self::ADDR[text()]"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="PHON"/>
		<!-- Cannot map any more items of the CORP tag to the ContactRec elements-->
	</ContactRec>
</xsl:template>

<!-- Handles SUBM Records of the form 0 @SUB1@ SUBM or gedml <SUBM ID="SUB1"> -->
<xsl:template match="SUBM[@ID]">
	<ContactRec>
		<xsl:attribute name="Id">
			<xsl:value-of select="generate-id()"/>
		</xsl:attribute>
		<!-- TODO?  implement Type attribute with the following values: person, business, organization -->
		<Name>
			<xsl:value-of select="NAME"/>
		</Name>
		<xsl:apply-templates select="ADDR" mode="MailAddress"/>
		<xsl:apply-templates select="PHON"/>
		<!-- Handle OBJE hits as either a <Evidence> Element or as a SourceRec link -->
		<xsl:apply-templates select="OBJE"/>
		
		<xsl:apply-templates select="NOTE"/>
		
		<xsl:call-template name="ExternalIDs"/>
 		
 		<xsl:apply-templates select="CHAN"/>
	</ContactRec>
</xsl:template>

<!-- DOC the <MailAddress> element's use is pretty limited.  It can only occur in GroupRec and ContactRec.  SourceRec,
	EventRec, and IndividualRec cannot connect to it via a <Link> Element contained it a Contact element  -->

<!-- Handles ADDR structure without handling PHON -->
 <xsl:template match="ADDR" mode="MailAddress">
 	<xsl:param name="PlaceName" select="text()"/>
 		<MailAddress>
 			<AddrLine>
 				<Addressee>
 					<xsl:value-of select="$PlaceName"/>
 				</Addressee>
 			</AddrLine>
			<xsl:if test="CONT">
				<AddrLine>
					<xsl:value-of select="self::CONT"/>
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
					<xsl:if test="CTRY">
						<PlacePart Type="country">
							<xsl:value-of select="CTRY"/>
						</PlacePart>
					</xsl:if>
				</AddrLine>
			</xsl:if>
 		</MailAddress>
</xsl:template><!-- end ADDR mode=MailAddress template -->

<!-- Handler ADDR as it occurs in a INDI SOUR OBJE tags -->
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
  
  FIX - The first problem is with the first line.  Instead of a "street address" attribute as I have it below, the contents of a
  ADDR field may be the name of a building "Springfield Hospital" or person's name "Homer Simpson."  I have made this
  a level 7 PlacePart but have left out the Type attribute.  It would best be described as a PlaceName.  It is possible to put
  this information in the PlaceName element because that permits PCDATA.  However, the contents of ADDR may in fact be a
  streetname because it is perfectly acceptable for ADDR to contain that instead of a building name.
  For example, a person's home address does not have a PlaceName - their home does not have a name.  It can instead
  be identified like a postal address
  Homer Simpson
  11 Drive
  Springfield
  
  DOC - I have decided that this program will always assume that the ADDR line as opposed to the ADR1 and ADR2
  lines contains PCDATA that indicates a placename such as ACME Publishing Company or, in the case of a personal address, 
  the person's name
  
 The second problem involves the PHON tag.  There is no equivalent in a <Place> element.  
 
  -->
 <xsl:template match="ADDR" mode="PlacePart">
 	<Place>
 		<PlaceName>
			<xsl:call-template name="handleCONCT"/>
 			<xsl:for-each select="node()">
 				<xsl:choose>
 					<xsl:when test="self::ADR1">
  						<!-- DOC street name is not localized -->
 						<PlacePart Level="6" Type="street name">
 							<xsl:value-of select="self::ADR1"/>
 						</PlacePart>					
 					</xsl:when>
 					<xsl:when test="self::ADR2">
 						<PlacePart level="6" Type="street name">
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
 		</PlaceName>
 	</Place>
 </xsl:template>
 
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

<!-- HANDLE linked NOTE_STRUCTURE.  NOTE tags that reference a NOTE_RECORD will not be linked in 
	GEDCOM XML 6.0 because there is no mechanism for that.  There contents will instead be place in
	the element which referenced them -->
<xsl:template match="NOTE[@REF]">
	<xsl:variable name="NoteID" select="@REF"/>
	<xsl:apply-templates select="//NOTE[@ID=$NoteID]"/>
</xsl:template>

<xsl:template match="NOTE[@ID]">
	<Note>
		<xsl:call-template name="handleCONCT"/>
	</Note>
</xsl:template>
<!-- Handles "simple" NOTE_STRUCTURE -->
<xsl:template match="NOTE">
	<Note>
		<xsl:call-template name="handleCONCT"/>
	</Note>
</xsl:template>

<!-- Handles FAMILY_RECORD-->
<xsl:template match="FAM">
	<!-- First Create/get the  HUSB and WIFE ids, if they exist -->
	<xsl:variable name="HusbID">
		<xsl:if test="HUSB">
			<xsl:variable name="husbRef" select="HUSB/@REF"/>
			<xsl:value-of select="generate-id(//INDI[@ID=$husbRef])"/>
		</xsl:if>
	</xsl:variable>
	<xsl:variable name="WifeID">
		<xsl:if test="WIFE">
			<xsl:variable name="wifeRef" select="WIFE/@REF"/>
			<xsl:value-of select="generate-id(//INDI[@ID=$wifeRef])"/>
		</xsl:if>
	</xsl:variable>

	<FamilyRec>
		<xsl:attribute name="Id">
			<xsl:value-of select="generate-id()"/>
		</xsl:attribute>
			<xsl:if test="HUSB">
				<HusbFath>
					<Link>
						<xsl:attribute name="Target">IndividualRec</xsl:attribute>
					 	<xsl:attribute name="Ref">
 							<xsl:variable name="husbRef" select="HUSB/@REF"/>
							<xsl:value-of select="generate-id(//INDI[@ID=$husbRef])"/>
 						</xsl:attribute>
 					</Link>
				</HusbFath>
			</xsl:if>
			<xsl:if test="WIFE">
				<WifeMoth>
					<Link>
						<xsl:attribute name="Target">IndividualRec</xsl:attribute>
 						<xsl:attribute name="Ref">
							<xsl:variable name="wifeRef" select="WIFE/@REF"/>
							<xsl:value-of select="generate-id(//INDI[@ID=$wifeRef])"/>
  						</xsl:attribute>
  					</Link>
				</WifeMoth>
			</xsl:if>
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

		<xsl:apply-templates select="SOUR"/>
		
		<xsl:apply-templates select="CHAN"/>
	</FamilyRec>
</xsl:template>

<xsl:template match="CHIL">
	<Child>	
		<Link>
			<xsl:attribute name="Target">IndividualRec</xsl:attribute>
 			<xsl:attribute name="Ref">
 				<xsl:variable name="childID" select="@REF"/>
				<xsl:value-of select="generate-id(//INDI[@ID=$childID])"/>
			</xsl:attribute>
		</Link>
			<xsl:choose>
 <!-- TEST to  determinine if ADOP handled correctly -->
 				<xsl:when test="//INDI[@ID=@REF]/ADOP">
 					<xsl:element name="RelToMoth">adopted</xsl:element>
					<xsl:element name="RelToFath">adopted</xsl:element>	
 				</xsl:when>
				<xsl:otherwise>
					<xsl:element name="RelToMoth">biological</xsl:element>
					<xsl:element name="RelToFath">biological</xsl:element>
				</xsl:otherwise>
			</xsl:choose>
		<ChildNbr><xsl:number/></ChildNbr>
	</Child>
</xsl:template><!-- End CHIL template-->

<!-- Handle CHIL elements in the context of creating Family EventRec Particpants -->
<xsl:template match="CHIL" mode="Events">
	<Participant>
		<Link>
			<xsl:attribute name="Target">IndividualRec</xsl:attribute>
			<xsl:attribute name="Ref">
				<xsl:variable name="ChildID" select="CHIL/@REF"/>
				<xsl:value-of select="generate-id(//INDI[@ID=$ChildID])"/>
			</xsl:attribute>
		</Link>
		<Role>child</Role>
	</Participant>
</xsl:template>

<!-- Handles CHAN tag -->
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
		<!-- This is a hack since I can't figure out how to loop into the TIME element/tag -->
		<xsl:attribute name="Time">
				<xsl:value-of select="DATE/TIME"/>
		</xsl:attribute>
		<xsl:apply-templates select="NOTE"/>
	</Changed>
</xsl:template>

<!-- Handles REPO @R2@ -->
<xsl:template match="REPO[@REF]">
	<Repository>
		<Link>
			<xsl:attribute name="Target">RepositoryRec</xsl:attribute>
			<xsl:attribute name="Id">
				<xsl:variable name="RepoID" select="@REF"/>
				<xsl:value-of select="generate-id(//REPO[@ID=$RepoID])"/>
			</xsl:attribute>
		</Link>
		<xsl:apply-templates select="CALN"/>
	</Repository>
</xsl:template>

<xsl:template match="CALN">
	<CallNbr>
		<xsl:value-of select="text()"/>
	</CallNbr>
</xsl:template>

<!-- Handles 0 @R2@ REPO -->
<xsl:template match="REPO[@ID]">
	<RepositoryRec>
		<xsl:attribute name="Id">
			<xsl:value-of select="generate-id()"/>
		</xsl:attribute> 
		<Name>
			<xsl:value-of select="NAME"/>
		</Name>
		<xsl:apply-templates select="ADDR" mode="MailAddress"/>
		<xsl:apply-templates select="PHON"/>
		<!-- not implementing Email or URI elements because no equivalent in GEDCOM 5.5 -->
		<xsl:apply-templates select="NOTE"/>
		<xsl:apply-templates select="CHAN"/>
	</RepositoryRec>
</xsl:template>

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
			<xsl:attribute name="Type">User</xsl:attribute>
			<xsl:attribute name="Id">
				<xsl:value-of select="@ID"/>
			</xsl:attribute>
		</ExternalID>
</xsl:template>

<xsl:template match="REFN">
	<ExternalID>
		<xsl:attribute name="Type">REFN</xsl:attribute>
		<xsl:attribute name="Id">
			<xsl:value-of select="text()"/>
		</xsl:attribute>
	</ExternalID>
</xsl:template>

</xsl:stylesheet>
