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
string CurrentOutFilename;

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

// Example function definition used by a lex rule
// You probably don't want to do these couts in general
// but okay for debugging a few small input files
void DowncaseAndPrint (const char Str[])
{
char Ch;

   for (int i=0; i < (int)strlen(Str); i++)
   {
      if ('A' <= Str[i] && Str[i] <= 'Z')
      {
         Ch = (char) ('a' + Str[i] - 'A');
         fprintf (yyout, "%c", Ch); 
      }
      else
         fprintf (yyout, "%c", Str[i]); 
   }
   fprintf (yyout, "\n"); 
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

   DocumentHT->Print(CurrentOutFilename.c_str());

   delete DocumentHT;
   DocumentHT = NULL;
}
void WriteInvertedIndex()
{
   int start = 0;

   for (auto it = Postings.begin(); it != Postings.end(); it++)
   {
      string term = it->first;
      vector<pair<int, float>> &documents = it->second;

      // Ignore words appearing in only one document
      if (documents.size() <= 1)
         continue;

      InvFile.writeDictRecord(term, documents.size(), start);

      for (unsigned int i = 0; i < documents.size(); i++)
      {
         InvFile.writePostRecord(documents[i].first, documents[i].second);
         start++;
      }
   }
}

%}
%x HTML
%x HREF
%x SCRIPT
%x STYLE

/*----------------------------------------------------------*/
/*Section of code which specifies lex substitution patterns */
/*----------------------------------------------------------*/


%%
    /* Javascript rules */
<INITIAL>"<script"[^>]*">"    { BEGIN(SCRIPT); }

<SCRIPT>"</script>"           { BEGIN(INITIAL); }
    /* Ignore all javascript chars */
<SCRIPT>.                     ;
<SCRIPT>\n                    ;

    /* CSS rules */
<INITIAL>"<style"[^>]*">"     { BEGIN(STYLE); }

<STYLE>"</style>"             { BEGIN(INITIAL); }
    /* Ignore all CSS chars */
<STYLE>.                      ;
<STYLE>\n                     ;


    /* HTML Rules */
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
bool OutputFileIsOpen = false;


// This is called once per file.
int yywrap()
{
struct dirent* InputDirEntryPtr;
string InFilename;
string OutFilename;

   // if there was an input file open 
   // close it to get ready for the next file 
   if (yyin != NULL)
   {
      fclose (yyin);
      yyin = NULL;
      //***  Just closed the file
      ProcessDocumentHashtable();
   }

   // if there was an output file open
   // close it to get ready for the next file 
   if (OutputFileIsOpen)
   {
      fclose (yyout);
      OutputFileIsOpen = false;
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
      InvFile.writeMapRecord(InFilename);
      CurrentDocId++;
      // open the next file in the list as yyin
      InFilename = InDirname + '/'+ InputDirEntryPtr->d_name;
      cout << "\nProcessing file " << InFilename << endl;
      yyin = fopen (InFilename.c_str(), "r");

      // if file open failed, print an error
      if(yyin == NULL) 
         perror(InFilename.c_str());

//   Only needed if doing Multiway Merge (creates temporary token files)

      // open a matching output file and set it to yyout
      OutFilename = OutDirname + '/' + InputDirEntryPtr->d_name;
      CurrentOutFilename = OutFilename;
      yyout = fopen (OutFilename.c_str(), "w");

      // if file open failed, print an error
      if(yyout == NULL) 
         perror(OutFilename.c_str());
      else
          OutputFileIsOpen = true;
   }
   // if yyin is NULL, return 1, else return 0
   return (yyin==NULL);
}

int main(int argc, char **argv)
{
    DIR *OutputDirPtr = NULL;
    CollectionHT = new HashTable(COLLECTION_HT_SIZE);
    InvFile.openForWrite();

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
      cerr << "Unable to open input directory: " << InDirname << endl;
   else
   {
      // open or create the output directory
      OutputDirPtr = opendir (OutDirname.c_str());
      if (!OutputDirPtr)
      {
         string Command = "mkdir -p "+ OutDirname;
         system (Command.c_str());
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
      (void) closedir (OutputDirPtr);
   }
    cout << "Done tokenizing." << endl;
    WriteInvertedIndex();
    delete CollectionHT;
    CollectionHT = NULL;
    InvFile.closeAfterWriting();
   
}