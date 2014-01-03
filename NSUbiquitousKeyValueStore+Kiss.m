//
//  NSUbiquitousKeyValueStore+Kiss.m
//  KissNSUbiquitousKeyValueStore
//
//  Copyright (c) 2014 CHEN Xian'an <xianan.chen@gmail.com>. All rights reserved.
//  KissNSUbiquitousKeyValueStore is released under the MIT license. In short, it's royalty-free but you must you keep the copyright notice in your code or software distribution.

//

#import "NSUbiquitousKeyValueStore+Kiss.h"
#import <objc/runtime.h>

NSString * const KissNSUbiquitousKeyValueStoreDidChangeLocallyNotification = @"KissNSUbiquitousKeyValueStoreDidChangeLocallyNotification";
NSString * const KissNSUbiquitousKeyValueStoreDidChangeLocallyKeyKey = @"KissNSUbiquitousKeyValueStoreDidChangeLocallyKeyKey";
NSString * const KissNSUbiquitousKeyValueStoreDidChangeLocallyValueKey = @"KissNSUbiquitousKeyValueStoreDidChangeLocallyValueKey";

#define SETTER_IMP(type, setter, key, boxedValue)                       \
imp_implementationWithBlock(^void(id sender, type value){               \
[sender setter:value forKey:key];                                       \
[[NSNotificationCenter defaultCenter] postNotificationName:KissNSUbiquitousKeyValueStoreDidChangeLocallyNotification object:nil userInfo:@{KissNSUbiquitousKeyValueStoreDidChangeLocallyKeyKey : key, KissNSUbiquitousKeyValueStoreDidChangeLocallyValueKey : boxedValue}] ; \
})

#define GETTER_IMP(type, getter, userDefaultsKey)      \
imp_implementationWithBlock(^type (id sender){         \
return [sender getter:userDefaultsKey];                \
})

#if !defined(OBJC_HIDE_64) && TARGET_OS_IPHONE && __LP64__
#define KISS_BOOL_TYPE @"B"
#else
#define KISS_BOOL_TYPE @"c"
#endif

@implementation NSUbiquitousKeyValueStore (Kiss)

+ (void)kiss_setup
{
  [self kiss_setupWithCustomKeys:nil];
}

