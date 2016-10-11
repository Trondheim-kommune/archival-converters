# archival-converters
This is a collection of scripts for converting documents from working formats to archival formats.

## doc_to_pdf.js
Converts Microsoft Word documents to ISO 19005-1 PDF/A.
Requires office 2007 (at least) to be installed on the machine running this script.
    
### Usage
Running the command `cscript.exe doc_to_pdfa.js PATH1 PATH2 PATH3 ... PATHN`
from a windows commandline will convert all the documents with the paths to pdf.
The pdfs will be placed in the same folder as the original document with the extension changed to pdf.
***WARNING: it will overwrite any existing file with that name***.
