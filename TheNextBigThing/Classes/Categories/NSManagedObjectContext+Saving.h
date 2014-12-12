//
//  NSManagedObjectContext+Saving.h
//  skoleintra
//
//  Created by Alexey Minaev on 01/12/14.
//  Copyright (c) 2014 Apphuset. All rights reserved.
//

#import <CoreData/CoreData.h>

typedef void (^CoreSaveCompletionHandler)(BOOL success, NSError *error);

@interface NSManagedObjectContext (Saving)

- (void)saveSynchronously:(BOOL)syncSave completion:(CoreSaveCompletionHandler)completion;

@end
