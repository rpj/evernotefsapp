/**
 * Autogenerated by Thrift
 *
 * DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING
 */

#import <Cocoa/Cocoa.h>

#import "TProtocol.h"
#import "TApplicationException.h"
#import "TProtocolUtil.h"

#import "UserStore.h"
#import "Types.h"
#import "Errors.h"
#import "Limits.h"

@interface EDAMSyncState : NSObject {
  EDAMTimestamp __currentTime;
  EDAMTimestamp __fullSyncBefore;
  int32_t __updateCount;
  int64_t __uploaded;

  BOOL __currentTime_isset;
  BOOL __fullSyncBefore_isset;
  BOOL __updateCount_isset;
  BOOL __uploaded_isset;
}

- (id) initWithCurrentTime: (EDAMTimestamp) currentTime fullSyncBefore: (EDAMTimestamp) fullSyncBefore updateCount: (int32_t) updateCount uploaded: (int64_t) uploaded;

- (void) read: (id <TProtocol>) inProtocol;
- (void) write: (id <TProtocol>) outProtocol;

- (EDAMTimestamp) currentTime;
- (void) setCurrentTime: (EDAMTimestamp) currentTime;
- (BOOL) currentTimeIsSet;

- (EDAMTimestamp) fullSyncBefore;
- (void) setFullSyncBefore: (EDAMTimestamp) fullSyncBefore;
- (BOOL) fullSyncBeforeIsSet;

- (int32_t) updateCount;
- (void) setUpdateCount: (int32_t) updateCount;
- (BOOL) updateCountIsSet;

- (int64_t) uploaded;
- (void) setUploaded: (int64_t) uploaded;
- (BOOL) uploadedIsSet;

@end

@interface EDAMSyncChunk : NSObject {
  EDAMTimestamp __currentTime;
  int32_t __chunkHighUSN;
  int32_t __updateCount;
  NSArray * __notes;
  NSArray * __notebooks;
  NSArray * __tags;
  NSArray * __searches;
  NSArray * __resources;
  NSArray * __expungedNotes;
  NSArray * __expungedNotebooks;
  NSArray * __expungedTags;
  NSArray * __expungedSearches;

  BOOL __currentTime_isset;
  BOOL __chunkHighUSN_isset;
  BOOL __updateCount_isset;
  BOOL __notes_isset;
  BOOL __notebooks_isset;
  BOOL __tags_isset;
  BOOL __searches_isset;
  BOOL __resources_isset;
  BOOL __expungedNotes_isset;
  BOOL __expungedNotebooks_isset;
  BOOL __expungedTags_isset;
  BOOL __expungedSearches_isset;
}

- (id) initWithCurrentTime: (EDAMTimestamp) currentTime chunkHighUSN: (int32_t) chunkHighUSN updateCount: (int32_t) updateCount notes: (NSArray *) notes notebooks: (NSArray *) notebooks tags: (NSArray *) tags searches: (NSArray *) searches resources: (NSArray *) resources expungedNotes: (NSArray *) expungedNotes expungedNotebooks: (NSArray *) expungedNotebooks expungedTags: (NSArray *) expungedTags expungedSearches: (NSArray *) expungedSearches;

- (void) read: (id <TProtocol>) inProtocol;
- (void) write: (id <TProtocol>) outProtocol;

- (EDAMTimestamp) currentTime;
- (void) setCurrentTime: (EDAMTimestamp) currentTime;
- (BOOL) currentTimeIsSet;

- (int32_t) chunkHighUSN;
- (void) setChunkHighUSN: (int32_t) chunkHighUSN;
- (BOOL) chunkHighUSNIsSet;

- (int32_t) updateCount;
- (void) setUpdateCount: (int32_t) updateCount;
- (BOOL) updateCountIsSet;

- (NSArray *) notes;
- (void) setNotes: (NSArray *) notes;
- (BOOL) notesIsSet;

- (NSArray *) notebooks;
- (void) setNotebooks: (NSArray *) notebooks;
- (BOOL) notebooksIsSet;

- (NSArray *) tags;
- (void) setTags: (NSArray *) tags;
- (BOOL) tagsIsSet;

- (NSArray *) searches;
- (void) setSearches: (NSArray *) searches;
- (BOOL) searchesIsSet;

- (NSArray *) resources;
- (void) setResources: (NSArray *) resources;
- (BOOL) resourcesIsSet;

- (NSArray *) expungedNotes;
- (void) setExpungedNotes: (NSArray *) expungedNotes;
- (BOOL) expungedNotesIsSet;

- (NSArray *) expungedNotebooks;
- (void) setExpungedNotebooks: (NSArray *) expungedNotebooks;
- (BOOL) expungedNotebooksIsSet;

- (NSArray *) expungedTags;
- (void) setExpungedTags: (NSArray *) expungedTags;
- (BOOL) expungedTagsIsSet;

- (NSArray *) expungedSearches;
- (void) setExpungedSearches: (NSArray *) expungedSearches;
- (BOOL) expungedSearchesIsSet;

