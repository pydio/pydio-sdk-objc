# iOS Pydio Server API Wrapper

This is the iOS Pydio Server API wrapper which you can use in your application to communicate with Pydio servers in unified and quick way. This SDK encapsulates, in form of Objective-C messages, queries which you would have to send to server. It simplifies authorization logic and lets you operate on objects representing server data structures.

**If you would like to contribute to iOS Pydio Server API Wrapper, you are very welcome** :)

## Initializing project

Project uses third party libraries.
[AFNetworking][0] is used for network communication.
For unit testing [OCMockito][1] and [OCHamcrest][2] are used.

Third party libraries are referenced using git submodules. To initialize project the first time after performing `git clone` run `initialize_repo.sh` script:

```sh
$ ./initialize_repo.sh
``` 

## How to add Pydio Server API Wrapper to your project 
 
 You can add library as source code or as a static library.

1. To add by source code just copy `PydioSDK/PydioSDK/Classes` into your project. Remember to also add [AFNetworking][0].
2. To add static library do the following:
	- Open `PydioSDK/PydioSDK.xcodeproj`
  	- Build `PydioSDKLipo`
  	- Copy `PydioSDK/lipo-build/` directory into your project's directory and add header files
  	- Add linking with `libPydioSDK.a` in project's `Build Phases` tab
  	- Add `-ObjC` flag to `Other Linker flags` in `Build Settings`
  	- Add copied `lipo-build` directory to `Library Search Paths` in `Build Settings`
  	- Compile and run

## Usage instructions 

There are two basic classes in SDK:

 - PydioClient
 - ServersParamsManager

ServersParamsManager holds parameters set by user of the library or received durring authoriztion process. User sets name and password for given server, authorization process sets seed and secure token. ServersParamsManager is a singleton object.

Parameters used to communicate with Pydio servers are identified on a per server basis.

Pydio Client is created with server address so it uniquely identifies server parameters. **For each operation new Pydio client has to be created.**

Logging to server is done in lazy way, user of the library only has to set server credentials.
PydioClient does authorization automatically when needed.

In `ExampleApplication` directory you can find example application with usage of library classes.

All operations on PydioClient and ServersParamsManager were tested on main thread. 

### How to set user credentials:

```obj-c
ServersParamsManager *manager = [ServersParamsManager sharedManager];
User* user = [User userWithId:self.username.text AndPassword:self.password.text];
[manager setUser:user ForServer:[NSURL URLWithString:self.server.text]];
```

### How to ask for list of workspaces for given server

```obj-c
[[self pydioClient] listWorkspacesWithSuccess:^(NSArray *files) {
    self.workspaces = files;
    [self.tableView reloadData];
} failure:^(NSError *error) {
    if (error.code == PydioErrorGetSeedWithCaptcha || error.code == PydioErrorLoginWithCaptcha) {
        [self loadCaptcha];
    }
}];
```
As you can see you just call listWorkspaces and in case of success you reload your table data with answer and in case of failure you have to handle error case. 
Sometimes server might request additional authorization step, it might request to input captcha. In that situation current operation finishes as failure with captcha error and application developer has download captcha image using Pydio Client, present it to the user and relogin once again.

Pydio client is created for each invocation:

```obj-c
-(PydioClient *)pydioClient {
    return [[PydioClient alloc] initWithServer:[self.server absoluteString]];
}
```

## Architecture of library

**PydioClient:** exposes server API to library user, internally it uses OperationsClient and AuthorizationClient.

**OperationsClient:** is encapsulates operations performed on server.

**AuthorizationClient:** encapsulates authorization process, and other authorization operations.

OperationsClient and AuthorizationClient are internal classes and should not be used by application.

### PydioClient

Lets take a look at `listFiles` method, every new implementation of server API request - response should be similary.

```obj-c
-(BOOL)listNodes:(ListNodesRequestParams *)params WithSuccess:(void(^)(NSArray* nodes))success failure:(FailureBlock)failure {
    if (self.progress) {
        return NO;
    }
    [self setupCommons:success failure:failure];
    
    typeof(self) strongSelf = self;
    self.operationBlock = ^{
        [strongSelf.operationsClient listFiles:[params dictionaryRepresentation] WithSuccess:strongSelf.successResponseBlock failure:strongSelf.failureResponseBlock];
    };
    
    self.operationBlock();
    
    return YES;
}
```

Method is invoked with three arguments:

 - `(ListNodesRequestParams *)params` parameters to perform request 
 - `(void(^)(NSArray* nodes))success` success block called when operation finished with success, it takes response argument, (list of nodes) in this case
 - `(FailureBlock)failure` failure block called when operation failed with error

`self.operationBlock` represents actual operation. In this block appropriate method of OperationsClient is called. 

Specific construction of PydioClient method is needed to handle automatic authorizaton when operation fails with authorization error.

### OperationsClient

In `OperationsClient` we use AFNetworking to perform actual operation. 

All arguments required by given operation are set in this client:
 
 - server address
 - operation parameters (for example node id for list files, secue token if needed)
 - AFNetworking response serializers
 - success and failure blocks

Response serializer is actually compound serializer. It contains array of generic response serializers + response serializer specific for given operation. For example for `listFiles` we have:

```obj-c
NSArray *serializers = [self defaultResponseSerializersWithSerializer:[self createSerializerForListFiles]];
```

```obj-c
-(NSArray*)defaultResponseSerializersWithSerializer:(XMLResponseSerializer*)serializer {
    return @[
             [self createSerializerForNotAuthorized],
             [self createSerializerForErrorResponse],
             serializer,
             [self createFailingSerializer]
             ];
}
```

Generic serializers are following:

1. recognizer of authorization error
2. recognizer of server XML error response (missing parameter in request or wrong directory/node id)
3. recognizer of actual response
4. recognizer treating all other responses as error.

## How to contribute

If you like, you can add new not implemented operations, for example described [here][3].
Please <a href="http://pyd.io/contribute/cla">sign the Contributor License Agreement</a> before your PR can be merged.


 [0]: https://github.com/AFNetworking/AFNetworking
 [1]: https://github.com/jonreid/OCMockito
 [2]: https://github.com/hamcrest/OCHamcrest
 [3]: http://pyd.io/resources/serverapi/#!/access.fs
