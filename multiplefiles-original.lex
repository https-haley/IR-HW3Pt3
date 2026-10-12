/*----------------------------------------------------------------*/
/* Filename:  multiplefiles.lex                                   */
/* To compile: flex multiplefiles.lex                             */
/*            g++ -o multiplefiles lex.yy.c -lfl                  */
/* Flex can also use gcc or cc instead of g++                     */
/* Takes in and out directories: ./multiplefiles <indir> <outdir */
/*----------------------------------------------------------------*/

%{
#include <string.h>
#include <dirent.h>
#include <iostream>
extern "C" int yylex(void);
using namespace std;

#undef yywrap            // safety measure in case using old flex 

//---------  INSERT ANY CODE CALLED BY THE LEX RULES HERE --------

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

// Example of a function called inside yywrap
void ProcessDocumentHashtable()
{
   cout << endl;
   cout << "Document hashtable should have been filled.\n";
   cout << "Time to deal with its contents.\n";
}

%}

/*----------------------------------------------------------*/
/*Section of code which specifies lex substitution patterns */
/*----------------------------------------------------------*/

WORD			[A-Za-z][a-z]*

%%
{WORD}				DowncaseAndPrint(yytext); 
[\n\r\t ]			;
.					;
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

      // close the input and output directories
      (void) closedir (InputDirPtr);
      (void) closedir (OutputDirPtr);
   }
   cout << "Done tokenizing.  Good place to write the dict and post files."  << endl;
}