@end

@interface EDAMNoteFilter : NSObject {
  int __order;
  BOOL __ascending;
  NSString * __words;
  EDAMGuid __notebookGuid;
  NSArray * __tagGuids;
  NSString * __timeZone;
  BOOL __inactive;

  BOOL __order_isset;
  BOOL __ascending_isset;
  BOOL __words_isset;
  BOOL __notebookGuid_isset;
  BOOL __tagGuids_isset;
  BOOL __timeZone_isset;
  BOOL __inactive_isset;
}

- (id) initWithOrder: (int) order ascending: (BOOL) ascending words: (NSString *) words notebookGuid: (EDAMGuid) notebookGuid tagGuids: (NSArray *) tagGuids timeZone: (NSString *) timeZone inactive: (BOOL) inactive;

- (void) read: (id <TProtocol>) inProtocol;
- (void) write: (id <TProtocol>) outProtocol;

- (int) order;
- (void) setOrder: (int) order;
- (BOOL) orderIsSet;

- (BOOL) ascending;
- (void) setAscending: (BOOL) ascending;
- (BOOL) ascendingIsSet;

- (NSString *) words;
- (void) setWords: (NSString *) words;
- (BOOL) wordsIsSet;

- (EDAMGuid) notebookGuid;
- (void) setNotebookGuid: (EDAMGuid) notebookGuid;
- (BOOL) notebookGuidIsSet;

- (NSArray *) tagGuids;
- (void) setTagGuids: (NSArray *) tagGuids;
- (BOOL) tagGuidsIsSet;

- (NSString *) timeZone;
- (void) setTimeZone: (NSString *) timeZone;
- (BOOL) timeZoneIsSet;

- (BOOL) inactive;
- (void) setInactive: (BOOL) inactive;
- (BOOL) inactiveIsSet;

@end

@interface EDAMNoteList : NSObject {
  int32_t __startIndex;
  int32_t __totalNotes;
  NSArray * __notes;
  NSArray * __stoppedWords;
  NSArray * __searchedWords;

  BOOL __startIndex_isset;
  BOOL __totalNotes_isset;
  BOOL __notes_isset;
  BOOL __stoppedWords_isset;
  BOOL __searchedWords_isset;
}

- (id) initWithStartIndex: (int32_t) startIndex totalNotes: (int32_t) totalNotes notes: (NSArray *) notes stoppedWords: (NSArray *) stoppedWords searchedWords: (NSArray *) searchedWords;

- (void) read: (id <TProtocol>) inProtocol;
- (void) write: (id <TProtocol>) outProtocol;

- (int32_t) startIndex;
- (void) setStartIndex: (int32_t) startIndex;
- (BOOL) startIndexIsSet;

- (int32_t) totalNotes;
- (void) setTotalNotes: (int32_t) totalNotes;
- (BOOL) totalNotesIsSet;

- (NSArray *) notes;
- (void) setNotes: (NSArray *) notes;
- (BOOL) notesIsSet;

- (NSArray *) stoppedWords;
- (void) setStoppedWords: (NSArray *) stoppedWords;
- (BOOL) stoppedWordsIsSet;

- (NSArray *) searchedWords;
- (void) setSearchedWords: (NSArray *) searchedWords;
- (BOOL) searchedWordsIsSet;

@end

@interface EDAMNoteCollectionCounts : NSObject {
  NSDictionary * __notebookCounts;
  NSDictionary * __tagCounts;

  BOOL __notebookCounts_isset;
  BOOL __tagCounts_isset;
}

- (id) initWithNotebookCounts: (NSDictionary *) notebookCounts tagCounts: (NSDictionary *) tagCounts;

- (void) read: (id <TProtocol>) inProtocol;
- (void) write: (id <TProtocol>) outProtocol;

- (NSDictionary *) notebookCounts;
- (void) setNotebookCounts: (NSDictionary *) notebookCounts;
- (BOOL) notebookCountsIsSet;

- (NSDictionary *) tagCounts;
- (void) setTagCounts: (NSDictionary *) tagCounts;
- (BOOL) tagCountsIsSet;

@end

