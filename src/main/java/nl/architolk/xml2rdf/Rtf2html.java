package nl.architolk.xml2rdf;

import java.io.StringReader;
import java.io.StringWriter;
import java.io.Writer;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.DocumentType;
import org.jsoup.safety.Cleaner;
import org.jsoup.safety.Safelist;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import nl.architolk.rtf2html.RtfReader;
import nl.architolk.rtf2html.RtfHtml;

public class Rtf2html {

    private static final Logger LOG = LoggerFactory.getLogger(Rtf2html.class);

    private static String rtf2html(String rtf) {
      try {
        RtfReader reader = new RtfReader();
        reader.parse(rtf.replace("<","&lt;"));
        RtfHtml formatter = new RtfHtml();

        Cleaner cleaner = new Cleaner(Safelist.relaxed().addAttributes(":all","class"));
        Document doc = cleaner.clean(Jsoup.parse(formatter.format(reader.root, true)));
        doc.outputSettings().syntax(Document.OutputSettings.Syntax.xml);
        return doc.html();


      } catch (Exception e) {
        LOG.error(e.getMessage());
        return rtf;
      }
    }

    /*
    private static String rtf2html(String rtf) {
      try {
        JEditorPane p = new JEditorPane();
        p.setContentType("text/rtf");

        EditorKit kitRtf = p.getEditorKitForContentType("text/rtf");
        kitRtf.read(new StringReader(rtf), p.getDocument(), 0);
        kitRtf = null;

        EditorKit kitHtml = p.getEditorKitForContentType("text/html");
        Writer writer = new StringWriter();
        kitHtml.write(writer, p.getDocument(), 0, p.getDocument().getLength());

        Cleaner cleaner = new Cleaner(Safelist.relaxed().addAttributes(":all","class"));
        Document doc = cleaner.clean(Jsoup.parse(writer.toString()));
        doc.outputSettings().syntax(Document.OutputSettings.Syntax.xml);
        return doc.html();

      } catch (Exception e) {
        LOG.error(e.getMessage());
        return rtf;
      }
    }
    */

    public static String convert(String rtf) {
      return rtf2html(rtf);
    }
}
