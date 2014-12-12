//
//  NSManagedObjectContext+Saving.m
//  skoleintra
//
//  Created by Alexey Minaev on 01/12/14.
//  Copyright (c) 2014 Apphuset. All rights reserved.
//

#import "NSManagedObjectContext+Saving.h"
#import "ITBStorageManager.h"

@implementation NSManagedObjectContext (Saving)

- (void)saveSynchronously:(BOOL)syncSave completion:(CoreSaveCompletionHandler)completion;
{
    if (![self hasChanges]) {

        if (completion)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, nil);
            });
        }
        
        return;
    }
    
    id saveBlock = ^{
        NSError *error = nil;
        BOOL     saved = NO;
        @try
        {
            saved = [self save:&error];
        }
        @catch(NSException *exception)
        {
            DBGLog(@"Unable to perform save: %@", (id)[exception userInfo] ? : (id)[exception reason]);
        }
        
        @finally
        {
            if (!saved) {
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(saved, error);
                    });
                }
            } else {
                if ([self parentContext]) {
                    [[self parentContext] saveSynchronously:syncSave completion:completion];
                }
                else {
                    if (completion) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(saved, error);
                        });
                    }
                }
            }
        }
    };
    
    if (YES == syncSave) {
        [self performBlockAndWait:saveBlock];
    } else {
        [self performBlock:saveBlock];
    }
}

@end
