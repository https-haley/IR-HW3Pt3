%{
#include <stdio.h>
#include <ctype.h>

void downcase (char *word)
{
    int i;
    for(i = 0; word[i] != '\0'; i++)
    {
        word[i] = tolower(word[i]);
    }
}
%}

%x HTML
%x HREF
%x SCRIPT
%x STYLE

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
                              printf("%s\n", yytext);
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
                                                        printf("%s\n", yytext); }
    /* Websites */
https?:\/\/[A-Za-z0-9.\/_?=&%#:+~-]+    {
                                            printf("%s\n", yytext); }
    /* Keep floating point numbers */
[0-9]+\.[0-9]+ { printf("%s\n", yytext); }
    /* Keep Integers */
[0-9]+         { printf("%s\n", yytext); }

    /* Downcase */
[A-Za-z]+      {   downcase(yytext);
                    printf("%s\n", yytext); }
    /* Ignore Whitespace */
[ \t\r\n]+     ;

.              ;

%%

// end of a input file
int yywrap()
{
    return 1;
}

int main()
{
    yylex();
    return 0;
}
