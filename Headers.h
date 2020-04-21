#import <UIKit/UIKit.h>

@interface _UIRemoteViewController : UIViewController
+ (NSInvocation *)requestViewController:(NSString *)className
	fromServiceWithBundleIdentifier:(NSString *)bundleIdentifier
	connectionHandler:(void(^)(_UIRemoteViewController *, NSError *))callback;
- (NSProxy *)serviceViewControllerProxy;
@end

@interface NSXPCInterface : NSObject
+ (instancetype)interfaceWithProtocol:(Protocol *)protocol;
@end

// Client
@protocol SERVRootViewControllerRemoteHost
@end

// Service
@protocol SERVRootViewControllerRemoteService
- (instancetype)init;
- (void)setText:(NSString *)text;
@end