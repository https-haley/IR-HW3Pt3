/*----------------------------------------------------------------*/
/* Filename:  multiplefiles.lex                                   */
/* To compile: flex multiplefiles.lex                             */
/*            g++ -o multiplefiles lex.yy.c hashtable.cpp -lfl    */
/* Flex can also use gcc or cc instead of g++                     */
/* Takes in and out directories: ./multiplefiles <indir> <outdir */
/*----------------------------------------------------------------*/

%{
#include <string.h>
#include <dirent.h>
#include <iostream>
#include <stdio.h>
#include <ctype.h>
#include <map>
#include <vector>
#include <utility>

#include "hashtable.h"
#include "invertedFile.h"

extern "C" int yylex(void);
using namespace std;

const int MAX_LENGTH = 55;
const int MAX_TOKEN_LEN = 12;
const int DOCUMENT_HT_SIZE = 100003;
const int COLLECTION_HT_SIZE = 100003;

HashTable *DocumentHT = NULL;
HashTable *CollectionHT = NULL;
invertedFile InvFile;
int CurrentDocId = 0;
map<string, vector<pair<int, float>>> Postings;

int DocumentTotalTokens = 0;
int CollectionTotalTokens = 0;

#undef yywrap            // safety measure in case using old flex 

//---------  INSERT ANY CODE CALLED BY THE LEX RULES HERE --------
void downcase(char *word)
{
    int i;

    for (i = 0; word[i] != '\0'; i++)
    {
        word[i] = tolower(word[i]);
    }
}

void ProcessToken(char *token)
{
    int length = strlen(token);

    // Ignore tokens that are too long
    if (length > MAX_LENGTH)
        return;

    string key = token;

    // Truncate accepted tokens
    if ((int)key.length() > MAX_TOKEN_LEN)
        key = key.substr(0, MAX_TOKEN_LEN);

    DocumentHT->Increment(key);

    DocumentTotalTokens++;
    CollectionTotalTokens++;
}


void ProcessDocumentHashtable()
{
   int used;
   int collisions;
   int lookups;

   DocumentHT->GetUsage(used, collisions, lookups);

   cout << "Total tokens in document: " << DocumentTotalTokens << endl;
   cout << "Unique tokens in document: " << used << endl;

   string key;
   int frequency;

   // Each unique token is counted once per document
   for (unsigned long i = 0; i < DocumentHT->GetSize(); i++)
   {
        if (DocumentHT->GetEntry(i, key, frequency))
        {
            CollectionHT->Increment(key);
            Postings[key].push_back(make_pair(CurrentDocId - 1, (float)frequency));
        }
   }


   delete DocumentHT;
   DocumentHT = NULL;
}
void WriteInvertedIndex()
{
    int start = 0;
    string term;
    int documentFrequency;

    // Go through the global hash table in bucket order
    for (unsigned long i = 0; i < CollectionHT->GetSize(); i++)
    {
        if (CollectionHT->GetEntry(i, term, documentFrequency))
        {
            // Remove terms that appear in only one document
            if (documentFrequency <= 1)
            {
                InvFile.writeDictRecord("", 0, 0);
                continue;
            }

            // Write the dictionary record for this bucket
            InvFile.writeDictRecord(term, documentFrequency, start);

            // Write the postings for this term
            vector<pair<int, float>> &documents = Postings[term];

            for (unsigned int j = 0; j < documents.size(); j++)
            {
                InvFile.writePostRecord(documents[j].first,
                                        documents[j].second);
                start++;
            }
        }
        else
        {
            // Keep an empty record for an unused bucket
            InvFile.writeDictRecord("", 0, 0);
        }
    }
}

%}
%x HTML
%x HREF
%x SCRIPT
%x STYLE
%x COMMENT

/*----------------------------------------------------------*/
/*Section of code which specifies lex substitution patterns */
/*----------------------------------------------------------*/


%%
    /* Ignore JavaScript content */
<INITIAL>"<"[Ss][Cc][Rr][Ii][Pp][Tt]([ \t\r\n][^>]*)?">" {
    BEGIN(SCRIPT);
}

<SCRIPT>"</"[Ss][Cc][Rr][Ii][Pp][Tt][ \t\r\n]*">" {
    BEGIN(INITIAL);
}

<SCRIPT>.     ;
<SCRIPT>\n    ;

    /* Ignore CSS content */
<INITIAL>"<"[Ss][Tt][Yy][Ll][Ee]([ \t\r\n][^>]*)?">" {
    BEGIN(STYLE);
}

<STYLE>"</"[Ss][Tt][Yy][Ll][Ee][ \t\r\n]*">" {
    BEGIN(INITIAL);
}

<STYLE>.     ;
<STYLE>\n    ;

    /* HTML Rules */
    /* Ignore HTML comments, including multiline comments */
