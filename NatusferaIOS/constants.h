//
//  constants.h
//  Natusfera
//
//  Created by Ken-ichi Ueda on 2/17/12.
//  Copyright (c) 2012 Natusfera. All rights reserved.
//

#ifndef Natusfera_constants_h
#define Natusfera_constants_h

#define INatUsernamePrefKey @"INatUsernamePrefKey"
#define INatPasswordPrefKey @"INatPasswordPrefKey"
#define INatTokenPrefKey    @"INatTokenPrefKey"
#define INatLastDeletedSync @"INatLastDeletedSync"
#define kINatAuthServiceExtToken @"INatAuthServiceExtToken"
#define kINatAuthService @"INatAuthService"
#define kINatAutocompleteNamesPrefKey @"INatAutocompleteNamesPrefKey"
#define kInatCustomBaseURLStringKey @"InatCustomBaseURLStringKey"
#define kInatAutouploadPrefKey @"InatAutouploadPrefKey"


#ifdef DEBUG1
    //#define INatBaseURL @"http://localhost:3000"
    #define INatBaseURL @"http://natusfera.gbif.es"
    //#define INatMediaBaseURL @"http://127.0.0.1:3000"
    #define INatMediaBaseURL @"http://natusfera.gbif.es"
    //#define INatWebBaseURL @"http://127.0.0.1:3000"
    #define INatWebBaseURL @"http://natusfera.gbif.es"
#else
    // base URL for all API requests
    #define INatBaseURL @"http://natusfera.gbif.es"

    // base URL for all media upload API requests
    #define INatMediaBaseURL @"http://natusfera.gbif.es"

    // base URL for all website requests
    #define INatWebBaseURL @"http://natusfera.gbif.es"
#endif

#endif
