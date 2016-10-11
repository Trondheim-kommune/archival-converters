var fileSystem = new ActiveXObject("Scripting.FileSystemObject");
var wordApplication = null;

try {
    wordApplication = new ActiveXObject("Word.Application");
    wordApplication.Visible = false;
    for (var i = 0; i < WScript.Arguments.length; i++) {
        var wordDocument = null;
        var wordDocumentPath = null;

        try {
            wordDocumentPath = fileSystem.GetAbsolutePathName(WScript.Arguments(i));
            wordDocument = wordApplication.Documents.Open(wordDocumentPath);
            wordDocument.ExportAsFixedFormat(
                wordDocumentPath.replace(/\.[docxDOCX]{3,4}$/, ".pdf"), // output path
                17, // Filetype enum: pdf = 17
                false, // open after export
                0, // optimizefor enum: print = 0
                0, // range: entire document = 0
                0, // from: only used with range != 0
                0, // to: only used with range != 0
                0, // export item enum: no idea, 1 doesn't work with pdf/a.
                true, // include doc props: no idea
                true, // keep irm: no idea
                2, // Create bookmarks enum: create pdf bookmarks for existing word bookmarks = 2
                true, // DocStructureTags enum: no idea
                true, // BitmapMissingFonts: convert proprietary fonts to bitmaps instead of using font refferences.
                true  // Use iso 19005_1: stores the pdf in pdf/a-1b format
            );
        } catch (err) {
            WScript.Echo("Failed to convert: " + wordDocumentPath);
            WScript.Echo("Word.Application.Documents error: " + err.message)
        } finally {
            if (wordDocument != null) {
                wordDocument.Close();
            }
        }
    }
} catch (err) {
    WScript.Echo("Word.Application error: " + err.message)
} finally {
    if (wordApplication != null) {
        wordApplication.Quit();
    }
}