<INITIAL>"<!--"     { BEGIN(COMMENT); }

<COMMENT>"-->"      { BEGIN(INITIAL); }
<COMMENT>.          ;
<COMMENT>\n         ;
<INITIAL>"<"       { BEGIN(HTML); }

<HTML>[Hh][Rr][Ee][Ff][ \t\r\n]*=[ \t\r\n]*[\"\']    { BEGIN(HREF); }

<HREF>[^\"'> \t\r\n]+    {
                              downcase(yytext);
                              ProcessToken(yytext);
                              BEGIN(HTML);
                          }

    /* Ignore anything else when working with HREF */
<HREF>.             ;
<HREF>\n            ;
    /* Leave HTML mode after the closing bracket */
<HTML>">"           { BEGIN(INITIAL); }
    /* Ignore all HTML chars */
<HTML>.             ;
<HTML>\n            ;

    /* Email */
[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}    {
                                                        downcase(yytext);
                                                        ProcessToken(yytext); }
    /* Websites */
https?:\/\/[A-Za-z0-9.\/_?=&%#:+~-]+    {
                                            ProcessToken(yytext); }
    /* Keep floating point numbers */
[0-9]+\.[0-9]+ { ProcessToken(yytext); }
    /* Keep Integers */
[0-9]+         { ProcessToken(yytext); }

    /* Downcase */
[A-Za-z]+      {   downcase(yytext);
                   ProcessToken(yytext); }
    /* Ignore Whitespace */
[ \t\r\n]+     ;

.              ;

%%
// global variables for the input directory pointer
// and output directory name for use in yywrap
DIR *InputDirPtr = NULL;
string InDirname;
string OutDirname;


// This is called once per file.
int yywrap()
{
struct dirent* InputDirEntryPtr;
string InFilename;

   // if there was an input file open 
   // close it to get ready for the next file 
   if (yyin != NULL)
   {
      fclose (yyin);
      yyin = NULL;
      //***  Just closed the file
      ProcessDocumentHashtable();
   }

   // skip over the hidden filenames that begin with dot
   do
   {
      InputDirEntryPtr = readdir (InputDirPtr);
   } while ((InputDirEntryPtr != NULL) &&
            (InputDirEntryPtr->d_name[0] == '.'));

   // if there are still files to process
   if(InputDirEntryPtr !=NULL) 
   {
      DocumentHT = new HashTable(DOCUMENT_HT_SIZE);
      DocumentTotalTokens = 0;
      InFilename = InDirname + '/' + InputDirEntryPtr->d_name;
      InvFile.writeMapRecord(InputDirEntryPtr->d_name);
      CurrentDocId++;
      // open the next file in the list as yyin
      InFilename = InDirname + '/'+ InputDirEntryPtr->d_name;
      cout << "\nProcessing file " << InFilename << endl;
      yyin = fopen (InFilename.c_str(), "r");

      // if file open failed, print an error
      if(yyin == NULL) 
         perror(InFilename.c_str());

   }
   // if yyin is NULL, return 1, else return 0
   return (yyin==NULL);
}

int main(int argc, char **argv)
{
    DIR *OutputDirPtr = NULL;
    CollectionHT = new HashTable(COLLECTION_HT_SIZE);

   if (argc != 3)
   {
      cerr << "Incorrect number of arguments.\n";
      return (1);
   }
      
   InDirname = argv[1];
   OutDirname = argv[2];
   InputDirPtr = opendir (InDirname.c_str());

   // open the input directory
   if (!InputDirPtr)
    {
        cerr << "Unable to open input directory: " << InDirname << endl;
        delete CollectionHT;
        return 1;
    }
   else
   {
      // open or create the output directory
      OutputDirPtr = opendir (OutDirname.c_str());
      if (!OutputDirPtr)
        {
        string Command = "mkdir -p " + OutDirname;
        system(Command.c_str());
        }
        else
        {
        closedir(OutputDirPtr);
        }

        if (!InvFile.openForWrite(OutDirname))
        {
        cerr << "Unable to create index files in: " << OutDirname << endl;
        return 1;
        }  

      // initialize the input and output file pointers
      yyin = NULL;
      yyout = NULL;

      // call yywrap and yylex to process the files
      yywrap();
      yylex();

      int collectionUsed;
      int collectionCollisions;
      int collectionLookups;

      CollectionHT->GetUsage(collectionUsed,
                    collectionCollisions,
                    collectionLookups);

    cout << "Collection unique tokens: "
        << collectionUsed << endl;

      cout << "\nCollection total tokens: "
         << CollectionTotalTokens << endl;

      // close the input and output directories
      (void) closedir (InputDirPtr);

   }
    cout << "Done tokenizing." << endl;
    WriteInvertedIndex();
    delete CollectionHT;
    CollectionHT = NULL;
    InvFile.closeAfterWriting();
   
}