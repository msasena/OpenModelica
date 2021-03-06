within Modelica.Utilities;
package Streams "Read from files and write to files"
  extends Modelica.Icons.Library;
  annotation(preferedView="info", Documentation(info="<HTML>
<h3><font color=\"#008000\">Library content</font></h3>
<p>
Package <b>Streams</b> contains functions to input and output strings
to a message window or on files. Note that a string is interpreted 
and displayed as html text (e.g., with print(..) or error(..))
if it is enclosed with the Modelica html quotation, e.g.,
</p>
<center>
string = \"&lt;html&gt; first line &lt;br&gt; second line &lt;/html&gt;\". 
</center>
<p>
It is a quality of implementation, whether (a) all tags of html are supported
or only a subset, (b) how html tags are interpreted if the output device
does not allow to display formatted text.
</p>
<p>
In the table below an example call to every function is given:
</p>
<table border=1 cellspacing=0 cellpadding=2>
  <tr><th><b><i>Function/type</i></b></th><th><b><i>Description</i></b></th></tr>
  <tr><td><a href=\"Modelica:Modelica.Utilities.Streams.print\">print</a>(string)<br>
          <a href=\"Modelica:Modelica.Utilities.Streams.print\">print</a>(string,fileName)</td>
      <td> Print string \"string\" or vector of strings to message window or on
           file \"fileName\".</td>
  </tr>
  <tr><td>stringVector = 
         <a href=\"Modelica:Modelica.Utilities.Streams.readFile\">readFile</a>(fileName)</td>
      <td> Read complete text file and return it as a vector of strings.</td>
  </tr>
  <tr><td>(string, endOfFile) = 
         <a href=\"Modelica:Modelica.Utilities.Streams.readLine\">readLine</a>(fileName, lineNumber)</td>
      <td>Returns from the file the content of line lineNumber.</td>
  </tr>
  <tr><td>lines = 
         <a href=\"Modelica:Modelica.Utilities.Streams.countLines\">countLines</a>(fileName)</td>
      <td>Returns the number of lines in a file.</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Utilities.Streams.error\">error</a>(string)</td>
      <td> Print error message \"string\" to message window
           and cancel all actions</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Utilities.Streams.close\">close</a>(fileName)</td>
      <td> Close file if it is still open. Ignore call if
           file is already closed or does not exist. </td>
  </tr>
</table>
<p>
Use functions <b>scanXXX</b> from package 
<a href=\"Modelica:Modelica.Utilities.Strings\">Strings</a>
to parse a string.
</p>
<p>
If Real, Integer or Boolean values shall be printed 
or used in an error message, they have to be first converted
to strings with the builtin operator 
<a href=\"Modelica:ModelicaReference.Operators.string\">String</a>(...).
Example:
</p>
<pre>
  <b>if</b> x &lt; 0 <b>or</b> x &gt; 1 <b>then</b>
     Streams.error(\"x (= \" + String(x) + \") has to be in the range 0 .. 1\");
  <b>end if</b>;
</pre>
</HTML>
"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  function print "Print string to terminal or file"
    extends Modelica.Icons.Function;
    input String string="" "String to be printed";
    input String fileName="" "File where to print (empty string is the terminal)";
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));

    external "C" ModelicaInternal_print(string,fileName) ;
    annotation(preferedView="info", Documentation(info="<HTML>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
Streams.<b>print</b>(string);
Streams.<b>print</b>(string,fileName);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
Function <b>print</b>(..) opens automatically the given file, if
it is not yet open. If the file does not exist, it is created.
If the file does exist, the given string is appended to the file.
If this is not desired, call \"Files.remove(fileName)\" before calling print
(\"remove(..)\" is silent, if the file does not exist).
The Modelica environment may close the file whenever appropriate.
This can be enforced by calling <b>Streams.close</b>(fileName).
After every call of \"print(..)\" a \"new line\" is printed automatically.
</p>
<h3><font color=\"#008000\">Example</font></h3>
<blockquote><pre>
  Streams.print(\"x = \" + String(x));
  Streams.print(\"y = \" + String(y));
  Streams.print(\"x = \" + String(y), \"mytestfile.txt\");
</pre></blockquote>
<p>
<h3><font color=\"#008000\">See also</font></h3>
<p>
<a href=\"Modelica:Modelica.Utilities.Streams\">Streams</a>,
<a href=\"Modelica:Modelica.Utilities.Streams.error\">Streams.error</a>,
<a href=\"Modelica:ModelicaReference.Operators.string\">String</a>
</p>
</HTML>"));
  end print;

  function readFile "Read content of a file and return it in a vector of strings"
    extends Modelica.Icons.Function;
    input String fileName "Name of the file that shall be read";
    output String stringVector[countLines(fileName)] "Content of file";
    annotation(preferedView="info", Documentation(info="<html>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
stringVector = Streams.<b>readFile</b>(fileName)
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
Function <b>readFile</b>(..) opens the given file, reads the complete
content, closes the file and returns the content as a vector of strings. Lines are separated by LF or CR-LF; the returned strings do not contain the line separators. 
</p>
</html>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  algorithm 
    for i in 1:size(stringVector, 1) loop
      stringVector[i]:=readLine(fileName, i);
    end for;
    Streams.close(fileName);
  end readFile;

  function readLine "Reads a line of text from a file and returns it in a string"
    extends Modelica.Icons.Function;
    input String fileName "Name of the file that shall be read";
    input Integer lineNumber(min=1) "Number of line to read";
    output String string "Line of text";
    output Boolean endOfFile "If true, end-of-file was reached when trying to read line";
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));

    external "C" string=ModelicaInternal_readLine(fileName,lineNumber,endOfFile) ;
    annotation(preferedView="info", Documentation(info="<html>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
(string, endOfFile) = Streams.<b>readLine</b>(fileName, lineNumber)
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
Function <b>readLine</b>(..) opens the given file, reads enough of the
content to get the requested line, and returns the line as a string.
Lines are separated by LF or CR-LF; the returned string does not 
contain the line separator. The file might remain open after
the call.
</p>
<p>
If lineNumber > countLines(fileName), an empty string is returned 
and endOfFile=true. Otherwise endOfFile=false.
</p>
</html>"));
  end readLine;

  function countLines "Returns the number of lines in a file"
    extends Modelica.Icons.Function;
    input String fileName "Name of the file that shall be read";
    output Integer numberOfLines "Number of lines in file";
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));

    external "C" numberOfLines=ModelicaInternal_countLines(fileName) ;
    annotation(preferedView="info", Documentation(info="<html>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
numberOfLines = Streams.<b>countLines</b>(fileName)
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
Function <b>countLines</b>(..) opens the given file, reads the complete
content, closes the file and returns the number of lines. Lines are
separated by LF or CR-LF.
</p>
</html>"));
  end countLines;

  function error "Print error message and cancel all actions"
    extends Modelica.Icons.Function;
    input String string "String to be printed to error message window";
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));

    external "C" ModelicaError(string) ;
    annotation(preferedView="info", Documentation(info="<html>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
Streams.<b>error</b>(string);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
Print the string \"string\" as error message and
cancel all actions. Line breaks are characterized 
by \"\\n\" in the string.
</p>
<h3><font color=\"#008000\">Example</font></h3>
<blockquote><pre>
  Streams.error(\"x (= \" + String(x) + \")\\nhas to be in the range 0 .. 1\");
</pre></blockquote>
<h3><font color=\"#008000\">See also</font></h3>
<p>
<a href=\"Modelica:Modelica.Utilities.Streams\">Streams</a>,
<a href=\"Modelica:Modelica.Utilities.Streams.print\">Streams.print</a>,
<a href=\"Modelica:ModelicaReference.Operators.string\">String</a>
</p>
</html>"));
  end error;

  function close "Close file"
    extends Modelica.Icons.Function;
    input String fileName "Name of the file that shall be closed";
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));

    external "C" ModelicaStreams_closeFile(fileName) ;
    annotation(preferedView="info", Documentation(info="<html>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
Streams.<b>close</b>(fileName)
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
Close file if it is open. Ignore call if
file is already closed or does not exist.
</p>
</html>"));
  end close;

end Streams;
