<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
  xmlns:rtf="http://example.org/def/rtf#"
>

<xsl:template match="/">
  <rdf:RDF>
    <xsl:for-each select="rtf">
      <rdf:Description rdf:about="urn:name:test">
        <rtf:asRTF><xsl:value-of select="."/></rtf:asRTF>
        <xsl:variable name="html" xmlns:Rtf2html="nl.architolk.xml2rdf.Rtf2html" select="Rtf2html:convert(.)"/>
        <rtf:asHTML><xsl:value-of select="$html"/></rtf:asHTML>
        <rdfs:comment>
          <xsl:for-each xmlns:saxon="http://saxon.sf.net/" select="saxon:parse($html)/html/body/p[.!='']">
            <xsl:if test="position()!=1"><xsl:text>\n</xsl:text></xsl:if>
            <xsl:value-of select="."/>
          </xsl:for-each>
        </rdfs:comment>
      </rdf:Description>
    </xsl:for-each>
  </rdf:RDF>
</xsl:template>

</xsl:stylesheet>
