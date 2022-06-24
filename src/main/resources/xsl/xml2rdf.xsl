<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:xmlvoc="http://bp4mc2.org/def/xml#"

	xmlns:fn="http://architolk.nl/fn"
>

	<xsl:function name="fn:upperCamelCase" as="xs:string">
		<xsl:param name="input" as="xs:string"/>
		<xsl:value-of select="concat(upper-case(substring($input,1,1)),substring($input,2))"/>
	</xsl:function>

	<xsl:function name="fn:lowerCamelCase" as="xs:string">
		<xsl:param name="input" as="xs:string"/>
		<xsl:value-of select="concat(lower-case(substring($input,1,1)),substring($input,2))"/>
	</xsl:function>

	<xsl:template match="*[(count(*)+count(@*))>0]" mode="property">
		<xsl:element name="xmlvoc:{fn:lowerCamelCase(local-name())}">
			<xsl:attribute name="rdf:resource">urn:uuid:<xsl:value-of select="generate-id()"/></xsl:attribute>
		</xsl:element>
	</xsl:template>

	<xsl:template match="*" mode="property">
		<!--Don't show empty properties -->
		<xsl:if test=".!=''">
			<xsl:element name="xmlvoc:{fn:lowerCamelCase(local-name())}">
				<xsl:value-of select="."/>
			</xsl:element>
		</xsl:if>
	</xsl:template>

	<xsl:template match="@*" mode="attribute">
		<!--Don't show empty properties -->
		<xsl:if test=".!=''">
			<xsl:element name="xmlvoc:{fn:lowerCamelCase(local-name())}">
				<xsl:value-of select="."/>
			</xsl:element>
		</xsl:if>
	</xsl:template>

	<xsl:template match="*" mode="node">
		<xsl:element name="xmlvoc:{fn:upperCamelCase(local-name())}">
			<xsl:attribute name="rdf:about">urn:uuid:<xsl:value-of select="generate-id()"/></xsl:attribute>
			<xsl:apply-templates select="@*" mode="attribute"/>
			<xsl:apply-templates select="*" mode="property"/>
		</xsl:element>
		<xsl:apply-templates select="*[(count(*)+count(@*))>0]" mode="node"/>
	</xsl:template>

	<xsl:template match="/">
		<rdf:RDF>
			<xsl:for-each select="*[local-name()!='container' and local-name()!='file']">
				<xsl:element name="xmlvoc:{fn:upperCamelCase(local-name())}">
					<xsl:attribute name="rdf:about">urn:uuid:<xsl:value-of select="generate-id()"/></xsl:attribute>
					<xsl:apply-templates select="@*" mode="attribute"/>
					<xsl:apply-templates select="*" mode="property"/>
				</xsl:element>
				<xsl:apply-templates select="*[(count(*)+count(@*))>0]" mode="node"/>
			</xsl:for-each>
		</rdf:RDF>
	</xsl:template>
</xsl:stylesheet>
