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
<!-- Start at Root-->
<xsl:template match="/">
	<GEDCOM>
 	<xsl:apply-templates select="//HEAD"/>
 <!-- 	<xsl:apply-templates select="//SUBM"/> -->
 	<xsl:apply-templates select="//FAM"/>
 	<xsl:apply-templates select="//INDI"/>
<!--  	<xsl:apply-templates select="//SOUR"/>
 	<xsl:apply-templates select="//NOTE"/> -->
 	
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
								<xsl:value-of select="@REF"/>
							</xsl:attribute>
						</Link>
					</Submitter>
				</xsl:when>
			</xsl:choose>	
		</xsl:for-each>
	</HeaderRec>
</xsl:template> <!-- end Template for HEAD to HeaderRec -->

<!-- Template for INDI to IndividualRec -->
 <xsl:template match="INDI">
	<IndividualRec>
		<xsl:attribute name="Id">
			<xsl:value-of select="generate-id()"/>
		</xsl:attribute>
		<xsl:apply-templates select="NAME"/>
		<xsl:apply-templates select="SEX"/>

		<!-- BAPM, CONF, IMMI etc. -->
		<xsl:call-template name="persinfo"/>
		<xsl:call-template name="extras"/>
	<!--	<xsl:call-template name="family-links"/> -->	
		<xsl:apply-templates select="CHAN"/>
		<ExternalID>
			<xsl:attribute name="Type">User</xsl:attribute>
			<xsl:attribute name="Id">
				<xsl:value-of select="@ID"/>
			</xsl:attribute>
		</ExternalID>
	</IndividualRec>
	<xsl:call-template name="vitalevents"/>
	<xsl:call-template name="otherevents"/>
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
		<!-- I have to implement NPFX GIVN SPFX SURN and NSFX -->
		<!-- Implementing NICK separately -->
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
 
 <!-- Strictly speaking GEDCOM 6.0 XML makes no distinction between events associated individuals and
 	other events.  But we begin parsing these 2 events within the INDI structure-->
 <xsl:template name="vitalevents">
 	<xsl:apply-templates select="BIRT"/>
 	<xsl:apply-templates select="DEAT"/>
 </xsl:template>
 
 <!-- Handles BIRT Tag-->
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
			<Role>principal</Role>
		</Participant>
		<xsl:apply-templates select="DATE"/>
		<xsl:apply-templates select="PLAC"/>
		<xsl:apply-templates select="SOUR[@REF]"/>
			<!-- Since this event is created from the INDI record we assign this the same
				Change element as it has -->
		<xsl:apply-templates select="../CHAN"/>
 	</EventRec>
 </xsl:template><!-- End BIRT template -->
 
 <!-- begin templates related to death -->
 <xsl:template match="DEAT">
 	<EventRec>
 		<xsl:attribute name="Id">
 			<xsl:value-of select="generate-id()"/>
 		</xsl:attribute>
 		<xsl:attribute name="Type">death</xsl:attribute>
 		<xsl:attribute name="VitalType">death</xsl:attribute>
 		<Participant>
			<Link>
				<xsl:attribute name="Target">IndividualRec</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:value-of select="generate-id(..)"/>
				</xsl:attribute>
			</Link>
			<Role>principal</Role>
		</Participant>
		<xsl:apply-templates select="DATE"/>
		<xsl:apply-templates select="PLAC"/>
		<xsl:apply-templates select="SOUR[@REF]"/>
			<!-- Since this event is created from the INDI record we assign this the same
				Change element as it has -->
		<xsl:apply-templates select="../CHAN"/>
 	</EventRec>
 </xsl:template> <!-- end DEAT template -->
 
 <!-- Handles BURI tag -->
 <xsl:template match="BURI">
  	<EventRec>
 		<xsl:attribute name="Id">
 			<xsl:value-of select="generate-id()"/>
 		</xsl:attribute>
 		<xsl:attribute name="Type">burial</xsl:attribute>
 		<Participant>
			<Link>
				<xsl:attribute name="Target">IndividualRec</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:value-of select="generate-id(..)"/>
				</xsl:attribute>
			</Link>
			<Role>principal</Role>
		</Participant>
		<xsl:apply-templates select="DATE"/>
		<xsl:apply-templates select="PLAC"/>
		<xsl:apply-templates select="SOUR[@REF]"/>
			<!-- Since this event is created from the INDI record we assign this the same
				Change element as it has -->
		<xsl:apply-templates select="../CHAN"/>
 	</EventRec>
 </xsl:template>
 
 <!-- Handles CREM tag -->
 <xsl:template match="CREM">
  	<EventRec>
 		<xsl:attribute name="Id">
 			<xsl:value-of select="generate-id()"/>
 		</xsl:attribute>
 		<xsl:attribute name="Type">cremation</xsl:attribute>
 		<Participant>
			<Link>
				<xsl:attribute name="Target">IndividualRec</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:value-of select="generate-id(..)"/>
				</xsl:attribute>
			</Link>
			<Role>principal</Role>
		</Participant>
		<xsl:apply-templates select="DATE"/>
		<xsl:apply-templates select="PLAC"/>
		<xsl:apply-templates select="SOUR[@REF]"/>
			<!-- Since this event is created from the INDI record we assign this the same
				Change element as it has -->
		<xsl:apply-templates select="../CHAN"/>
 	</EventRec>
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
 		<xsl:value-of select="."/>
 	</Place>
 </xsl:template>
 
 <!-- Handles ADDR structure without handling PHON -->
 <xsl:template match="ADDR">
 	<ContactRec>
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
 	</ContactRec>
