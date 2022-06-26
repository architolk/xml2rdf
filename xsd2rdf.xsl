<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
>

<!-- TO DO: PRoblem -->
<!-- It seems possible to have the same name for an element and its type - how to distinguish? -->

<xsl:variable name="targetNamespace"><xsl:value-of select="xs:schema/@targetNamespace"/></xsl:variable>
<xsl:variable name="prefix">
  <xsl:choose>
    <xsl:when test="$targetNamespace!=''"><xsl:value-of select="$targetNamespace"/></xsl:when>
    <xsl:otherwise>urn:file:<xsl:value-of select="replace(document-uri(/),'^.+(/|#)([^/]+)$','$2')"/>#</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="@name" mode="def">
  <rdfs:label><xsl:value-of select="."/></rdfs:label>
</xsl:template>

<xsl:template match="@type" mode="def">
  <xsl:variable name="qname" select="resolve-QName(.,..)"/>
  <xsl:variable name="qname-namespace" select="namespace-uri-from-QName($qname)"/>
  <xsl:variable name="namespace">
    <!-- References can be explicit (prefix or namespace available) or implicit (local to the file) -->
    <xsl:choose>
      <xsl:when test="$qname-namespace!=''"><xsl:value-of select="$qname-namespace"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$prefix"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xs:type rdf:resource="{$namespace}{local-name-from-QName($qname)}"/>
</xsl:template>

<xsl:template match="@base" mode="def">
  <xsl:variable name="qname" select="resolve-QName(.,..)"/>
  <xsl:variable name="qname-namespace" select="namespace-uri-from-QName($qname)"/>
  <xsl:variable name="namespace">
    <!-- References can be explicit (prefix or namespace available) or implicit (local to the file) -->
    <xsl:choose>
      <xsl:when test="$qname-namespace!=''"><xsl:value-of select="$qname-namespace"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$prefix"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xs:base rdf:resource="{$namespace}{local-name-from-QName($qname)}"/>
</xsl:template>

<xsl:template match="@minOccurs" mode="def">
  <xs:minOccurs><xsl:value-of select="."/></xs:minOccurs>
</xsl:template>

<xsl:template match="@maxOccurs" mode="def">
  <xs:maxOccurs><xsl:value-of select="."/></xs:maxOccurs>
</xsl:template>

<xsl:template match="@use" mode="def">
  <xs:use><xsl:value-of select="."/></xs:use>
</xsl:template>

<xsl:template match="xs:documentation" mode="def">
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

<xsl:template match="xs:pattern" mode="def">
  <xsl:choose>
    <xsl:when test="exists(*)">
      <!-- A pattern can have annotations, if those are present: use a qualified blank node -->
      <xs:pattern>
        <xs:Pattern>
          <xsl:apply-templates select="xs:annotation/xs:documentation" mode="def"/>
          <rdf:value><xsl:value-of select="@value"/></rdf:value>
        </xs:Pattern>
      </xs:pattern>
    </xsl:when>
    <xsl:when test="exists(@value)">
      <xs:pattern><xsl:value-of select="@value"/></xs:pattern>
    </xsl:when>
  </xsl:choose>
</xsl:template>

<xsl:template match="xs:sequence" mode="ref">
  <xsl:for-each select="xs:element">
    <!-- For inline complex type, the element parent name should be another element, for names complex types, it should be the complex type itself -->
    <xsl:if test="exists(@name)">
      <xs:sequence rdf:resource="{$prefix}{../../../@name|../../@name}.{@name}"/>
    </xsl:if>
    <xsl:if test="exists(@ref)">
      <xsl:variable name="qname" select="resolve-QName(@ref,.)"/>
      <xs:sequence rdf:resource="{namespace-uri-from-QName($qname)}{local-name-from-QName($qname)}"/>
    </xsl:if>
  </xsl:for-each>
</xsl:template>

<xsl:template match="xs:sequence" mode="def">
  <xsl:for-each select="xs:element">
    <!-- For inline complex type, the element parent name should be another element, for named complex types, it should be the complex type itself -->
    <xs:Element rdf:about="{$prefix}{../../../@name|../../@name}.{@name}">
      <xsl:apply-templates select="@type|@name|@minOccurs|@maxOccurs" mode="def"/>
      <xsl:apply-templates select="xs:annotation/xs:documentation" mode="def"/>
      <xs:index><xsl:value-of select="position()"/></xs:index>
    </xs:Element>
  </xsl:for-each>
