#ifndef LvDBWrapper_h
#define LvDBWrapper_h

#import <Foundation/Foundation.h>

@interface LvDBWrapper : NSObject

- (id)initWithDBPath:(NSString *)path;

- (BOOL)isKeyExist:(NSData *)key;

- (NSArray *)getAllKeys;
- (NSData *)getValue:(NSData *)key;
- (BOOL)setValue:(NSData *)key :(NSData *)data;
- (BOOL)deleteValue:(NSData *)key;

- (BOOL)exportValue:(NSData *)key :(NSString *)path;

@end

#endif /* LvDBWrapper_h */
