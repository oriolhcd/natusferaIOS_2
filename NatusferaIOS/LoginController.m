//
//  LoginController.m
//  Natusfera
//
//  Created by Alex Shepard on 5/15/15.
//  Copyright (c) 2015 Natusfera. All rights reserved.
//

#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <NXOAuth2Client/NXOAuth2.h>
#import "LoginController.h"
#import "Analytics.h"
#import "NatusferaAppDelegate.h"
#import "GooglePlusAuthViewController.h"
#import "UIColor+Natusfera.h"
#import "Partner.h"
#import "User.h"
#import "UploadManager.h"
#import "Taxon.h"

@interface LoginController ()  {
    NSString    *iNatAccessToken;
    NSString    *accountType;
    BOOL        isLoginCompleted;
    NSInteger   lastAssertionType;
    BOOL        tryingGoogleReauth;
}
@property (atomic, readwrite, copy) LoginSuccessBlock currentSuccessBlock;
@property (atomic, readwrite, copy) LoginErrorBlock currentErrorBlock;
@end

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })

#pragma mark - NSNotification names

NSString *kUserLoggedInNotificationName = @"UserLoggedInNotificationName";
NSInteger INatMinPasswordLength = 6;

@implementation LoginController
@synthesize externalAccessToken;

- (instancetype)init {
    if (self = [super init]) {
        self.uploadManager = [[UploadManager alloc] init];
        
        [self initOAuth2Service];
        [self initGoogleLogin];
    }
    
    return self;
}

- (void)logout {
    
}

#pragma mark - Facebook

- (void)loginWithFacebookUsingViewController:(UIViewController *)viewController
                                     success:(LoginSuccessBlock)successBlock
                                     failure:(LoginErrorBlock)errorBlock {
    
    self.currentSuccessBlock = successBlock;
    self.currentErrorBlock = errorBlock;
    
    accountType = nil;
    accountType = kINatAuthServiceExtToken;
    isLoginCompleted = NO;

    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    [login
     logInWithReadPermissions: @[@"email"]
     fromViewController:viewController
     handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
         if (error) {
             if (error) {
                 [[Analytics sharedClient] event:kAnalyticsEventLoginFailed
                                  withProperties:@{ @"from": @"Facebook",
                                                    @"code": @(error.code) }];
                 
                 [self executeError:error];
                 
                 return;
             }
         } else if (result.isCancelled) {
             externalAccessToken = nil;
             
             [self executeError:nil];
         } else {
             externalAccessToken = [[[FBSDKAccessToken currentAccessToken] tokenString] copy];
             accountType = nil;
             accountType = kINatAuthServiceExtToken;
             [[Analytics sharedClient] event:kAnalyticsEventLogin
                              withProperties:@{ @"Via": @"Facebook" }];
             [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:accountType
                                                                  assertionType:[NSURL URLWithString:@"http://facebook.com"]
                                                                      assertion:externalAccessToken];
             [self executeSuccess:nil];
         }
     }];
}

#pragma mark - INat OAuth Login

