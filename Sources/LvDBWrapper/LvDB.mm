#import "LvDB.h"

#import <Foundation/Foundation.h>
#import <iostream>

#import "leveldb/db.h"
#import "leveldb/slice.h"
#import "leveldb/write_batch.h"
#import "leveldb/filter_policy.h"
#import "leveldb/cache.h"
#import "leveldb/zlib_compressor.h"
#import "leveldb/decompress_allocator.h"

/* ---------- ---------- ---------- ---------- ---------- ---------- ---------- */

int32_t get_int_value(leveldb::Slice slice, uint32_t offset) {
    int32_t retval = 0;
    // need to switch this to union based like the others.
    for(int i=0; i<4; i++) {
        // if I don't do the static cast, the top bit will be sign extended.
        retval |= (static_cast<uint8_t>(slice[offset+i])<<i*8);
    }
    return retval;
}


/* ---------- ---------- ---------- ---------- ---------- ---------- ---------- */

@implementation LvDB

leveldb::DB* db;
leveldb::Options options;
leveldb::ReadOptions readOptions;
leveldb::WriteOptions writeOptions;

- (id)initWithDBPath:(NSString *)path {
    if (self = [super init]) {
        options.create_if_missing = false;
        options.filter_policy = leveldb::NewBloomFilterPolicy(10);              //create a bloom filter to quickly tell if a key is in the database or not
        options.block_cache = leveldb::NewLRUCache(40 * 1024 * 1024);           //create a 40 mb cache (we use this on ~1gb devices)
        options.write_buffer_size = 4 * 1024 * 1024;                            //create a 4mb write buffer, to improve compression and touch the disk less
        options.compressors[0] = new leveldb::ZlibCompressorRaw(-1);            //use the new raw-zip compressor to write (and read)
        options.compressors[1] = new leveldb::ZlibCompressor();                 //also setup the old, slower compressor for backwards compatibility. This will only be used to read old compressed blocks.
        readOptions.decompress_allocator = new leveldb::DecompressAllocator();

        auto dbPath = [path UTF8String];
        leveldb::Status status = leveldb::DB::Open(options, dbPath, &db);
        if (!status.ok()) {
            return nil;
        }
    }
    return self;
}

/* ---------- ---------- ---------- */

- (BOOL)isKeyExist:(NSData *)key {
    leveldb::Slice dbKey = leveldb::Slice((const char *)[key bytes], [key length]);
    std::string value;
    leveldb::Status status = db->Get(readOptions, dbKey, &value);
    return status.ok();
}

/// Get a array of all keys stored in the leveldb.
/// @return NSArray
- (NSArray *)getAllKeys {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    leveldb::Iterator *iter = db->NewIterator(readOptions);
    for (iter->SeekToFirst(); iter->Valid(); iter->Next()) {
        auto key = iter->key();
        NSData *data = [[NSData alloc] initWithBytes:key.data() length:key.size()];
        [array addObject:data];
    }
    delete iter;
    return (NSArray *)array;
}

/// Get value with a specified key.
/// @param key a leveldb key
/// @return NSData
- (NSData *)getValue:(NSData *)key {
    leveldb::Slice dbKey = leveldb::Slice((const char *)[key bytes], [key length]);
    std::string value;
    
    leveldb::Status status = db->Get(readOptions, dbKey, &value);
    if (status.ok()) {
        return [NSData dataWithBytes:value.data() length:value.length()];
    }
    exit(1);
    //return [[NSData alloc] init];
}

/// Add or Update value with a specified key.
/// @param key a leveldb key
/// @param data new data
/// @return BOOL
- (BOOL)setValue:(NSData *)key :(NSData *)data {
    leveldb::Slice dbKey = leveldb::Slice((const char *)[key bytes], [key length]);
    leveldb::Slice newData = leveldb::Slice((const char *)[data bytes], [data length]);
    
    leveldb::WriteBatch batch;
    batch.Put(dbKey, newData);
    leveldb::Status status = db->Write(writeOptions, &batch);
    
    return status.ok();
}

/// Delete a specified key.
/// @param key a leveldb key
/// @return BOOL
- (BOOL)deleteValue:(NSData *)key {
    leveldb::Slice dbKey = leveldb::Slice((const char *)[key bytes], [key length]);
    leveldb::Status status = db->Delete(writeOptions, dbKey);
    return status.ok();
}

/// Export value with a specified key to a specified file.
/// @param key a leveldb key
/// @param path path of the file
/// @return BOOL
- (BOOL)exportValue:(NSData *)key :(NSString *)path {
    NSData *data = [self getValue:key];
    return [data writeToFile:path atomically:true];;
}

@end