</xsl:template><!-- end ContactRec template -->

<!-- FIX if at all possible.  Usually the PHON tag belongs to the MailAddress ContactRec
	The problem is that GEDCOM 5.5 strict places the PHON and the ADDR tags at the same
	level.  The current implementation simply surrounds the Phone element with at ContactRec, losing, IOW,
	the relationship between the MailAddress and the Phone
-->
<xsl:template match="PHON">
	<ContactRec>
		<Phone>
			<xsl:value-of select="."/>
		</Phone>
	</ContactRec>
</xsl:template>

 <xsl:template name="persinfo">
	<xsl:if test="RELI">
		<PersInfo Type="religion">
			<Information>
				<xsl:value-of select="RELI"/>
			</Information>
		</PersInfo>
	</xsl:if>
	<xsl:if test="SSN">
		<PersInfo Type="SSN">
			<Information>
				<xsl:value-of select="SSN"/>
			</Information>
		</PersInfo>
	</xsl:if>
	<xsl:apply-templates select="EDUC"/>

	<xsl:apply-templates select="OCCU"/>
</xsl:template>

 <xsl:template match="EDUC">
 	<PersInfo Type="education">
		<Information>
 			<xsl:value-of select="text()"/>
		</Information>
 		<xsl:apply-templates select="child::*"/>
 	</PersInfo>
 </xsl:template>
 
 <xsl:template match="OCCU">
 	<PersInfo Type="occupation">
 		<Information>
 			<xsl:value-of select="text()"/>
 		</Information>
 		<xsl:apply-templates select="child::*"/>
 	</PersInfo>
 </xsl:template>
 
<xsl:template name="extras">
	<xsl:apply-templates select="NMR"/>
	<xsl:apply-templates select="NCHI"/>
</xsl:template>

<xsl:template match="NMR">
	<PersInfo Type="marriage">
			<Information>
				<xsl:value-of select="text()"/>
			</Information>
		<xsl:apply-templates select="child::*"/>
	</PersInfo>
</xsl:template>

<xsl:template match="NCHI">
	<PersInfo Type="children">
		<Information>
			<xsl:value-of select="text()"/>
		</Information>
		<xsl:apply-templates select="child::*"/>
	</PersInfo>
</xsl:template>

<!-- FIX this is wrong -->
<xsl:template match="AGE">
	<Particpant>
		<Age>
			<xsl:value-of select="."/>
		</Age>
	</Particpant>