</xsl:template>

<xsl:template match="xs:attribute" mode="ref">
  <!-- For inline complex type, the element parent name should be another element, for names complex types, it should be the complex type itself -->
  <xs:attribute rdf:resource="{$prefix}{../../@name|../@name}.{@name}"/>
</xsl:template>

<xsl:template match="xs:attribute" mode="def">
  <!-- For inline complex type, the element parent name should be another element, for names complex types, it should be the complex type itself -->
  <xs:Attribute rdf:about="{$prefix}{../../@name|../@name}.{@name}">
    <xsl:apply-templates select="@type|@name|@use" mode="def"/>
  </xs:Attribute>
</xsl:template>

<xsl:template match="xs:restriction" mode="refdef">
  <xs:restriction>
    <xs:Restriction>
      <xsl:apply-templates select="@base" mode="def"/>
      <xsl:apply-templates select="xs:pattern" mode="def"/>
      <xsl:apply-templates select="xs:annotation/xs:documentation" mode="def"/>
    </xs:Restriction>
  </xs:restriction>
</xsl:template>

<xsl:template match="xs:simpleType" mode="def">
  <xs:SimpleType rdf:about="{$prefix}{@name}">
    <xsl:apply-templates select="@name" mode="def"/>
    <xsl:apply-templates select="xs:restriction" mode="refdef"/>
    <xsl:apply-templates select="xs:annotation/xs:documentation" mode="def"/>
  </xs:SimpleType>
</xsl:template>

<xsl:template match="xs:complexType" mode="def">
  <xs:ComplexType rdf:about="{$prefix}{@name}">
    <xsl:apply-templates select="@name" mode="def"/>
    <xsl:apply-templates select="xs:annotation/xs:documentation" mode="def"/>
    <xsl:apply-templates select="xs:sequence|xs:attribute" mode="ref"/>
  </xs:ComplexType>
  <xsl:apply-templates select="xs:sequence|xs:attribute" mode="def"/>
</xsl:template>

<xsl:template match="xs:complexType" mode="refdef">
  <xs:type>
    <xs:ComplexType>
      <xsl:apply-templates select="xs:sequence|xs:attribute" mode="ref"/>
      <xsl:apply-templates select="xs:annotation/xs:documentation" mode="def"/>
    </xs:ComplexType>
  </xs:type>
</xsl:template>

<xsl:template match="xs:element" mode="ref">
  <xs:element rdf:resource="{$prefix}{@name}"/>
</xsl:template>

<xsl:template match="xs:element" mode="def">
  <xs:Element rdf:about="{$prefix}{@name}"> <!--root elements -->
    <xsl:apply-templates select="@type|@name|@minOccurs|@maxOccurs" mode="def"/>
    <xsl:apply-templates select="xs:annotation/xs:documentation" mode="def"/>
    <xsl:apply-templates select="xs:complexType" mode="refdef"/> <!-- Seems that complexType inline are blank nodes -->
  </xs:Element>
  <xsl:apply-templates select="xs:complexType/(xs:sequence|xs:attribute)" mode="def"/>
</xsl:template>

<xsl:template match="xs:schema" mode="def">
  <xs:Schema rdf:about="{$prefix}">
    <rdfs:label><xsl:value-of select="$prefix"/></rdfs:label>
    <xsl:apply-templates select="xs:element" mode="ref"/>
  </xs:Schema>
  <xsl:apply-templates select="xs:element" mode="def"/>
  <xsl:apply-templates select="xs:complexType" mode="def"/>
  <xsl:apply-templates select="xs:simpleType" mode="def"/>
</xsl:template>

<xsl:template match="/">
  <rdf:RDF>
    <!-- Adding all used namespaces to the output -->
    <xsl:for-each select="xs:schema/namespace::*[name()!='xml']">
      <xsl:namespace name="{name()}"><xsl:value-of select="."/></xsl:namespace>
    </xsl:for-each>
    <xsl:if test="$targetNamespace=''">
      <xsl:namespace name="schema"><xsl:value-of select="$prefix"/></xsl:namespace>
    </xsl:if>
    <xsl:apply-templates select="xs:schema" mode="def"/>
  </rdf:RDF>
</xsl:template>

</xsl:stylesheet>
