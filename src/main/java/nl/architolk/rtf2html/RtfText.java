// Forked from: https://github.com/kschroeer/rtf-html-java
package nl.architolk.rtf2html;

/**
 * This class represents an RTF text element in the element tree.
 *
 * @author <a href="mailto:acsf.dev@gmail.com">Kay Schröer</a>
 */
public class RtfText extends RtfElement {
	/**
	 * Plain text
	 */
	public String text;

	/*
	 * (non-Javadoc)
	 *
	 * @see org.rtf.RtfElement#dump(int)
	 */
	@Override
	public void dump(int level) {
		System.out.println("<div style='color:red'>");
		indent(level);
		System.out.println("TEXT " + text);
		System.out.println("</div>");
	}
}