- (void)createAccountWithEmail:(NSString *)email
                      password:(NSString *)password
                      username:(NSString *)username
                          site:(NSInteger)siteId
                       license:(NSString *)license
                       success:(LoginSuccessBlock)successBlock
                       failure:(LoginErrorBlock)errorBlock {
    
    self.currentSuccessBlock = successBlock;
    self.currentErrorBlock = errorBlock;
    
    NSString *localeString = [[NSLocale currentLocale] localeIdentifier];
    // format for rails
    localeString = [localeString stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
    // default to english
    if (!localeString) { localeString = @"en-US"; }
    
    [[Analytics sharedClient] debugLog:@"Network - Post Users"];
    
    [[RKClient sharedClient] post:@"/users.json"
                       usingBlock:^(RKRequest *request) {
                           request.params = @{
                                              @"user[email]": email,
                                              @"user[login]": username,
                                              @"user[password]": password,
                                              @"user[password_confirmation]": password,
                                              @"user[site_id]": @(siteId),
                                              @"user[preferred_observation_license]": license,
                                              @"user[preferred_photo_license]": license,
                                              @"user[preferred_sound_license]": license,
                                              @"user[locale]": localeString,
                                              };
                           
                           request.onDidLoadResponse = ^(RKResponse *response) {
                               NSError *error = nil;
                               id respJson = [NSJSONSerialization JSONObjectWithData:response.body
                                                                             options:NSJSONReadingAllowFragments
                                                                               error:&error];
                               
                               if (error) {
                                   [self executeError:error];
                                   return;
                               }
                               
                               if ([respJson valueForKey:@"errors"]) {
                                   // TODO: extract error from json and notify user
                                   NSArray *errors = [respJson valueForKey:@"errors"];
                                   //NSError *newError = [NSError errorWithDomain:@"org.natusfera"
                                   NSError *newError = [NSError errorWithDomain:@"es.gbif.natusfera"
                                                                           code:response.statusCode
                                                                       userInfo:@{
                                                                                  NSLocalizedDescriptionKey: errors.firstObject
                                                                                  }];
                                   [self executeError:newError];
                                   return;
                               }

                               [[Analytics sharedClient] event:kAnalyticsEventSignup];
                               
                               [self loginWithUsername:username
                                              password:password
                                               success:successBlock
                                               failure:errorBlock];
                               
                           };
                           
                           request.onDidFailLoadWithError = ^(NSError *error) {
                               [self executeError:error];
                           };
                           
                       }];
}

- (void)loginWithUsername:(NSString *)username
                 password:(NSString *)password
                  success:(LoginSuccessBlock)successBlock
                  failure:(LoginErrorBlock)errorBlock {
    
    self.currentSuccessBlock = successBlock;
    self.currentErrorBlock = errorBlock;
    
    accountType = nil;
    accountType = kINatAuthService;
    isLoginCompleted = NO;
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:accountType
                                                              username:username
                                                              password:password];
    
}

-(void)initOAuth2Service{
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                      object:[NXOAuth2AccountStore sharedStore]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification){
                                                      if (!isLoginCompleted) {
                                                          [self finishWithAuth2Login];
                                                      }
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification
                                                      object:[NXOAuth2AccountStore sharedStore]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification) {
                                                      id err = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
                                                      NSLog(@"err is %@", err);
                                                      if (err && [err isKindOfClass:[NSError class]]) {
                                                          [self executeError:err];
                                                      } else {
                                                          [self executeError:nil];
                                                      }
                                                  }];
}


-(void)finishWithAuth2Login{
    
    NXOAuth2AccountStore *sharedStore = [NXOAuth2AccountStore sharedStore];
    BOOL loginSucceeded = NO;
    for (NXOAuth2Account *account in [sharedStore accountsWithAccountType:accountType]) {
        NSString *accessT = [[account accessToken] accessToken];
        if (accessT && [accessT length] > 0){
            iNatAccessToken = nil;
            iNatAccessToken = [NSString stringWithFormat:@"Bearer %@", accessT ];
            loginSucceeded = YES;
        }
    }
    
    if (loginSucceeded) {
        if ([accountType isEqualToString:kINatAuthService]) {
            [[Analytics sharedClient] event:kAnalyticsEventLogin
                             //withProperties:@{ @"Via": @"Natusfera" }];
                            withProperties:@{ @"Via": @"Natusfera" }];
        }
        isLoginCompleted = YES;
        [[NSUserDefaults standardUserDefaults] setValue:iNatAccessToken
                                                 forKey:INatTokenPrefKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NatusferaAppDelegate *app = (NatusferaAppDelegate *)[[UIApplication sharedApplication] delegate];
        [RKClient.sharedClient setValue:iNatAccessToken forHTTPHeaderField:@"Authorization"];
        [RKClient.sharedClient setAuthenticationType:RKRequestAuthenticationTypeNone];
        [app.photoObjectManager.client setValue:iNatAccessToken forHTTPHeaderField:@"Authorization"];
        [app.photoObjectManager.client setAuthenticationType: RKRequestAuthenticationTypeNone];
        [self removeOAuth2Observers];
        
        // because we're in the midst of switching the default URL, and adding access tokens,
        // we can't seem to make an object loader fetch here. so instead we do the ugly GET
        // and do the User object mapping manually. admittedly not ideal, and worth another
        // look when we upgrade to RK 0.2x
        [[Analytics sharedClient] debugLog:@"Network - Get Me User"];
        [[RKClient sharedClient] get:@"/users/edit.json"
                          usingBlock:^(RKRequest *request) {
                              
                              request.onDidFailLoadWithError = ^(NSError *error) {
                                  NSLog(@"error fetching self: %@", error.localizedDescription);
                                  [self executeError:error];
                              };
                              
                              request.onDidLoadResponse = ^(RKResponse *response) {
                                  NSError *error = nil;
                                  id parsedData = [NSJSONSerialization JSONObjectWithData:response.body
                                                                                  options:NSJSONReadingAllowFragments
                                                                                    error:&error];
                                  if (error) {
                                      NSLog(@"error parsing json: %@", error.localizedDescription);
                                  }
                                  
                                  NSManagedObjectContext *context = [NSManagedObjectContext defaultContext];
                                  User *user = [[User alloc] initWithEntity:[User entity]
                                             insertIntoManagedObjectContext:context];
                                  user.login = [parsedData objectForKey:@"login"] ?: nil;
                                  user.recordID = [parsedData objectForKey:@"id"] ?: nil;
                                  user.observationsCount = [parsedData objectForKey:@"observations_count"] ?: nil;
                                  user.identificationsCount = [parsedData objectForKey:@"identifications_count"] ?: nil;
                                  user.siteId = NULL_TO_NIL([parsedData objectForKey:@"site_id"])?: [NSNumber numberWithInt:0];
                                  
                                  [[Analytics sharedClient] registerUserWithIdentifier:user.recordID.stringValue];
                                  
                                  NSError *saveError = nil;
                                  [[[RKObjectManager sharedManager] objectStore] save:&saveError];
                                  if (saveError) {
                                      [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error saving: %@",
                                                                          saveError.localizedDescription]];
                                      [self executeError:saveError];
                                      return;
                                  }
                                  
                                  NSString *userName = [parsedData objectForKey:@"login"];
                                  [[NSUserDefaults standardUserDefaults] setValue:userName
                                                                           forKey:INatUsernamePrefKey];
                                  
                                  [[NSUserDefaults standardUserDefaults] setValue:iNatAccessToken
                                                                           forKey:INatTokenPrefKey];
                                  [[NSUserDefaults standardUserDefaults] synchronize];
                                  
                                  [self executeSuccess:nil];

                                  [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedInNotificationName
                                                                                      object:nil];
                              };
                          }];        
    } else {
        [[Analytics sharedClient] event:kAnalyticsEventLoginFailed
                         //withProperties:@{ @"from": @"Natusfera" }];
                        withProperties:@{ @"from": @"Natusfera" }];
        
        [self executeError:nil];
    }
}

