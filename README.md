# Information Retrieval – HW3 Part III

## Overview

This project was developed for my Information Retrieval course at the University of Arkansas. The goal was to build an inverted index for a collection of HTML documents using C++, Flex, and hash tables.

The program processes multiple HTML files, extracts tokens, tracks how frequently each term appears in each document, and creates an inverted index that can be used to locate documents containing specific terms.

## Features

- Tokenizes multiple HTML documents using Flex.
- Converts tokens to lowercase and limits token length.
- Uses hash tables to track term frequencies.
- Builds an inverted index with document IDs and term frequencies.
- Removes terms that appear in only one document.
- Writes the index to fixed-length dictionary, postings, and document mapping files.

## Technologies Used

- C++
- Flex (Lex)
- Linux / Bash
- Hash tables

## Project Files

| File | Description |
|---|---|
| `multiplefiles.lex` | Flex tokenizer for processing HTML documents |
| `hashtable.cpp` / `hashtable.h` | Hash table implementation |
| `invertedFile.cpp` / `invertedFile.h` | Creates the inverted index files |
| `hw3pt3.sh` | Compiles and runs the program |
| `tinyfiles/` | Small collection of HTML files used for testing |
| `large-index-samples.txt` | Samples from the index generated using the larger document collection |

## How to Run

The project was developed and tested in a Linux environment with Flex and g++ installed.

**1. Make the shell script executable:**

```bash
chmod +x hw3pt3.sh
```

**2. Run the program using the included test files:**

```bash
./hw3pt3.sh tinyfiles tinyoutput
```

The script compiles the Flex tokenizer and C++ source files before running the program.

## Output Files

The program generates four files:

- `dict.txt` — Dictionary of indexed terms, document frequencies, and posting starting positions.
- `post.txt` — Posting records containing document IDs and term frequencies.
- `map.txt` — Maps document IDs to their corresponding file paths.
- `config.txt` — Stores the number of dictionary, posting, and mapping records.

## Testing and Results

The program was tested with both a small collection of four HTML files and a larger collection of 1,200 HTML files.

| Result | Small Collection | Large Collection |
|---|---:|---:|
| Documents processed | 4 | 1,200 |
| Total tokens | 20 | 5,266,293 |
| Unique terms before filtering | 10 | 160,997 |
| Dictionary terms after filtering | 3 | 57,391 |
| Posting records | 10 | 859,021 |

Terms appearing in only one document were excluded from the final dictionary.

## Notes

The repository does not include the full large HTML collection because of its size. Sample output from the larger collection is provided in `large-index-samples.txt`.

The tokenizer is based on the earlier parts of the assignment and may retain some unwanted HTML-related tokens.

## Author

Haley Trejo  
University of Arkansas  
Computer Science