</xsl:template>

 <xsl:template name="otherevents">
 	<xsl:apply-templates select="BAPM"/>
 	<xsl:apply-templates select="CONF"/>
 	<xsl:apply-templates select="IMMI"/>
 </xsl:template>
 <xsl:template match="BAPM">
 	<EventRec>
 		<xsl:attribute name="Id">
 			<xsl:value-of select="generate-id()"/>
 		</xsl:attribute>
 		<xsl:attribute name="Type">baptism</xsl:attribute>
 		<Participant>
			<Link>
				<xsl:attribute name="Target">IndividualRec</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:value-of select="generate-id(..)"/>
				</xsl:attribute>
			</Link>
			<Role>principal</Role>
		</Participant>
		<xsl:apply-templates select="DATE"/>
		<xsl:apply-templates select="PLAC"/>
		<xsl:apply-templates select="SOUR[@REF]"/>
			<!-- Since this event is created from the INDI record we assign this the same
				Change element as it has -->
		<xsl:apply-templates select="../CHAN"/>
 	</EventRec>
 </xsl:template>

 <xsl:template match="CONF">
 	<EventRec>
 		<xsl:attribute name="Id">
 			<xsl:value-of select="generate-id()"/>
 		</xsl:attribute>
 		<xsl:attribute name="Type">confirmation</xsl:attribute>
 		<Participant>
			<Link>
				<xsl:attribute name="Target">IndividualRec</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:value-of select="generate-id(..)"/>
				</xsl:attribute>
			</Link>
			<Role>principal</Role>
		</Participant>
		<xsl:apply-templates select="DATE"/>
		<xsl:apply-templates select="PLAC"/>
		<xsl:apply-templates select="SOUR[@REF]"/>
			<!-- Since this event is created from the INDI record we assign this the same
				Change element as it has -->
		<xsl:apply-templates select="../CHAN"/>
 	</EventRec>
 </xsl:template>

 <xsl:template match="IMMI">
  	<EventRec>
 		<xsl:attribute name="Id">
 			<xsl:value-of select="generate-id()"/>
 		</xsl:attribute>
 		<xsl:attribute name="Type">immigration</xsl:attribute>
 		<Participant>
			<Link>
				<xsl:attribute name="Target">IndividualRec</xsl:attribute>
				<xsl:attribute name="Ref">
					<xsl:value-of select="generate-id(..)"/>
				</xsl:attribute>
			</Link>
			<Role>principal</Role>
		</Participant>
		<xsl:apply-templates select="DATE"/>
		<xsl:apply-templates select="PLAC"/>
		<xsl:apply-templates select="SOUR[@REF]"/>
			<!-- Since this event is created from the INDI record we assign this the same
				Change element as it has -->
		<xsl:apply-templates select="../CHAN"/>
 	</EventRec>
 </xsl:template>
 
 <xsl:template name="family-links">
 	<xsl:apply-templates select="FAMC"/>
 	<xsl:apply-templates select="FAMS"/>
 </xsl:template>
 <!-- not used in GEDCOM XML 6.0 Beta  where IndividualRecs are not linked to FamilyRecs, but
   	its the other way around -->
 <xsl:template match="FAMC">
 	<FamilyRec>
 		<Child>
 			<Link>
 				<xsl:attribute name="Target">FamilyRec</xsl:attribute>
 				<xsl:attribute name="Ref">
 					<xsl:value-of select="@REF"/>
 				</xsl:attribute>
 			</Link>
 <!-- TODO handle sealing -->
 			<xsl:choose>
 <!-- TEST to  determinine if ADOP handled correctly -->
 				<xsl:when test="parent::ADOP">
 					<xsl:element name="RelToMoth">adopted</xsl:element>
					<xsl:element name="RelToFath">adopted</xsl:element>	
 				</xsl:when>
				<xsl:otherwise>
					<xsl:element name="RelToMoth">biological</xsl:element>
					<xsl:element name="RelToFath">biological</xsl:element>
				</xsl:otherwise>
			</xsl:choose>
 		</Child>
 		<!-- TODO handle SOUR and NOTE -->
 	</FamilyRec>
 </xsl:template>
 
 <!-- As of this implementation, when the FAMS template is called it creates both HusbFath and WifeMoth elements
 	even when GEDCOM 5.5 strict they are optional (i.e., mother or father unknown) as it is in
 	GEDCOM XML 6.0 beta
 -->
 <!-- not used in GEDCOM XML 6.0 Beta  where IndividualRecs are not linked to FamilyRecs, but
   	its the other way around -->
 <xsl:template match="FAMSold">
 	<xsl:variable name="Ref" select="@REF"/>
 	<FamilyRec>
 		<HusbFath>
 			<Link>
 				<xsl:attribute name="Target">
 				<xsl:text>IndividualRec</xsl:text>
 				</xsl:attribute>
 				<xsl:attribute name="Ref">
 					<xsl:value-of select="//FAM[@ID=$Ref]/HUSB/@REF"/>
 				</xsl:attribute>
 			</Link>
 		</HusbFath>
 		<WifeMoth>
 			<Link>
 			 	<xsl:attribute name="Target">
 				<xsl:text>IndividualRec</xsl:text>
 				</xsl:attribute>
 				<xsl:attribute name="Ref">
					<xsl:value-of select="//FAM[@ID=$Ref]/WIFE/@REF"/>
 				</xsl:attribute>
 			</Link>
 		</WifeMoth>
 	</FamilyRec>
 </xsl:template>
 
