package nl.architolk.xml2rdf;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.StringReader;
import java.nio.file.Files;
import java.nio.file.Paths;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.DocumentType;
import org.jsoup.safety.Cleaner;
import org.jsoup.safety.Safelist;
import org.apache.commons.io.FilenameUtils;
import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.ModelFactory;
import org.apache.jena.riot.RDFDataMgr;
import org.apache.jena.riot.RDFFormat;
import org.apache.jena.riot.RDFLanguages;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Convert {

  private static final Logger LOG = LoggerFactory.getLogger(Convert.class);

  public static void main(String[] args) {

    if (args.length >= 2) {

      LOG.info("Input file: {}",args[0]);
      LOG.info("Ouput file: {}",args[1]);

      if (args.length == 3) {
        LOG.info("Stylesheet: {}",args[2]);
      }

      try {
        StreamSource inputSource;
        if (FilenameUtils.getExtension(args[0]).equals("html")) {
          LOG.info("Input file is HTML");
          Cleaner cleaner = new Cleaner(Safelist.relaxed().addAttributes(":all","class"));
          Document doc = cleaner.clean(Jsoup.parse(new File(args[0]),"UTF-8","http://example.com/"));
          doc.outputSettings().syntax(Document.OutputSettings.Syntax.xml);
          inputSource = new StreamSource(new StringReader(doc.html().replace("&nbsp;"," ")));
          System.out.println(doc.html());
        } else {
          inputSource = new StreamSource(new File(args[0]));
        }
        ByteArrayOutputStream outBuffer = new ByteArrayOutputStream();
        if (args.length == 2) {
          XmlEngine.transform(inputSource,"xsl/xml2rdf.xsl",new StreamResult(outBuffer));
        } else {
          XmlEngine.transform(inputSource,new StreamSource(new File(args[2])),new StreamResult(outBuffer));
        }
        ByteArrayInputStream inBuffer = new ByteArrayInputStream(outBuffer.toByteArray());
        Model model = ModelFactory.createDefaultModel();
        model.read(inBuffer,null);
        RDFDataMgr.write(new FileOutputStream(args[1]),model, RDFLanguages.filenameToLang(args[1],RDFLanguages.JSONLD));
        LOG.info("Done!");
      }
      catch (Exception e) {
        LOG.error(e.getMessage(),e);
      }
    } else {
      LOG.warn("Usage: xml2rdf <input.xml> <output> [stylesheet.xsl]");
    }
  }
}
