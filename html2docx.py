import win32com.client as win32
import sys, os, glob

if len(sys.argv) != 2:
    print 'python html2docx.py <path-to-html-files>'
    sys.exit(0)
else:
    doc_path = sys.argv[1]

if (not os.path.exists(doc_path)):
    print "{1} does not exist".format(doc_path)
    sys.exit(1)

#doc_path = "C:/Users/limwang/PycharmProjects/html2docx/"
word = win32.Dispatch('Word.Application')
word.Visible = False
if os.path.isfile(doc_path):
    filenames = [doc_path]
else:
    filenames = glob.glob(os.path.join(doc_path, '*.html'))
assert len(filenames) > 0
for filename in filenames:
    print filename
    doc = word.Documents.Open(filename)
    tgt_filename = os.path.splitext(filename)[0]
    word.ActiveDocument.SaveAs(tgt_filename, FileFormat=12)
word.Quit()
