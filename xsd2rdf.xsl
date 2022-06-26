<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"

  xmlns:fn="http://architolk.nl/fn"
>

<!-- TO DO: PRoblem -->
<!-- It seems possible to have the same name for an element and its type - how to distinguish? -->

<xsl:variable name="targetNamespace"><xsl:value-of select="xs:schema/@targetNamespace"/></xsl:variable>
<xsl:variable name="localNamespace">
  <xsl:choose>
    <xsl:when test="$targetNamespace!=''"><xsl:value-of select="$targetNamespace"/></xsl:when>
    <xsl:otherwise>urn:file:<xsl:value-of select="replace(document-uri(/),'^.+(/|#)([^/]+)$','$2')"/>#</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<!-- HELPERS -->
<xsl:function name="fn:resolve" as="xs:string">
  <xsl:param name="name" as="xs:string"/>
  <xsl:param name="parent" as="element()"/>
  <xsl:variable name="qname" select="resolve-QName($name,$parent)"/>
  <xsl:variable name="qname-namespace" select="namespace-uri-from-QName($qname)"/>
  <!-- References can be explicit (prefix or namespace available) or implicit (local to the file) -->
  <xsl:variable name="result">
    <xsl:choose>
      <xsl:when test="$qname-namespace!=''"><xsl:value-of select="$qname-namespace"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$localNamespace"/></xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="local-name-from-QName($qname)"/>
  </xsl:variable>
  <xsl:value-of select="$result"/>
</xsl:function>

<xsl:template match="*" mode="facet">
  <xsl:param name="datatype"/>
  <xsl:choose>
    <xsl:when test="exists(*)">
      <!-- A facet can have annotations, if those are present: use a qualified blank node -->
      <xs:Facet>
        <xsl:apply-templates select="*" mode="ref"/>
        <rdf:value>
          <xsl:if test="$datatype!=''"><xsl:attribute name="rdf:datatype" select="$datatype"/></xsl:if>
          <xsl:value-of select="@value"/>
        </rdf:value>
      </xs:Facet>
    </xsl:when>
    <xsl:otherwise>
      <xsl:if test="$datatype!=''"><xsl:attribute name="rdf:datatype" select="$datatype"/></xsl:if>
      <xsl:value-of select="@value"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- ATTRIBUTES -->

<!-- named nodes -->
<xsl:template match="@name" mode="def">
  <rdfs:label><xsl:value-of select="."/></rdfs:label>
</xsl:template>

<!-- annotated nodes -->
<xsl:template match="xs:annotation" mode="ref">
  <!-- Annotations contain only appInfo and documentation, no need to add this as a separate blank node -->
  <xsl:apply-templates select="*" mode="ref"/>
</xsl:template>

<!-- referencing elements (xs:schema, xs:sequence) -->
<!-- Context is used when elements are part of a sequence that is part of a named complextype or an unnamed complextype in an element -->
<xsl:template match="xs:element[@name!='']" mode="ref">
  <xsl:param name="context"/>
  <xs:element rdf:resource="{$localNamespace}{$context}{@name}"/>
</xsl:template>
<xsl:template match="xs:element[@ref!='']" mode="ref">
  <xs:element rdf:resource="{fn:resolve(@ref,.)}"/>
</xsl:template>

<!-- xs:annotation -->
<xsl:template match="xs:documentation" mode="ref">
  <xsl:choose>
    <xsl:when test="exists(@source) and .!=''">
      <!-- Documentation can have content AND a source attribute, if both are present: use a qualified blank node -->
      <xs:documentation>
        <xs:Documentation>
          <xs:source><xsl:value-of select="@source"/></xs:source>
          <rdf:value><xsl:value-of select="."/></rdf:value>
        </xs:Documentation>
      </xs:documentation>
    </xsl:when>
    <xsl:when test="exists(@source)">
      <xs:documentation-source><xsl:value-of select="@source"/></xs:documentation-source>
    </xsl:when>
    <xsl:when test=".!=''">
      <xs:documentation><xsl:value-of select="."/></xs:documentation>
    </xsl:when>
    <xsl:otherwise />
  </xsl:choose>
