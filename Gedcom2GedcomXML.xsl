<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<!-- $ID$ -->
<!-- At the moment, this stylesheet creates the GEDCOM XML according to this pattern:
	1) Name elements
	2) Vital Event elements
	3) PersInfo elements SSN NMR NCHI OCCU EDUC
	4) Other event elements CONF BAPM IMMI 
	5) Family elements 
IOW, it does not follow how the original flow of the input GEDCOM 5.5 file -->
<xsl:output method="xml" indent="yes"/>
<!-- TODO add param to set the Type attribute in the ExternalID -->
<!--For Debugging -->
<xsl:template match="/">

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
<!-- GroupRec -->
<!-- What do I do with GEDCOM 5.5 "0 @N1@ NOTE" -->

 	
 	</GEDCOM>
</xsl:template>

<!-- Template from HEAD to HeaderRec -->
<xsl:template match="HEAD">
	<HeaderRec>
		<xsl:for-each select="node()">
			<xsl:choose>
				<xsl:when test="self::DATE">
					<FileCreation>
						<xsl:attribute name="Date">
							<xsl:value-of select="text()"/>
						</xsl:attribute>
						<!-- Only #IMPLIED in FileCreation Element-->
						<xsl:if test="TIME">
							<xsl:attribute name="Time">
								<xsl:value-of select="TIME"/>
							</xsl:attribute>
						</xsl:if>
					</FileCreation>
				</xsl:when>
				<xsl:when test="self::SOUR">
					<Product>
						<ProductId>
							<xsl:value-of select="."/>
						</ProductId>
						<Name>
							<xsl:value-of select="."/>
						</Name>
					</Product>
				</xsl:when>
				<xsl:when test="self::SUBM">
					<Submitter>
						<Link Target="ContactRec">
							<xsl:attribute name="Ref">
								<xsl:variable name="SubmID" select="@REF"/>
								<xsl:value-of select="generate-id(//SUBM[@ID=$SubmID])"/>
							</xsl:attribute>
						</Link>
					</Submitter>
				</xsl:when>
			</xsl:choose>	
		</xsl:for-each>
	</HeaderRec>
</xsl:template> <!-- end Template for HEAD to HeaderRec -->

<!-- Handles SUBM Records of the form 0 @SUB1@ SUBM or gedml <SUBM ID="SUB1"> -->
<xsl:template match="SUBM[@ID]">
	<ContactRec>
		<xsl:attribute name="Id">
			<xsl:value-of select="generate-id()"/>
		</xsl:attribute>
		<!-- TODO?  implement Type attribute with the following values: person, business, organization -->
		<xsl:apply-templates select="NAME"/>
		<xsl:apply-templates select="ADDR"/>
		<xsl:apply-templates select="PHON"/>
		<!-- Handle OBJE hits as either a <Evidence> Element or as a SourceRec link -->
		<xsl:apply-templates select="OBJE"/>
		
		<xsl:apply-templates select="NOTE"/>
		
		<xsl:call-template name="ExternalIDs"/>
 		
 		<xsl:apply-templates select="CHAN"/>
	</ContactRec>
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
 </xsl:template>
 <xsl:template match="SEX">
 	<Gender>
 		<xsl:value-of select="."/>
 	</Gender>
 </xsl:template><!-- end NICK template -->
 
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
 <!-- TODO will need to handle all elements related to PLAC such as PlaceName PlaceNameVar --> 
 <xsl:template match="PLAC">
 	<Place>
 		<PlaceName>
 			<xsl:call-template name="handleCONCT"/>	
 		</PlaceName>
 	</Place>
 </xsl:template>
 
 <!-- Handles ADDR structure without handling PHON -->
 <xsl:template match="ADDR">
 		<MailAddress>
 			<AddrLine>
 				<xsl:value-of select="text()"/>
 			</AddrLine>
 			<xsl:for-each select="node()">
				<xsl:choose>
					<xsl:when test="self::ADR1">
						<AddrLine>
							<xsl:value-of select="self::ADR1"/>
						</AddrLine>
					</xsl:when>
					<xsl:when test="self::ADR2">
						<AddrLine>
							<xsl:value-of select="self::ADR2"/>
						</AddrLine>
					</xsl:when>
					<xsl:when test="self::CITY">
						<AddrLine Type="city">
							<xsl:value-of select="self::CITY"/>
						</AddrLine>
					</xsl:when>
					<xsl:when test="self::STAE">
						<AddrLine Type="state">
							<xsl:value-of select="self::STAE"/>
						</AddrLine>
					</xsl:when>
					<xsl:when test="self::POST">
						<AddrLine Type="postal code">
							<xsl:value-of select="self::POST"/>
						</AddrLine>
					</xsl:when>
					<xsl:when test="self::CTRY">
						<AddrLine Type="country">
							<xsl:value-of select="self::CTRY"/>
						</AddrLine>
					</xsl:when>
 				</xsl:choose>
			</xsl:for-each>
 		</MailAddress>
</xsl:template><!-- end ADDR template -->

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
 
 			<xsl:apply-templates select="NOTE"/>
 		</Citation>
	</Evidence>
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
			<Link>
				<xsl:attribute name="Target">SourceRec</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:value-of select="generate-id()"/>
				</xsl:attribute>
			</Link>
			<xsl:if test="TITL">
				<Caption>
					<xsl:value-of select="TITL"/>
				</Caption>
			</xsl:if>
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
 
 <xsl:template name="ContactRecs">
  	<xsl:apply-templates select="//SUBM"/>
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

<!-- TODO HANDLE linked NOTE_STRUCTURE -->
<xsl:template match="NOTE[@REF]">
</xsl:template>

<!-- Handles "simple NOTE_STRUCTURE 
	TODO Handle the NOTE @N2@ which may occur in the GEDCOM 5.5 standard -->
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

<!-- Handles 0 @R2@ REPO -->
<xsl:template match="REPO[@ID]">
</xsl:template>

<xsl:template match="CALN">
	<CallNbr>
		<xsl:value-of select="text()"/>
	</CallNbr>
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
