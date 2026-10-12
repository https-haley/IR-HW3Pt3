#include <iostream>
#include <fstream>
#include <iomanip>
#include <algorithm>
#include <string>

#include "invertedFile.h"

using namespace std;

const int MAP_FILENAME_SIZE = 30;
const int POST_DOCID_SIZE = 4;
const int POST_WEIGHT_SIZE = 8;
const int DICT_TERM_SIZE = 14;
const int DICT_NUMDOCS_SIZE = 4;
const int DICT_START_SIZE = 6;


// ---------------- MAP FILE ----------------

mapFile::mapFile()
{
    numRecords = -1;
}

bool mapFile::openForWrite(string filename)
{
    mapStream.open(filename.c_str(), ios::out);

    if (!mapStream)
    {
        cout << "Could not open " << filename << " for writing.\n";
        return false;
    }

    numRecords = 0;
    return true;
}

bool mapFile::writeRecord(string filename)
{
    if (!mapStream || numRecords < 0)
        return false;

    mapStream << setw(MAP_FILENAME_SIZE)
              << filename.substr(0, min((int)filename.length(),
                                       MAP_FILENAME_SIZE))
              << endl;

    numRecords++;

    return true;
}

int mapFile::closeAfterWriting()
{
    if (!mapStream)
        return -1;

    int recordsWritten = numRecords;

    mapStream.close();
    numRecords = -1;

    return recordsWritten;
}


// ---------------- POST FILE ----------------

postFile::postFile()
{
    numRecords = -1;
}

bool postFile::openForWrite(string filename)
{
    postStream.open(filename.c_str(), ios::out);

    if (!postStream)
    {
        cout << "Could not open " << filename << " for writing.\n";
        return false;
    }

    numRecords = 0;
    return true;
}

bool postFile::writeRecord(int docId, float weight)
{
    if (!postStream || numRecords < 0)
        return false;

    postStream << setw(POST_DOCID_SIZE)
               << docId
               << " "
               << setw(POST_WEIGHT_SIZE)
               << weight
               << endl;

    numRecords++;

    return true;
}

int postFile::closeAfterWriting()
{
    if (!postStream)
        return -1;

    int recordsWritten = numRecords;

    postStream.close();
    numRecords = -1;

    return recordsWritten;
}


// ---------------- DICTIONARY FILE ----------------

dictFile::dictFile()
{
    numRecords = -1;
}

bool dictFile::openForWrite(string filename)
{
    dictStream.open(filename.c_str(), ios::out);

    if (!dictStream)
    {
        cout << "Could not open " << filename << " for writing.\n";
        return false;
    }

    numRecords = 0;
    return true;
}

bool dictFile::writeRecord(string term, int numDocs, int start)
{
    if (!dictStream || numRecords < 0)
        return false;

    dictStream << setw(DICT_TERM_SIZE)
               << term.substr(0, min((int)term.length(),
                                    DICT_TERM_SIZE))
               << " "
               << setw(DICT_NUMDOCS_SIZE)
               << numDocs
               << " "
               << setw(DICT_START_SIZE)
               << start
               << endl;

    numRecords++;

    return true;
}

int dictFile::closeAfterWriting()
{
    if (!dictStream)
        return -1;

    int recordsWritten = numRecords;

    dictStream.close();
    numRecords = -1;

    return recordsWritten;
}


// ---------------- INVERTED FILE ----------------

invertedFile::invertedFile()
{
    configFilename = "config.txt";
}

bool invertedFile::openForWrite(string outputDir)
{
    if (!outputDir.empty() && outputDir.back() != '/')
    {
        outputDir += "/";
    }

    bool mapOpened = map.openForWrite(outputDir + "map.txt");
    bool dictOpened = dict.openForWrite(outputDir + "dict.txt");
    bool postOpened = post.openForWrite(outputDir + "post.txt");

    configFilename = outputDir + "config.txt";

    return mapOpened && dictOpened && postOpened;
}

bool invertedFile::writeMapRecord(string filename)
{
    return map.writeRecord(filename);
}

bool invertedFile::writeDictRecord(string term, int numDocs, int start)
{
    return dict.writeRecord(term, numDocs, start);
}

bool invertedFile::writePostRecord(int docId, float weight)
{
    return post.writeRecord(docId, weight);
}

void invertedFile::closeAfterWriting()
{
    int mapRecords = map.closeAfterWriting();
    int dictRecords = dict.closeAfterWriting();
    int postRecords = post.closeAfterWriting();

    ofstream config(configFilename.c_str());

    if (config)
    {
        config << dictRecords << endl;
        config << postRecords << endl;
        config << mapRecords << endl;

        config.close();
    }
}