<xsl:template match="CHAN">
	<Change>
		<xsl:attribute name="Date">
			<xsl:value-of select="DATE"/>
		</xsl:attribute>
		<xsl:attribute name="Time">
			<xsl:value-of select="DATE/TIME"/>
		</xsl:attribute>
		<xsl:apply-templates select="NOTE"/>
	</Change>
</xsl:template>
 <!-- this does not work when call like this:

  	<xsl:call-template name="events">
 		<xsl:with-param name="eventType"  select="BAPM|CONF"/>
 	</xsl:call-template>
  -->
<xsl:template name="events">
	<xsl:param name="eventType"/>
	<EventRec>
	<xsl:choose>
		<xsl:when test="contains( $eventType, 'BAPM')">
			<xsl:attribute name="Type"><xsl:text>baptism</xsl:text></xsl:attribute>
		</xsl:when>
		<xsl:when test="contains( $eventType, 'CONF')">
			<xsl:attribute name="Type"><xsl:text>confirmation</xsl:text></xsl:attribute>
		</xsl:when>
	</xsl:choose>
	</EventRec>
</xsl:template>

<!-- Handles simple GEDCOM SOUR_CITATION (no link)  -->
<xsl:template match="SOUR">
<Evidence>
	<Citation>
		<Extract>
			<xsl:value-of select="text()"/>	
			<xsl:for-each select="CONT">
				<br/>
				<xsl:value-of select="CONT"/>
			</xsl:for-each>
			<xsl:for-each select="CONC">
				<!-- Add Space to prevent lines running together-->
				<xsl:text> </xsl:text>
				<xsl:value-of select="CONC"/>
			</xsl:for-each>
		</Extract>
		<xsl:apply-templates select="NOTE"/>
	</Citation>
 </Evidence>
</xsl:template>

<!-- Handles GEDCOM 5.5 SOUR_CITATION (linked), i.e., SOUR @S2@ or GEDML <SOUR REF="S2"/> -->
<!-- TEST -->
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
 			<xsl:for-each select="child::*">
 				<xsl:choose>
 					<xsl:when test="self::PAGE">
 					 	<WhereInSource>
 							<xsl:value-of select="self::PAGE"/>
 						</WhereInSource>
 					</xsl:when>
 					<xsl:when test="self::QUAY">
 						<Note>
 							<xsl:text>The GEDCOM 5.5 quality of this source is:  </xsl:text>
 							<xsl:value-of select="self::QUAY"/>
 						</Note>
 					</xsl:when>
 					<xsl:when test="self::DATA">
 						<xsl:apply-templates select="self::DATA"/>
 					</xsl:when>
 				</xsl:choose>
 			</xsl:for-each>
 			<xsl:if test="DATA/DATE">
 				<WhenRecorded>
 					<xsl:value-of select="DATA/DATE"/>
 				</WhenRecorded>
 			</xsl:if>
 			<xsl:apply-templates select="NOTE"/>
 		</Citation>
	</Evidence>
 </xsl:template>
 
