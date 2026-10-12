/* Filename:  hashtable.h
 * Author:    Haley and Tim
 * Date:      10/1/26
 * Purpose:   The header file for a hash table of strings and ints. 
*/

using namespace std;

class HashTable {
public:
   HashTable (const HashTable& ht );       // constructor for a copy
   HashTable(const unsigned long NumKeys);          // constructor of hashtable 
   ~HashTable();                           // destructor
   void Print (const char *filename) const;       
   void Insert (const string Key, const int Data); 
   void Increment (const string Key);
   int GetData (const string Key); 
   bool GetEntry(const unsigned long Index, string &Key, int &Data) const;
   unsigned long GetSize() const;
   void GetUsage (int &Used, int &Collisions, int &Lookups) const;
protected:
   struct StringIntPair // the datatype stored in the hashtable`
   {
      string key;
      int data;
   };
   unsigned long Find (const string Key); // the index of the ddr in the hashtable
private:
   StringIntPair *hashtable;        // the hashtable array itself
   unsigned long size;              // the hashtable size
   unsigned long used;
   unsigned long collisions;
   unsigned long lookups;
};