+ (void)kiss_setupWithCustomKeys:(NSDictionary *)propertyKeyPairs
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    @autoreleasepool {
      NSDictionary *getters;
      NSDictionary *setters;
      NSDictionary *types;
      [self kiss_getDynamicGetters:&getters setters:&setters types:&types];
      for (id key in getters){
        NSString *getterName = getters[key];
        NSString *setterName = setters[key];
        if (!setterName){
          NSMutableString *mStr = [key mutableCopy];
          [mStr deleteCharactersInRange:NSMakeRange(0, 1)];
          NSString *part = [NSString stringWithFormat:@"set%@", [[key substringWithRange:NSMakeRange(0, 1)] uppercaseString]];
          [mStr insertString:part atIndex:0];
          [mStr appendString:@":"];
          setterName = mStr;
        }
        
        NSString *type = types[key];
        NSString *ubKey = propertyKeyPairs && propertyKeyPairs[key] ? propertyKeyPairs[key] : key;
        IMP imp = NULL;
        if ([type isEqualToString:@"@"])
          imp = SETTER_IMP(id, setObject, ubKey, value);
        else if ([type isEqualToString:KISS_BOOL_TYPE])
          imp = SETTER_IMP(BOOL, setBool, ubKey, (value ? @YES : @NO));
        else if ([type isEqualToString:@"d"])
          imp = SETTER_IMP(double, setDouble, ubKey, @(value));
        else if ([type isEqualToString:@"q"])
          imp = SETTER_IMP(long long, setLongLong, ubKey, @(value));
        else
          @throw [NSException exceptionWithName:@"KissNSUserDefaults" reason:[NSString stringWithFormat:@"type %@ is not supported by NSUbiquitousKeyValueStore, use object, bool, double, long long only.", type] userInfo:nil];
        
        SEL sel = NSSelectorFromString(setterName);
        const char *methodType = [[NSString stringWithFormat:@"v@:%@", types[key]] UTF8String];
        class_addMethod(self, sel, imp, methodType);
        
        if ([type isEqualToString:@"@"])
          imp = GETTER_IMP(id, objectForKey, ubKey);
        else if ([type isEqualToString:KISS_BOOL_TYPE])
          imp = GETTER_IMP(BOOL, boolForKey, ubKey);
        else if ([type isEqualToString:@"d"])
          imp = GETTER_IMP(double, doubleForKey, ubKey);
        else if ([type isEqualToString:@"q"])
          imp = GETTER_IMP(long long, longLongForKey, ubKey);
        else
          @throw [NSException exceptionWithName:@"KissNSUserDefaults" reason:[NSString stringWithFormat:@"type %@ is not supported by NSUbiquitousKeyValueStore, use object, bool, double, long long only.", type] userInfo:nil];
        
        sel = NSSelectorFromString(getterName);
        methodType = [[NSString stringWithFormat:@"%@@:", types[key]] UTF8String];
        class_addMethod(self, sel, imp, methodType);
      }
#if TARGET_OS_IPHONE
#ifdef UIKIT_EXTERN
      NSArray *notes = @[UIApplicationDidFinishLaunchingNotification, UIApplicationWillTerminateNotification, UIApplicationDidEnterBackgroundNotification];
#define hasNotes
#endif
#else
#ifdef _APPKITDEFINES_H
      NSArray *notes = @[NSApplicationWillTerminateNotification, NSApplicationWillResignActiveNotification];
#define hasNotes
#endif
#endif
#ifdef hasNotes
      [notes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
        [[NSNotificationCenter defaultCenter] addObserverForName:obj object:nil queue:nil usingBlock:^(NSNotification *note){
          [[self defaultStore] synchronize];
        }];
      }];
#endif
    }
  });
}

+ (NSString *)kiss_getAccessorName:(NSString *)accessor
{
  NSRange r = NSMakeRange(2, [accessor length]-2);
  if ((r = [accessor rangeOfString:@"," options:0 range:r]).location != NSNotFound)
    return [accessor substringWithRange:NSMakeRange(2, r.location-2)];
  
  return [accessor substringFromIndex:2];
}

+ (void)kiss_getDynamicGetters:(NSDictionary **)outGetters
                       setters:(NSDictionary **)outSetters
                         types:(NSDictionary **)outTypes
{
  NSMutableDictionary *getters = [NSMutableDictionary dictionary];
  NSMutableDictionary *setters = [NSMutableDictionary dictionary];
  NSMutableDictionary *types = [NSMutableDictionary dictionary];
  unsigned int outCount, i;
  objc_property_t *classProperties = class_copyPropertyList([self class], &outCount);
  for (i=0; i<outCount; i++){
    objc_property_t property = classProperties[i];
    const char *propChar = property_getName(property);
    if (propChar){
      const char *attr = property_getAttributes(property);
      if (strstr(attr, "D,")){ // only interests in dynamic property
        NSString *propName = [NSString stringWithUTF8String:propChar];
        char *subAttr = NULL;
        if ((subAttr = strstr(attr, ",G"))) // handle custom getter
          getters[propName] = [self kiss_getAccessorName:[NSString stringWithUTF8String:subAttr]];
        else
          getters[propName] = propName;
        
        if ((subAttr = strstr(attr, ",S"))) // handle custom setter
          setters[propName] = [self kiss_getAccessorName:[NSString stringWithUTF8String:subAttr]];
        
        types[propName] = [[NSString stringWithUTF8String:attr] substringWithRange:NSMakeRange(1, 1)];
      }
    }
  }
  
  free(classProperties);
  *outGetters = getters;
  *outSetters = [setters count] ? setters : nil;
  *outTypes = types;
}

@end