<xsl:template match="OBJE[@ID]"> 	
 </xsl:template>
 <!-- GEDCOM's 5.5 DATA has been dropped in GEDCOM XML 6.0 but I dotn't think we should lose
 	this information, hence it is wrapped in a Note element -->
 <xsl:template match="DATA">
 	<Note>
 		<xsl:text>The date of this information is:  </xsl:text>
 	</Note>
 	<Extract>
 <!-- TODO handle the CONC and CONT tags in the TEXT element (add spaces at each occurance) -->
 		<xsl:value-of select="TEXT"/>
 	</Extract>
</xsl:template>

<!-- Handles GEDCOM SOURCE_RECORD, ie. "0 @S2@ SOUR" or GedML <SOUR ID="S2"> -->
 <xsl:template match="SOUR[@ID]">
 	<SourceRec>
 		<xsl:attribute name="Type"/>
 		<xsl:attribute name="Id">
			<xsl:value-of select="generate-id()"/>
 		</xsl:attribute>
 		<!-- TODO implement Repository -->
 		<xsl:apply-templates select="TITL"/>
 		<xsl:apply-templates select="AUTH"/>
 		<xsl:if test="OBJE/FILE">
 			<URI>
 				<xsl:value-of select="OBJE/FILE"/>
 			</URI>
 		</xsl:if>
 		<xsl:apply-templates select="PUBL"/>
 		<xsl:if test="TEXT">
 			<Evidence>
 				<Citation>
 					<xsl:if test="OBJE[@REF]">
 						<Link>
 							<xsl:attribute name="Target">SourceRec</xsl:attribute>
 							<xsl:attribute name="Ref">
 								<xsl:variable name="ObjectID" select="OBJE[@REF]"/>
 								<xsl:value-of select="generate-id(//SOUR[@ID=$ObjectID])"/>
 							</xsl:attribute>
 						</Link>
 					</xsl:if>
 					<xsl:if test="DATA/EVEN/DATE">
 						<WhenRecorded>
 							<xsl:value-of select="DATA/EVEN/DATE"/>
 						</WhenRecorded>
 					</xsl:if>
 					<xsl:apply-templates select="TEXT"/>
 				</Citation>
 			</Evidence>
 		</xsl:if>
 		<xsl:apply-templates select="NOTE"/>
 		<xsl:apply-templates select="CHAN"/>
 		<ExternalID>
 			<xsl:attribute name="Type">User</xsl:attribute>
 			<xsl:attribute name="Id">
 				<xsl:value-of select="@ID"/>
 			</xsl:attribute>
 		</ExternalID>
 	</SourceRec>
 </xsl:template>	

<xsl:template match="TITL">
	<Title>
		<xsl:value-of select="text()"/>
		<xsl:for-each select="CONT">
			<xsl:text> </xsl:text>
			<xsl:value-of select="CONT"/>
		</xsl:for-each>
		<xsl:for-each select="CONC">
			<xsl:text> </xsl:text>
			<xsl:value-of select="CONC"/>
		</xsl:for-each>
	</Title>
</xsl:template>
<xsl:template match="AUTH">
	<Author>
		<xsl:value-of select="text()"/>
		<xsl:for-each select="CONT">
			<xsl:text> </xsl:text>
			<xsl:value-of select="CONT"/>
		</xsl:for-each>
		<xsl:for-each select="CONC">
			<xsl:text> </xsl:text>
			<xsl:value-of select="CONC"/>
		</xsl:for-each>
	</Author>
</xsl:template>
<xsl:template match="PUBL">
	<Publishing>
		<xsl:value-of select="text()"/>
		<xsl:for-each select="CONT">
			<xsl:text> </xsl:text>
			<xsl:value-of select="CONT"/>
		</xsl:for-each>
		<xsl:for-each select="CONC">
			<xsl:text> </xsl:text>
			<xsl:value-of select="CONC"/>
		</xsl:for-each>
	</Publishing>
</xsl:template>
<!-- Handles TEXT or TEXT_FROM_SOURCE -->
<xsl:template match="TEXT">
	<Extract>
		<xsl:value-of select="text()"/>
		<xsl:for-each select="CONT">
			<br/>
			<xsl:value-of select="CONT"/>
		</xsl:for-each>
		<xsl:for-each select="CONC">
			<xsl:text> </xsl:text>
			<xsl:value-of select="CONC"/>
		</xsl:for-each>
	</Extract>