</xsl:template>

<!-- xs:restriction -->
<xsl:template match="@base" mode="def">
  <xs:base rdf:resource="{fn:resolve(.,..)}"/>
</xsl:template>

<!-- xs:schema -->
<xsl:template match="@version" mode="def">
  <xs:version><xsl:value-of select="."/></xs:version>
</xsl:template>
<xsl:template match="@attributeFormDefault" mode="def">
  <xs:attributeFormDefault><xsl:value-of select="."/></xs:attributeFormDefault>
</xsl:template>
<xsl:template match="@elementFormDefault" mode="def">
  <xs:elementFormDefault><xsl:value-of select="."/></xs:elementFormDefault>
</xsl:template>
<xsl:template match="@targetNamespace" mode="def">
  <xs:targetNamespace><xsl:value-of select="."/></xs:targetNamespace>
</xsl:template>
<xsl:template match="xs:import" mode="ref">
  <xs:import><xsl:apply-templates select="." mode="def"/></xs:import>
</xsl:template>
<xsl:template match="xs:simpleType[@name!='']" mode="ref">
  <xs:type rdf:resource="{$localNamespace}{@name}"/>
</xsl:template>
<xsl:template match="xs:complexType[@name!='']" mode="ref">
  <xs:type rdf:resource="{$localNamespace}{@name}"/>
</xsl:template>

<!-- xs:import -->
<xsl:template match="@schemaLocation" mode="def">
  <xs:schemaLocation><xsl:value-of select="."/></xs:schemaLocation>
</xsl:template>
<xsl:template match="@namespace" mode="def">
  <xs:namespace><xsl:value-of select="."/></xs:namespace>
</xsl:template>

<!-- xs:simpleType -->
<xsl:template match="xs:restriction" mode="ref">
  <xs:restriction><xsl:apply-templates select="." mode="def"/></xs:restriction>
</xsl:template>

<!-- xs:restriction -->
<xsl:template match="xs:enumeration" mode="ref">
  <!-- TODO: Discussion - should enumerations be named values? Don't think so, officially.. -->
  <xs:enumeration><xsl:apply-templates select="." mode="facet"/></xs:enumeration>
</xsl:template>
<xsl:template match="xs:maxLength" mode="ref">
  <xs:maxLength><xsl:apply-templates select="." mode="facet"><xsl:with-param name="datatype">http://www.w3.org/2001/XMLSchema#integer</xsl:with-param></xsl:apply-templates></xs:maxLength>
</xsl:template>
<xsl:template match="xs:pattern" mode="ref">
  <xs:pattern><xsl:apply-templates select="." mode="facet"/></xs:pattern>
</xsl:template>
<xsl:template match="xs:totalDigits" mode="ref">
  <xs:totalDigits><xsl:apply-templates select="." mode="facet"><xsl:with-param name="datatype">http://www.w3.org/2001/XMLSchema#integer</xsl:with-param></xsl:apply-templates></xs:totalDigits>
</xsl:template>

<!-- xs:element -->
<xsl:template match="@abstract" mode="def">
  <xs:abstract rdf:datatype="http://www.w3.org/2001/XMLSchema#boolean"><xsl:value-of select="."/></xs:abstract>
</xsl:template>
<xsl:template match="@type" mode="def">
  <xs:type rdf:resource="{fn:resolve(.,..)}"/>
</xsl:template>
<xsl:template match="@minOccurs" mode="def">
  <xs:minOccurs rdf:datatype="http://www.w3.org/2001/XMLSchema#integer"><xsl:value-of select="."/></xs:minOccurs>
</xsl:template>
<xsl:template match="@maxOccurs" mode="def">
  <xsl:choose>
    <xsl:when test=".='unbounded'"><xs:maxOccurs><xsl:value-of select="."/></xs:maxOccurs></xsl:when>
    <xsl:otherwise><xs:maxOccurs rdf:datatype="http://www.w3.org/2001/XMLSchema#integer"><xsl:value-of select="."/></xs:maxOccurs></xsl:otherwise>
  </xsl:choose>