-(void) removeOAuth2Observers{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                  object:[NXOAuth2AccountStore sharedStore]];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NXOAuth2AccountStoreDidFailToRequestAccessNotification
                                                  object:[NXOAuth2AccountStore sharedStore]];
}

#pragma mark - Google methods

- (void)loginWithGoogleUsingNavController:(UINavigationController *)nav
                                  success:(LoginSuccessBlock)success
                                  failure:(LoginErrorBlock)error {
    
    self.currentSuccessBlock = success;
    self.currentErrorBlock = error;
    
    accountType = nil;
    accountType = kINatAuthServiceExtToken;
    isLoginCompleted = NO;

    [[GIDSignIn sharedInstance] signOut];
    [[GIDSignIn sharedInstance] signIn];
}

- (NSString *)scopesForGoogleSignin {
    GIDSignIn *signin= [GIDSignIn sharedInstance];
    
    __block NSString *scopes;
    [signin.scopes enumerateObjectsUsingBlock:^(NSString *scope, NSUInteger idx, BOOL *stop) {
        if (idx == 0)
            scopes = [NSString stringWithString:scope];
        else
            scopes = [scopes stringByAppendingString:[NSString stringWithFormat:@" %@", scope]];
    }];
    
    return scopes;
}

- (NSString *)clientIdForGoogleSignin {
    return [[GIDSignIn sharedInstance] clientID];
}

- (GIDSignIn *)googleSignin {
    return [GIDSignIn sharedInstance];
}



-(void) initGoogleLogin {
    GIDSignIn *googleSignIn = [GIDSignIn sharedInstance];
    googleSignIn.shouldFetchBasicProfile = true;

    googleSignIn.clientID = GoogleClientId;

    [googleSignIn setDelegate:self];
    [googleSignIn signInSilently]; //linea comentada M.Lujano:01/12/16
}