</xsl:template>
<!-- TODO HANDLE linked NOTE_STRUCTURE -->
<xsl:template match="NOTE[@REF]">
</xsl:template>
<!-- Handles "simple NOTE_STRUCTURE 
	TODO Handle the SOUR @S2@ which may occur in the GEDCOM 5.5 standard -->
<xsl:template match="NOTE">
	<Note>
		<xsl:value-of select="text()"/>
		<xsl:for-each select="CONT">
			<xsl:text> </xsl:text>
			<xsl:value-of select="CONT"/>
		</xsl:for-each>
		<xsl:for-each select="CONC">
			<xsl:text> </xsl:text>
			<xsl:value-of select="CONC"/>
		</xsl:for-each>
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

	<!-- Create separate EventRect elementfor MARR and DIV which no longer belong in a FamilyRec as
		they did in a FAMILY_STRUCTURE -->
	<xsl:if test="MARR">
		<EventRec>
			<xsl:attribute name="Id">
				<xsl:value-of select="generate-id(child::MARR)"/>
			</xsl:attribute>
			<xsl:attribute name="Type">marriage</xsl:attribute>
			<xsl:attribute name="VitalType">marriage</xsl:attribute>
			<xsl:if test="HUSB">
				<Participant>
					<Link>
						<xsl:attribute name="Target">IndividualRec</xsl:attribute>
						<xsl:attribute name="Ref">
							<xsl:value-of select="$HusbID"/>
						</xsl:attribute>
					</Link>
					<Role>husband</Role>
				</Participant>
			</xsl:if>
			<xsl:if test="WIFE">
				<Participant>
					<Link>
						<xsl:attribute name="Target">IndividualRec</xsl:attribute>
						<xsl:attribute name="Ref">
							<xsl:value-of select="$WifeID"/>
						</xsl:attribute>
					</Link>
					<Role>wife</Role>
				</Participant>
			</xsl:if>
			<xsl:apply-templates select="DATE"/>
			<xsl:apply-templates select="PLAC"/>
			<xsl:apply-templates select="SOUR[@REF]"/>
			<!-- Since the MARR event is created from the FAM record we assign this the same
				Change element as the FAM -->
			<xsl:apply-templates select="parent::CHAN"/>
		</EventRec>
	</xsl:if>
	<xsl:if test="DIV">
		<EventRec>
			<xsl:attribute name="Id">
				<xsl:value-of select="generate-id(child::DIV)"/>
			</xsl:attribute>
			<xsl:attribute name="Type">divorce</xsl:attribute>
			<!-- Even though the Recommedation mention VitalType divorce, it does not
				exist in the DTD, so we leave it out, which doesn't mean that much because
				it is an #IMPLIED attribute -->
			<xsl:if test="HUSB">
				<Participant>
					<Link>
						<xsl:attribute name="Target">IndividualRec</xsl:attribute>
						<xsl:attribute name="Ref">
							<xsl:value-of select="$HusbID"/>
						</xsl:attribute>
					</Link>
					<Role>husband</Role>
				</Participant>
			</xsl:if>
			<xsl:if test="WIFE">
				<Participant>
					<Link>
						<xsl:attribute name="Target">IndividualRec</xsl:attribute>
						<xsl:attribute name="Ref">
							<xsl:value-of select="$WifeID"/>
						</xsl:attribute>
					</Link>
					<Role>wife</Role>
				</Participant>
			</xsl:if>
			<xsl:apply-templates select="DATE"/>
			<xsl:apply-templates select="PLAC"/>
			<xsl:apply-templates select="SOUR[@REF]"/>
			<!-- Since the MARR event is created from the FAM record we assign this the same
				Change element as the FAM -->
			<xsl:apply-templates select="parent::CHAN"/>
		</EventRec>
	</xsl:if>
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
		<ExternalID>
			<xsl:attribute name="Type">User</xsl:attribute>
			<xsl:attribute name="Id"><xsl:value-of select="@ID"/></xsl:attribute>
		</ExternalID>
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
</xsl:template>
</xsl:stylesheet>
