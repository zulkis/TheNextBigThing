//
//  ITBMacroses.h
//  TheNextBigThing
//
//  Created by Alexey Minaev on 12/12/14.
//  Copyright (c) 2014 IttiBitty. All rights reserved.
//

#ifndef TheNextBigThing_ITBMacroses_h
#define TheNextBigThing_ITBMacroses_h


/*
 * localization
 */

#pragma mark - localization macroses

#define LOC(key)    \
NSLocalizedStringWithDefaultValue((key), nil, [NSBundle mainBundle], @" ", nil)

/*
 * logging
 */

#pragma mark - logging macroses

#define ERROR_TO_LOG(__FORMAT__...)                 {NSString *__ERROR_STRING__ = [NSString stringWithFormat:__FORMAT__]; NSLog(@"ERROR::%s:%d:%@", __func__, __LINE__, __ERROR_STRING__);}

#if defined(SHOW_WARNINGS) && SHOW_WARNINGS
#define WARNING_TO_LOG(__FORMAT__...)               {NSString *__WARNING_STRING__ = [NSString stringWithFormat:__FORMAT__]; NSLog(@"WARNING::%s:%@", __func__, __WARNING_STRING__);}
#else
#define WARNING_TO_LOG(__FORMAT__...)
#endif

#ifdef DEBUG
#define DEBUG_LOG(__FORMAT__...)                {NSString *__DEBUG_STRING__ = [NSString stringWithFormat:__FORMAT__]; NSLog(@"DEBUG IN FUNCTION \'%s\' ON LINE \'%d\' :: Class [%@] called \'%@\', debug message:\"%@\"", __func__, __LINE__, [self class], NSStringFromSelector(_cmd), __DEBUG_STRING__);}
#define DBGLog(__FORMAT__...) NSLog(@"%@", [NSString stringWithFormat:__FORMAT__])
#else
#define DEBUG_LOG(__FORMAT__...)
#define DBGLog(__FORMAT__...)
#endif


/*
 * OS version defining
 */
#pragma mark - OS Version macroses

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

/*
 * Block helper
 */

#define weakify(__TARGET__) __typeof__(__TARGET__) __weak weak##__TARGET__ = __TARGET__;



#define strongify(__TARGET__) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__typeof__(__TARGET__) __strong __TARGET__ = weak##__TARGET__;\
_Pragma("clang diagnostic pop")


#define SAFE_MAIN_THREAD_EXECUTION(__CODE__) \
if ([NSThread isMainThread]) { \
{__CODE__}; \
} else { \
dispatch_sync(dispatch_get_main_queue(), ^{ \
{__CODE__}; \
}); \
}

#endif
