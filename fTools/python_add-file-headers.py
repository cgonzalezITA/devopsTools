#!/usr/bin/env python3

# add headers to .h, .cpp, .c and .ino files automatically.
# the script will first list the files missing headers, then
# prompt for confirmation. The modification is made inplace.
#
# usage:
#   add-headers.py <header file> <root dir>
#
# The script will first read the header template in <header file>,
# then scan for source files recursively from <root dir>.

import sys, os
import os.path as path
import fileinput

src_extensions = {
    'c': { 'fileExtension': ['.h', '.cpp', '.c', '.ino'], 'skipFirstNLines':0},
    'py':{ 'fileExtension': ['.py'],                      'skipFirstNLines':0},
    'js':{ 'fileExtension': ['.js'],                      'skipFirstNLines':0},
    'ts':{ 'fileExtension': ['.ts'],                      'skipFirstNLines':0},
    'sh':{ 'fileExtension': ['.sh'],                      'skipFirstNLines':1}
}

def is_src_file(language, f):
    results = [f.endswith(ext) for ext in language['fileExtension']]
    return True in results

def is_header_missing( jsonLanguage, f, headerLines):
    with open(f) as reader:
        lines = reader.read().lstrip().rstrip().splitlines()
        if len(lines) >= len(headerLines): 
            n=0
            nHeader=0
            while n < len(headerLines):
                if n < jsonLanguage['skipFirstNLines']:
                    n= n + 1
                    continue
                elif lines[n] != headerLines[nHeader]:
                    return True
                n= n + 1
                nHeader=nHeader + 1
            return False
        else:
            return True

def get_src_files(jsonLanguage, dirname, headerLines):
    src_files = []
    for cur, _dirs, files in os.walk(dirname):
        if cur == dirname:
            [src_files.append(path.join(cur,f)) for f in files if is_src_file(jsonLanguage, f)]

    return src_files, [f for f in src_files if is_header_missing(jsonLanguage, f, headerLines)]

def add_headers(jsonLanguage, files, headerLines):
    answer=''
    for file in files:
        if answer != 'A':
            answer = input(f"Dou you want to add headers to file {file}? [y/N/A] ")
            if answer == 'N':
                continue
        isFirstLine=True
        nLine=0
        for line in fileinput.input(file, inplace=True):
            nLine=nLine+1
            if isFirstLine:
                if nLine <= jsonLanguage['skipFirstNLines']:
                    print(line, end="")
                    continue
                [ print(h) for h in headerLines]
                isFirstLine= False
            print(line, end="")



if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("usage: %s <language> <header file> <root dir>" % sys.argv[0])
        exit()

    args = sys.argv # [path.abspath(arg) for arg in sys.argv]
    root_path = path.abspath(args[3])

    language= args[1]
    header = open(args[2]).read().lstrip().rstrip()
    headerLines = header.splitlines()
    totalFiles, filesWithoutHeader = get_src_files(src_extensions[language], root_path, headerLines)

    print("Header: ")
    print(header)
    print()
    print(f'{len(filesWithoutHeader)}/{len(totalFiles)} {language} Files without headers in folder {root_path}:')
    [print("  - %s" % f) for f in filesWithoutHeader]
    
    if len(filesWithoutHeader)>0:
        confirm = input("Dou you want to add headers to these files? [y/N] ")
        if confirm != "y": 
            exit(0)
        add_headers(src_extensions[language], filesWithoutHeader, headerLines)
    else:
        print('It seems that all files already have the proper header :-)')

    print()
    print()
    print()
    print()