</xsl:template>
<xsl:template match="xs:simpleType[not(exists(@name))]" mode="ref">
  <xs:type><xsl:apply-templates select="." mode="def"/></xs:type>
</xsl:template>
<xsl:template match="xs:complexType[not(exists(@name))]" mode="ref">
  <xs:type><xsl:apply-templates select="." mode="def"/></xs:type>
</xsl:template>

<!--xs:complexType -->
<xsl:template match="xs:attribute" mode="ref">
  <!-- Attributes can be references ("ref") or named ("name"), but not both -->
  <!-- Currently, only named attributes are supported -->
  <!-- TODO: Decision - should named attributes be referenceable outside the complexType? -->
  <xs:attribute>
    <xsl:apply-templates select="." mode="def"/>
  </xs:attribute>
</xsl:template>
<xsl:template match="xs:sequence" mode="ref">
  <!-- As sequence is an ordered container, so it seems appropriate to make it a subclass of rdf:Seq -->
  <xsl:param name="context"/>
  <xs:sequence>
    <xsl:apply-templates select="." mode="def"><xsl:with-param name="context" select="$context"/></xsl:apply-templates>
  </xs:sequence>
</xsl:template>
<xsl:template match="xs:choice" mode="ref">
  <xsl:param name="context"/>
  <xs:choice>
    <xsl:apply-templates select="." mode="def"><xsl:with-param name="context" select="$context"/></xsl:apply-templates>
  </xs:choice>
</xsl:template>
<xsl:template match="xs:complexContent" mode="ref">
  <xsl:param name="context"/>
  <!-- complex content is just a grouping element, can be ignored -->
  <!-- TODO: not actually true, but good enough for now -->
  <xsl:apply-templates select="*" mode="ref"><xsl:with-param name="context" select="$context"/></xsl:apply-templates>
</xsl:template>
<xsl:template match="xs:extension" mode="ref">
  <!-- Extensions are grouping elements and specification elements, simple solution -->
  <!-- TODO: shortcut solution, should be elaborated -->
  <xsl:param name="context"/>
  <xs:extension rdf:resource="{fn:resolve(@base,.)}"/>
  <xsl:apply-templates select="*" mode="ref"><xsl:with-param name="context" select="$context"/></xsl:apply-templates>
</xsl:template>

<!-- xs:attribute -->
<xsl:template match="@use" mode="def">
  <xs:use><xsl:value-of select="."/></xs:use>
</xsl:template>

<xsl:template match="@*" mode="def">
  <!-- Failsafe: should not get to here.-->
  <xs:TODO-Attr><xsl:value-of select="name()"/></xs:TODO-Attr>
</xsl:template>

<xsl:template match="*" mode="ref">
  <!-- Failsafe: should not get to here.-->
  <xs:TODO-Node><xsl:value-of select="name()"/></xs:TODO-Node>
</xsl:template>

<!-- NODES -->

<xsl:template match="xs:schema" mode="def">
  <xs:Schema rdf:about="{$localNamespace}">
    <xsl:apply-templates select="@*" mode="def"/>
    <xsl:apply-templates select="*" mode="ref"/>
  </xs:Schema>
  <xsl:apply-templates select="*[local-name()!='import']" mode="def"/>
</xsl:template>

<xsl:template match="xs:import" mode="def">
  <!-- Imports are always locally defined, so blank node -->
  <xs:Import>
    <xsl:apply-templates select="@*" mode="def"/>
    <xsl:apply-templates select="*" mode="ref"/>
  </xs:Import>
</xsl:template>

<xsl:template match="xs:restriction" mode="def">
  <!-- Restrictions are always locally defined, so blank node -->
  <xs:Restriction>
    <xsl:apply-templates select="@*" mode="def"/>
    <xsl:apply-templates select="*" mode="ref"/>
  </xs:Restriction>
</xsl:template>

