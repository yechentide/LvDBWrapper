#ifndef LvDB_h
#define LvDB_h

#import <Foundation/Foundation.h>

@interface LvDB : NSObject

- (id)initWithDBPath:(NSString *)path;

- (BOOL)isKeyExist:(NSData *)key;

- (NSArray *)getAllKeys;
- (NSData *)getValue:(NSData *)key;
- (BOOL)setValue:(NSData *)key :(NSData *)data;
- (BOOL)deleteValue:(NSData *)key;

- (BOOL)exportValue:(NSData *)key :(NSString *)path;

@end

#endif /* LvDB_h */
