/*
 Copyright (c) 2012-2014, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SFDirectoryManager.h"
#import "SFUserAccountManager.h"
#import "SFUserAccount.h"

static NSString * const kDefaultOrgName = @"org";

@implementation SFDirectoryManager

+ (instancetype)sharedManager {
    static dispatch_once_t pred;
    static SFDirectoryManager *manager = nil;
    dispatch_once(&pred, ^{
		manager = [[self alloc] init];
	});
    return manager;
}

+ (BOOL)ensureDirectoryExists:(NSString*)directory {
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:directory]) {
        NSError *error = nil;
        [manager createDirectoryAtPath:directory
           withIntermediateDirectories:YES
                            attributes:[NSDictionary dictionaryWithObjectsAndKeys:NSFileProtectionComplete, NSFileProtectionKey, nil]
                                 error:&error];
        if (error) {
            [self log:SFLogLevelError format:@"Error creating directory path: %@", [error localizedDescription]];
            return NO;
        } else {
            return YES;
        }
    } else {
        return YES;
    }
}

+ (NSString*)safeStringForDiskRepresentation:(NSString*)candidate {
    NSCharacterSet *invalidCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>:@"];
    return [[candidate componentsSeparatedByCharactersInSet:invalidCharacters] componentsJoinedByString:@"_"];
}

- (NSString*)directoryForOrg:(NSString*)orgId user:(NSString*)userId community:(NSString*)communityId type:(NSSearchPathDirectory)type components:(NSArray*)components {
    NSArray *directories = NSSearchPathForDirectoriesInDomains(type, NSUserDomainMask, YES);
    if (directories.count > 0) {
        NSString *directory = [directories objectAtIndex:0];
        if (nil != userId) {
            directory = [directory stringByAppendingPathComponent:[[self class] safeStringForDiskRepresentation:[NSString stringWithFormat:@"%@-%@", orgId?:kDefaultOrgName, userId]]];
            if (nil == communityId) {
                directory = [directory stringByAppendingPathComponent:@"internal"];
            } else {
                directory = [directory stringByAppendingPathComponent:[[self class] safeStringForDiskRepresentation:communityId]];
            }
        }
        
        for (NSString *component in components) {
            directory = [directory stringByAppendingPathComponent:component];
        }
        
        return directory;
    } else {
        return nil;
    }
}

- (NSString*)directoryForUser:(SFUserAccount*)user type:(NSSearchPathDirectory)type components:(NSArray*)components {
    if (nil == user) {
        user = [SFUserAccountManager sharedInstance].currentUser;
    }
    if (user) {
        NSAssert(user.credentials.organizationId, @"Organization ID must be set");
        return [self directoryForOrg:user.credentials.organizationId user:user.credentials.userId community:user.communityId type:type components:components];
    } else {
        return [self directoryForOrg:nil user:nil community:nil type:type components:components];
    }
}

- (NSString*)directoryOfCurrentUserForType:(NSSearchPathDirectory)type components:(NSArray*)components {
    return [self directoryForUser:nil type:type components:components];
}

@end
