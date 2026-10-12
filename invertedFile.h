#ifndef INVERTEDFILE_H
#define INVERTEDFILE_H

#include <fstream>
#include <string>

using namespace std;

class mapFile
{
private:
    fstream mapStream;
    int numRecords;

public:
    mapFile();
    bool openForWrite(string filename);
    bool writeRecord(string filename);
    int closeAfterWriting();
};

class postFile
{
private:
    fstream postStream;
    int numRecords;

public:
    postFile();
    bool openForWrite(string filename);
    bool writeRecord(int docId, float weight);
    int closeAfterWriting();
};

class dictFile
{
private:
    fstream dictStream;
    int numRecords;

public:
    dictFile();
    bool openForWrite(string filename);
    bool writeRecord(string term, int numDocs, int start);
    int closeAfterWriting();
};

class invertedFile
{
private:
    mapFile map;
    dictFile dict;
    postFile post;
    string configFilename;

public:
    invertedFile();

    bool openForWrite(string outputDir);

    bool writeMapRecord(string filename);
    bool writeDictRecord(string term, int numDocs, int start);
    bool writePostRecord(int docId, float weight);

    void closeAfterWriting();
};

#endif