-(void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {
    externalAccessToken = [[[user authentication] accessToken] copy];

    if (externalAccessToken != nil) {
        [[Analytics sharedClient] event:kAnalyticsEventLogin
                         withProperties:@{ @"Via": @"Google+" }];
        
        accountType = kINatAuthServiceExtToken;
        [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:accountType
                                                             assertionType:[NSURL URLWithString:@"http://google.com"]
                                                                 assertion:externalAccessToken];
        tryingGoogleReauth = NO;
        [self executeSuccess:nil];
    }
}

-(void)signIn:(GIDSignIn *)signIn didDisconnectWithUser:(GIDGoogleUser *)user withError:(NSError *)error {
    externalAccessToken = nil;
}

#pragma mark - Success / Failure helpers

- (void)executeSuccess:(NSDictionary *)results {
    @synchronized(self) {
        if (self.currentSuccessBlock) {
            self.currentSuccessBlock(results);
        }
        
        self.currentSuccessBlock = nil;
        self.currentErrorBlock = nil;
    }
}

- (void)executeError:(NSError *)error {
    @synchronized(self) {
        if (self.currentErrorBlock) {
            self.currentErrorBlock(error);
        }
        
        self.currentSuccessBlock = nil;
        self.currentErrorBlock = nil;
    }
}

#pragma mark - Partners

- (void)loggedInUserSelectedPartner:(Partner *)partner completion:(void (^)(void))completion {
    // be extremely defensive here. an invalid baseURL shouldn't be possible,
    // but if it does happen, nothing in the app will work.
    NSURL *partnerURL = partner.baseURL;
    if (!partnerURL) { return; }
    [[NSUserDefaults standardUserDefaults] setObject:partnerURL.absoluteString
                                              forKey:kInatCustomBaseURLStringKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [((NatusferaAppDelegate *)[UIApplication sharedApplication].delegate) reconfigureForNewBaseUrl];
    
    // put user object changing site id
    User *me = [self fetchMe];
    if (!me) { return; }
    me.siteId = @(partner.identifier);
    
    // delete any stashed taxa
    [Taxon deleteAll];
    
    NSError *saveError = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&saveError];
    if (saveError) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error saving: %@",
                                            saveError.localizedDescription]];
        return;
    }
    
    [[Analytics sharedClient] debugLog:@"Network - Re-fetch Taxa after login"];
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:@"/taxa"
                                                    usingBlock:^(RKObjectLoader *loader) {
                                                        
                                                        loader.objectMapping = [Taxon mapping];
                                                        
                                                        loader.onDidLoadObjects = ^(NSArray *objects) {
                                                            
                                                            // update timestamps on taxa objects
                                                            NSDate *now = [NSDate date];
                                                            [objects enumerateObjectsUsingBlock:^(INatModel *o,
                                                                                                  NSUInteger idx,
                                                                                                  BOOL *stop) {
                                                                [o setSyncedAt:now];
                                                            }];
                                                            
                                                            NSError *saveError = nil;
                                                            [[[RKObjectManager sharedManager] objectStore] save:&saveError];
                                                            if (saveError) {
                                                                [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Error saving store: %@",
                                                                                                    saveError.localizedDescription]];
                                                            }
                                                        };
                                                    }];
    
    [[Analytics sharedClient] debugLog:@"Network - Put Me User"];
    [[RKClient sharedClient] put:[NSString stringWithFormat:@"/users/%ld", (long)me.recordID.integerValue]
                      usingBlock:^(RKRequest *request) {
                          request.params = @{
                                             @"user[site_id]": @(partner.identifier),
                                             };
                          request.onDidFailLoadWithError = ^(NSError *error) {
                              NSLog(@"error");
                          };
                          request.onDidLoadResponse = ^(RKResponse *response) {
                              if (completion) {
                                  completion();
                              }
                          };
                      }];
}

#pragma mark - Convenience method for fetching the logged in User

- (User *)fetchMe {
    NSString *username = [[NSUserDefaults standardUserDefaults] valueForKey:INatUsernamePrefKey];
    if (username) {
        NSFetchRequest *meFetch = [[NSFetchRequest alloc] initWithEntityName:@"User"];
        meFetch.predicate = [NSPredicate predicateWithFormat:@"login == %@", username];
        NSError *fetchError;
        User *me = [[[User managedObjectContext] executeFetchRequest:meFetch error:&fetchError] firstObject];
        if (fetchError) {
            [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error fetching: %@",
                                                fetchError.localizedDescription]];
            return nil;
        }
        return me;
    } else {
        return nil;
    }
}

- (BOOL)isLoggedIn {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = [defaults objectForKey:INatUsernamePrefKey];
    NSString *inatToken = [defaults objectForKey:INatTokenPrefKey];
    
    return ((username && username.length > 0) || (inatToken && inatToken.length > 0)) || externalAccessToken != nil;
}

@end