@protocol EDAMNoteStore <NSObject>
- (EDAMSyncState *) getSyncState: (NSString *) authenticationToken;  // throws EDAMUserException *, EDAMSystemException *, TException
- (EDAMSyncChunk *) getSyncChunk: (NSString *) authenticationToken : (int32_t) afterUSN : (int32_t) maxEntries;  // throws EDAMUserException *, EDAMSystemException *, TException
- (NSArray *) listNotebooks: (NSString *) authenticationToken;  // throws EDAMUserException *, EDAMSystemException *, TException
- (EDAMNotebook *) getNotebook: (NSString *) authenticationToken : (EDAMGuid) guid;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (EDAMNotebook *) getDefaultNotebook: (NSString *) authenticationToken;  // throws EDAMUserException *, EDAMSystemException *, TException
- (EDAMNotebook *) createNotebook: (NSString *) authenticationToken : (EDAMNotebook *) notebook;  // throws EDAMUserException *, EDAMSystemException *, TException
- (int32_t) updateNotebook: (NSString *) authenticationToken : (EDAMNotebook *) notebook;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (int32_t) expungeNotebook: (NSString *) authenticationToken : (EDAMGuid) guid;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (NSArray *) listTags: (NSString *) authenticationToken;  // throws EDAMUserException *, EDAMSystemException *, TException
- (EDAMTag *) getTag: (NSString *) authenticationToken : (EDAMGuid) guid;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (EDAMTag *) createTag: (NSString *) authenticationToken : (EDAMTag *) tag;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (int32_t) updateTag: (NSString *) authenticationToken : (EDAMTag *) tag;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (void) untagAll: (NSString *) authenticationToken : (EDAMGuid) guid;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (int32_t) expungeTag: (NSString *) authenticationToken : (EDAMGuid) guid;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (NSArray *) listSearches: (NSString *) authenticationToken;  // throws EDAMUserException *, EDAMSystemException *, TException
- (EDAMSavedSearch *) getSearch: (NSString *) authenticationToken : (EDAMGuid) guid;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (EDAMSavedSearch *) createSearch: (NSString *) authenticationToken : (EDAMSavedSearch *) search;  // throws EDAMUserException *, EDAMSystemException *, TException
- (int32_t) updateSearch: (NSString *) authenticationToken : (EDAMSavedSearch *) search;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (int32_t) expungeSearch: (NSString *) authenticationToken : (EDAMGuid) guid;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (EDAMNoteList *) findNotes: (NSString *) authenticationToken : (EDAMNoteFilter *) filter : (int32_t) offset : (int32_t) maxNotes;  // throws EDAMUserException *, EDAMSystemException *, TException
- (EDAMNoteCollectionCounts *) findNoteCounts: (NSString *) authenticationToken : (EDAMNoteFilter *) filter;  // throws EDAMUserException *, EDAMSystemException *, TException
- (EDAMNote *) getNote: (NSString *) authenticationToken : (EDAMGuid) guid : (BOOL) withContent;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (NSString *) getNoteContent: (NSString *) authenticationToken : (EDAMGuid) guid;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (NSArray *) getNoteTagNames: (NSString *) authenticationToken : (EDAMGuid) guid;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (EDAMNote *) createNote: (NSString *) authenticationToken : (EDAMNote *) note;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (EDAMNote *) updateNote: (NSString *) authenticationToken : (EDAMNote *) note;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (int32_t) expungeNote: (NSString *) authenticationToken : (EDAMGuid) guid;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (int32_t) expungeNotes: (NSString *) authenticationToken : (NSArray *) noteGuids;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (int32_t) expungeInactiveNotes: (NSString *) authenticationToken;  // throws EDAMUserException *, EDAMSystemException *, TException
- (EDAMNote *) copyNote: (NSString *) authenticationToken : (EDAMGuid) noteGuid : (EDAMGuid) toNotebookGuid;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (EDAMResource *) getResource: (NSString *) authenticationToken : (EDAMGuid) guid : (BOOL) withData : (BOOL) withRecognition : (BOOL) withAttributes;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (int32_t) updateResource: (NSString *) authenticationToken : (EDAMResource *) resource;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (NSData *) getResourceData: (NSString *) authenticationToken : (EDAMGuid) guid;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (EDAMResource *) getResourceByHash: (NSString *) authenticationToken : (EDAMGuid) noteGuid : (NSData *) contentHash : (BOOL) withData : (BOOL) withRecognition;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (NSData *) getResourceRecognition: (NSString *) authenticationToken : (EDAMGuid) guid;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (EDAMResourceAttributes *) getResourceAttributes: (NSString *) authenticationToken : (EDAMGuid) guid;  // throws EDAMUserException *, EDAMSystemException *, EDAMNotFoundException *, TException
- (int64_t) getAccountSize: (NSString *) authenticationToken;  // throws EDAMUserException *, EDAMSystemException *, TException
- (EDAMNotebook *) getPublicNotebook: (EDAMUserID) userId : (NSString *) publicUri;  // throws EDAMSystemException *, EDAMNotFoundException *, TException
- (EDAMNoteList *) findPublicNotes: (EDAMNoteFilter *) filter : (int32_t) offset : (int32_t) maxNotes;  // throws EDAMUserException *, EDAMNotFoundException *, EDAMSystemException *, TException
@end

@interface EDAMNoteStoreClient : NSObject <EDAMNoteStore> {
  id <TProtocol> inProtocol;
  id <TProtocol> outProtocol;
}
- (id) initWithProtocol: (id <TProtocol>) protocol;
- (id) initWithInProtocol: (id <TProtocol>) inProtocol outProtocol: (id <TProtocol>) outProtocol;
@end

@interface EDAMNoteStoreConstants {
}
@end