<xsl:template match="xs:sequence" mode="def">
  <!-- Sequences are always locally defined, so blank node -->
  <xsl:param name="context"/>
  <xs:Sequence>
    <xsl:apply-templates select="@*" mode="def"/>
    <xsl:apply-templates select="*" mode="ref"><xsl:with-param name="context" select="$context"/></xsl:apply-templates>
  </xs:Sequence>
</xsl:template>

<xsl:template match="xs:choice" mode="def">
  <!-- Choices are always locally defined, so blank node -->
  <xsl:param name="context"/>
  <xs:Choice>
    <xsl:apply-templates select="@*" mode="def"/>
    <xsl:apply-templates select="*" mode="ref"><xsl:with-param name="context" select="$context"/></xsl:apply-templates>
  </xs:Choice>
</xsl:template>

<xsl:template match="xs:attribute[@name!='']" mode="def">
  <!-- It IS possible for attributes to be globally defined, but currently we only support blank node -->
  <!-- TODO: Decision - how to work with global attributes vs named attributes and referenced attributes -->
  <xs:Attribute>
    <xsl:apply-templates select="@*" mode="def"/>
    <xsl:apply-templates select="*" mode="ref"/>
  </xs:Attribute>
</xsl:template>

<xsl:template match="xs:simpleType[@name!='']" mode="def">
  <xs:SimpleType rdf:about="{$localNamespace}{@name}">
    <xsl:apply-templates select="@*" mode="def"/>
    <xsl:apply-templates select="*" mode="ref"/>
  </xs:SimpleType>
</xsl:template>

<xsl:template match="xs:simpleType[not(exists(@name))]" mode="def">
  <xs:SimpleType>
    <xsl:apply-templates select="@*" mode="def"/>
    <xsl:apply-templates select="*" mode="ref"/>
  </xs:SimpleType>
</xsl:template>

<xsl:template match="xs:complexType[@name!='']" mode="def">
  <xs:ComplexType rdf:about="{$localNamespace}{@name}">
    <xsl:apply-templates select="@*" mode="def"/>
    <xsl:apply-templates select="*" mode="ref"><xsl:with-param name="context" select="concat(@name,'.')"/></xsl:apply-templates>
  </xs:ComplexType>
  <!-- Elements of sequences/choices are references, so should be defined -->
  <xsl:apply-templates select="(xs:sequence|xs:choice)/*" mode="def">
    <xsl:with-param name="context" select="concat(@name,'.')"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="xs:complexType[not(exists(@name))]" mode="def">
  <xs:ComplexType>
    <xsl:apply-templates select="@*" mode="def"/>
    <xsl:apply-templates select="*" mode="ref"/>
  </xs:ComplexType>
</xsl:template>

<xsl:template match="xs:element[@name!='']" mode="def">
  <xsl:param name="context"/>
  <xs:Element rdf:about="{$localNamespace}{$context}{@name}">
    <xsl:apply-templates select="@*" mode="def"/>
    <xsl:apply-templates select="*" mode="ref"/>
  </xs:Element>
</xsl:template>

<xsl:template match="*" mode="def">
  <!-- Failsafe: should not get here -->
  <rdf:Description rdf:about="http://www.w3.org/2001/XMLSchema{local-name()}">
    <xs:TODO><xsl:value-of select="name()"/></xs:TODO>
  </rdf:Description>
</xsl:template>

<xsl:template match="/">
  <rdf:RDF>
    <!-- Adding all used namespaces to the output -->
    <xsl:for-each select="xs:schema/namespace::*[name()!='xml']">
      <xsl:namespace name="{name()}"><xsl:value-of select="."/></xsl:namespace>
    </xsl:for-each>
    <!-- If the targetNamespace is not available, we must create our own prefix for local referenced elements -->
    <xsl:if test="$targetNamespace=''">
      <xsl:namespace name="schema"><xsl:value-of select="$localNamespace"/></xsl:namespace>
    </xsl:if>
    <!-- Globally defined elements -->
    <!-- Note: if two elements have the same name, but different types, these elements will be combined and will have both types! -->
    <xsl:apply-templates select="*" mode="def"/>
  </rdf:RDF>
</xsl:template>

</xsl:stylesheet>
