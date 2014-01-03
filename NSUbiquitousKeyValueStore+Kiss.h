//
//  NSUbiquitousKeyValueStore+Kiss.h
//  KissNSUbiquitousKeyValueStore
//
//  Copyright (c) 2014 CHEN Xian'an <xianan.chen@gmail.com>. All rights reserved.
//  KissNSUbiquitousKeyValueStore is released under the MIT license. In short, it's royalty-free but you must you keep the copyright notice in your code or software distribution.

//

#import <Foundation/Foundation.h>

extern NSString * const KissNSUbiquitousKeyValueStoreDidChangeLocallyNotification;
extern NSString * const KissNSUbiquitousKeyValueStoreDidChangeLocallyKeyKey;
extern NSString * const KissNSUbiquitousKeyValueStoreDidChangeLocallyValueKey;

@interface NSUbiquitousKeyValueStore (Kiss)

+ (void)kiss_setup;
+ (void)kiss_setupWithCustomKeys:(NSDictionary *)propertyKeyPairs;

@end
